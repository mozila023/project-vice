// Serves build/web locally, gzipping on the fly as a real web host would.
//   node tools/serve_web.mjs [port]
// Phones on the same Wi-Fi can open http://<this-computer-ip>:<port>/
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { gzip } from 'node:zlib';
import { promisify } from 'node:util';
import { join, extname, normalize } from 'node:path';
import { networkInterfaces } from 'node:os';
import { fileURLToPath } from 'node:url';

const root = join(fileURLToPath(new URL('.', import.meta.url)), '..', 'build', 'web');
const port = Number(process.argv[2] ?? 8060);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.svg': 'image/svg+xml' };
const compress = promisify(gzip);
const cache = new Map();

createServer(async (req, res) => {
	const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname)).replace(/^([/\\])+/, '') || 'index.html';
	if (path.startsWith('..')) { res.writeHead(403).end(); return; }
	try {
		const stamp = (await stat(join(root, path))).mtimeMs;
		if (cache.get(path)?.stamp !== stamp) cache.set(path, { stamp, body: await compress(await readFile(join(root, path))) });
		res.writeHead(200, { 'Content-Type': types[extname(path)] ?? 'application/octet-stream', 'Content-Encoding': 'gzip', 'Cache-Control': 'no-cache' });
		res.end(cache.get(path).body);
	} catch {
		res.writeHead(404).end('Not found');
	}
}).listen(port, '0.0.0.0', () => {
	console.log(`ready http://localhost:${port}/`);
	for (const list of Object.values(networkInterfaces())) for (const net of list) if (net.family === 'IPv4' && !net.internal) console.log(`phone http://${net.address}:${port}/`);
});
