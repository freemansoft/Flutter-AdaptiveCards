# Public API Documentation Remediation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]` / `- [ ]`) syntax for tracking.

**Status:** **Tasks 0–5** — implemented and merged on `main`. **Final verification** — `cards_fs` analyze clean for `public_member_api_docs`; 400 tests pass (2026-06-11).

**Goal:** Bring exported public `///` documentation across library packages in line with the **`dart-public-api-docs`** standard: explain why an API exists and how callers use it; do not narrate implementation steps or restate signatures.

**Architecture:** Codify the rule in always-on AI instructions and a task skill; remediate exported APIs in four phases (blockers → host entry points → extension surface → polish); **Phase 5** promotes `public_member_api_docs` to error on `flutter_adaptive_cards_fs` and fills remaining gaps. Doc-only changes — no runtime behavior changes.

**Tech Stack:** Dart 3.12+, Flutter (FVM), `very_good_analysis`, dartdoc `///` comments.

**Standard references:**

- Root [`AGENTS.md`](../../../AGENTS.md) — Documentation Philosophy
- [`.agents/skills/dart-public-api-docs/SKILL.md`](../../../.agents/skills/dart-public-api-docs/SKILL.md)
- [`.agents/skills/code-review/SKILL.md`](../../../.agents/skills/code-review/SKILL.md) — public `///` checklist

**Audit baseline (2026-06-11):** ~45% PASS, ~40% WEAK, ~5% FAIL, ~5% MISSING on exported barrel APIs across five library packages.

---

## Implementation summary

| Phase                       | Scope                                                         | Result                                   |
| --------------------------- | ------------------------------------------------------------- | ---------------------------------------- |
| Task 0 — Codify standard    | `AGENTS.md`, skill, code-review                               | Done                                     |
| Phase 1 — Blockers          | FAIL + MISSING on exported APIs                               | Done (14 lib files)                      |
| Phase 2 — Host entry points | Canvas, raw card, handlers, registry, HostConfig top-level    | Done (7 lib files)                       |
| Phase 3 — Extension surface | Mixins, utils, additional, charts, test helpers               | Done (6 lib files; overlap with Phase 1) |
| Phase 4 — Polish            | HostConfig fields, charts layout DTOs, host adapter WEAK docs | Done (11 lib files)                      |
| Phase 5 — Lint enforcement  | Enable `public_member_api_docs` + fill ~99 gaps in `cards_fs` | Done (2026-06-11)                        |
| Final verification          | analyze + full test suite                                     | cards_fs analyze clean; 400 tests pass   |

### Changed files (merged)

**AI instructions (Task 0):**

| File                                           | Change                                     |
| ---------------------------------------------- | ------------------------------------------ |
| `AGENTS.md`                                    | Documentation Philosophy + skill pointer   |
| `.agents/skills/dart-public-api-docs/SKILL.md` | **Create** — standard, patterns, checklist |
| `.agents/skills/code-review/SKILL.md`          | Public `///` checklist items               |

**Library packages (Phases 1–4):**

| Package                               | Files                                                                                                                                                                                                                                                            |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flutter_adaptive_cards_fs`           | … `src/hostconfig/host_config.dart`, **`src/hostconfig/charts_layout_config.dart`**, `src/models/choice.dart`, …                                                                                                                                                 |
| `flutter_adaptive_cards_host_fs`      | **`src/adapters/plain_json_invoke_adapter.dart`**, **`teams_invoke_adapter.dart`**, `plain_json_invoke_response_parser.dart`, `backend_client.dart`, `http_backend_client.dart`, **`invoke_effect.dart`**, **`invoke_request.dart`**, **`invoke_response.dart`** |
| `flutter_adaptive_charts_fs`          | `lib/flutter_adaptive_charts_fs.dart`, `src/card_chart_registry.dart`                                                                                                                                                                                            |
| `flutter_adaptive_template_fs`        | `lib/flutter_adaptive_template_fs.dart`, `src/template.dart`                                                                                                                                                                                                     |
| `flutter_adaptive_cards_test_support` | `lib/flutter_adaptive_cards_test_support.dart`, `src/golden_helpers.dart`, `src/http_overrides.dart`, `src/test_widget_helpers.dart`                                                                                                                             |

**Post-Phase fix:** Library barrel `comment_references` — use backticks instead of `[TypeName]` in `flutter_adaptive_cards_fs.dart` and `flutter_adaptive_charts_fs.dart` library docs.

### Verification evidence (2026-06-11, partial)

```text
fvm flutter analyze packages/flutter_adaptive_cards_fs \
  packages/flutter_adaptive_cards_host_fs \
  packages/flutter_adaptive_charts_fs \
  packages/flutter_adaptive_template_fs \
  packages/flutter_adaptive_cards_test_support
→ 1 pre-existing info (prefer_constructors_over_static_methods in theme_color_fallbacks.dart)
→ No new issues from doc changes
```

Full suite (required before merge claim):

```bash
fvm flutter analyze
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden
cd packages/flutter_adaptive_cards_host_fs && fvm flutter test
cd packages/flutter_adaptive_charts_fs && fvm flutter test
cd packages/flutter_adaptive_template_fs && fvm flutter test
```

---

## File map (exported API scope)

| Package                               | Barrel                                         | Primary doc targets                                                  |
| ------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------------- |
| `flutter_adaptive_cards_fs`           | `lib/flutter_adaptive_cards_fs.dart`           | Canvas, raw card, handlers, registry, models, HostConfig             |
| extend                                | `lib/flutter_adaptive_cards_extend_fs.dart`    | Mixins, `additional.dart`, `utils.dart`, `charts_layout_config.dart` |
| `flutter_adaptive_cards_fs` (Phase 5) | `analysis_options.yaml`                        | `public_member_api_docs: error` on entire `lib/` tree                |
| `flutter_adaptive_cards_host_fs`      | `lib/flutter_adaptive_cards_host_fs.dart`      | Adapters, client, handlers, invoke models                            |
| `flutter_adaptive_charts_fs`          | `lib/flutter_adaptive_charts_fs.dart`          | `CardChartsRegistry`                                                 |
| `flutter_adaptive_template_fs`        | `lib/flutter_adaptive_template_fs.dart`        | `AdaptiveCardTemplate`                                               |
| `flutter_adaptive_cards_test_support` | `lib/flutter_adaptive_cards_test_support.dart` | Golden helpers, HTTP overrides, widget helpers                       |

---

### Task 0: Codify the documentation standard

**Files:**

- Modify: `AGENTS.md`
- Create: `.agents/skills/dart-public-api-docs/SKILL.md`
- Modify: `.agents/skills/code-review/SKILL.md`

- [x] **Step 1:** Expand `AGENTS.md` Documentation Philosophy with why/how rule and anti-narration guidance
- [x] **Step 2:** Add `dart-public-api-docs` skill (patterns, good/bad examples, review checklist)
- [x] **Step 3:** Extend `code-review` skill with public `///` checklist and cross-references

**Acceptance:** AI instructions reference the skill; code review gates exported doc quality.

---

### Task 1 (Phase 1): Blockers — FAIL, MISSING, worst package

**Priority:** `flutter_adaptive_template_fs` (was 0% compliant), all **FAIL** ratings, all **MISSING** on exported helpers.

**Files:**

- Modify: `packages/flutter_adaptive_template_fs/lib/flutter_adaptive_template_fs.dart`
- Modify: `packages/flutter_adaptive_template_fs/lib/src/template.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart` — `documentContainer`, `rebuild`, `timePickerMaterial`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/utils/utils.dart` — `UUIDGenerator`, `generateUniqueId`, `injectIds`, `FadeAnimationState`, `FullCircleClipper`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart` — `resolveBackgroundImage`, `checkRequired`; class docs for `AdaptiveActionMixin`, `AdaptiveActionStateMixin`, `AdaptiveInputMixin`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart` — class docs for four content providers
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/choice.dart`, `fact.dart`, `media_source.dart` — `*FromJsonList` / `*ToJsonList`
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/adapters/plain_json_invoke_response_parser.dart`
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/client/backend_client.dart`, `http_backend_client.dart`
- Modify: `packages/flutter_adaptive_cards_test_support/lib/flutter_adaptive_cards_test_support.dart`
- Modify: `packages/flutter_adaptive_cards_test_support/lib/src/golden_helpers.dart`, `http_overrides.dart`

- [x] **Step 1:** Rewrite `AdaptiveCardTemplate` public API (class, constructor, `expand`) and add library doc
- [x] **Step 2:** Replace FAIL docs on raw card state, UUID/id injection, mixins, backend `post`/`parse`
- [x] **Step 3:** Add MISSING class/member docs (content providers, JSON list helpers, mixins, test HTTP stubs)
- [x] **Step 4:** Run `fvm flutter analyze` on affected packages

**Executed via:** subagent (Phase 1), 2026-06-11.

---

### Task 2 (Phase 2): Host-facing entry points

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/registry.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config.dart` — class + top-level constructors/fields only

- [x] **Step 1:** Library and registry export comments — host-app purpose, when to pass registries
- [x] **Step 2:** `InheritedAdaptiveCardHandlers` and `AdaptiveCardsCanvas` — caller workflow, fix `actionTypeRegistry` mislabel
- [x] **Step 3:** `RawAdaptiveCard` / `RawAdaptiveCardState` — prefer canvas vs raw card; overlay host role
- [x] **Step 4:** `CardTypeRegistry.getElement` / `getAction`, `ElementCreator`, `addedElements`, `removedElements`
- [x] **Step 5:** `HostConfig` class, constructors, `imageBaseUrl`, `fontFamily`

**Executed via:** subagent (Phase 2), 2026-06-11.

---

### Task 3 (Phase 3): Extension surface

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart` — WEAK member docs
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/utils/utils.dart` — keys, ids, `Tuple`, `parseTextString`, fade fields
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/additional.dart`
- Modify: `packages/flutter_adaptive_charts_fs/lib/flutter_adaptive_charts_fs.dart`
- Modify: `packages/flutter_adaptive_charts_fs/lib/src/card_chart_registry.dart`
- Modify: `packages/flutter_adaptive_cards_test_support/lib/src/test_widget_helpers.dart`

- [x] **Step 1:** Mixin member docs — background helpers, input hooks, visibility
- [x] **Step 2:** Utils id/key helpers — deterministic keys, natural vs generated ids
- [x] **Step 3:** Extension widgets — `SeparatorElement`, `AdaptiveTappable`, `ChildStyler`
- [x] **Step 4:** Charts registry — merge-into-host-registry workflow
- [x] **Step 5:** Test widget helpers — when to use path vs map vs string fixtures

**Executed via:** subagent (Phase 3), 2026-06-11.

---

### Task 4 (Phase 4): Polish — remaining WEAK exported docs

**Done (2026-06-11).** Consolidated class-level docs; trimmed repetitive HostConfig section and charts layout field docs; caller-oriented host adapter and invoke model docs; improved Choice/Fact/MediaSource field docs.

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config.dart` — section fields (`imageSet`, `textStyles`, …) currently repeat JSON keys; consolidate guidance at class level and trim redundant per-field one-liners
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/charts_layout_config.dart` — DTO field docs (extend export); keep class-level PASS docs, document non-obvious defaults only on fields
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/adapters/plain_json_invoke_adapter.dart` — `toMap`, `requestFromMap`, `responseFromMap`
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/adapters/teams_invoke_adapter.dart` — `toMap`, `responseFromMap`
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/models/invoke_*.dart` — thin constructor docs (`Creates an…` → when hosts/adapters construct vs parse)
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/choice.dart`, `fact.dart`, `media_source.dart` — field docs (`title`, `toJson`, `fromJson`) where still signature-level

- [x] **Step 1:** HostConfig — add class-level “section map” paragraph; shorten repetitive field docs to non-obvious behavior only
- [x] **Step 2:** `charts_layout_config.dart` — same pattern for layout DTOs
- [x] **Step 3:** Host adapters — caller-oriented docs (when to use PlainJson vs Teams, plug-in points on `AdaptiveCardBackendHandlers`)
- [x] **Step 4:** Invoke model constructors — document parse vs manual construction
- [x] **Step 5:** Re-audit exported APIs; target ≥80% PASS on spot-check of barrel exports

**Acceptance:** Spot-check of exported members shows no remaining “Returns the…”, “Creates a…”, or algorithm narration on public APIs.

---

### Task 5 (Phase 5): Enable `public_member_api_docs` in `flutter_adaptive_cards_fs`

**Done (2026-06-11).** Promoted lint to error; added ~99 `///` summaries on `HostConfig` section fields and charts layout DTOs.

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/analysis_options.yaml`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/charts_layout_config.dart`
- Modify: `docs/Implementation-Status.md` — lint enforced + remediation complete for `cards_fs`
- Modify: `.agents/skills/dart-public-api-docs/SKILL.md` — note lint enforcement on `flutter_adaptive_cards_fs`

- [x] **Step 1:** `LineChartLayout` — constructor + fields
- [x] **Step 2:** `BarChartLayout`, `PieChartLayout`, `BarChartAlignmentToken`
- [x] **Step 3:** `*LayoutSection` types — constructors, fields, `fromJson`, `toLayout`
- [x] **Step 4:** `ChartsLayoutConfig` — constructor, subsections, `fromJson`, `defaults`, `resolve*Layout`
- [x] **Step 5:** `HostConfig` section fields (19)
- [x] **Step 6:** `public_member_api_docs: error` in `analysis_options.yaml`
- [x] **Step 7:** `fvm dart analyze lib` — zero `public_member_api_docs` findings
- [x] **Step 8:** `fvm flutter test --exclude-tags=golden` — 400 passed
- [x] **Step 9:** Update `Implementation-Status.md` and `dart-public-api-docs` skill

**Verification (2026-06-11):**

```text
cd packages/flutter_adaptive_cards_fs
fvm dart analyze lib → 0 public_member_api_docs (1 pre-existing info elsewhere)
fvm flutter test --exclude-tags=golden → 400 passed, 2 skipped
```

---

## Final Task: Full verification

- [x] **Step 1:** `fvm flutter analyze` on five touched packages (2026-06-11)
- [x] **Step 2:** Repo-root `fvm flutter analyze` (after Phase 5)
- [x] **Step 3:** `packages/flutter_adaptive_cards_fs` — `fvm flutter test --exclude-tags=golden` (400 passed, 2026-06-11)
- [x] **Step 4:** `packages/flutter_adaptive_cards_host_fs` — `fvm flutter test` (15 passed, 2026-06-11)
- [x] **Step 5:** Re-run Step 3 after Phase 5 doc-only changes (400 passed, 2026-06-11)
- [x] **Step 6:** Commit + PR (Tasks 0–5)

**Gate:** Do not claim plan complete until Phase 5 passes and Steps 2 + 5 pass (per `AGENTS.md` plan completion gate).

---

## Follow-up (after Phase 5)

- [x] Update `docs/Implementation-Status.md` — public API doc standard, remediation status, **`public_member_api_docs` enforced on `flutter_adaptive_cards_fs`**
- [ ] Optional: enable `public_member_api_docs: error` on sibling packages (`flutter_adaptive_charts_fs`, `flutter_adaptive_template_fs`, …) in separate tasks

---

## Deviations / notes

| Item                        | Plan                          | As built                                                             |
| --------------------------- | ----------------------------  | -------------------------------------------------------------------- |
| Execution                   | Sequential tasks              | Phases 1–3 run in **parallel subagents** (2026-06-11)                |
| Git                         | Per-task commits              | Merged on `main` (2026-06-11)                                        |
| Library dartdoc links       | `[TypeName]` in library docs  | Backticks in barrel files to satisfy `comment_references`            |
| Phase 3 scope               | `utils.dart` only             | Also included charts + test helpers (overlap with Phase 1 file list) |
| `charts_layout_config.dart` | Phase 3 mention               | Deferred to **Phase 4** (extend export; large field surface)         |
| Phase 4 field doc trim      | Satisfies lint                | Removed ~99 `///` lines → **Phase 5** re-adds under quality standard |
| `public_member_api_docs`    | Follow-up “consider enabling” | **Phase 5** — enforce as error on `flutter_adaptive_cards_fs` only   |
