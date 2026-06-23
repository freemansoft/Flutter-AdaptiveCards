# Test Coverage Gate + Worst-Offender Tests — Design

- **Date:** 2026-06-22
- **Status:** Draft (awaiting review)
- **Scope:** Tooling, CI, tests, docs, and project-authored skills. **No `lib/` behavior changes.**

## Problem

The repo has **no coverage measurement at all**:

- `.github/workflows/test.yml` runs `flutter test` per package with **no `--coverage`, no threshold, and no upload**.
- The only coverage artifact found — `packages/flutter_adaptive_cards_fs/coverage/lcov.info` — is **gitignored, untracked, and stale** (dated 2026-05-31, generated from a partial run reporting a misleading 77.2%). It is a developer's local leftover, not a repo signal.

Because nothing measures coverage, it drifts silently and regressions land unnoticed.

### Measured baseline (full suite, golden tests excluded, local)

| Package                               | Line coverage | Lines hit/total                  |
| ------------------------------------- | ------------- | -------------------------------- |
| `flutter_adaptive_template_fs`        | 95.5%         | 484/507                          |
| `flutter_adaptive_cards_fs` (core)    | 86.8%         | 4825/5556                        |
| `flutter_adaptive_cards_host_fs`      | 72.2%         | 197/273                          |
| `flutter_adaptive_charts_fs`          | 71.6%         | 485/677                          |
| `flutter_adaptive_cards_test_support` | n/a           | test helper, no tests (expected) |

> These numbers exclude golden tests (`--exclude-tags=golden`). The gate uses a **dedicated golden-excluded coverage pass in CI** running the same command, so the CI number matches these local numbers exactly — no CI/local drift (see A4).

### Biggest gaps

- **Entirely untested files (~0%):** `charts_fs/src/charts/pie_donut_chart.dart` (67 lines), `cards_fs/src/cards/actions/insert_image.dart` (10 lines).
- **High-value reactive core under-tested:** `riverpod/adaptive_card_document_notifier.dart` (81%, 72 missed), `reference_resolver.dart` (80%, 66 missed), `flutter_raw_adaptive_card.dart` (65%, 83 missed).
- **Backend host weak:** `handlers/backend_handlers.dart` (37%), `adapters/teams_invoke_adapter.dart` (57%).
- **Charts rendering branches:** `bar_chart.dart` (60%), `chart_element_overlay_extension.dart` (61%).

## Goals

1. Make coverage **measured and enforced** in CI so it stops drifting.
2. Use a **ratchet-from-baseline** gate: floors start at today's CI numbers and only catch regressions; never blocks merging on day one.
3. Close the **worst offenders** with targeted tests (highest value per test), lifting the baseline.
4. Document the gate in **project-authored** skills and docs.

### Non-goals

- No global "everything to 85%" push. Other gaps are left to the ratchet over time.
- No external coverage service (Codecov/Coveralls) — kept self-contained, no secrets.
- No `lib/` source changes.
- Not touching vendored skills (any `dart-*`, `flutter-*`, or superpowers skill).

## Decisions (from brainstorming)

| Decision                               | Choice                                                                                                                                                                                     |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Threshold model                        | **Ratchet from baseline** (per-package floor; raise as tests land)                                                                                                                         |
| Reporting/enforcement                  | **Self-contained lcov check** (script in CI, no third-party service)                                                                                                                       |
| Gap-test ambition                      | **Worst offenders only**                                                                                                                                                                   |
| Check script language                  | **Dart** (`dart run`), robust + itself testable. (Repo's one existing `tool/` script is bash; Dart chosen for the parser.)                                                                 |
| `flutter_raw_adaptive_card.dart` (65%) | **Out of scope for now** — flagged. Needs a check of whether it is a still-supported public entry path or legacy before investing test effort. Decide during implementation; do not guess. |

## Part A — Self-contained ratchet gate

### A1. Floors config — `tool/coverage_floors.yaml` (tracked)

Per-package minimum line percentage:

```yaml
# Per-package minimum line coverage %. Ratchet floors — raise as tests land.
# Values below are PLACEHOLDERS; replace with CI-measured numbers (rounded down
# to whole percents) after the report-only run in step 1.
flutter_adaptive_cards_fs: 85
flutter_adaptive_template_fs: 95
flutter_adaptive_cards_host_fs: 71
flutter_adaptive_charts_fs: 71
```

`flutter_adaptive_cards_test_support` is omitted (test helper, no own tests).

### A2. Check script — `tool/coverage/check_coverage.dart`

- Reads `tool/coverage_floors.yaml`.
- For each listed package, parses `packages/<name>/coverage/lcov.info`, sums `LF`/`LH`, computes line %.
- Prints a table (package, %, hit/total, floor, pass/fail).
- Exits **non-zero** if any package is missing its lcov or is below its floor; exits 0 otherwise.
- No external deps beyond what's already available (`package:yaml`); pure file parsing.
- Has its own unit test (`tool/coverage/check_coverage_test.dart` or under the workspace test runner) feeding sample lcov fixtures — verifies pass, fail-below-floor, and missing-file cases.

### A3. CI wiring — `.github/workflows/test.yml`

- **Keep the existing per-package test steps as-is** (full suite _with_ golden) — they remain responsible for golden render validation.
- **Add a dedicated coverage pass per gated package**, after the golden passes, running `flutter test --coverage --exclude-tags=golden`. These passes own the coverage number.
- Add a final **"Coverage gate"** step that runs `dart run tool/coverage/check_coverage.dart` from the repo root, reading every package's freshly written `coverage/lcov.info`.
- Bump the job `timeout-minutes` (5 → 15) to absorb the second pass.

### A4. Two design points

- **Coverage is golden-excluded ⇒ CI equals local, deterministically.** The dedicated coverage passes run `--exclude-tags=golden`, the identical command a developer runs locally (`fvm flutter test --coverage --exclude-tags=golden`). The measured number is therefore the same locally and in CI — there is no platform/golden variance to buffer against, so floors are **authoritative, not provisional**. (Floors are still rounded down ~1 point as a margin.) The gate ships in **report-only** mode first only to validate the CI plumbing (paths resolve, `dart run` works), then flips to enforcing.
- **Ratchet, not target.** Floors equal baseline. The gate only catches _regressions_; raising a floor is a deliberate commit after tests land.

## Part B — Worst-offender tests

Tests live beside existing ones and follow the `adaptive-cards-testing` patterns.

| Target                                                       | Now             | Test                                                                                                                                                   |
| ------------------------------------------------------------ | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `charts_fs/src/charts/pie_donut_chart.dart`                  | 0%              | Widget/painter test rendering Donut + Pie `Chart.*` cards (mirror existing `charts/` tests) — under `packages/flutter_adaptive_charts_fs/test/charts/` |
| `cards_fs/src/cards/actions/insert_image.dart`               | 0%              | Action test under `packages/flutter_adaptive_cards_fs/test/actions/` exercising the InsertImage path                                                   |
| `host_fs/src/handlers/backend_handlers.dart`                 | 37%             | Expand `packages/flutter_adaptive_cards_host_fs/test/handlers/` — Submit/Execute/Refresh/onChange round-trips + error / no-handler branches            |
| `cards_fs/src/riverpod/adaptive_card_document_notifier.dart` | 81% (72 missed) | Cover uncovered overlay mutations & edge cases (`setInputError`, `setChoices`, `setActionEnabled`, reset paths)                                        |
| `cards_fs/src/reference_resolver.dart`                       | 80% (66 missed) | Cover unresolved-reference / fallback-config branches                                                                                                  |

Each new/expanded test must actually exercise the previously-uncovered lines (verify by re-measuring `--coverage` for that package, not just by passing).

## Part C — Skills & docs

**Project-authored skills only. Do NOT modify any `dart-*`, `flutter-*`, or superpowers skill.**

- **`adaptive-cards-testing` skill (primary home):** add a "Coverage" section — how to run `fvm flutter test --coverage`, where floors live (`tool/coverage_floors.yaml`), how the ratchet gate works, and how to update a floor after adding tests.
- **`code-review` skill:** add a coverage-gate line to its testing/quality-gate checklist (e.g. "new untested files lower a package toward its floor; the CI coverage gate must stay green").
- **`docs/testing-coverage.md` (new):** canonical doc — gate mechanism, the floors file, the report-only → enforce rollout, and the floor-update procedure. Cross-link from `AGENTS.md`.
- **`AGENTS.md`:** brief pointer in the verification/testing area to the new coverage gate and doc.

## Housekeeping

- Adding test files touches `packages/<name>/`, so each affected package (`flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, `flutter_adaptive_cards_host_fs`) gets an `## [Unreleased]` CHANGELOG bullet.
- No `lib/` changes ⇒ no public-API doc or architecture-doc sync needed beyond the new testing doc.

## Verification

1. Per affected package: `fvm flutter test --coverage` (from the package dir).
2. From repo root: `dart run tool/coverage/check_coverage.dart` — prints the table and passes.
3. `fvm flutter analyze` clean at repo root.
4. The check script's own unit test passes.
5. CI: confirm the "Coverage gate" step runs and is green on the PR.

## Rollout order

1. Add floors config + check script + CI golden-excluded coverage passes + gate step (report-only). Floors are the golden-excluded baseline (authoritative, since CI == local).
2. After one green CI run confirms the plumbing, drop `--report-only` to make the gate enforcing.
3. Add worst-offender tests (Part B); raise the affected floors.
4. Update `adaptive-cards-testing` + `code-review` skills, add `docs/testing-coverage.md`, point from `AGENTS.md` (Part C).

## Open question to resolve during implementation

- `flutter_raw_adaptive_card.dart`: is it a supported public entry path (worth tests) or legacy (leave to ratchet)? Inspect usage/exports before deciding.
