# Diátaxis documentation audit & restructure plan (2026-07-07)

Audit of the canonical `docs/` set against the [Diátaxis](https://diataxis.fr) framework,
plus the restructure plan being executed from it. Governance rules live in the
[`adaptive-cards-diataxis-docs`](../../.agents/skills/adaptive-cards-diataxis-docs/SKILL.md)
skill.

## Scope

**In scope (governed):** canonical flat `docs/*.md` and the package READMEs.
**Out of scope:** `docs/plans/`, `docs/superpowers/`, `docs/reviews/` (this file), `docs/archive/`,
and any dated `YYYY-MM-DD-*` design/spec — these are process / decision-record artifacts where
mode-mixing is intended.

## Verdict

The set is **explanation/reference-heavy, has zero tutorials, and buries how-to content inside
large mixed-mode docs**. Four docs at the canonical level were actually out-of-scope artifacts.

## Per-doc classification

| Doc | Dominant quadrant | State |
| --- | --- | --- |
| `Architecture-Overview.md` | Explanation | ✅ clean |
| `overlay-properties-by-type.md` | Reference | ✅ clean |
| `documentation-scope.md` | Reference | ✅ clean |
| `adaptive-style.md` | Explanation | ✅ mostly |
| `Adaptive-expressions-...functions.md` | Reference | ✅ clean (speculative/future) |
| `optional-packages-and-extensions.md` | Explanation | ⚠️ mild mix (consumer checklist) |
| `AdaptiveWidget-Key-Generation.md` | Reference | ⚠️ mild mix |
| `reactive-riverpod.md` | Explanation | ⚠️ mild mix (how-to + backlog) |
| `testing-coverage.md` | How-to | ⚠️ mild mix |
| `hostconfig.md` | **Mixed** | ❌ violation (ref + explanation + how-to) |
| `actions-architecture.md` | **Mixed** | ❌ violation → **Phase 1 done** (recipe extracted) |
| `adaptive-template-design.md` | **Mixed** | ❌ violation |
| `AI-Agent-Support.md` | **Mixed** | ❌ violation |
| `backend-host-integration.md` | **Mixed** | ❌ violation |
| `form-inputs.md` | **Mixed** | ❌❌ worst → **Phase 1 done** (see below) |
| `Implementation-Status.md` | Index + Mixed | ❌ special (index) |
| `README.md` | Index | ➖ n/a (TOC) |
| `Column-ColumnSet-Fill-Vertical-Height.md` | — | 🗄️ **archived** (fixed-bug history) |
| `semantic-label-localization.md` | — | 🗄️ **archived** (proposal / findings) |
| `backgroundImage.md` | Reference | 🔖 tagged `doc_type: reference` (kept — README-linked) |
| `Encoded-Image-Support.md` | Reference | 🔖 tagged `doc_type: reference` (kept — README-linked) |
| `adaptive-explorer-design.md` | Explanation | 🔬 sample (lower priority) |
| `widgetbook-overlay-demos.md` | How-to/Reference | 🔬 sample (lower priority) |

Package READMEs are Reference-dominant hybrid landing pages — conventionally acceptable, not
split.

## Findings

1. **Gap — the Tutorial quadrant is empty.** No learning-oriented "render your first Adaptive
   Card" walkthrough. Every doc assumes competence.
2. **Imbalance — how-to content is trapped inside explanation/reference docs** rather than
   standing alone (`hostconfig.md`, `actions-architecture.md`, `backend-host-integration.md`,
   `form-inputs.md`). Extracting those recipes both purifies the parents and builds the missing
   how-to layer.
3. **Four canonical-level docs were out-of-scope artifacts** (a fixed-issue history, a proposal,
   two spec notes). Two were archived; two were kept in place (they are load-bearing feature
   links from the published README) and tagged `reference`.

## Restructure approach

`form-inputs.md` is linked from ~79 locations with hot anchor deep-links; `actions-architecture.md`
from 16. A naive "one file per quadrant" split would shatter those anchors. The adopted pattern
instead:

- **Keep the heavily-anchored doc in place** as the reference/explanation hub (preserves links).
- **Extract only sections with zero external anchor links** into new pure how-to docs.
- **De-dupe** "Backend invoke round-trips" duplication down to a pointer to
  `backend-host-integration.md`.
- **Archive** dated history sections to `docs/archive/specs/`.
- **Tag** each governed doc with `doc_type:` front matter.

### Completed in this changeset

- **#3 — archived out-of-scope artifacts:** `semantic-label-localization.md` and
  `Column-ColumnSet-Fill-Vertical-Height.md` → `docs/archive/specs/`; inbound links repointed;
  `backgroundImage.md` / `Encoded-Image-Support.md` kept and tagged `reference`.
- **`form-inputs.md` (worst offender), Phase 1:** extracted phone-filtering + password-reveal
  recipes → new [`input-text-recipes.md`](../input-text-recipes.md) (`doc_type: how-to`);
  archived the key-naming history → `archive/specs/form-inputs-key-naming-2026-01-30.md`;
  collapsed the duplicated backend section; tagged the doc `reference`. 405 → 321 lines. All 6
  externally deep-linked anchors preserved.
- **`actions-architecture.md`, Phase 1:** extracted "How to implement a custom action" → new
  [`custom-action-recipe.md`](../custom-action-recipe.md) (`doc_type: how-to`); collapsed the
  duplicated backend section; tagged the doc `explanation`.
- **`backend-host-integration.md`, Phase 1:** this doc is an integration **how-to** that had
  swallowed the wire-protocol reference. Extracted the request payloads, adapters, response
  contract, effect apply order, and error table → new
  [`backend-invoke-reference.md`](../backend-invoke-reference.md) (`doc_type: reference`);
  repointed the one `#effect-types-and-apply-order` anchor link; tagged the guide `how-to`.
  Architecture and sign-in sections stay in place (anchor-linked from `Architecture-Overview.md`
  and the host README).
- **`hostconfig.md`, Phase 1:** extracted the serialization-test requirements + theme-fallback
  verification checklist → new [`hostconfig-testing.md`](../hostconfig-testing.md)
  (`doc_type: how-to`); repointed the one `#serialization-test-requirements` anchor link
  (`adaptive-style.md`); tagged the doc `explanation`. The non-standard extension specs remain
  inline as embedded reference (Phase-2 candidate).

### Remaining (not yet done)

- **Violations to address next:** `adaptive-template-design.md`, `AI-Agent-Support.md`.
- **Tutorial gap:** author a "render your first Adaptive Card" tutorial (`doc_type: tutorial`).
- **Phase 2 (optional):** trim residual explanation prose in the tagged reference docs; consider
  moving `actions-architecture.md` payload tables into a dedicated reference doc.
- **Process:** wire the Diátaxis check into the `code-review` skill's "Documentation impact" gate.
