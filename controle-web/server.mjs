// Controle do Cinema em Casa pelo navegador.
// Mostra a tela do projetor e manda toques/teclas via ADB. Sem dependencias externas.
// Uso: node server.mjs   ->  http://<ip-do-mac>:8090
import http from 'node:http';
import { execFile, spawn } from 'node:child_process';
import { readFile, writeFile, mkdtemp } from 'node:fs/promises';
import { tmpdir, networkInterfaces } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = dirname(fileURLToPath(import.meta.url));
const ADB = '/opt/homebrew/bin/adb';
const PORTA = Number(process.env.PORTA || 8090);
const HOST = process.env.HOST || '0.0.0.0';
const SENHA = process.env.SENHA || '';            // vazio = sem senha (uso em casa)
const IP_FILE = join(process.env.HOME, 'Library/Application Support/Projetor-HY300/ip.txt');
const LARG = 1280, ALT = 720;                       // resolucao do projetor

const APPS = {
  netflix: 'com.netflix.mediaclient',
  youtube: 'com.google.android.youtube.tv',
  prime: 'com.amazon.amazonvideo.livingroom',
  appletv: 'com.apple.atve.androidtv.appletv',
  hdmi: 'com.android.rockchip.camera2',
  config: 'com.cinemaemcasa.configuracoes',
};
const TECLAS = {
  cima: 'DPAD_UP', baixo: 'DPAD_DOWN', esq: 'DPAD_LEFT', dir: 'DPAD_RIGHT', ok: 'DPAD_CENTER',
  voltar: 'BACK', inicio: 'HOME', volmais: 'VOLUME_UP', volmenos: 'VOLUME_DOWN', mudo: 'VOLUME_MUTE',
  play: 'MEDIA_PLAY_PAUSE', energia: 'POWER',
};

let alvo = '';
async function serial() {
  if (alvo) return alvo;
  let ip = process.env.PROJETOR_IP || '';
  try { ip = (await readFile(IP_FILE, 'utf8')).trim() || ip; } catch {}
  alvo = `${ip}:3268`;
  return alvo;
}
function adb(args, opts = {}) {
  return new Promise(async (res) => {
    const s = await serial();
    execFile(ADB, ['-s', s, ...args], { encoding: opts.binario ? 'buffer' : 'utf8', maxBuffer: 20e6, timeout: 15000 },
      (err, out) => res({ err, out }));
  });
}
async function conectar() {
  const s = await serial();
  return new Promise((res) => execFile(ADB, ['connect', s], { timeout: 8000 }, () => res()));
}

// ---- captura de tela: uma por vez, convertida para JPEG pelo sips do macOS ----
let ultimoQuadro = null, ultimoEm = 0, capturando = null, ultimoPedido = 0;
const pasta = await mkdtemp(join(tmpdir(), 'cinema-'));
async function capturar() {
  if (capturando) return capturando;
  capturando = (async () => {
    let r = await adb(['exec-out', 'screencap', '-p'], { binario: true });
    if (r.err || !r.out || r.out.length < 1000) { await conectar(); r = await adb(['exec-out', 'screencap', '-p'], { binario: true }); }
    if (!r.err && r.out && r.out.length > 1000) {
      const png = join(pasta, 'q.png'), jpg = join(pasta, 'q.jpg');
      await writeFile(png, r.out);
      await new Promise((ok) => execFile('/usr/bin/sips', ['-s', 'format', 'jpeg', '-s', 'formatOptions', '60', '-Z', '960', png, '--out', jpg], () => ok()));
      try { ultimoQuadro = await readFile(jpg); ultimoEm = Date.now(); } catch {}
    }
    capturando = null;
  })();
  return capturando;
}
// mantem a imagem fresca so enquanto alguem esta olhando
setInterval(() => { if (Date.now() - ultimoPedido < 5000) capturar(); }, 350);

function autorizado(req) {
  if (!SENHA) return true;
  const c = (req.headers.cookie || '').match(/cinema=([^;]+)/);
  return c && decodeURIComponent(c[1]) === SENHA;
}
function corpo(req) {
  return new Promise((res) => { let d = ''; req.on('data', (c) => (d += c)); req.on('end', () => { try { res(JSON.parse(d || '{}')); } catch { res({}); } }); });
}
function json(res, cod, obj) { res.writeHead(cod, { 'content-type': 'application/json' }); res.end(JSON.stringify(obj)); }

const servidor = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://x');
  try {
    if (url.pathname === '/entrar' && req.method === 'POST') {
      const b = await corpo(req);
      if (SENHA && b.senha === SENHA) {
        res.writeHead(200, { 'set-cookie': `cinema=${encodeURIComponent(SENHA)}; Path=/; HttpOnly; SameSite=Strict; Max-Age=31536000` });
        return res.end('{}');
      }
      return json(res, 401, { erro: 'senha' });
    }
    if (url.pathname === '/' || url.pathname === '/index.html') {
      const html = await readFile(join(AQUI, 'index.html'));
      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' });
      return res.end(html);
    }
    if (!autorizado(req)) return json(res, 401, { erro: 'senha' });

    if (url.pathname === '/quadro.jpg') {
      ultimoPedido = Date.now();
      if (!ultimoQuadro || Date.now() - ultimoEm > 1500) await capturar();
      if (!ultimoQuadro) return json(res, 503, { erro: 'projetor fora do ar' });
      res.writeHead(200, { 'content-type': 'image/jpeg', 'cache-control': 'no-store' });
      return res.end(ultimoQuadro);
    }
    if (req.method !== 'POST') return json(res, 404, {});
    const b = await corpo(req);
    const num = (v, max) => Math.max(0, Math.min(max, Math.round(Number(v) || 0)));

    if (url.pathname === '/toque') {
      const x = num(b.x * LARG, LARG - 1), y = num(b.y * ALT, ALT - 1);
      await adb(['shell', 'input', 'tap', String(x), String(y)]);
    } else if (url.pathname === '/arrastar') {
      const v = [b.x1 * LARG, b.y1 * ALT, b.x2 * LARG, b.y2 * ALT].map((n, i) => String(num(n, i % 2 ? ALT : LARG)));
      await adb(['shell', 'input', 'swipe', ...v, '250']);
    } else if (url.pathname === '/tecla') {
      const k = TECLAS[b.tecla]; if (!k) return json(res, 400, { erro: 'tecla' });
      await adb(['shell', 'input', 'keyevent', k]);
    } else if (url.pathname === '/app') {
      const p = APPS[b.app]; if (!p) return json(res, 400, { erro: 'app' });
      await adb(['shell', 'monkey', '-p', p, '-c', 'android.intent.category.LAUNCHER', '1']);
    } else return json(res, 404, {});
    ultimoEm = 0;                                   // forca imagem nova apos a acao
    return json(res, 200, { ok: true });
  } catch (e) {
    return json(res, 500, { erro: String(e) });
  }
});

await conectar();
servidor.listen(PORTA, HOST, () => {
  const ips = Object.values(networkInterfaces()).flat().filter((i) => i && i.family === 'IPv4' && !i.internal).map((i) => i.address);
  console.log(`Controle do Cinema em Casa no ar: ${ips.map((i) => `http://${i}:${PORTA}`).join('  ')}${SENHA ? ' (com senha)' : ''}`);
});
