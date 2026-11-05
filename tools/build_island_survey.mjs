// Rebuild the discoverable-place inventory from a dated OSM extract. Preserve source IDs and coordinates.
import fs from 'node:fs';
const raw=JSON.parse(fs.readFileSync('tools/.cache/island-survey/efate-pois.json','utf8'));
const geography=JSON.parse(fs.readFileSync('assets/geography/efate-game-map.json','utf8'));
const inside=(p,poly)=>{let c=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])c=!c;}return c;};
const special={
 'way/105052376':['market','Port Vila Central Market'],
 'node/1208562570':['museum','Vanuatu National Museum'],
 'way/307095157':['hospital','Port Vila Central Hospital'],
 'way/52246235':['airport','Bauerfield International Airport'],
 'way/1455014782':['waterfall','Mele Cascades'],
 'node/5589112723':['lagoon','Blue Lagoon'],
 'node/5340983048':['beach','Eton Beach'],
 'node/5589729824':['culture','Ekasup Cultural Village'],
 'node/1211001893':['post','Vanuatu Post Office'],
 'node/2030007766':['underwater_post','Underwater Post Office'],
 'node/6567613985':['river','Eden on the River'],
 'node/5341017574':['museum','WW II Museum'],
 'node/6835817085':['cave','Siviri Cave'],
};
const entries=[];
const audit=[];
for(const e of raw.elements){
 const t=e.tags||{},id=e.type+'/'+e.id,name=t.name||t['name:en'];if(!name)continue;
 const lat=e.lat??e.center?.lat,lon=e.lon??e.center?.lon;if(!Number.isFinite(lat)||!Number.isFinite(lon))continue;
 const at=[(lon-168.363)*10600,-(lat+17.6625)*11100];
 if(at.some(v=>Math.abs(v)>2800)||!geography.coasts.some(poly=>inside(at,poly))&&!special[id]){audit.push({id,name,reason:'outside modelled island coast/extent'});continue;}
 if(/sano/i.test(name)){audit.push({id,name,reason:'user requested temporary bar name'});continue;}
 let category=special[id]?.[0]??(t.place?'village':t.natural==='beach'?'beach':t.aeroway?'airport':['hospital','clinic','doctors','pharmacy'].includes(t.amenity)?'health':['police','fire_station','post_office','townhall'].includes(t.amenity)?'service':t.amenity==='marketplace'?'market':t.amenity==='ferry_terminal'?'ferry':['restaurant','cafe','pub','bar','fast_food'].includes(t.amenity)?'food':t.tourism?'visit':t.shop?'shop':t.amenity==='school'?'school':'community');
 const entry={id,name:special[id]?.[1]??name,latitude:lat,longitude:lon,at,category,featured:!!special[id],source:'https://www.openstreetmap.org/'+id,representation:special[id]?'interpreted_landmark':'mapped_place',opening_hours:t.opening_hours??'',website:t.website??''};
 const duplicate=entries.find(p=>p.category===category&&Math.hypot(p.at[0]-at[0],p.at[1]-at[1])<6&&(p.name===entry.name||/central hospital/i.test(p.name+' '+entry.name)));
 if(duplicate){audit.push({id,name,reason:'duplicate nearby mapped facility',kept:duplicate.id});continue;}
 entries.push(entry);
}
entries.sort((a,b)=>Number(b.featured)-Number(a.featured)||a.name.localeCompare(b.name));
fs.writeFileSync('assets/geography/efate-places.json',JSON.stringify({version:1,map_scale:10,source:'© OpenStreetMap contributors · ODbL 1.0',queried_at:'2026-11-05',description:'All named results within the modelled island coast from the documented POI query; not a complete census or architectural survey.',entries}));
fs.writeFileSync('checks/island-survey-audit.json',JSON.stringify({source_count:raw.elements.length,included:entries.length,excluded:audit},null,2));
const dimensions={airport:[28,10],hospital:[18,10],market:[18,10],museum:[12,8],post:[12,8],culture:[12,8],beach:[7,5],underwater_post:[7,5],waterfall:[18,16],lagoon:[18,12],river:[18,12],cave:[10,8]};
const sites=entries.filter(e=>e.featured).map(e=>({id:e.id,name:e.name,category:e.category,at:e.at,size:dimensions[e.category]}));
// Hospital campus centroid conflicts with the compressed salon parcel and road.
// Keep the geographic directory pin; stage the interpreted model on a nearby clear plot.
const hospital=sites.find(e=>e.category==='hospital');
hospital.at=[-421.56486,852.01488];
hospital.building_note='Model staged on nearby dry plot to avoid Sunshine and road; original OSM pin retained.';
// The OSM attraction centroid is beside the entrance road; stage the interpreted cliff behind its entry.
const cascades=sites.find(e=>e.category==='waterfall');
cascades.at=[cascades.at[0]-22,cascades.at[1]-24];
cascades.building_note='Interpreted cliff behind mapped attraction entry; original pin is retained in the inventory.';
const roadSegments=geography.roads.filter(r=>r.type!=='runway').flatMap(r=>r.points.slice(1).map((p,i)=>[r.points[i],p]));
const closestRoad=p=>{let best={distance:Infinity,at:p};for(const [a,b] of roadSegments){const dx=b[0]-a[0],dz=b[1]-a[1],t=Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dz)/(dx*dx+dz*dz||1)));const q=[a[0]+dx*t,a[1]+dz*t],distance=Math.hypot(p[0]-q[0],p[1]-q[1]);if(distance<best.distance)best={distance,at:q};}return best;};
const preferred=cascades.at;let best=null;
for(let dx=-64;dx<=64;dx+=4)for(let dz=-64;dz<=64;dz+=4){const p=[preferred[0]+dx,preferred[1]+dz],road=closestRoad(p);if(road.distance<17||!geography.coasts.some(poly=>inside(p,poly)))continue;const score=Math.hypot(dx,dz);if(!best||score<best.score)best={at:p,score};}
if(best)cascades.at=best.at;
// A site's boundary centroid is not its building: use the separately mapped international terminal.
const terminal=JSON.parse(fs.readFileSync('tools/.cache/osm-detail/efate-detail.json','utf8')).elements.find(e=>e.type==='way'&&e.id===52246281);
const airport=sites.find(e=>e.category==='airport');
airport.at=[(terminal.center.lon-168.363)*10600,-(terminal.center.lat+17.6625)*11100];
airport.building_source='https://www.openstreetmap.org/way/52246281';
for(const site of sites)site.facing=closestRoad(site.at).at[1]<site.at[1]?-1:1;
fs.writeFileSync('scripts/place_sites.gd','extends RefCounted\n## Generated by tools/build_island_survey.mjs. Geographic pins; architecture is interpreted.\nconst SITES := '+JSON.stringify(sites,null,'\t')+'\nstatic func reserved(x: float,z: float,margin := 0.0) -> bool:\n\tfor site in SITES:\n\t\tif absf(x-site.at[0])<site.size[0]/2+3+margin and absf(z-site.at[1])<site.size[1]/2+10+margin: return true\n\treturn false\n');
const counts={};for(const e of entries)counts[e.category]=(counts[e.category]??0)+1;
console.log(JSON.stringify({mapped_places:entries.length,featured:entries.filter(e=>e.featured).map(e=>e.name),categories:counts},null,2));
