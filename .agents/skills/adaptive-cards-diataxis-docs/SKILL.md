---
name: adaptive-cards-diataxis-docs
description: >
  Classify, audit, and enforce the Diátaxis documentation framework across the
  Flutter-AdaptiveCards canonical `docs/` and package READMEs. Keeps each doc in
  exactly one quadrant (tutorial / how-to / reference / explanation) and flags
  mixed-mode drift. Use when writing or reviewing a doc under `docs/`, adding a
  `doc_type:` front-matter tag, auditing the doc set for gaps or violations, or
  when the user mentions Diátaxis or documentation structure. Advisory only — it
  proposes splits, it does not silently move or rewrite files.
---

# Diátaxis Documentation Governance (Flutter-AdaptiveCards)

Diátaxis (by Daniele Procida, [diataxis.fr](https://diataxis.fr)) sorts documentation into four
types by **user need**. A doc that tries to be two of them at once serves neither well. This skill
encodes the framework for *this repo's* published documentation and plugs into the
`adaptive-cards-code-review` "Documentation impact" gate.

## Scope — what this skill governs

**In scope (published product docs):**

- Canonical docs at the flat level of `docs/*.md` (e.g. `hostconfig.md`, `reactive-riverpod.md`,
  `Architecture-Overview.md`, `form-inputs.md`).
- The four package READMEs (`packages/*/README.md`) and their `## Implementation status` sections.

**Out of scope (process / decision-record artifacts — do NOT reclassify):**

- `docs/plans/`, `docs/superpowers/` — implementation plans are *intentionally* mixed-mode
  (narrative + steps + rationale). That is correct for a plan.
- `docs/reviews/` — dated, point-in-time findings.
- `docs/archive/` and `docs/archive/specs/` — superseded / frozen design specs.
- Any dated `YYYY-MM-DD-*.md` design or spec doc.

This split mirrors [`docs/documentation-scope.md`](../../../docs/documentation-scope.md) (published
vs. sample/working). When in doubt, an artifact that records *a decision made at a point in time*
is out of scope; an artifact a reader consults to *use or understand the library today* is in scope.

## The Diátaxis Compass

Classify every in-scope doc into **exactly one** quadrant using two questions:

1. Does it inform **action** (doing) or **cognition** (knowing)?
2. Does it serve **acquisition** (study / learning) or **application** (work)?

| If content...     | ...and serves...        | ...then it is... |
| ----------------- | ----------------------- | ---------------- |
| informs action    | acquisition (study)     | **Tutorial**     |
| informs action    | application (work)      | **How-to**       |
| informs cognition | application (work)      | **Reference**    |
| informs cognition | acquisition (study)     | **Explanation**  |

### Quadrant rules

- **Tutorial** (learning) — a guaranteed-to-succeed lesson for a newcomer. Sequential, concrete,
  minimal explanation, no alternatives. "We will… First, do X… You'll see Y."
- **How-to** (goal) — directions for a competent reader with a real task. Conditional imperatives,
  assumes background. "To register a new element type, do X." *Not* for teaching beginners or
  explaining why.
- **Reference** (information) — austere, neutral description of the machinery; structure mirrors the
  thing. Tables, property lists, specs. "The HostConfig sections are…" *No* instructions, no "why".
- **Explanation** (understanding) — discursive "why": context, trade-offs, connections, admits
  opinion. "The reason overlays are separate from the raw map is…" *No* numbered procedures or
  exhaustive tables.

## How this repo's docs classify (baseline)

Use these as worked examples; verify rather than assume:

- **Reference:** `hostconfig.md`, `overlay-properties-by-type.md`, `AdaptiveWidget-Key-Generation.md`.
- **Explanation:** `Architecture-Overview.md`, `reactive-riverpod.md`, `actions-architecture.md`,
  `optional-packages-and-extensions.md`.
- **How-to (or should be split into one):** `form-inputs.md`, `backend-host-integration.md`.
- **Tutorial:** currently thin — a likely gap to flag in an audit.

## Operating modes

Infer the mode from the request; ask if genuinely ambiguous.

- **classify** — read the doc, apply the compass, report **quadrant + confidence (high/med/low) +
  evidence** (specific phrases / structural signals). Example:
  > **Reference** (high). Evidence: property tables, neutral "X is…" phrasing, no imperatives, no rationale.
- **audit** — inventory the in-scope set, classify each, report **gaps** (missing quadrants — e.g. no
  tutorial), **violations** (mixed-mode / wrong quadrant), and **imbalances** (reference-heavy,
  tutorial-poor).
- **restructure** — propose splitting a mixed doc into one-doc-per-quadrant with cross-links.
  **Present the plan and get confirmation before moving or rewriting any file.** Respect the
  "Architecture documentation sync gate" in `AGENTS.md` — splitting a doc that other docs / skills /
  `AGENTS.md` link to means updating those links in the same change.
- **generate** — only with a stated or confirmed target quadrant; apply that quadrant's rules
  strictly and refuse to blend.

## Violation anti-patterns to flag

- **Reference that drifts into how-to** — `hostconfig.md` starting to walk you through wiring a form.
- **How-to that stops to explain why** — link out to an Explanation doc instead of inlining rationale.
- **Explanation padded with exhaustive tables** — move the tables to a Reference doc.
- **Tutorial offering choices/alternatives** — a tutorial has one happy path.
- **Any single doc emitting multiple quadrant signals** — the core Diátaxis smell; propose a split.

## Optional: `doc_type:` front matter

To make classification machine-checkable and reviewable, stamp in-scope docs with front matter:

```yaml
---
doc_type: reference   # reference | how-to | explanation | tutorial
---
```

This is the lightweight, repo-native alternative to reorganizing `docs/` into four folders — folder
moves would break the many relative links from `AGENTS.md`, package READMEs, and skills. Prefer the
tag; do not restructure the directory tree without an explicit, separately-scoped request.

## Integration with the review gate

The `adaptive-cards-code-review` skill's "Documentation impact" check should also ask: **does each touched in-scope
doc stay within one Diátaxis quadrant, and is its `doc_type:` correct?** A mixed-mode doc is a review
comment, not a blocker on its own — but a *newly introduced* mode-mix in a doc that was previously
pure is drift worth fixing in the same change.

## Non-goals

- Does not invent documentation strategy or information architecture.
- Does not move, split, or rewrite files without confirmation.
- Does not touch out-of-scope process/archive docs.
- Does not override repo style rules (`AGENTS.md`, `adaptive-cards-public-api-docs`) — it composes with them.

## Attribution

Diátaxis is the work of Daniele Procida. Authoritative source: [diataxis.fr](https://diataxis.fr).
Compass and quadrant framing adapted from the framework; skill structure follows this repo's
`.agents/skills/*/SKILL.md` convention.
