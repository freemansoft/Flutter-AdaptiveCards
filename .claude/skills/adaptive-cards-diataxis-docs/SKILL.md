---
name: adaptive-cards-diataxis-docs
description: >
  Classify, audit, and enforce the Diátaxis documentation framework across the
  Flutter-AdaptiveCards canonical `docs/` and package READMEs. Keeps each doc in
  exactly one quadrant (tutorial / how-to / reference / explanation) and flags
  mixed-mode drift. Use when writing or reviewing a doc under `docs/`, adding a
  `doc_type:` front-matter tag, auditing the doc set for gaps or violations, or
  when the user mentions Diátaxis or documentation structure. Also carries the
  repo's documentation **register** rule — analyst, not publicist — so use it
  when asked to make a doc less dramatic, tone down a write-up, or sweep prose
  for hype. Advisory only — it proposes splits, it does not silently move or
  rewrite files.
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

## Register — how the prose reads, in every quadrant

Quadrant is *what* a doc does; register is *how* it reads. They are independent:
a Reference table and an Explanation essay can both be written in hype. The repo
rule is in [`AGENTS.md`](../../../AGENTS.md) under **Documentation tone** —
**analyst, not publicist** — and it applies to all four quadrants.

Register also applies **wider than this skill's classification scope**. The
measurement notebooks (`adaptive_chat_server_dart/ModelBehavior.md`) and the
`CHANGELOG.md` files are out of scope for quadrant classification — they are
dated records — but they are squarely in scope for tone, and they are where
this drift shows up most, because a measurement write-up is the easiest place
to start selling a result.

Worked before/after, all from real sweeps of this repo's docs:

| Smell | Before | After |
| ----- | ------ | ----- |
| Rhetorical question as a heading | "Is `nemotron-3.5-lightning:30b` the better large model? No." | "`nemotron-3.5-lightning:30b` is not the better large model." |
| Amplified verb | "collapses to 9/25", "helped decisively" | "falls to 9/25", "helped" |
| Vague superlative | "the only perfect score in this file" | "the only 25/25 in this file" |
| Inference stated as measurement | "Filling a schema argument **pulls** a model toward the cheapest filler" | "…**appears to favour** the cheapest filler" |
| Verdict heading | "The canary over-predicted, and that is a lesson about the canary" | "The phase-1 canary over-predicted willingness" |
| Closing flourish | "…and on this channel the gap between them is where the failures moved." | (cut — end on the last factual sentence) |
| Emphasis bold | "erodes **nothing**", "did **not** help" | "erodes nothing", "did not help" |

Two rules that keep a tone sweep honest:

1. **Wording only.** Never change a figure, date, verdict, or claim while
   adjusting register. After sweeping a file, diff its numeric tokens against
   the previous commit and account for every difference — the only legitimate
   delta is a superlative replaced by the figure it stood for, which *adds* a
   number rather than changing one.
2. **Keep load-bearing bold and load-bearing claims.** "This axis does not
   discriminate, and that is the finding" asserts something the data supports;
   it is not hype. Strip amplification, not substance. Structural bold on topic
   sentences is what makes a long file scannable — reduce it, do not eliminate it.

## Integration with the review gate

The `adaptive-cards-code-review` skill's "Documentation impact" check should also ask: **does each touched in-scope
doc stay within one Diátaxis quadrant, is its `doc_type:` correct, and does newly added prose hold the analyst register above?** A mixed-mode doc is a review
comment, not a blocker on its own — but a *newly introduced* mode-mix in a doc that was previously
pure is drift worth fixing in the same change.

## Non-goals

- Does not invent documentation strategy or information architecture.
- Does not move, split, or rewrite files without confirmation.
- Does not touch out-of-scope process/archive docs.
- Does not override repo style rules (`AGENTS.md`, `adaptive-cards-public-api-docs`) — it composes with them.
- Does not rewrite a doc's register unasked. A tone sweep changes wording across a whole file, so propose it and get confirmation the same way a quadrant split is proposed.

## Attribution

Diátaxis is the work of Daniele Procida. Authoritative source: [diataxis.fr](https://diataxis.fr).
Compass and quadrant framing adapted from the framework; skill structure follows this repo's
`.agents/skills/*/SKILL.md` convention.
