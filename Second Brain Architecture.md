# Second Brain — Architecture

**A local, agentic pipeline that turns documents into structured, reusable knowledge.**

This document explains *how the system is put together* so you can read the code with a map in hand — and retarget it to your own domain. For install steps see [INSTALLATION.md](INSTALLATION.md); for running and troubleshooting see [DEPLOYMENT.md](DEPLOYMENT.md).

---

## Goal

Build your first **local AI-agentic application**: a small "document → structured knowledge → reusable context" pipeline that runs entirely on your machine. Nothing leaves the computer unless *you* opt into the cloud. The worked example extracts **ML/AI study notes**, but every part is meant to be swapped for your own domain.

Design principles:
- **Local-first** — a local LLM (via Ollama) does the heavy lifting; your data stays on disk.
- **Schema-driven** — what gets extracted is defined in one file (`CLAUDE.md`), not hardwired in code.
- **Steerable** — small `SKILL.md` files nudge the model toward better, domain-specific results.
- **No build step** — plain Node.js + a single-file browser UI + Bash scripts. Read it top to bottom.

---

## The layers

```
[ LOCAL ]
  raw/                 ← incoming documents after conversion to markdown
  knowledge/           ← structured, extracted knowledge (the output)
  Ollama (local LLM)   ← reads raw/, extracts JSON following the schema

[ ORCHESTRATION ]
  server.js            ← Node.js HTTP server: routes, prompts, settings
  ui/index.html        ← single-file browser UI (no framework, inline JS)
  scripts/*.sh         ← ingest / process / skill-building Bash scripts

[ CLOUD — optional, opt-in only ]
  Claude API           ← deeper analysis on demand; can anonymize first
```

---

## Repository layout

```
second-brain/
├── raw/                      ← converted source docs, grouped by project (git-ignored)
├── knowledge/
│   └── projects/<project>/   ← extracted knowledge per project
│       ├── concepts.md
│       ├── models.md
│       ├── datasets.md
│       ├── experiments.md
│       └── <project>-SKILL.md ← optional per-project extraction skill
├── skills/                   ← reusable global skills (SKILL.md files)
├── templates/                ← .md document templates for artifact generation
├── scripts/
│   ├── ingest.sh             ← convert a folder of documents into raw/
│   ├── process.sh            ← run the model over raw/ → knowledge/
│   └── create_skill_*.sh     ← build a SKILL.md from knowledge or a PDF
├── server.js                 ← Node.js server
├── ui/index.html             ← browser UI
└── CLAUDE.md                 ← the extraction schema (system prompt for the model)
```

---

## The pipeline, step by step

1. **Ingest** — `ingest.sh <project> <folder>` walks a folder and converts each file to markdown:
   - `.pdf`, `.docx`, `.pptx` → `pandoc`
   - images → `tesseract` OCR
   - `.txt` → renamed to `.md`

   Each converted file gets YAML frontmatter (`source`, `project`, `date`, `type`, `processed: false`) and lands in `raw/<project>/`. Originals are never moved or deleted.

2. **(Optional) Skill** — analyze the loaded docs to propose a `<project>-SKILL.md`, a short instruction telling the model what to look for in this domain.

3. **Process** — `process.sh <project>` loads `CLAUDE.md` as the system prompt, then feeds each raw file to the local model. Large documents are split into chunks (sized to your RAM and model) with **full coverage** — nothing is dropped — and the per-file results are merged with ID de-duplication. The model returns JSON matching the schema, which is written into `knowledge/projects/<project>/`.

4. **Use it** — ask questions across projects, generate document drafts from templates, or build diagrams from the knowledge base.

---

## The schema (`CLAUDE.md`)

`CLAUDE.md` is the heart of the system: it is loaded verbatim as the model's system prompt (`scripts/process.sh`), and it defines the exact JSON the model must return. The default ML/AI schema captures **concepts, models, datasets, techniques, experiments, papers, open questions, resources** — each item carrying a `source: [[file]]` backlink so every claim is traceable.

**Editing `CLAUDE.md` is the main way you adapt the project to a new domain.** Change the categories and the few-shot example, and the whole pipeline follows.

Two rules in the schema are load-bearing:
- **Traceability** — every item must cite its source file `[[name]]`.
- **Epistemic honesty** — any claim with no traceable source is tagged `#hypothesis`, so facts and guesses stay separated.

---

## Skills

A **skill** is a small `SKILL.md` that steers extraction toward a domain. Two scopes:
- **Project skill** → `knowledge/projects/<project>/<project>-SKILL.md`, applied to one project; can be promoted to global.
- **Global skill** → a file under `skills/`, available to any project. The built-in `knowledge-processor` (which *is* `CLAUDE.md`) is always present and read-only.

Skills can be generated from a project's existing knowledge or from a PDF book/framework, then hand-edited. See [`skills/README.md`](skills/README.md).

---

## Privacy model

Everything runs locally by default. Content is sent to the cloud **only** when you explicitly use the Claude API feature — and the app can anonymize it first.

| Stays local — always | May go to the cloud (when you opt in) |
|---|---|
| Raw source materials (`raw/`) | Anonymized, structured items from `knowledge/` |
| Personal or sensitive names | Generic patterns with no identifying detail |
| Commercial figures and terms | General questions ("how should I phrase this?") |

If you plan to use the cloud features, keep sensitive material out of `knowledge/`.

---

## Where to start reading the code

- **`CLAUDE.md`** — the schema. Read this first; it defines the output.
- **`scripts/process.sh`** — how a document becomes structured knowledge (chunking, prompting, merging).
- **`server.js`** — the routes that the UI calls (settings, self-check, chat, artifact and diagram generation).
- **`ui/index.html`** — the whole front end in one file (i18n, onboarding wizard, the views).

No framework, no build — clone it, run `./start.sh`, and trace a single document through the pipeline to learn how it fits together.
