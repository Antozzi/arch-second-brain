# Second Brain

**Build your first local, agentic AI application — a pipeline that turns documents into structured, reusable knowledge.**

This is an educational project. It runs entirely on your machine (no data leaves it unless *you* opt into the cloud), and it shows, end to end, how a small "document → structured knowledge → reusable context" pipeline works. The worked example extracts **ML/AI study notes** (concepts, models, datasets, experiments, papers), but the whole thing is designed to be retargeted to *your* domain.

> Learning goals: how a local LLM (via Ollama) reads documents, how a JSON extraction **schema** shapes the output, how small **skill** files steer the model toward better domain-specific results, and how to wire a simple Node.js server + browser UI around it.

> **First time here?** → [INSTALLATION.md](INSTALLATION.md) — install the components and run the setup wizard
> **Running, logs, troubleshooting?** → [DEPLOYMENT.md](DEPLOYMENT.md)

---

## Quick start

```bash
./start.sh
```

Open **http://localhost:3030** in your browser. Ollama starts automatically if it isn't already running.

On first launch a **setup wizard** walks you through:
1. **Environment self-check** — verifies the required tools are installed (Node, Ollama + a model, pandoc, …).
2. **Language** — the UI is bilingual (English / Русский); switch any time from the header.
3. **Industry** — which industry your ML/AI knowledge base targets. The default (**General ML/AI**) ships with ready-made templates; pick another and the app will ask you to upload your own `.md` templates.
4. **Model** — pick a local Ollama model; optionally add a Claude API key for deeper analysis.

---

## How the pipeline works

```
  raw/            ingest          knowledge/           skills/
 ┌──────┐   convert + OCR   ┌──────────────┐   steer   ┌──────────┐
 │ PDFs │ ───────────────▶ │ local LLM    │ ◀──────── │ SKILL.md │
 │ docs │                  │ (Ollama)     │           └──────────┘
 │ code │                  │  extracts    │
 └──────┘                  │  JSON schema │
                           └──────┬───────┘
                                  ▼
                       structured markdown you can
                       search, link, and reuse
```

1. **Ingest** documents into a *project* (any short label, e.g. `ATTENTION-PAPERS`). Formats: PDF, Word, Excel, PowerPoint, images, diagrams.
2. **(Optional) Add a skill** — a small `SKILL.md` that tells the model what to look for in this domain. See [`skills/`](skills/).
3. **Process** — the local model reads each document and extracts knowledge following the JSON schema in [`CLAUDE.md`](CLAUDE.md).
4. **Use it** — ask the model questions across projects, generate document drafts from templates, or build diagrams.

---

## Walkthrough

### 1. Load documents
Open **⊕ Load project**. Enter a project label and a path to a folder of documents, then **① Load & convert**. Use **■ Stop** to interrupt.

### 2. (Optional) Tune the project skill
After loading, the **② Project skill** card appears. Click **⇒ Analyze** — the model reads the docs and proposes an extraction instruction (`<project>-SKILL.md`). Edit it and **✓ Save**, or **Skip**. Without a skill, the base prompt from `CLAUDE.md` is used.

### 3. Process with the model
Click **③ Run processing**. Large documents are split into chunks (`MAX_CHARS`, auto-sized to your RAM and model) with **full coverage** — nothing is dropped. Big projects can take a while. During processing you can **■ Stop** or **⇥ Skip file**.

### 4. Check what loaded
Open **⚠ Skipped files** and pick your project. Unreadable files (scanned PDFs, broken encodings) show up here — **⇪ Replace** them with a readable version and **Reprocess**.

### 5. Ask the model
Open **◎ Ask the model**. Select one or more projects (their contexts merge) and ask, e.g.:
- *What models are compared, and on which datasets?*
- *Summarize the key techniques.*
- *What open questions does this work leave?*

For deeper analysis, use **✦ Claude API** (sends content to the cloud — see privacy below).

### 6. Generate drafts and diagrams
Open **◈ Generate artifact**:
- **📄 Text section** — pick a template (e.g. Paper Summary, Concept Note, Experiment Log), pick a section, and let the model fill it from your knowledge base.
- **◫ PlantUML** / **⬚ drawio** — generate diagrams from the knowledge base, with live preview and export.

### 7. Level up with skills
Skills are domain instructions that make extraction sharper:
- **Project skill** → `knowledge/projects/<project>/<project>-SKILL.md`, scoped to one project; can be promoted to global (`skills/`).
- **Global skills** (`◆ Skills`) → build one from a project's knowledge or from a PDF book/framework. The built-in `knowledge-processor` (CLAUDE.md) is always shown read-only.

### 8. Save your knowledge base
```bash
git add knowledge/ templates/ scripts/ skills/ CLAUDE.md
git commit -m "update knowledge base"
```
Raw materials (`raw/`) and secrets (`.env`) are git-ignored — only the structured knowledge is versioned.

---

## What gets extracted (the schema)

The default ML/AI schema (in [`CLAUDE.md`](CLAUDE.md)) captures:

- **Concepts** — definitions worth remembering
- **Models** — architectures and what makes them special
- **Datasets** — what data, what task
- **Techniques** — training / optimization / evaluation methods
- **Experiments** — setups, results, takeaways
- **Papers** — sources and their contribution
- **Open questions** — what's unresolved
- **Resources** — courses, blogs, repos

Every item is traceable to its source `[[file]]`. Claims with no traceable source are tagged `#hypothesis`. **Editing this schema in `CLAUDE.md` is the main way you adapt the project to a new domain.**

---

## Privacy

Everything runs locally by default. Only when you explicitly use **✦ Claude API** is content sent to the cloud — and the app can anonymize it first (**⚙ Settings → Anonymize**). Keep sensitive material out of `knowledge/` if you plan to use the cloud features.

---

## Make it yours

- Change the extraction schema → edit [`CLAUDE.md`](CLAUDE.md)
- Write a domain skill → add a file under [`skills/`](skills/) (see [`skills/README.md`](skills/README.md))
- Add document templates → drop `.md` files in [`templates/`](templates/)
- Switch industry / language / model → header **✦ Setup wizard** or **⚙ Settings**

---

## Tech

Node.js server (`server.js`), a single-file browser UI (`ui/index.html`), Bash processing scripts (`scripts/`), local inference via **Ollama**, optional **Claude API**. No build step, no framework — read it top to bottom to learn how it fits together.
