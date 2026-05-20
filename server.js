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
import { exec } from 'child_process';
import { readFileSync, existsSync, readdirSync, statSync, writeFileSync, rmSync, mkdirSync, unlinkSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { totalmem } from 'os';

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

function killChild(key) {
  const child = activeProcesses.get(key);
  if (!child) return false;
  child.kill('SIGTERM');
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
    ctx += `\n\n### ${f}\n${readFileSync(join(dir, f), 'utf8').slice(0, 3000)}`;
  }
  return ctx;
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
      const child = exec(`bash "${join(__dirname, 'scripts', 'ingest.sh')}" "${jira}" "${srcPath}"`);
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
        { env: { ...process.env, OLLAMA_MODEL: _ollamaModel, MAX_CHARS: _maxChars } });
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
