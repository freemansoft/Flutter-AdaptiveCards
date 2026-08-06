# Consumer-minimal `.pubignore` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a consumer-minimal `.pubignore` to each of the four published packages so pub.dev archives contain only `lib/`, `pubspec.yaml`, README/CHANGELOG/LICENSE, and `analysis_options.yaml`.

**Architecture:** Approach A from the design — slim per-package `.pubignore` with publish-only excludes (`test/`, `tool/`, `dart_test.yaml`, `analyze.json`). Do not duplicate `.gitignore`; ancestor ignores and hidden-file rules still apply. Verify with `dart pub publish --dry-run` and pana report-only.

**Tech Stack:** Dart/Flutter pub packaging, `.pubignore` (gitignore syntax), existing `tool/pana/check_pana.dart`.

**Spec:** [`docs/superpowers/specs/2026-08-06-consumer-minimal-pubignore-design.md`](../specs/2026-08-06-consumer-minimal-pubignore-design.md)

## Global Constraints

- Only the four published packages under `packages/` get `.pubignore`.
- When `.pubignore` exists in a package directory, it replaces **that directory’s** `.gitignore` for packaging; ancestor `.gitignore` files still apply. Do not duplicate gitignore patterns into `.pubignore`.
- Keep-set only: `lib/`, `pubspec.yaml`, `README.md`, `CHANGELOG.md`, `LICENSE`, `analysis_options.yaml`.
- Do not change git tracking; do not touch `flutter_adaptive_cards_test_support` or sample apps.
- Changelog bullets go under each package’s current in-development heading (`## [0.17.0]`), replacing `- no changes yet` where that is the only bullet.
- Prefix flutter/dart commands with `fvm` when available; otherwise use the pinned SDK on PATH.

---

### Task 1: Add `.pubignore` to all four published packages

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/.pubignore`
- Create: `packages/flutter_adaptive_charts_fs/.pubignore`
- Create: `packages/flutter_adaptive_template_fs/.pubignore`
- Create: `packages/flutter_adaptive_cards_host_fs/.pubignore`
- Modify: each package `CHANGELOG.md` under `## [0.17.0]`
- Modify: `docs/pub-score-pana.md` (short consumer-minimal `.pubignore` subsection)
- Modify: `.claude/skills/adaptive-cards-release-engineer/SKILL.md` (one dry-run note)

**Interfaces:**
- Consumes: package `.gitignore` contents; design keep/exclude sets
- Produces: dry-run archives with keep-set only

- [x] **Step 1: Create each `.pubignore`** — slim publish-only list (no gitignore mirror):

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

(`tool/` / `dart_test.yaml` / `analyze.json` are harmless no-ops when absent.)

- [x] **Step 2: Changelog** — under `## [0.17.0]`, replace `- no changes yet` with:

```markdown
- chore: add consumer-minimal `.pubignore` so pub.dev archives exclude `test/` and other non-consumer files.
```

- [x] **Step 3: Docs** — in `docs/pub-score-pana.md`, add a section after “Current state” documenting consumer-minimal `.pubignore`, dry-run verification, and link to the design spec. In the release-engineer skill, note that dry-run must not list `test/`.

- [x] **Step 4: Verify dry-run** — for each package:

```bash
cd packages/<name> && dart pub publish --dry-run
```

Expected: top-level tree is only CHANGELOG, LICENSE, README, analysis_options.yaml, lib, pubspec.yaml. Compressed size drops (especially cards/charts).

- [x] **Step 5: Verify pana**

```bash
# from repo root
dart run tool/pana/check_pana.dart --report-only
```

Expected: no score regression attributable to `.pubignore` (cards may still be below floor for unrelated reasons; charts/host stay ~40).

- [ ] **Step 6: Commit** (only when user confirms)

```bash
git add packages/*/.pubignore packages/*/CHANGELOG.md docs/pub-score-pana.md docs/superpowers/specs/2026-08-06-consumer-minimal-pubignore-design.md docs/superpowers/plans/2026-08-06-consumer-minimal-pubignore.md .claude/skills/adaptive-cards-release-engineer/SKILL.md
git commit -m "$(cat <<'EOF'
chore: add consumer-minimal .pubignore to published packages

Keep pub.dev archives to lib + docs + analysis_options; exclude tests and local tooling.
EOF
)"
```

## Verification (full)

Same as Steps 4–5 for all four packages.
