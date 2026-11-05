// Turns OpenStreetMap extracts into game data. Run tools/download_osm_detail.ps1 first, then:
//   node tools/process_geography.mjs
// Outputs: efate-game-map.json (runtime), coast-distance.bin (runtime), land-cover.bin (bake only).
// The game map is 1:10, so a town block is only a few metres across: the road network is generalised the way a
// printed map does it, and individual buildings become a density raster that the world bake draws houses from.
import fs from 'node:fs';
const geo = name => new URL(`../assets/geography/${name}`, import.meta.url);
const raw = JSON.parse(fs.readFileSync(geo('efate-osm.json'), 'utf8'));
const detail = JSON.parse(fs.readFileSync(new URL('./.cache/osm-detail/efate-detail.json', import.meta.url), 'utf8'));

// ---- Coast (unchanged source) ----
const parts = raw.elements.filter(e => e.tags?.natural === 'coastline' && e.geometry?.length).map(e => ({ ids: e.nodes.slice(), points: e.geometry.slice() }));
const loops = [];
while (parts.length) {
  const chain = parts.shift();
  let joined = true;
  while (joined && chain.ids[0] !== chain.ids.at(-1)) {
    joined = false;
    for (let i = 0; i < parts.length; i++) {
      let p = parts[i];
      if (chain.ids.at(-1) === p.ids.at(-1)) p = { ids: p.ids.toReversed(), points: p.points.toReversed() };
      if (chain.ids.at(-1) === p.ids[0]) { chain.ids.push(...p.ids.slice(1)); chain.points.push(...p.points.slice(1)); parts.splice(i, 1); joined = true; break; }
      if (chain.ids[0] === p.ids[0]) p = { ids: p.ids.toReversed(), points: p.points.toReversed() };
      if (chain.ids[0] === p.ids.at(-1)) { chain.ids.unshift(...p.ids.slice(0, -1)); chain.points.unshift(...p.points.slice(0, -1)); parts.splice(i, 1); joined = true; break; }
    }
  }
  loops.push(chain);
}
const project = p => [(p.lon - 168.363) * 10600, -(p.lat + 17.6625) * 11100];
const area = pts => Math.abs(pts.reduce((a, p, i) => { const q = pts[(i + 1) % pts.length]; return a + p[0] * q[1] - q[0] * p[1]; }, 0) / 2);
function simplify(points, gap) { const out = [points[0]]; for (let i = 1; i < points.length - 1; i++) if (Math.hypot(points[i][0] - out.at(-1)[0], points[i][1] - out.at(-1)[1]) > gap) out.push(points[i]); out.push(points.at(-1)); return out; }
const polygons = loops.filter(p => p.ids[0] === p.ids.at(-1)).map(p => simplify(p.points.map(project), 12)).filter(p => p.length > 6).sort((a, b) => area(b) - area(a));
const places = raw.elements.filter(e => e.type === 'node' && e.tags?.place).map(e => ({ name: e.tags.name ?? e.tags['name:en'] ?? '', position: project(e) }));

// ---- Roads ----
// rank: draw/selection priority. spacing: closest a road may run beside an already kept one. minRun: shortest stretch worth keeping.
const CLASSES = {
  runway: { rank: 0, spacing: 0, minRun: 0 },
  secondary: { rank: 1, spacing: 14, minRun: 6 },
  tertiary: { rank: 2, spacing: 16, minRun: 12 }, tertiary_link: { rank: 2, spacing: 16, minRun: 12, as: 'tertiary' },
  unclassified: { rank: 3, spacing: 18, minRun: 16 },
  residential: { rank: 4, spacing: 22, minRun: 20 }, living_street: { rank: 4, spacing: 22, minRun: 20, as: 'residential' },
  service: { rank: 5, spacing: 26, minRun: 26 },
  track: { rank: 6, spacing: 38, minRun: 60 },
};
const UNPAVED = new Set(['unpaved', 'dirt', 'compacted', 'gravel', 'ground', 'grass', 'sand', 'earth', 'fine_gravel']);
const VILA = places.find(p => p.name === 'Port Vila').position;
const ways = detail.elements.filter(e => e.type === 'way' && e.geometry?.length > 1 && ((e.tags?.highway && CLASSES[e.tags.highway]) || e.tags?.aeroway === 'runway'));
const keyOf = g => `${g.lat.toFixed(7)},${g.lon.toFixed(7)}`;

// OSM splits streets at every junction; join stretches first so short pieces of a long street are not discarded.
function chainWays(list) {
  const incident = new Map();
  const touch = (k, w) => { if (!incident.has(k)) incident.set(k, []); incident.get(k).push(w); };
  for (const w of list) { touch(keyOf(w.geometry[0]), w); touch(keyOf(w.geometry.at(-1)), w); }
  const used = new Set(), chains = [];
  for (const start of list) {
    if (used.has(start)) continue;
    used.add(start);
    let geometry = start.geometry.slice();
    const grow = () => {
      for (;;) {
        const k = keyOf(geometry.at(-1)), around = incident.get(k);
        if (around.length !== 2) return;
        const next = around.find(w => !used.has(w));
        if (!next) return;
        used.add(next);
        const forward = keyOf(next.geometry[0]) === k;
        geometry.push(...(forward ? next.geometry : next.geometry.toReversed()).slice(1));
      }
    };
    grow();
    geometry.reverse();
    grow();
    chains.push({ id: start.id, tags: start.tags, geometry });
  }
  return chains;
}
const lengthOf = pts => { let l = 0; for (let i = 1; i < pts.length; i++) l += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]); return l; };
function resample(pts, step) {
  const out = [pts[0]];
  for (let i = 1; i < pts.length; i++) {
    const [a, b] = [pts[i - 1], pts[i]], l = Math.hypot(b[0] - a[0], b[1] - a[1]), n = Math.max(1, Math.ceil(l / step));
    for (let k = 1; k <= n; k++) out.push([a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n]);
  }
  return out;
}
function douglas(pts, tol) {
  const keep = new Uint8Array(pts.length); keep[0] = keep[pts.length - 1] = 1;
  const stack = [[0, pts.length - 1]];
  while (stack.length) {
    const [s, e] = stack.pop(); let far = -1, best = tol;
    const [ax, ay] = pts[s], dx = pts[e][0] - ax, dy = pts[e][1] - ay, den = dx * dx + dy * dy;
    for (let i = s + 1; i < e; i++) {
      const t = den ? Math.max(0, Math.min(1, ((pts[i][0] - ax) * dx + (pts[i][1] - ay) * dy) / den)) : 0;
      const d = Math.hypot(pts[i][0] - ax - t * dx, pts[i][1] - ay - t * dy);
      if (d > best) { best = d; far = i; }
    }
    if (far >= 0) { keep[far] = 1; stack.push([s, far], [far, e]); }
  }
  return pts.filter((_, i) => keep[i]);
}
// Rounds corners by a bounded amount: bends become curves, but the road never strays from its mapped line.
function roundCorners(pts, cut, passes = 2) {
  let cur = pts;
  for (let pass = 0; pass < passes; pass++) {
    const out = [cur[0]];
    for (let i = 1; i < cur.length - 1; i++) {
      for (const [from, sign] of [[cur[i - 1], 0], [cur[i + 1], 1]]) {
        const l = Math.hypot(from[0] - cur[i][0], from[1] - cur[i][1]), f = Math.min(0.25, cut / Math.max(l, 0.001));
        const p = [cur[i][0] + (from[0] - cur[i][0]) * f, cur[i][1] + (from[1] - cur[i][1]) * f];
        if (sign === 0) out.push(p); else out.push(p);
      }
    }
    out.push(cur.at(-1));
    cur = out;
  }
  return cur;
}
const smooth = pts => douglas(roundCorners(douglas(pts, 0.3), 3.5), 0.1).map(p => [+p[0].toFixed(2), +p[1].toFixed(2)]);

// Spatial hash over kept road segments.
const CELL = 40, grid = new Map();
function addSegments(pts) {
  for (let i = 1; i < pts.length; i++) {
    const seg = [pts[i - 1], pts[i]];
    const n = Math.max(1, Math.ceil(Math.hypot(seg[1][0] - seg[0][0], seg[1][1] - seg[0][1]) / (CELL / 2)));
    const cells = new Set();
    for (let k = 0; k <= n; k++) cells.add(`${Math.floor((seg[0][0] + (seg[1][0] - seg[0][0]) * k / n) / CELL)},${Math.floor((seg[0][1] + (seg[1][1] - seg[0][1]) * k / n) / CELL)}`);
    for (const c of cells) { if (!grid.has(c)) grid.set(c, []); grid.get(c).push(seg); }
  }
}
function nearestRoad(p) {
  let best = 1e9, at = null;
  const cx = Math.floor(p[0] / CELL), cy = Math.floor(p[1] / CELL);
  for (let y = cy - 2; y <= cy + 2; y++) for (let x = cx - 2; x <= cx + 2; x++) for (const [a, b] of grid.get(`${x},${y}`) ?? []) {
    const dx = b[0] - a[0], dy = b[1] - a[1], den = dx * dx + dy * dy;
    const t = den ? Math.max(0, Math.min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / den)) : 0;
    const q = [a[0] + t * dx, a[1] + t * dy], d = Math.hypot(p[0] - q[0], p[1] - q[1]);
    if (d < best) { best = d; at = q; }
  }
  return { d: best, at };
}
const roads = [];
for (const rank of [0, 1, 2, 3, 4, 5, 6]) {
  const group = ways.filter(w => (w.tags.aeroway === 'runway' ? 0 : CLASSES[w.tags.highway].rank) === rank);
  const chains = chainWays(group).map(c => ({ ...c, pts: c.geometry.map(project) })).sort((a, b) => lengthOf(b.pts) - lengthOf(a.pts));
  const accepted = [];
  for (const chain of chains) {
    const cls = chain.tags.aeroway === 'runway' ? CLASSES.runway : CLASSES[chain.tags.highway];
    const samples = resample(chain.pts, 2);
    const free = samples.map(s => cls.spacing === 0 || nearestRoad(s).d > cls.spacing);
    // A brief close pass is a crossing, not a parallel road: bridge it so the street continues through the junction.
    const maxGap = Math.ceil((cls.spacing * 2.4 + 4) / 2);
    for (let i = 0; i < free.length;) {
      if (free[i]) { i++; continue; }
      let j = i; while (j < free.length && !free[j]) j++;
      if (i > 0 && j < free.length && j - i <= maxGap) free.fill(true, i, j);
      i = j;
    }
    const runs = [];
    for (let i = 0; i < free.length;) {
      if (!free[i]) { i++; continue; }
      let j = i; while (j < free.length && free[j]) j++;
      runs.push(samples.slice(i, j)); i = j;
    }
    const type = cls.as ?? (chain.tags.aeroway === 'runway' ? 'runway' : chain.tags.highway);
    const tagged = chain.tags.surface;
    const paved = tagged ? !UNPAVED.has(tagged) : rank <= 2 || Math.hypot(samples[0][0] - VILA[0], samples[0][1] - VILA[1]) < 230;
    for (let pts of runs) {
      if (lengthOf(pts) < cls.minRun || pts.length < 2) continue;
      // Tie the cut ends back to the kept network so every junction actually joins.
      const reach = Math.max(cls.spacing * 1.25, 4);
      const head = nearestRoad(pts[0]), tail = nearestRoad(pts.at(-1));
      // A connector that doubles back on the street would draw a hook: leave that end unjoined instead.
      const forwardFrom = (from, to, next) => (to[0] - from[0]) * (next[0] - to[0]) + (to[1] - from[1]) * (next[1] - to[1]) > 0;
      const headNext = pts[Math.min(3, pts.length - 1)], tailPrev = pts[Math.max(pts.length - 4, 0)];
      const joinedHead = cls.spacing > 0 && head.d <= reach && forwardFrom(head.at, pts[0], headNext);
      const joinedTail = cls.spacing > 0 && tail.d <= reach && forwardFrom(tailPrev, pts.at(-1), tail.at);
      if (rank >= 5 && !joinedHead && !joinedTail) continue;
      if (joinedHead) pts = [head.at, ...pts];
      if (joinedTail) pts = [...pts, tail.at];
      accepted.push({ id: chain.id, name: chain.tags.name ?? '', type, paved, rank, points: smooth(pts) });
    }
  }
  for (const road of accepted) addSegments(road.points);
  roads.push(...accepted);
}
// Mele's hand-placed village green gets its own lane down to the Ring Road (gameplay layout, not mapped data).
{
  const lane = [[-486, 62], [-486, 100], [-487, 130]];
  const end = nearestRoad([-488, 165]);
  roads.push({ id: 0, name: 'Mele village lane', type: 'track', paved: false, rank: 6, points: smooth([...lane, [-488, 150], end.at]) });
  addSegments(roads.at(-1).points);
}
// A road end is "open" when it stops short of any other road: it fades out rather than ending in a hard edge.
function touchesOther(road, p) {
  const others = roads.filter(r => r !== road && Math.abs(r.points[0][0] - p[0]) < 4000);
  for (const r of others) for (let i = 1; i < r.points.length; i++) {
    const [a, b] = [r.points[i - 1], r.points[i]], dx = b[0] - a[0], dy = b[1] - a[1], den = dx * dx + dy * dy;
    const t = den ? Math.max(0, Math.min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / den)) : 0;
    if (Math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy) < 2.5) return true;
  }
  return false;
}
for (const r of roads) r.open = [!touchesOther(r, r.points[0]), !touchesOther(r, r.points.at(-1))];
// Short stubs left behind by generalising read as clutter on the map: prune minor dead ends, then re-check the rest.
{
  const stub = r => r.rank >= 3 && r.id !== 0 && (r.open[0] || r.open[1]) && lengthOf(r.points) < 32;
  for (let i = roads.length - 1; i >= 0; i--) if (stub(roads[i])) roads.splice(i, 1);
  for (const r of roads) r.open = [!touchesOther(r, r.points[0]), !touchesOther(r, r.points.at(-1))];
}
// Minor roads first in the file: drawn in order, so a main road always paints over the end of a side road.
roads.sort((a, b) => b.rank - a.rank);

// Cars keep driving the same stretch of Ring Road past Mele.
const routeIds = [307581421, 252559007, 252558999, 332891673];
const routeRaw = routeIds.map(id => detail.elements.find(e => e.type === 'way' && e.id === id));
if (routeRaw.some(w => !w)) throw new Error('traffic route ways missing from OSM extract');
const route = [];
for (const way of routeRaw) {
  const pts = way.geometry.map(project);
  if (route.length && Math.hypot(pts[0][0] - route.at(-1)[0], pts[0][1] - route.at(-1)[1]) > Math.hypot(pts.at(-1)[0] - route.at(-1)[0], pts.at(-1)[1] - route.at(-1)[1])) pts.reverse();
  route.push(...pts);
}

const data = { source: '© OpenStreetMap contributors', license: 'ODbL 1.0', origin: [168.363, -17.6625], meters_per_game_meter: 10, coasts: polygons, roads, places, traffic_route: smooth(route) };
fs.writeFileSync(geo('efate-game-map.json'), JSON.stringify(data));

// ---- Land cover raster for the world bake: 240 x 240 cells of 12 m ----
// Layout: Uint16 real-building count per cell, Uint16 shop count per cell, Uint8 land class per cell.
const LAND = 240, LAND_STEP = 24, LAND_MIN = -2880;
const CLASS = { residential: 1, commercial: 2, retail: 2, industrial: 3, farmland: 4, orchard: 4, meadow: 4, forest: 5, wood: 5, scrub: 6, park: 7, wetland: 8, aerodrome: 9 };
const density = new Uint16Array(LAND * LAND), shops = new Uint16Array(LAND * LAND), land = new Uint8Array(LAND * LAND);
const cellOf = (x, z) => { const ix = Math.floor((x - LAND_MIN) / LAND_STEP), iz = Math.floor((z - LAND_MIN) / LAND_STEP); return ix < 0 || iz < 0 || ix >= LAND || iz >= LAND ? -1 : iz * LAND + ix; };
function inside(x, y, poly) { let value = false; for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) { const a = poly[i], b = poly[j]; if ((a[1] > y) !== (b[1] > y) && x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]) value = !value; } return value; }
const areas = [];
let buildingCount = 0;
for (const e of detail.elements) {
  if (e.type === 'node' && e.tags?.shop) { const c = cellOf(...project(e)); if (c >= 0) shops[c]++; continue; }
  if (e.type !== 'way') continue;
  if (e.tags?.building && e.center) { const c = cellOf(...project(e.center)); if (c >= 0) { density[c] = Math.min(65535, density[c] + 1); buildingCount++; } continue; }
  const kind = CLASS[e.tags?.landuse] ?? CLASS[e.tags?.natural] ?? CLASS[e.tags?.leisure] ?? CLASS[e.tags?.aeroway];
  if (kind && e.geometry?.length > 3) { const poly = e.geometry.map(project); areas.push({ kind, poly, size: area(poly) }); }
}
// Largest first, so a small commercial block stays visible inside a big residential polygon.
for (const { kind, poly } of areas.sort((a, b) => b.size - a.size)) {
  const xs = poly.map(p => p[0]), zs = poly.map(p => p[1]);
  for (let z = Math.min(...zs); z <= Math.max(...zs) + LAND_STEP; z += LAND_STEP) for (let x = Math.min(...xs); x <= Math.max(...xs) + LAND_STEP; x += LAND_STEP) {
    const c = cellOf(x, z);
    if (c < 0) continue;
    const cx = LAND_MIN + (c % LAND + 0.5) * LAND_STEP, cz = LAND_MIN + (Math.floor(c / LAND) + 0.5) * LAND_STEP;
    if (inside(cx, cz, poly)) land[c] = kind;
  }
}
fs.writeFileSync(geo('land-cover.bin'), Buffer.concat([Buffer.from(density.buffer), Buffer.from(shops.buffer), Buffer.from(land.buffer)]));

// ---- Offline signed-distance field: avoid polygon queries every physics tick ----
const side = 241, step = 24, origin = [-2880, -2880];
const edges = polygons.flatMap(poly => poly.slice(0, -1).map((p, i) => [p, poly[i + 1]]));
const distance = new Float32Array(side * side);
for (let z = 0; z < side; z++) for (let x = 0; x < side; x++) {
  const px = origin[0] + x * step, pz = origin[1] + z * step;
  let min = 1e20;
  for (const [a, b] of edges) { const dx = b[0] - a[0], dz = b[1] - a[1], den = dx * dx + dz * dz; if (den === 0) continue; const t = Math.max(0, Math.min(1, ((px - a[0]) * dx + (pz - a[1]) * dz) / den)); const d = (px - a[0] - t * dx) ** 2 + (pz - a[1] - t * dz) ** 2; min = Math.min(min, d); }
  distance[z * side + x] = Math.sqrt(min) * (polygons.some(poly => inside(px, pz, poly)) ? 1 : -1);
}
fs.writeFileSync(geo('coast-distance.bin'), Buffer.from(distance.buffer));

const byType = {};
for (const r of roads) { const t = byType[r.type] ??= { roads: 0, length: 0, paved: 0 }; t.roads++; const l = lengthOf(r.points); t.length += Math.round(l); if (r.paved) t.paved += Math.round(l); }
console.log(JSON.stringify({ roads: roads.length, openEnds: roads.reduce((n, r) => n + r.open.filter(Boolean).length, 0), byType, totalLength: Object.values(byType).reduce((a, t) => a + t.length, 0), points: roads.reduce((n, r) => n + r.points.length, 0), buildingsInRaster: buildingCount, shops: shops.reduce((a, b) => a + b, 0), landAreas: areas.length, jsonKB: Math.round(fs.statSync(geo('efate-game-map.json')).size / 1024) }, null, 1));
