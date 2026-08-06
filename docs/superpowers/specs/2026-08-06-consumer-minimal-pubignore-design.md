# Consumer-minimal `.pubignore` for published packages

**Status:** Approved design  
**Date:** 2026-08-06  
**Packages:** `flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, `flutter_adaptive_template_fs`, `flutter_adaptive_cards_host_fs`

## Goal

Publish only what package consumers need on pub.dev. Shrink archives by excluding tests, goldens, local tooling, and other non-runtime files that currently ship because nothing overrides pub’s default “everything git tracks” packaging.

## Non-goals

- Fixing pana score gaps unrelated to archive contents (missing `example/` documentation points; charts/host dependency resolution until core is published at the matching version; cards dependency-section loss observed at 120/150 on 2026-08-06).
- Changing what is tracked in git — `.pubignore` affects the published archive only.
- Adding CI that fails on dry-run contents (optional follow-up; not required for this work).
- Publishing `flutter_adaptive_cards_test_support` (remains `publish_to: none`).

## Baseline (2026-08-06)

No package has a `.pubignore` today. `dart pub publish --dry-run` showed:

| Package | Compressed archive | Extra top-level vs consumer keep-set |
| --- | --- | --- |
| `flutter_adaptive_cards_fs` | 1 MB | `analyze.json`, `dart_test.yaml`, entire `test/` (~3.3 MB on disk; ~1.9 MB goldens) |
| `flutter_adaptive_charts_fs` | 275 KB | `dart_test.yaml`, entire `test/` (~408 KB; mostly goldens) |
| `flutter_adaptive_template_fs` | 94 KB | entire `test/` (~1.3 MB MS fixtures), `tool/` |
| `flutter_adaptive_cards_host_fs` | 20 KB | entire `test/` (~60 KB) |

Pana (`tool/pana/check_pana.dart --report-only`, `--no-dartdoc`, max 150):

| Package | Points | Floor |
| --- | --- | --- |
| `flutter_adaptive_cards_fs` | 120 | 140 |
| `flutter_adaptive_template_fs` | 140 | 140 |
| `flutter_adaptive_charts_fs` | 40 | 40 |
| `flutter_adaptive_cards_host_fs` | 40 | 40 |

## Decision

**Approach A — per-package `.pubignore`.** Each published package gets a small
`.pubignore` listing only the **extra** publish-time excludes beyond what git
already ignores (`test/`, `tool/`, `dart_test.yaml`, `analyze.json` as needed).

Per [Dart publishing docs](https://dart.dev/tools/pub/publishing#what-files-are-published):

- Files ignored by a `.pubignore` **or** `.gitignore` are omitted from the archive.
- If a directory contains **both** `.pubignore` and `.gitignore`, pub ignores
  **that directory’s** `.gitignore` and uses `.pubignore` instead.
- Ancestor `.gitignore` files (e.g. the monorepo root) still apply, and hidden
  paths (names starting with `.`) are never published.

So the package `.pubignore` does **not** need to duplicate the package or root
`.gitignore`. Duplicating those patterns is unnecessary maintenance; a slim
publish-only list is enough. Verify with `dart pub publish --dry-run`.

Rejected alternatives: mirroring the full `.gitignore` into `.pubignore`
(redundant here); shared copy-script template; allowlist `*` + `!` un-ignores.

## What ships (keep-set)

Every published archive must contain only:

| Path | Why |
| --- | --- |
| `lib/` | Runtime API and implementation |
| `pubspec.yaml` | Required |
| `README.md` | pub.dev / consumers |
| `CHANGELOG.md` | pub.dev / consumers |
| `LICENSE` | Required |
| `analysis_options.yaml` | Small; useful when the dependency is analyzed |

## What must not ship (exclude-set)

| Path | Packages |
| --- | --- |
| `test/` | all four |
| `tool/` | `flutter_adaptive_template_fs` |
| `dart_test.yaml` | `flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs` |
| `analyze.json` | `flutter_adaptive_cards_fs` |
| Patterns already in each package `.gitignore` (`.dart_tool/`, `/build/`, `/coverage/`, IDE junk, golden failure dirs, etc.) | all four — **do not** re-list in `.pubignore`; ancestor/repo `.gitignore` + hidden-file rules still exclude them. Package-local `.gitignore` is overruled only for **this** directory when `.pubignore` is present — covered in practice by root ignores + `test/` |

Hidden Flutter IDE files such as `.metadata` were not observed in dry-run trees; do not rely on that — if a future dry-run shows them, add them to that package’s `.pubignore`.

## Per-package `.pubignore` shape

Each file is a short publish-only list (same content is fine for all four):

```gitignore
# Publish-only excludes (consumer-minimal archive).
#
# Rules from ancestor .gitignore files (e.g. repo root) still apply.
# This file replaces only THIS directory's .gitignore for packaging.
# Hidden paths (names starting with '.') are never published.
# https://dart.dev/tools/pub/publishing#what-files-are-published
test/
tool/
dart_test.yaml
analyze.json
```

Do **not** delete or weaken `.gitignore`; git and pub remain separate concerns.
`tool/` / `dart_test.yaml` / `analyze.json` are harmless when absent from a package.

## Verification

After adding each `.pubignore`:

1. From `packages/<name>/`, run `fvm dart pub publish --dry-run` (or `dart pub publish --dry-run` under the pinned SDK).
2. Assert the printed tree’s top-level entries are only the keep-set (no `test/`, `tool/`, `dart_test.yaml`, `analyze.json`).
3. Record compressed archive size; expect a large drop for cards and charts (goldens gone), and removal of template fixtures/`tool/`.
4. From repo root: `fvm dart run tool/pana/check_pana.dart --report-only`. Expect scores unchanged or better for reasons related to archive contents. Do **not** treat this change as fixing cards’ 120 floor miss or charts/host’s 40 baseline.

## Docs and changelog

- Add a short subsection to [`docs/pub-score-pana.md`](../../pub-score-pana.md) stating that the four published packages use consumer-minimal `.pubignore`, that dry-run is the check, and linking this design (or the later plan).
- Optionally one line in the release-engineer skill: dry-run must not list `test/`.
- Each of the four package `CHANGELOG.md` files gets an `## [Unreleased]` bullet noting `.pubignore` so pub archives exclude tests and non-consumer files.

## Success criteria

- [ ] Four `.pubignore` files exist under the four published packages.
- [ ] Dry-run for each package shows only the keep-set at top level.
- [ ] Pana report-only still completes; no new score regressions attributable to `.pubignore`.
- [ ] Changelogs and `docs/pub-score-pana.md` updated.
- [ ] `flutter_adaptive_cards_test_support` and sample apps remain unpublished / untouched.

## Risks

| Risk | Mitigation |
| --- | --- |
| Forgetting package-local gitignore patterns that are not covered by the repo root or by `test/` | Dry-run after every `.pubignore` edit; keep `.pubignore` slim and rely on ancestor ignores + hidden-file rule |
| Someone later adds a package asset under `test/` or `tool/` that consumers need | Keep runtime assets under `lib/` or a declared `flutter: assets:` path outside excluded dirs |
| Maintainers assume tests ship on pub.dev | Document in `docs/pub-score-pana.md`; tests remain in git |
