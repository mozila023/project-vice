// Opens the exported game in real Chrome (no extra packages) and reports what happened.
//   node tools/web_test.mjs <out_dir> <label> <url> [width height mobile]
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const [out, label, url, width = '1280', height = '720', mobile = '0'] = process.argv.slice(2);
mkdirSync(out, { recursive: true });
const profile = join(tmpdir(), `vice-web-test-${process.pid}`);
const port = 9300 + (process.pid % 500);
const chrome = spawn('C:/Program Files/Google/Chrome/Application/chrome.exe', [
	`--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, '--headless=new', '--no-first-run', '--use-angle=d3d11',
	'--ignore-gpu-blocklist', '--enable-gpu-rasterization', `--window-size=${width},${height}`, 'about:blank',
], { stdio: 'ignore' });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let targets;
for (let i = 0; i < 40 && !targets; i++) {
	await sleep(250);
	try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); } catch {}
}
const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => { ws.onopen = r; });
let id = 0;
const pending = new Map();
const logs = [];
ws.onmessage = (event) => {
	const m = JSON.parse(event.data);
	if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result ?? m.error); pending.delete(m.id); }
	if (m.method === 'Runtime.consoleAPICalled') logs.push(`[${m.params.type}] ` + m.params.args.map((a) => a.value ?? a.description ?? '').join(' '));
	if (m.method === 'Runtime.exceptionThrown') logs.push('[exception] ' + (m.params.exceptionDetails.exception?.description ?? m.params.exceptionDetails.text));
};
const send = (method, params = {}) => new Promise((r) => { const n = ++id; pending.set(n, r); ws.send(JSON.stringify({ id: n, method, params })); });
const evaluate = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result?.value;

await send('Runtime.enable');
await send('Page.enable');
if (mobile === '1') {
	await send('Emulation.setDeviceMetricsOverride', { width: +width, height: +height, deviceScaleFactor: 2, mobile: true });
	await send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
}
const started = Date.now();
await send('Page.navigate', { url });
// Loading is over once the engine's status overlay is gone and frames are flowing.
let loaded = -1;
for (let i = 0; i < 480; i++) {
	await sleep(250);
	const state = await evaluate(`(()=>{const s=document.getElementById('status');return !s||getComputedStyle(s).visibility==='hidden'||s.style.display==='none'})()`);
	if (state) { loaded = Date.now() - started; break; }
}
const fpsProbe = `new Promise(r=>{let n=0,t=performance.now();function f(){n++;const d=performance.now()-t;if(d>=4000)r(Math.round(n/(d/1000)));else requestAnimationFrame(f)}requestAnimationFrame(f)})`;
await sleep(4000);
const fps = await evaluate(fpsProbe);
const gl = await evaluate(`(()=>{const c=document.createElement('canvas').getContext('webgl2');const d=c&&c.getExtension('WEBGL_debug_renderer_info');return c?c.getParameter(d?d.UNMASKED_RENDERER_WEBGL:c.RENDERER):'no webgl2'})()`);
const shot = await send('Page.captureScreenshot', { format: 'png' });
if (shot.data) writeFileSync(join(out, `${label}.png`), Buffer.from(shot.data, 'base64'));
console.log(JSON.stringify({ label, load_ms: loaded, raf_fps: fps, gpu: gl }));
const errors = logs.filter((l) => /error|exception|fail|cannot|invalid/i.test(l));
console.log(`console lines=${logs.length} problems=${errors.length}`);
for (const line of errors.slice(0, 25)) console.log(line.slice(0, 300));
if (process.argv.includes('--all')) for (const line of logs) console.log(line.slice(0, 200));
ws.close();
chrome.kill();
await sleep(500);
try { rmSync(profile, { recursive: true, force: true }); } catch {}
process.exit(0);
