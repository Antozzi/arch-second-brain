import { createServer } from 'http';
import { createWriteStream } from 'fs';
import { readFileSync as readFS, writeFileSync as writeFS, existsSync as existsFS } from 'fs';
import { join as joinPath } from 'path';

// Загрузка .env
function loadEnv() {
  const envPath = joinPath(dirname(fileURLToPath(import.meta.url)), '.env');
  if (!existsFS(envPath)) return {};
  const env = {};
  readFS(envPath, 'utf8').split('\n').forEach(line => {
    const m = line.match(/^([^=]+)=(.*)$/);
    if (m) env[m[1].trim()] = m[2].trim().replace(/^["']|["']$/g, '');
  });
  return env;
}
let ENV = loadEnv();
import { exec, spawn } from 'child_process';
import { readFileSync, existsSync, readdirSync, statSync, writeFileSync, rmSync, mkdirSync, unlinkSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { totalmem } from 'os';
import { inflateRawSync } from 'zlib';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = 3030;

function computeAutoMaxChars(model) {
  const ramGB = Math.floor(totalmem() / (1024 ** 3));
  const m = (model || '').toLowerCase();
  let b = 8;
  if (/70b|72b/.test(m))      b = 70;
  else if (/34b|30b/.test(m)) b = 34;
  else if (/27b/.test(m))     b = 27;
  else if (/12b|13b/.test(m)) b = 13;
  else if (/3b|4b/.test(m))   b = 3;
  if (b >= 70) return ramGB >= 64 ? 24000 : 16000;
  if (b >= 27) {
    if (ramGB >= 64) return 20000;
    if (ramGB >= 32) return 14000;
    if (ramGB >= 16) return 8000;
    return 4000;
  }
  if (b >= 12) {
    if (ramGB >= 32) return 14000;
    if (ramGB >= 16) return 10000;
    if (ramGB >= 8)  return 6000;
    return 4000;
  }
  if (ramGB >= 32) return 10000;
  if (ramGB >= 16) return 7000;
  if (ramGB >= 8)  return 5000;
  return 3000;
}

const MIME = { '.html':'text/html', '.js':'application/javascript', '.css':'text/css', '.json':'application/json' };

const activeProcesses = new Map(); // key: 'ingest-JIRA' | 'process-JIRA' → child

// Windows: add common tool paths to process PATH so bash scripts can find pandoc, tesseract, etc.
if (process.platform === 'win32') {
  const winPaths = [
    'C:\\Program Files\\Git\\bin',
    'C:\\Program Files\\Git\\usr\\bin',
    'C:\\Program Files\\Git\\mingw64\\bin',
    'C:\\Users\\' + (process.env.USERNAME || 'User') + '\\AppData\\Local\\Programs\\Ollama',
    'C:\\Program Files\\Pandoc',
    'C:\\Program Files\\Tesseract-OCR',
    'C:\\Program Files\\ImageMagick-7.1.0-portable',
  ];
  process.env.PATH = winPaths.join(';') + ';' + (process.env.PATH || '');
}

function killChild(key) {
  const child = activeProcesses.get(key);
  if (!child) return false;
  if (process.platform === 'win32') {
    exec(`taskkill /F /T /PID ${child.pid}`, () => {});
  } else {
    // убиваем всю группу процессов (sh -c → bash-скрипт → curl/python),
    // а не только обёртку sh — для этого процесс запущен с detached:true
    try { process.kill(-child.pid, 'SIGTERM'); }
    catch { try { child.kill('SIGTERM'); } catch { /* уже мёртв */ } }
  }
  activeProcesses.delete(key);
  return true;
}

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

function json(res, data, status = 200) {
  cors(res); res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
}

function getBody(req) {
  return new Promise(resolve => {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => { try { resolve(JSON.parse(body)); } catch { resolve({}); } });
  });
}

function getProjects() {
  const dir = join(__dirname, 'knowledge', 'projects');
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter(f => statSync(join(dir, f)).isDirectory())
    .map(name => {
      const files = readdirSync(join(dir, name));
      const rawDir = join(__dirname, 'raw', name);
      const totalRaw = existsSync(rawDir) ? readdirSync(rawDir).filter(f => f.endsWith('.md')).length : 0;
      const processedRaw = existsSync(rawDir)
        ? readdirSync(rawDir).filter(f => {
            if (!f.endsWith('.md')) return false;
            return readFileSync(join(rawDir, f), 'utf8').includes('processed: true');
          }).length : 0;
      return { name, files, totalRaw, processedRaw };
    });
}

function getSkippedFiles(jira) {
  const rawDir = join(__dirname, 'raw', jira);
  if (!existsSync(rawDir)) return [];
  return readdirSync(rawDir)
    .filter(f => f.endsWith('.md'))
    .filter(f => {
      const c = readFileSync(join(rawDir, f), 'utf8');
      return c.includes('processed: false') || c.includes('pdf-scan-failed');
    })
    .map(f => {
      const c = readFileSync(join(rawDir, f), 'utf8');
      const source = c.match(/source: "([^"]+)"/)?.[1] || '';
      const type = c.match(/type: "([^"]+)"/)?.[1] || '';
      const reason = type === 'pdf-scan-failed' ? 'OCR не смог извлечь текст' : 'не обработан';
      return { file: f, source, type, reason };
    });
}

function getTemplates() {
  const dir = join(__dirname, 'templates');
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter(f => f.endsWith('.md'))
    .map(f => {
      const content = readFileSync(join(dir, f), 'utf8');
      const sections = [...content.matchAll(/^#{1,3} (.+)$/gm)].map(m => m[1]);
      return { file: f, name: f.replace('.md', ''), sections };
    });
}

function getKnowledgeContext(jira) {
  const dir = join(__dirname, 'knowledge', 'projects', jira);
  if (!existsSync(dir)) return '';
  let ctx = '';
  for (const f of readdirSync(dir)) {
    if (!f.endsWith('.md')) continue;
    if (f.endsWith('-SKILL.md')) continue; // скилл — инструкция, не знание
    ctx += `\n\n### ${f}\n${readFileSync(join(dir, f), 'utf8').slice(0, 3000)}`;
  }
  return ctx;
}

// =============================================================================
// PlantUML — генерация диаграмм из знаний + локальный рендер через jar/Java
// =============================================================================

const DIAGRAM_SPECS = {
  sequence:    { label: 'Sequence — последовательность', start: '@startuml',    hint: 'participant/actor, стрелки -> ->> --> , блоки alt/loop/opt/par, activate/deactivate.' },
  usecase:     { label: 'Use Case — варианты использования', start: '@startuml', hint: 'actor "Роль", usecase "Действие", связи -->, группировка rectangle/package.' },
  class:       { label: 'Class — классы', start: '@startuml',                   hint: 'class с полями и методами, связи наследования --|>, композиции --*, агрегации --o, зависимости ..>.' },
  component:   { label: 'Component — компоненты системы', start: '@startuml',    hint: 'component [Имя], interface, package/node для группировки, связи -->. Подходит для архитектуры AS-IS / TO-BE.' },
  deployment:  { label: 'Deployment — развёртывание', start: '@startuml',        hint: 'node, artifact, database, cloud, frame; связи --> с подписями протоколов.' },
  activity:    { label: 'Activity — процесс / алгоритм', start: '@startuml',     hint: 'Новый синтаксис: start / stop, :действие;, if (условие?) then (да)/else (нет)/endif, fork/fork again.' },
  state:       { label: 'State — состояния', start: '@startuml',                hint: 'state "Имя", [*] начальное и конечное состояние, переходы --> с подписями событий.' },
  er:          { label: 'ER — модель данных', start: '@startuml',               hint: 'entity "Таблица" с атрибутами, связи crow-foot: ||--o{, }|--|| и т.п.' },
  c4context:   { label: 'C4 — System Context', start: '@startuml',              hint: 'Первая строка после @startuml: !include <C4/C4_Context>. Элементы Person(), System(), System_Ext(), Rel().' },
  c4container: { label: 'C4 — Container', start: '@startuml',                   hint: 'Первая строка после @startuml: !include <C4/C4_Container>. Элементы Person(), Container(), ContainerDb(), System_Ext(), Rel().' },
  mindmap:     { label: 'MindMap — карта мыслей', start: '@startmindmap',        hint: 'Блок @startmindmap / @endmindmap. Уровни задаются числом звёздочек: *, **, ***.' },
  gantt:       { label: 'Gantt — план-график', start: '@startgantt',            hint: 'Блок @startgantt / @endgantt. [Задача] lasts N days; [Б] starts after [А]\\u0027s end.' },
  wbs:         { label: 'WBS — структура работ', start: '@startwbs',            hint: 'Блок @startwbs / @endwbs. Иерархия через *, **, ***.' },
  json:        { label: 'JSON — структура данных', start: '@startjson',         hint: 'Блок @startjson / @endjson с валидным JSON-объектом внутри.' },
};

function extractUml(text) {
  if (!text) return '';
  const t = text.replace(/```[a-zA-Z]*\n?/g, '').replace(/```/g, '');
  const m = t.match(/@start\w+[\s\S]*?@end\w+/);
  return (m ? m[0] : t).trim();
}

function plantumlCmd() {
  const bundled = join(__dirname, 'vendor', 'plantuml.jar');
  if (existsSync(bundled)) return { cmd: 'java', args: ['-jar', bundled] };
  if (ENV.PLANTUML_JAR && existsSync(ENV.PLANTUML_JAR)) return { cmd: 'java', args: ['-jar', ENV.PLANTUML_JAR] };
  return { cmd: 'plantuml', args: [] }; // brew/choco/scoop кладут команду в PATH
}

function renderPlantuml(uml) {
  return new Promise((resolve, reject) => {
    const { cmd, args } = plantumlCmd();
    let child;
    try {
      child = spawn(cmd, [...args, '-tsvg', '-pipe', '-charset', 'UTF-8']);
    } catch (e) { return reject(new Error('PlantUML/Java не найден. Установи: brew install plantuml')); }
    let out = Buffer.alloc(0), err = '';
    const timer = setTimeout(() => { child.kill(); reject(new Error('PlantUML: таймаут рендера')); }, 30000);
    child.on('error', () => { clearTimeout(timer); reject(new Error('PlantUML/Java не найден. Установи: brew install plantuml (см. INSTALLATION.md)')); });
    child.stdout.on('data', d => { out = Buffer.concat([out, d]); });
    child.stderr.on('data', d => { err += d; });
    child.on('close', code => {
      clearTimeout(timer);
      const svg = out.toString('utf8');
      if (svg.includes('<svg')) resolve(svg);
      else reject(new Error(err.trim() || `PlantUML вернул пустой результат (код ${code})`));
    });
    child.stdin.on('error', () => {});
    child.stdin.write(uml, 'utf8');
    child.stdin.end();
  });
}

// =============================================================================
// drawio — генерация валидного mxGraphModel XML из знаний + каталог объектов
// =============================================================================

const DRAWIO_STYLES = {
  system:    'rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;',
  external:  'rounded=1;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#666666;dashed=1;',
  database:  'shape=cylinder3;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;boundedLbl=1;',
  component: 'rounded=0;whiteSpace=wrap;html=1;fillColor=#ffe6cc;strokeColor=#d79b00;',
  actor:     'shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1;outlineConnect=0;',
  process:   'rhombus;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;',
  queue:     'shape=process;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;',
  note:      'shape=note;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;size=14;',
  default:   'rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;',
};
const DRAWIO_TYPES = Object.keys(DRAWIO_STYLES).filter(t => t !== 'default');

function slugify(s) {
  return (s || '').toString().toLowerCase()
    .replace(/[^a-zа-яё0-9]+/gi, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48) || 'obj';
}

function escXml(s) {
  return (s || '').toString()
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function cleanLabel(v) {
  if (!v) return '';
  return v.toString()
    .replace(/<br\s*\/?>/gi, ' ').replace(/<[^>]+>/g, '')
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
    .replace(/&#10;|&#xa;/gi, ' ').replace(/&nbsp;/gi, ' ').replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ').trim();
}

function inferType(style) {
  const s = (style || '').toLowerCase();
  if (s.includes('cylinder')) return 'database';
  if (s.includes('umlactor') || s.includes('shape=actor')) return 'actor';
  if (s.includes('rhombus')) return 'process';
  if (s.includes('shape=note')) return 'note';
  if (s.includes('dashed=1')) return 'external';
  if (s.includes('shape=process')) return 'queue';
  return 'component';
}

// graph: { nodes:[{id?,label,type}], edges:[{from,to,label?}] } → { xml, objects }
function buildDrawioXml(graph, diagramName) {
  const nodes = Array.isArray(graph && graph.nodes) ? graph.nodes : [];
  const edges = Array.isArray(graph && graph.edges) ? graph.edges : [];
  const W = 170, H = 70, GAP_X = 90, GAP_Y = 100;
  const cols = Math.max(1, Math.ceil(Math.sqrt(nodes.length || 1)));
  const idMap = {}, used = new Set(), cells = [], objects = [];

  nodes.forEach((n, i) => {
    const label = (n.label || n.id || 'Объект').toString();
    let cid = (n.id && /^node-/.test(n.id)) ? n.id : 'node-' + slugify(n.id || label);
    let base = cid, k = 2;
    while (used.has(cid)) cid = base + '-' + (k++);
    used.add(cid);
    if (n.id) idMap[n.id] = cid;
    idMap[label] = idMap[label] || cid;
    const type = DRAWIO_STYLES[n.type] ? n.type : 'component';
    const style = DRAWIO_STYLES[type];
    const x = 40 + (i % cols) * (W + GAP_X);
    const y = 40 + Math.floor(i / cols) * (H + GAP_Y);
    cells.push(`        <mxCell id="${escXml(cid)}" value="${escXml(label)}" style="${style}" vertex="1" parent="1"><mxGeometry x="${x}" y="${y}" width="${W}" height="${H}" as="geometry"/></mxCell>`);
    objects.push({ id: cid, label, type, style });
  });

  edges.forEach((e, i) => {
    const s = idMap[e.from], t = idMap[e.to];
    if (!s || !t) return;
    cells.push(`        <mxCell id="edge-${i + 1}" value="${escXml(e.label || '')}" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;elbow=vertical;" edge="1" parent="1" source="${escXml(s)}" target="${escXml(t)}"><mxGeometry relative="1" as="geometry"/></mxCell>`);
  });

  const name = diagramName || 'diagram';
  const xml = `<mxfile host="second-brain" type="device">
  <diagram name="${escXml(name)}" id="${slugify(name)}">
    <mxGraphModel dx="1100" dy="760" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1169" pageHeight="826" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
${cells.join('\n')}
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>`;
  return { xml, objects };
}

function decompressDrawio(xml) {
  if (!xml) return '';
  if (xml.includes('<mxGraphModel')) return xml;
  const m = xml.match(/<diagram[^>]*>([\s\S]*?)<\/diagram>/);
  if (m && m[1] && !m[1].includes('<')) {
    try {
      const inflated = inflateRawSync(Buffer.from(m[1].trim(), 'base64')).toString('utf8');
      return decodeURIComponent(inflated);
    } catch { /* fall through to raw */ }
  }
  return xml;
}

function parseDrawioXml(xml) {
  const model = decompressDrawio(xml);
  const nodes = [], edges = [];
  // labels carried on <object>/<UserObject> wrappers
  const objLabels = {};
  const objRe = /<(?:object|UserObject)\b([^>]*)>\s*<mxCell\b([^>]*)/g;
  let om;
  while ((om = objRe.exec(model))) {
    const idM = om[1].match(/\bid="([^"]*)"/);
    const lblM = om[1].match(/\blabel="([^"]*)"/);
    if (idM && lblM) objLabels[idM[1]] = lblM[1];
  }
  const cellRe = /<mxCell\b([^>]*?)(?:\/>|>)/g;
  let m;
  while ((m = cellRe.exec(model))) {
    const a = m[1];
    const get = (name) => { const r = a.match(new RegExp('\\b' + name + '="([^"]*)"')); return r ? r[1] : null; };
    const id = get('id'), style = get('style') || '';
    const value = get('value') || (id && objLabels[id]) || '';
    if (/\bvertex="1"/.test(a)) {
      const label = cleanLabel(value);
      if (label) nodes.push({ id, label, type: inferType(style), style });
    } else if (/\bedge="1"/.test(a)) {
      edges.push({ from: get('source'), to: get('target'), label: cleanLabel(value) });
    }
  }
  return { nodes, edges };
}

function catalogPath(jira) {
  return join(__dirname, 'knowledge', 'projects', jira, 'diagram-objects.json');
}
function readCatalog(jira) {
  const p = catalogPath(jira);
  if (!existsSync(p)) return [];
  try { const c = JSON.parse(readFileSync(p, 'utf8')); return Array.isArray(c) ? c : []; }
  catch { return []; }
}
function mergeCatalog(jira, newObjs) {
  const cat = readCatalog(jira);
  const seen = new Map(cat.map(o => [o.id, o]));
  for (const o of (newObjs || [])) {
    if (!o || !o.id || !o.label) continue;
    if (!seen.has(o.id)) { const obj = { id: o.id, label: o.label, type: o.type || 'component', style: o.style || '' }; cat.push(obj); seen.set(o.id, obj); }
    else { const ex = seen.get(o.id); if (o.style && !ex.style) ex.style = o.style; }
  }
  const dir = join(__dirname, 'knowledge', 'projects', jira);
  mkdirSync(dir, { recursive: true });
  writeFileSync(catalogPath(jira), JSON.stringify(cat, null, 2));
  return cat;
}

function extractJson(text) {
  if (!text) return null;
  const t = text.replace(/```[a-zA-Z]*\n?/g, '').replace(/```/g, '');
  const start = t.indexOf('{');
  if (start < 0) return null;
  let depth = 0, inStr = false, esc = false;
  for (let i = start; i < t.length; i++) {
    const ch = t[i];
    if (inStr) {
      if (esc) esc = false;
      else if (ch === '\\') esc = true;
      else if (ch === '"') inStr = false;
    } else if (ch === '"') inStr = true;
    else if (ch === '{') depth++;
    else if (ch === '}') { depth--; if (depth === 0) { try { return JSON.parse(t.slice(start, i + 1)); } catch { return null; } } }
  }
  return null;
}

// =============================================================================
// Шаблоны артефактов — генерация .md шаблонов из документов и ИТ-стандартов
// =============================================================================

const STANDARDS = {
  TOGAF:       { label: 'TOGAF 10 — Enterprise Architecture', artifacts: ['Architecture Vision', 'Architecture Definition Document', 'Architecture Requirements Specification', 'Architecture Roadmap', 'Architecture Building Blocks'] },
  'ISO-42010': { label: 'ISO/IEC/IEEE 42010 — Architecture Description', artifacts: ['Architecture Description', 'Stakeholders & Concerns', 'Architecture Viewpoints', 'Architecture Views'] },
  BABOK:       { label: 'BABOK v3 — Business Analysis', artifacts: ['Business Analysis Plan', 'Requirements Documentation', 'Stakeholder Analysis', 'Solution Assessment', 'Elicitation Results'] },
  PMBOK:       { label: 'PMBOK 7 — Project Management', artifacts: ['Project Charter', 'Project Management Plan', 'Risk Register', 'Stakeholder Register', 'Scope Statement'] },
  'ISO-25010': { label: 'ISO/IEC 25010 — Quality Requirements (NFR)', artifacts: ['Quality Requirements Specification', 'NFR Checklist'] },
};

function stripFrontmatter(text) {
  return (text || '')
    .replace(/^---\n[\s\S]*?\n---\n/, '')
    .replace(/```[a-zA-Z]*\n?/g, '').replace(/```/g, '')
    .trim();
}

function cleanTemplateMd(text) {
  return (text || '').replace(/^```(?:markdown|md)?\s*\n?/i, '').replace(/\n?```\s*$/i, '').trim();
}

async function genText(engine, sys, userMsg, maxTokens) {
  if (engine === 'claude') {
    if (!ENV.ANTHROPIC_API_KEY) throw new Error('Anthropic API ключ не задан. Добавь его в Настройках.');
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-api-key': ENV.ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
      body: JSON.stringify({ model: ENV.CLAUDE_MODEL || 'claude-sonnet-4-6', max_tokens: maxTokens || 4000, system: sys, messages: [{ role: 'user', content: userMsg }] }),
      signal: AbortSignal.timeout(120000)
    });
    const data = await r.json();
    if (data.error) throw new Error('Ошибка API: ' + data.error.message);
    return data.content?.[0]?.text || '';
  }
  const r = await fetch('http://localhost:11434/api/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: ENV.OLLAMA_MODEL || 'llama3.1:8b', prompt: sys + '\n\n' + userMsg, stream: false, options: { temperature: 0.2, num_ctx: 8192 } }),
    signal: AbortSignal.timeout(120000)
  });
  const data = await r.json();
  return data.response || '';
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  if (req.method === 'OPTIONS') { cors(res); res.writeHead(204); res.end(); return; }

  if (url.pathname.startsWith('/api/')) {

    if (req.method === 'GET' && url.pathname === '/api/projects')
      return json(res, getProjects());

    if (req.method === 'GET' && url.pathname === '/api/templates')
      return json(res, getTemplates());

    if (req.method === 'GET' && url.pathname.startsWith('/api/knowledge/')) {
      const jira = url.pathname.split('/').pop();
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(getKnowledgeContext(jira));
      return;
    }

    if (req.method === 'GET' && url.pathname.startsWith('/api/skipped/')) {
      const jira = url.pathname.split('/').pop();
      return json(res, getSkippedFiles(jira));
    }

    // GET /api/standards — список ИТ-стандартов и их артефактов
    if (req.method === 'GET' && url.pathname === '/api/standards') {
      return json(res, Object.entries(STANDARDS).map(([id, s]) => ({ id, label: s.label, artifacts: s.artifacts })));
    }

    // GET /api/raw-files/:jira — список конвертированных raw-документов проекта
    if (req.method === 'GET' && url.pathname.startsWith('/api/raw-files/')) {
      const jira = decodeURIComponent(url.pathname.split('/').pop());
      const dir = join(__dirname, 'raw', jira);
      if (!existsSync(dir)) return json(res, []);
      const files = readdirSync(dir).filter(f => f.endsWith('.md')).map(f => {
        const c = readFileSync(join(dir, f), 'utf8');
        return { file: f, source: c.match(/source: "([^"]+)"/)?.[1] || f, type: c.match(/type: "([^"]+)"/)?.[1] || '' };
      });
      return json(res, files);
    }

    // DELETE /api/template/:name — удалить шаблон
    if (req.method === 'DELETE' && url.pathname.startsWith('/api/template/')) {
      const name = decodeURIComponent(url.pathname.split('/').pop());
      const fp = join(__dirname, 'templates', name + '.md');
      if (!existsSync(fp)) return json(res, { error: 'not found' }, 404);
      unlinkSync(fp);
      return json(res, { ok: true });
    }

    // POST /api/template/save — сохранить .md шаблон в templates/
    if (req.method === 'POST' && url.pathname === '/api/template/save') {
      const { name, content } = await getBody(req);
      if (!name || !content) return json(res, { error: 'name и content обязательны' }, 400);
      const safe = name.replace(/[^a-zA-Zа-яА-Я0-9_-]+/g, '-').replace(/^-+|-+$/g, '') || 'template';
      const dir = join(__dirname, 'templates');
      mkdirSync(dir, { recursive: true });
      writeFileSync(join(dir, safe + '.md'), cleanTemplateMd(content));
      return json(res, { ok: true, file: safe + '.md', name: safe });
    }

    // POST /api/template/from-document — шаблон из структуры raw-документа
    if (req.method === 'POST' && url.pathname === '/api/template/from-document') {
      const { jira, file, engine } = await getBody(req);
      if (!jira || !file) return json(res, { error: 'jira и file обязательны' }, 400);
      const fp = join(__dirname, 'raw', jira, file);
      if (!existsSync(fp)) return json(res, { error: 'файл не найден' }, 404);
      const docBody = stripFrontmatter(readFileSync(fp, 'utf8'));
      const headings = [...docBody.matchAll(/^#{1,6} +(.+)$/gm)].map(m => m[1].trim());
      const sys = 'Ты помогаешь Solution Architect создавать переиспользуемые .md шаблоны архитектурных артефактов.';
      const userMsg = `Из документа-образца ниже извлеки СТРУКТУРУ и верни переиспользуемый MARKDOWN-ШАБЛОН.

ПРАВИЛА:
- Только заголовки разделов: # ## ### по иерархии документа.
- Под каждым заголовком — 1-2 строки курсивом (*...*): что должно быть в этом разделе.
- НЕ копируй конкретное содержание исходного документа — только структуру и подсказки.
- Верни ТОЛЬКО markdown шаблона: без markdown-ограждений, без пояснений до/после.
- Язык — русский.${headings.length ? '\n\nОбнаруженные заголовки документа:\n' + headings.slice(0, 60).map(h => '- ' + h).join('\n') : ''}

Документ-образец:
${docBody.slice(0, 9000)}`;
      try {
        const content = cleanTemplateMd(await genText(engine, sys, userMsg, 3000));
        if (!content) return json(res, { error: 'модель не вернула шаблон' }, 502);
        return json(res, { content });
      } catch (e) { return json(res, { error: e.message }, 502); }
    }

    // POST /api/template/from-standard — шаблон по ИТ-стандарту
    if (req.method === 'POST' && url.pathname === '/api/template/from-standard') {
      const { standard, artifact, engine } = await getBody(req);
      const std = STANDARDS[standard];
      if (!std) return json(res, { error: 'неизвестный стандарт' }, 400);
      if (!artifact) return json(res, { error: 'artifact обязателен' }, 400);
      const sys = 'Ты эксперт по ИТ-стандартам и методологиям (TOGAF, BABOK, PMBOK, ISO). Ты создаёшь переиспользуемые .md шаблоны артефактов.';
      const userMsg = `Собери переиспользуемый MARKDOWN-ШАБЛОН артефакта "${artifact}" по стандарту "${std.label}".

ПРАВИЛА:
- Структура разделов — каноничная для этого артефакта по стандарту.
- Заголовки: # — название документа, ## — разделы, ### — подразделы.
- Под каждым заголовком — 1-2 строки курсивом (*...*): что писать в разделе согласно стандарту.
- Верни ТОЛЬКО markdown шаблона: без markdown-ограждений, без пояснений до/после.
- Заголовки разделов — по-русски, при необходимости с англоязычным термином в скобках.`;
      try {
        const content = cleanTemplateMd(await genText(engine, sys, userMsg, 3000));
        if (!content) return json(res, { error: 'модель не вернула шаблон' }, 502);
        return json(res, { content });
      } catch (e) { return json(res, { error: e.message }, 502); }
    }

    if (req.method === 'GET' && url.pathname.startsWith('/api/template/')) {
      const name = url.pathname.split('/').pop();
      const fp = join(__dirname, 'templates', name + '.md');
      if (!existsSync(fp)) return json(res, { error: 'not found' }, 404);
      return json(res, { content: readFileSync(fp, 'utf8') });
    }

    if (req.method === 'POST' && url.pathname === '/api/ingest') {
      const { jira, path: srcPath } = await getBody(req);
      if (!jira || !srcPath) return json(res, { error: 'jira и path обязательны' }, 400);
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });
      const child = exec(`bash "${join(__dirname, 'scripts', 'ingest.sh')}" "${jira}" "${srcPath}"`, { detached: true });
      const ingestKey = `ingest-${jira}`;
      activeProcesses.set(ingestKey, child);
      child.stdout.on('data', d => res.write(d));
      child.stderr.on('data', d => res.write(d));
      child.on('close', code => { activeProcesses.delete(ingestKey); res.end(`\n[exit ${code}]`); });
      return;
    }

    if (req.method === 'POST' && url.pathname === '/api/process') {
      const { jira } = await getBody(req);
      if (!jira) return json(res, { error: 'jira обязателен' }, 400);
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });
      const _ollamaModel = ENV.OLLAMA_MODEL || 'llama3.1:8b';
      const _maxChars = String(ENV.MAX_CHARS || computeAutoMaxChars(_ollamaModel));
      const child = exec(`bash "${join(__dirname, 'scripts', 'process.sh')}" "${jira}"`,
        { detached: true, env: { ...process.env, OLLAMA_MODEL: _ollamaModel, MAX_CHARS: _maxChars } });
      const processKey = `process-${jira}`;
      activeProcesses.set(processKey, child);
      child.stdout.on('data', d => res.write(d));
      child.stderr.on('data', d => res.write(d));
      child.on('close', code => { activeProcesses.delete(processKey); res.end(`\n[exit ${code}]`); });
      return;
    }

    // POST /api/stop/:type/:jira
    if (req.method === 'POST' && url.pathname.startsWith('/api/stop/')) {
      const parts = url.pathname.split('/').filter(Boolean);
      const type = parts[2]; const jira = parts[3];
      if (!type || !jira) return json(res, { error: 'type и jira обязательны' }, 400);
      const stopped = killChild(`${type}-${jira}`);
      return json(res, { ok: stopped, message: stopped ? 'процесс остановлен' : 'нет активного процесса' });
    }

    // POST /api/skip/:jira
    if (req.method === 'POST' && url.pathname.startsWith('/api/skip/')) {
      const jira = url.pathname.split('/').pop();
      if (!jira) return json(res, { error: 'jira обязателен' }, 400);
      const logsDir = join(__dirname, 'logs');
      mkdirSync(logsDir, { recursive: true });
      writeFileSync(join(logsDir, `.skip-${jira}`), '');
      return json(res, { ok: true });
    }

    if (req.method === 'POST' && url.pathname === '/api/reprocess') {
      const { jira, files } = await getBody(req);
      if (!jira || !files?.length) return json(res, { error: 'jira и files обязательны' }, 400);
      let reset = 0;
      for (const f of files) {
        const fp = join(__dirname, 'raw', jira, f);
        if (!existsSync(fp)) continue;
        writeFileSync(fp, readFileSync(fp, 'utf8').replace('processed: true', 'processed: false'));
        reset++;
      }
      return json(res, { reset });
    }

    if (req.method === 'POST' && url.pathname === '/api/chat') {
      const { jira, jiras, question, history } = await getBody(req);
      const projectList = (jiras && jiras.length) ? jiras : (jira ? [jira] : []);
      if (!projectList.length || !question) return json(res, { error: 'jira/jiras и question обязательны' }, 400);
      let context = '';
      for (const j of projectList) {
        const c = getKnowledgeContext(j);
        if (c) context += `\n\n=== Проект ${j} ===\n${c}`;
      }
      const projectLabel = projectList.join(', ');
      const prompt = `Ты архитектурный ассистент Solution Architect в телеком IT-компании.
Используй ТОЛЬКО информацию из базы знаний проектов: ${projectLabel}.

ПРАВИЛА ОТВЕТА:
- Отвечай по-русски, структурированно
- Используй заголовки если ответ длинный
- Ссылайся на источники: [[filename]]
- Если информации нет в базе — прямо скажи об этом
- Не придумывай факты которых нет в документах
- Отвечай полностью, не обрезай ответ

База знаний:
${context.slice(0, 14000)}

Вопрос: ${question}`;
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });
      try {
        const r = await fetch('http://localhost:11434/api/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ model: ENV.OLLAMA_MODEL || 'llama3.1:8b', prompt, stream: false, options: { temperature: 0.1, num_ctx: 8192 } }),
          signal: AbortSignal.timeout(120000)
        });
        const data = await r.json();
        res.end(data.response || 'Нет ответа');
      } catch(e) { res.end('Ошибка модели: ' + e.message); }
      return;
    }

    if (req.method === 'POST' && url.pathname === '/api/artifact') {
      const body = await getBody(req);
      const { jira, jiras, template, section } = body;
      const projectList = (jiras && jiras.length) ? jiras : (jira ? [jira] : []);
      if (!projectList.length) return json(res, { error: 'jira/jiras обязательны' }, 400);
      let context = '';
      for (const j of projectList) {
        const c = getKnowledgeContext(j);
        if (c) context += `\n\n=== Проект ${j} ===\n${c}`;
      }
      const projectLabel = projectList.join(', ');
      const tmplPath = template ? join(__dirname, 'templates', template + '.md') : null;
      const tmplContent = (tmplPath && existsSync(tmplPath)) ? readFileSync(tmplPath, 'utf8').slice(0, 3000) : '';
      const sectionNote = section ? `Сфокусируйся на разделе: "${section}".` : 'Заполни все разделы шаблона.';
      const prompt = `Ты Solution Architect. На основе базы знаний проектов ${projectLabel} помоги заполнить архитектурный документ.\n\n${sectionNote}\n\nШаблон документа:\n${tmplContent}\n\nБаза знаний:\n${context.slice(0, 10000)}\n\nСгенерируй контент для указанного раздела на основе знаний из базы. Отвечай по-русски. Если данных недостаточно — укажи что именно нужно уточнить.`;
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });
      try {
        const r = await fetch('http://localhost:11434/api/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ model: ENV.OLLAMA_MODEL || 'llama3.1:8b', prompt, stream: false, options: { temperature: 0.2, num_ctx: 8192 } }),
          signal: AbortSignal.timeout(120000)
        });
        const data = await r.json();
        res.end(data.response || 'Нет ответа');
      } catch(e) { res.end('Ошибка модели: ' + e.message); }
      return;
    }

    // GET /api/diagram-types — список доступных типов PlantUML-диаграмм
    if (req.method === 'GET' && url.pathname === '/api/diagram-types') {
      return json(res, Object.entries(DIAGRAM_SPECS).map(([id, s]) => ({ id, label: s.label })));
    }

    // POST /api/diagram — модель строит PlantUML-код из знаний проектов
    if (req.method === 'POST' && url.pathname === '/api/diagram') {
      const { jira, jiras, diagramType, prompt: userPrompt, engine } = await getBody(req);
      const projectList = (jiras && jiras.length) ? jiras : (jira ? [jira] : []);
      const spec = DIAGRAM_SPECS[diagramType];
      if (!spec) return json(res, { error: 'неизвестный тип диаграммы' }, 400);
      if (!projectList.length) return json(res, { error: 'jira/jiras обязательны' }, 400);

      let context = '';
      for (const j of projectList) {
        const c = getKnowledgeContext(j);
        if (c) context += `\n\n=== Проект ${j} ===\n${c}`;
      }
      const task = (userPrompt && userPrompt.trim()) || 'Построй диаграмму на основе ключевой информации из базы знаний.';
      const sys = 'Ты Solution Architect. Ты строишь диаграммы PlantUML по базе знаний проектов.';
      const userMsg = `Тип диаграммы: ${spec.label}
Правила синтаксиса PlantUML: ${spec.hint}

ЗАДАЧА: ${task}

КРИТИЧЕСКИЕ ПРАВИЛА ВЫВОДА:
- Верни ТОЛЬКО код PlantUML — от ${spec.start} до соответствующего @end-тега.
- НИКАКОГО текста, объяснений или markdown-ограждений до или после кода.
- Подписи элементов — по-русски; латиницей только технические идентификаторы.
- Используй только факты из базы знаний — не выдумывай элементы.
- Код должен быть синтаксически корректным PlantUML.

База знаний проектов ${projectList.join(', ')}:
${context.slice(0, 11000)}`;

      try {
        let raw = '';
        if (engine === 'claude') {
          if (!ENV.ANTHROPIC_API_KEY) return json(res, { error: 'Anthropic API ключ не задан. Добавь его в Настройках.' }, 400);
          const r = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'x-api-key': ENV.ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
            body: JSON.stringify({
              model: ENV.CLAUDE_MODEL || 'claude-sonnet-4-6',
              max_tokens: 4000,
              system: sys,
              messages: [{ role: 'user', content: userMsg }]
            }),
            signal: AbortSignal.timeout(120000)
          });
          const data = await r.json();
          if (data.error) return json(res, { error: 'Ошибка API: ' + data.error.message }, 502);
          raw = data.content?.[0]?.text || '';
        } else {
          const r = await fetch('http://localhost:11434/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model: ENV.OLLAMA_MODEL || 'llama3.1:8b', prompt: sys + '\n\n' + userMsg, stream: false, options: { temperature: 0.1, num_ctx: 8192 } }),
            signal: AbortSignal.timeout(120000)
          });
          const data = await r.json();
          raw = data.response || '';
        }
        const uml = extractUml(raw);
        if (!uml) return json(res, { error: 'модель не вернула код диаграммы' }, 502);
        return json(res, { uml });
      } catch (e) {
        return json(res, { error: 'Ошибка модели: ' + e.message }, 502);
      }
    }

    // POST /api/render-uml — рендер PlantUML-кода в SVG через локальный jar
    if (req.method === 'POST' && url.pathname === '/api/render-uml') {
      const { uml } = await getBody(req);
      if (!uml || !uml.trim()) return json(res, { error: 'uml обязателен' }, 400);
      try {
        const svg = await renderPlantuml(uml);
        cors(res); res.writeHead(200, { 'Content-Type': 'image/svg+xml; charset=utf-8' });
        res.end(svg);
      } catch (e) {
        return json(res, { error: e.message }, 500);
      }
      return;
    }

    // GET /api/drawio/catalog/:jira — каталог переиспользуемых объектов проекта
    if (req.method === 'GET' && url.pathname.startsWith('/api/drawio/catalog/')) {
      const jira = decodeURIComponent(url.pathname.split('/').pop());
      return json(res, { jira, objects: readCatalog(jira) });
    }

    // POST /api/drawio — модель строит граф из знаний → валидный drawio XML
    if (req.method === 'POST' && url.pathname === '/api/drawio') {
      const { jira, jiras, prompt: userPrompt, engine, name } = await getBody(req);
      const projectList = (jiras && jiras.length) ? jiras : (jira ? [jira] : []);
      if (!projectList.length) return json(res, { error: 'jira/jiras обязательны' }, 400);

      let context = '';
      const catSeen = new Map();
      for (const j of projectList) {
        const c = getKnowledgeContext(j);
        if (c) context += `\n\n=== Проект ${j} ===\n${c}`;
        for (const o of readCatalog(j)) if (!catSeen.has(o.id)) catSeen.set(o.id, o);
      }
      const catalog = [...catSeen.values()];
      const catalogNote = catalog.length
        ? `\n\nКАТАЛОГ СУЩЕСТВУЮЩИХ ОБЪЕКТОВ ПРОЕКТА (если объект подходит — ПЕРЕИСПОЛЬЗУЙ его "id" и "label" дословно, чтобы диаграммы были согласованы):\n${catalog.map(o => `- id="${o.id}" label="${o.label}" type=${o.type}`).join('\n')}`
        : '';
      const task = (userPrompt && userPrompt.trim()) || 'Построй диаграмму архитектуры на основе ключевой информации из базы знаний.';
      const sys = 'Ты Solution Architect. Ты проектируешь архитектурные диаграммы и возвращаешь их в виде строгого JSON.';
      const userMsg = `ЗАДАЧА: ${task}

Верни ТОЛЬКО JSON такого вида (без markdown-ограждений, без текста до/после):
{
  "name": "краткое название диаграммы",
  "nodes": [ { "id": "уникальный-идентификатор", "label": "Название по-русски", "type": "ОДИН ИЗ: ${DRAWIO_TYPES.join(' | ')}" } ],
  "edges": [ { "from": "id источника", "to": "id цели", "label": "подпись связи (можно пустую)" } ]
}

ПРАВИЛА:
- "type" выбирай по смыслу: system — наша система, external — внешняя система, database — БД/хранилище, component — модуль/сервис, actor — пользователь/роль, process — процесс/шаг, queue — очередь/брокер, note — пояснение.
- В "edges" поля "from" и "to" ДОЛЖНЫ совпадать с "id" из "nodes".
- Используй только факты из базы знаний — не выдумывай элементы.
- Подписи — по-русски.${catalogNote}

База знаний проектов ${projectList.join(', ')}:
${context.slice(0, 11000)}`;

      try {
        let raw = '';
        if (engine === 'claude') {
          if (!ENV.ANTHROPIC_API_KEY) return json(res, { error: 'Anthropic API ключ не задан. Добавь его в Настройках.' }, 400);
          const r = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'x-api-key': ENV.ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
            body: JSON.stringify({ model: ENV.CLAUDE_MODEL || 'claude-sonnet-4-6', max_tokens: 4000, system: sys, messages: [{ role: 'user', content: userMsg }] }),
            signal: AbortSignal.timeout(120000)
          });
          const data = await r.json();
          if (data.error) return json(res, { error: 'Ошибка API: ' + data.error.message }, 502);
          raw = data.content?.[0]?.text || '';
        } else {
          const r = await fetch('http://localhost:11434/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model: ENV.OLLAMA_MODEL || 'llama3.1:8b', prompt: sys + '\n\n' + userMsg, stream: false, format: 'json', options: { temperature: 0.1, num_ctx: 8192 } }),
            signal: AbortSignal.timeout(120000)
          });
          const data = await r.json();
          raw = data.response || '';
        }
        const graph = extractJson(raw);
        if (!graph || !Array.isArray(graph.nodes) || !graph.nodes.length) {
          return json(res, { error: 'модель не вернула корректный граф диаграммы' }, 502);
        }
        const { xml, objects } = buildDrawioXml(graph, name || graph.name);
        mergeCatalog(projectList[0], objects);
        return json(res, { xml, objects, name: graph.name || name || 'diagram' });
      } catch (e) {
        return json(res, { error: 'Ошибка модели: ' + e.message }, 502);
      }
    }

    // POST /api/drawio/save — сохранить .drawio в репозиторий проекта + каталог
    if (req.method === 'POST' && url.pathname === '/api/drawio/save') {
      const { jira, name, xml } = await getBody(req);
      if (!jira || !xml) return json(res, { error: 'jira и xml обязательны' }, 400);
      const safe = slugify(name || 'diagram');
      const dir = join(__dirname, 'knowledge', 'projects', jira, 'diagrams');
      mkdirSync(dir, { recursive: true });
      const file = safe + '.drawio';
      writeFileSync(join(dir, file), xml);
      const { nodes } = parseDrawioXml(xml);
      const objects = nodes.map(n => ({ id: n.id || ('node-' + slugify(n.label)), label: n.label, type: n.type, style: n.style }));
      const catalog = mergeCatalog(jira, objects);
      return json(res, { ok: true, file: `diagrams/${file}`, catalogSize: catalog.length });
    }

    // POST /api/import-drawio — импорт .drawio: каталог + диаграмма + в пайплайн знаний
    if (req.method === 'POST' && url.pathname === '/api/import-drawio') {
      const contentType = req.headers['content-type'] || '';
      if (!contentType.includes('multipart/form-data')) return json(res, { error: 'multipart required' }, 400);
      const boundary = contentType.split('boundary=')[1];
      if (!boundary) return json(res, { error: 'no boundary' }, 400);

      const chunks = [];
      for await (const chunk of req) chunks.push(chunk);
      const body = Buffer.concat(chunks).toString('binary');

      const jiraM = body.match(/name="jira"\r\n\r\n([^\r]+)/);
      const jira = jiraM ? jiraM[1].trim() : null;
      const fileRe = /name="file"; filename="([^"]+)"[\s\S]*?\r\n\r\n([\s\S]+?)(?=\r\n--)/;
      const fileM = body.match(fileRe);
      if (!jira || !fileM) return json(res, { error: 'jira и file обязательны' }, 400);

      const origName = fileM[1];
      const xml = Buffer.from(fileM[2], 'binary').toString('utf8');
      if (!decompressDrawio(xml).includes('<mxGraphModel') && !decompressDrawio(xml).includes('<mxCell')) {
        return json(res, { error: 'файл не похож на .drawio (нет mxGraphModel)' }, 400);
      }

      const { nodes, edges } = parseDrawioXml(xml);
      const objects = nodes.map(n => ({ id: n.id || ('node-' + slugify(n.label)), label: n.label, type: n.type, style: n.style }));
      const catalog = mergeCatalog(jira, objects);

      const safe = slugify(origName.replace(/\.drawio$/i, ''));
      const diagDir = join(__dirname, 'knowledge', 'projects', jira, 'diagrams');
      mkdirSync(diagDir, { recursive: true });
      writeFileSync(join(diagDir, safe + '.drawio'), xml);

      // в пайплайн знаний: кладём как raw .md с frontmatter type: drawio
      const rawDir = join(__dirname, 'raw', jira);
      mkdirSync(rawDir, { recursive: true });
      const today = new Date().toISOString().slice(0, 10);
      const md = `---\nsource: "${origName}"\njira: "${jira}"\ndate: "${today}"\nprocessed: false\ntype: "drawio"\n---\n\n\`\`\`xml\n${decompressDrawio(xml)}\n\`\`\`\n`;
      writeFileSync(join(rawDir, safe + '.md'), md);

      return json(res, { ok: true, nodes: nodes.length, edges: edges.length, catalogSize: catalog.length, file: `diagrams/${safe}.drawio` });
    }

    // GET /api/cyrillic-check/:jira — доля кириллицы в raw + наличие кириллической модели
    if (req.method === 'GET' && url.pathname.startsWith('/api/cyrillic-check/')) {
      const jira = decodeURIComponent(url.pathname.split('/').pop());
      const dir = join(__dirname, 'raw', jira);
      let cyr = 0, lat = 0, files = 0;
      if (existsSync(dir)) {
        for (const f of readdirSync(dir).filter(f => f.endsWith('.md')).slice(0, 10)) {
          files++;
          const body = readFileSync(join(dir, f), 'utf8').replace(/^---\n[\s\S]*?\n---\n/, '').slice(0, 20000);
          for (const ch of body) {
            if (ch >= 'Ѐ' && ch <= 'ӿ') cyr++;
            else if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')) lat++;
          }
        }
      }
      const ratio = (cyr + lat) ? cyr / (cyr + lat) : 0;
      let installed = [];
      try {
        const r = await fetch('http://localhost:11434/api/tags', { signal: AbortSignal.timeout(4000) });
        installed = ((await r.json()).models || []).map(m => m.name);
      } catch { /* ollama down — installed остаётся пустым */ }
      const cyrillicModelInstalled = installed.some(n => /qwen|aya|vikhr|saiga|mistral/i.test(n));
      const isCyrillic = ratio >= 0.3;
      return json(res, {
        jira, files, percent: Math.round(ratio * 100),
        isCyrillic, cyrillicModelInstalled,
        recommendModel: 'qwen2.5:7b',
        recommend: isCyrillic && !cyrillicModelInstalled
      });
    }

    // POST /api/ollama-pull — установка модели Ollama со стримингом прогресса
    if (req.method === 'POST' && url.pathname === '/api/ollama-pull') {
      const { model } = await getBody(req);
      if (!model) return json(res, { error: 'model обязателен' }, 400);
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });
      try {
        const r = await fetch('http://localhost:11434/api/pull', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: model, stream: true })
        });
        res.write(`Загрузка ${model}...\n`);
        let buf = '', lastStatus = '', lastPct = -1;
        for await (const chunk of r.body) {
          buf += chunk.toString('utf8');
          let nl;
          while ((nl = buf.indexOf('\n')) >= 0) {
            const line = buf.slice(0, nl).trim();
            buf = buf.slice(nl + 1);
            if (!line) continue;
            try {
              const o = JSON.parse(line);
              if (o.error) { res.write('[ERR] ' + o.error + '\n'); continue; }
              if (o.total && o.completed != null) {
                const pct = Math.round(o.completed / o.total * 100);
                if (o.status === lastStatus && pct < lastPct + 5 && pct < 100) continue;
                lastStatus = o.status; lastPct = pct;
                res.write(`${o.status} ${pct}%\n`);
              } else {
                if (o.status === lastStatus) continue;
                lastStatus = o.status; lastPct = -1;
                res.write((o.status || '') + '\n');
              }
            } catch { /* неполная строка NDJSON */ }
          }
        }
        res.end('\n[exit 0]');
      } catch (e) {
        res.end('\n[ERR] ' + e.message);
      }
      return;
    }

    // POST /api/replace-file — загрузка замены для нечитабельного файла
    if (req.method === 'POST' && url.pathname === '/api/replace-file') {
      // Парсим multipart/form-data вручную
      const contentType = req.headers['content-type'] || '';
      if (!contentType.includes('multipart/form-data')) return json(res, { error: 'multipart required' }, 400);

      const boundary = contentType.split('boundary=')[1];
      if (!boundary) return json(res, { error: 'no boundary' }, 400);

      const chunks = [];
      for await (const chunk of req) chunks.push(chunk);
      const body = Buffer.concat(chunks).toString('binary');

      // Извлекаем поля
      const getField = (name) => {
        const re = new RegExp('name="' + name + '"\r\n\r\n([^\r]+)');
        const m = body.match(re);
        return m ? m[1].trim() : null;
      };

      const jira = getField('jira');
      const rawFile = getField('rawFile');

      if (!jira || !rawFile) return json(res, { error: 'jira и rawFile обязательны' }, 400);

      // Извлекаем загруженный файл
      const fileRe = new RegExp('name="file"; filename="([^"]+)"[\\s\\S]*?Content-Type: [^\\r\\n]+\\r\\n\\r\\n([\\s\\S]+?)(?=--)');
      const fileMatch = body.match(fileRe);
      if (!fileMatch) return json(res, { error: 'файл не найден в запросе' }, 400);

      const uploadedName = fileMatch[1];
      const fileContent = Buffer.from(fileMatch[2].replace(/\r\n$/, ''), 'binary');
      const ext = uploadedName.split('.').pop().toLowerCase();

      // Сохраняем временный файл
      const tmpPath = join(__dirname, 'raw', jira, '_tmp_replace.' + ext);
      writeFileSync(tmpPath, fileContent);

      // Читаем оригинальный frontmatter
      const rawPath = join(__dirname, 'raw', jira, rawFile);
      let origFrontmatter = '';
      if (existsSync(rawPath)) {
        const orig = readFileSync(rawPath, 'utf8');
        const fm = orig.match(/^(---[\s\S]+?---)/);
        if (fm) origFrontmatter = fm[1].replace('pdf-scan-failed', ext).replace('processed: true', 'processed: false');
      }

      // Конвертируем через pandoc или tesseract
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });

      const outTmp = join(__dirname, 'raw', jira, '_tmp_out.md');
      let cmd = '';

      if (['md', 'txt'].includes(ext)) {
        cmd = `cp "${tmpPath}" "${outTmp}"`;
      } else if (['docx', 'doc', 'pptx', 'xlsx'].includes(ext)) {
        cmd = `pandoc "${tmpPath}" -t markdown --wrap=none -o "${outTmp}"`;
      } else if (['png', 'jpg', 'jpeg'].includes(ext)) {
        cmd = `tesseract "${tmpPath}" stdout -l rus+eng > "${outTmp}"`;
      } else {
        cmd = `cp "${tmpPath}" "${outTmp}"`;
      }

      const child = exec(cmd);
      child.stderr.on('data', d => res.write('[warn] ' + d));
      child.on('close', (code) => {
        try {
          let newContent = existsSync(outTmp) ? readFileSync(outTmp, 'utf8') : '';
          const finalContent = origFrontmatter + '\n\n' + newContent;
          writeFileSync(rawPath, finalContent);
          // Чистим временные файлы
          if (existsSync(tmpPath)) rmSync(tmpPath);
          if (existsSync(outTmp)) rmSync(outTmp);
          res.end('[ok] Файл заменён: ' + rawFile + '\n[exit 0]');
        } catch(e) {
          res.end('[error] ' + e.message);
        }
      });
      return;
    }

    // POST /api/save-to-knowledge
    if (req.method === 'POST' && url.pathname === '/api/save-to-knowledge') {
      const { jira, text, source } = await getBody(req);
      if (!jira || !text) return json(res, { error: 'jira и text обязательны' }, 400);
      const knowledgeDir = join(__dirname, 'knowledge', 'projects', jira);
      if (!existsSync(knowledgeDir)) { mkdirSync(knowledgeDir, { recursive: true }); }
      const filePath = join(knowledgeDir, 'claude-insights.md');
      const date = new Date().toISOString().slice(0, 10);
      const entry = '\n\n---\n\n## ' + date + ' [' + (source || 'claude-api') + ']\n\n' + text + '\n\n#claude-generated #hypothesis';
      const header = '# Claude Insights — ' + jira + '\n';
      if (!existsSync(filePath)) {
        writeFileSync(filePath, header + entry);
      } else {
        const existing = readFileSync(filePath, 'utf8');
        writeFileSync(filePath, existing + entry);
      }
      return json(res, { ok: true, file: 'claude-insights.md' });
    }

    // DELETE /api/project/:jira
    if (req.method === 'DELETE' && url.pathname.startsWith('/api/project/')) {
      const jira = url.pathname.split('/').pop();
      if (!jira || jira.length < 3) return json(res, { error: 'invalid jira' }, 400);
      let deleted = [];
      const rawDir = join(__dirname, 'raw', jira);
      const knowledgeDir = join(__dirname, 'knowledge', 'projects', jira);
      if (existsSync(rawDir)) { rmSync(rawDir, { recursive: true, force: true }); deleted.push('raw/'+jira); }
      if (existsSync(knowledgeDir)) { rmSync(knowledgeDir, { recursive: true, force: true }); deleted.push('knowledge/projects/'+jira); }
      return json(res, { ok: true, deleted });
    }

    // GET /api/ollama-models
    if (req.method === 'GET' && url.pathname === '/api/ollama-models') {
      try {
        const r = await fetch('http://localhost:11434/api/tags', { signal: AbortSignal.timeout(5000) });
        const data = await r.json();
        const models = (data.models || []).map(m => ({
          name: m.name,
          size: m.size ? (m.size / 1e9).toFixed(1) + ' GB' : ''
        }));
        return json(res, models);
      } catch {
        return json(res, []);
      }
    }

    // GET /api/settings
    if (req.method === 'GET' && url.pathname === '/api/settings') {
      const ollamaModel = ENV.OLLAMA_MODEL || 'llama3.1:8b';
      const autoMaxChars = computeAutoMaxChars(ollamaModel);
      const manualMaxChars = ENV.MAX_CHARS ? parseInt(ENV.MAX_CHARS) : null;
      return json(res, {
        hasAnthropicKey: !!(ENV.ANTHROPIC_API_KEY),
        keyPreview: ENV.ANTHROPIC_API_KEY ? '...'+ENV.ANTHROPIC_API_KEY.slice(-6) : null,
        claudeModel: ENV.CLAUDE_MODEL || 'claude-sonnet-4-6',
        ollamaModel,
        maxChars: manualMaxChars || autoMaxChars,
        maxCharsAuto: autoMaxChars,
        maxCharsIsManual: !!manualMaxChars,
        ramGB: Math.floor(totalmem() / (1024 ** 3))
      });
    }

    // POST /api/settings  { ANTHROPIC_API_KEY, OLLAMA_MODEL, CLAUDE_MODEL, MAX_CHARS }
    if (req.method === 'POST' && url.pathname === '/api/settings') {
      const body = await getBody(req);
      const envPath = join(__dirname, '.env');
      let lines = existsSync(envPath) ? readFileSync(envPath, 'utf8').split('\n').filter(Boolean) : [];
      const allowed = ['ANTHROPIC_API_KEY', 'CLAUDE_MODEL', 'OLLAMA_MODEL', 'MAX_CHARS'];
      Object.entries(body).forEach(([k, v]) => {
        if (!allowed.includes(k)) return;
        if (k === 'MAX_CHARS' && v === '') {
          lines = lines.filter(l => !l.startsWith('MAX_CHARS='));
          return;
        }
        if (!v) return;
        const idx = lines.findIndex(l => l.startsWith(k + '='));
        if (idx >= 0) lines[idx] = k + '=' + v;
        else lines.push(k + '=' + v);
      });
      writeFileSync(envPath, lines.join('\n') + '\n');
      ENV = loadEnv();
      return json(res, { ok: true });
    }

    // POST /api/claude  { system, userPrompt, max_tokens }
    if (req.method === 'POST' && url.pathname === '/api/claude') {
      const { system, userPrompt, max_tokens } = await getBody(req);
      if (!ENV.ANTHROPIC_API_KEY) return json(res, { error: 'Anthropic API ключ не задан. Добавь его в Настройках.' }, 400);

      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });

      const payload = JSON.stringify({
        model: ENV.CLAUDE_MODEL || 'claude-sonnet-4-6',
        max_tokens: max_tokens || 8000,
        system: system || 'Ты Solution Architect. Отвечай по-русски.',
        messages: [{ role: 'user', content: userPrompt }]
      });

      try {
        const r = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': ENV.ANTHROPIC_API_KEY,
            'anthropic-version': '2023-06-01'
          },
          body: payload,
          signal: AbortSignal.timeout(120000)
        });
        const data = await r.json();
        if (data.error) res.end('Ошибка API: ' + data.error.message);
        else res.end(data.content?.[0]?.text || 'Нет ответа');
      } catch(e) { res.end('Ошибка запроса: ' + e.message); }
      return;
    }

    // GET /api/skills
    if (req.method === 'GET' && url.pathname === '/api/skills') {
      const skillsDir = join(__dirname, 'skills');
      const skills = existsSync(skillsDir)
        ? readdirSync(skillsDir)
            .filter(f => statSync(join(skillsDir, f)).isDirectory())
            .map(name => {
              const skillFile = join(skillsDir, name, 'SKILL.md');
              if (!existsSync(skillFile)) return null;
              const content = readFileSync(skillFile, 'utf8');
              const desc = content.match(/## DESCRIPTION\n([^\n]+)/)?.[1]?.trim() || '';
              const date = content.match(/- Создан: ([^\n]+)/)?.[1]?.trim() || '';
              const source = content.match(/- Книга: ([^\n]+)/)?.[1]?.trim() || '';
              const lines = content.split('\n').length;
              return { name, desc, date, source, lines };
            })
            .filter(Boolean)
        : [];
      const claudeMd = join(__dirname, 'CLAUDE.md');
      if (existsSync(claudeMd)) {
        const content = readFileSync(claudeMd, 'utf8');
        skills.unshift({
          name: 'knowledge-processor',
          desc: content.match(/## Role\n([^\n]+)/)?.[1]?.trim() || 'Основной скилл обработки знаний',
          source: 'CLAUDE.md',
          date: '',
          lines: content.split('\n').length,
          builtin: true
        });
      }
      return json(res, skills);
    }

    // GET /api/skills/:name
    if (req.method === 'GET' && url.pathname.startsWith('/api/skills/')) {
      const name = url.pathname.split('/').pop();
      const filePath = name === 'knowledge-processor'
        ? join(__dirname, 'CLAUDE.md')
        : join(__dirname, 'skills', name, 'SKILL.md');
      if (!existsSync(filePath)) return json(res, { error: 'not found' }, 404);
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(readFileSync(filePath, 'utf8'));
      return;
    }

    // DELETE /api/skills/:name
    if (req.method === 'DELETE' && url.pathname.startsWith('/api/skills/')) {
      const name = url.pathname.split('/').pop();
      if (!name || name.length < 2) return json(res, { error: 'invalid name' }, 400);
      const skillDir = join(__dirname, 'skills', name);
      if (!existsSync(skillDir)) return json(res, { error: 'not found' }, 404);
      rmSync(skillDir, { recursive: true, force: true });
      const readme = join(__dirname, 'skills', 'README.md');
      if (existsSync(readme)) {
        const lines = readFileSync(readme, 'utf8').split('\n')
          .filter(l => !l.includes(name + '/SKILL.md'));
        writeFileSync(readme, lines.join('\n'));
      }
      return json(res, { ok: true });
    }

    // POST /api/skills/create-from-knowledge — доменный скилл из базы знаний проекта
    if (req.method === 'POST' && url.pathname === '/api/skills/create-from-knowledge') {
      const { jira, skillName } = await getBody(req);
      if (!jira) return json(res, { error: 'jira обязателен' }, 400);
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });
      const nameArg = skillName ? ` "${skillName}"` : '';
      const child = exec(
        `echo y | OLLAMA_MODEL="${ENV.OLLAMA_MODEL || 'llama3.1:8b'}" bash "${join(__dirname, 'scripts', 'create_skill_from_knowledge.sh')}" "${jira}"${nameArg}`,
        { env: { ...process.env, OLLAMA_MODEL: ENV.OLLAMA_MODEL || 'llama3.1:8b' } }
      );
      child.stdout.on('data', d => res.write(d));
      child.stderr.on('data', d => res.write(d));
      child.on('close', code => res.end(`\n[exit ${code}]`));
      return;
    }

    // POST /api/skills/create — запуск process_book.sh со стримингом
    if (req.method === 'POST' && url.pathname === '/api/skills/create') {
      const { pdfPath, skillName } = await getBody(req);
      if (!pdfPath) return json(res, { error: 'pdfPath обязателен' }, 400);
      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });
      const nameArg = skillName ? ` "${skillName}"` : '';
      const child = exec(
        `echo y | OLLAMA_MODEL="${ENV.OLLAMA_MODEL || 'llama3.1:8b'}" bash "${join(__dirname, 'scripts', 'process_book.sh')}" "${pdfPath}"${nameArg}`,
        { env: { ...process.env, OLLAMA_MODEL: ENV.OLLAMA_MODEL || 'llama3.1:8b', ANTHROPIC_API_KEY: ENV.ANTHROPIC_API_KEY || '' } }
      );
      child.stdout.on('data', d => res.write(d));
      child.stderr.on('data', d => res.write(d));
      child.on('close', code => res.end(`\n[exit ${code}]`));
      return;
    }

    // GET /api/skill/:jira — check if project skill exists
    if (req.method === 'GET' && url.pathname.startsWith('/api/skill/') && !url.pathname.endsWith('/promote')) {
      const jira = url.pathname.split('/').pop();
      const skillPath = join(__dirname, 'knowledge', 'projects', jira, jira + '-SKILL.md');
      if (!existsSync(skillPath)) return json(res, { exists: false });
      return json(res, { exists: true, content: readFileSync(skillPath, 'utf8') });
    }

    // DELETE /api/skill/:jira — delete project SKILL.md
    if (req.method === 'DELETE' && url.pathname.startsWith('/api/skill/')) {
      const jira = url.pathname.split('/').pop();
      const skillPath = join(__dirname, 'knowledge', 'projects', jira, jira + '-SKILL.md');
      if (!existsSync(skillPath)) return json(res, { ok: true, deleted: false });
      unlinkSync(skillPath);
      return json(res, { ok: true, deleted: true });
    }

    // POST /api/analyze-for-skill — sample raw docs and suggest a skill via Ollama (streaming)
    if (req.method === 'POST' && url.pathname === '/api/analyze-for-skill') {
      const { jira } = await getBody(req);
      if (!jira) return json(res, { error: 'jira обязателен' }, 400);
      const rawDir = join(__dirname, 'raw', jira);
      if (!existsSync(rawDir)) return json(res, { error: 'raw папка не найдена' }, 404);

      const mdFiles = readdirSync(rawDir)
        .filter(f => f.endsWith('.md'))
        .map(f => ({ f, size: statSync(join(rawDir, f)).size }))
        .sort((a, b) => b.size - a.size)
        .map(x => x.f);
      let samples = ''; let sampled = 0;
      for (const f of mdFiles) {
        if (sampled >= 8) break;
        const raw = readFileSync(join(rawDir, f), 'utf8');
        const body = raw.replace(/^---[\s\S]+?---\n?/, '').trim();
        if (body.length < 200) continue;
        const garbled = (body.match(/[<EFBFBD>\x00-\x08\x0E-\x1F]/g) || []).length / body.length;
        if (garbled > 0.05) continue;
        samples += `\n\n### ${f}\n${body.slice(0, 1500)}`;
        sampled++;
      }
      if (!samples.trim()) return json(res, { error: 'нет читаемого контента в raw файлах' }, 400);

      const prompt = `Ты редактор базы знаний. Проанализируй отрывки документов проекта "${jira}" и напиши SKILL.md — инструкцию для LLM по извлечению знаний.

ПРАВИЛА:
- SKILL.md — это ИНСТРУКЦИЯ, а не каталог данных и не пример извлечения
- Верни ТОЛЬКО markdown-текст SKILL.md, без пояснений
- Не более 35 строк
- Ровно 3 секции: ## Домен, ## Задача модели, ## JSON-структура

ФОРМАТ:

## Домен
[одно предложение: тип документов и тематика]

## Задача модели
[2-4 пункта со знаком - : что именно извлекать]

## JSON-структура
\`\`\`json
{
  "секция1": [{"id": "X-001", "поле": "описание поля", "source": "[[filename]]"}],
  "секция2": [...]
}
\`\`\`
Отвечай ТОЛЬКО валидным JSON без пояснений.

---
Отрывки документов проекта (для понимания домена):
${samples.slice(0, 5000)}

Напиши SKILL.md для этого проекта:`;

      cors(res); res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Transfer-Encoding': 'chunked' });
      try {
        const r = await fetch('http://localhost:11434/api/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ model: ENV.OLLAMA_MODEL || 'llama3.1:8b', prompt, stream: true, options: { temperature: 0.2, num_ctx: 4096, num_predict: 900 } }),
          signal: AbortSignal.timeout(120000)
        });
        const rdr = r.body.getReader(); const dec = new TextDecoder();
        while (true) {
          const { value, done } = await rdr.read();
          if (done) break;
          for (const line of dec.decode(value).split('\n').filter(Boolean)) {
            try { const o = JSON.parse(line); if (o.response) res.write(o.response); } catch {}
          }
        }
        res.end();
      } catch(e) { res.end('\nОшибка: ' + e.message); }
      return;
    }

    // POST /api/skill/:jira/promote — copy project SKILL.md → skills/<name>/SKILL.md
    if (req.method === 'POST' && /^\/api\/skill\/[^/]+\/promote$/.test(url.pathname)) {
      const jira = url.pathname.split('/')[3];
      const { targetName } = await getBody(req);
      const name = (targetName || jira).replace(/[^a-zA-Z0-9_-]/g, '-').toLowerCase();
      const srcPath = join(__dirname, 'knowledge', 'projects', jira, jira + '-SKILL.md');
      if (!existsSync(srcPath)) return json(res, { error: 'project skill not found' }, 404);
      const destDir = join(__dirname, 'skills', name);
      mkdirSync(destDir, { recursive: true });
      const content = readFileSync(srcPath, 'utf8');
      writeFileSync(join(destDir, 'SKILL.md'), content);
      const readme = join(__dirname, 'skills', 'README.md');
      const entry = `- [${name}](${name}/SKILL.md)\n`;
      if (existsSync(readme)) {
        const existing = readFileSync(readme, 'utf8');
        if (!existing.includes(name + '/SKILL.md')) writeFileSync(readme, existing + entry);
      } else {
        writeFileSync(readme, `# Skills\n\n${entry}`);
      }
      return json(res, { ok: true, name });
    }

    // POST /api/save-skill — save project SKILL.md
    if (req.method === 'POST' && url.pathname === '/api/save-skill') {
      const { jira, content } = await getBody(req);
      if (!jira || !content) return json(res, { error: 'jira и content обязательны' }, 400);
      const knowledgeDir = join(__dirname, 'knowledge', 'projects', jira);
      if (!existsSync(knowledgeDir)) mkdirSync(knowledgeDir, { recursive: true });
      const cleaned = content.replace(/^```(?:markdown)?\s*\n?/i, '').replace(/\n?```\s*$/i, '').trim();
      writeFileSync(join(knowledgeDir, jira + '-SKILL.md'), cleaned);
      return json(res, { ok: true });
    }

    return json(res, { error: 'Not found' }, 404);
  }

  let filePath = url.pathname === '/' ? '/ui/index.html' : url.pathname;
  filePath = join(__dirname, filePath);
  if (!existsSync(filePath)) { json(res, { error: 'Not found' }, 404); return; }
  const ext = filePath.match(/\.[^.]+$/)?.[0] || '';
  cors(res); res.writeHead(200, { 'Content-Type': MIME[ext] || 'text/plain' });
  res.end(readFileSync(filePath));
});

server.listen(PORT, () => console.log(`\n🧠 Second Brain → http://localhost:${PORT}\n`));
