# ml-paper-domain

## WHEN_TO_USE
Load this skill when the document is an ML/AI research paper or a chapter that introduces models, datasets, and experiments — typical for arXiv preprints and conference papers (NeurIPS, ICML, ICLR, CVPR, ACL).

## CORE_CONCEPTS
- **Contribution** — the paper's main claim or new method.
- **Architecture** — the model design (layers, attention, blocks).
- **Benchmark** — a dataset + metric used to compare methods.
- **Ablation** — an experiment that removes one part to measure its effect.
- **SOTA** — the current best published result on a benchmark.

## DECISION_RULES
- If the paper proposes a model → fill `models` (name, family, key_idea) and `papers`.
- If it reports numbers on a benchmark → fill `experiments` (setup, result, takeaway) and `datasets`.
- If it defines a new term → fill `concepts`.
- If it states a limitation or future work → fill `open_questions`.

## PLAYBOOKS
1. Identify the contribution from the abstract → one `papers` entry.
2. Extract each named model/architecture → `models`.
3. Extract each benchmark table row → `experiments` + the `datasets` used.
4. Extract new terminology from the method section → `concepts`.
5. Extract limitations / future work → `open_questions`.

## ANTI_PATTERNS
- Don't copy long passages verbatim — summarize.
- Don't report a metric without its dataset and the model it belongs to.
- Don't invent numbers; if a result is unclear, tag it #hypothesis.

## SOURCE
- Domain skill example for the educational pipeline.
