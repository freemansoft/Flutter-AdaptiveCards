# Code Review Findings — PR #24 "docs: document public constructors for pana"

- **PR:** <https://github.com/freemansoft/Flutter-AdaptiveCards/pull/24> (`doc/add_missing_public` → `main`, open, unmerged)
- **Review date:** 2026-07-21
- **Method:** `/code-review high` — 8 independent finder angles (line-by-line, removed-behavior, cross-file tracer, reuse, simplification, efficiency, altitude, CLAUDE.md conventions), 22 candidates deduped, each survivor independently verified.
- **Baseline check:** the PR diff applied to a scratch clone passes `fvm flutter analyze` clean repo-wide (root, both packages, widgetbook). No correctness bugs found; all findings are API-design, changelog, and doc-quality issues.

## Status

PR #24 has since **merged**, so the remediation below lands on `main`, not on the PR branch.

| Finding                                                  | Status    | Where                                                                  |
| -------------------------------------------------------- | --------- | ---------------------------------------------------------------------- |
| 1. State classes documented instead of privatized        | **FIXED** | `fix/pr24-review-findings-2-3`                                         |
| 2. `const` constructor misfiled in changelog             | **FIXED** | `18c96e7` on `fix/pr24-review-findings-2-3`                            |
| 3. `FullCircleClipper()` left non-const                  | **FIXED** | `18c96e7` on `fix/pr24-review-findings-2-3`                            |
| 4. `AdaptiveUriValidationResult` ctor doc                | OPEN      | PLAUSIBLE, not actioned                                                |
| 5. `FullCircleClipper` ctor doc duplicates `getClip` doc | OPEN      | PLAUSIBLE; the const fix touched this line but left the doc text alone |

## Findings (most severe first)

### 1. FIXED — Two State classes documented "do not construct" instead of made non-public

**File:** `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart:264` (also `lib/src/utils/utils.dart` `FadeAnimationState`)
**Category:** api-design

`AdaptiveCardsCanvasState` and `FadeAnimationState` get documented public constructors saying "hosts should not construct this directly" / "not intended for direct host use", but neither class needs to be public at all:

- `git grep` finds **zero references** to either class outside its own file (including widgetbook, examples, tests).
- They leak into the public API only because `flutter_adaptive_cards_fs.dart` exports `adaptive_cards_canvas.dart` with no `show` clause, and `flutter_adaptive_cards_extend_fs.dart` re-exports `utils/utils.dart` wholesale. The very next export line in the barrel _does_ narrow deliberately (`show RawAdaptiveCard, RawAdaptiveCardState`), so the pattern is established in-repo.
- 0.15.0 is unreleased (pub.dev has 0.14.0), so privatizing (`_AdaptiveCardsCanvasState`) or narrowing the export is a **free** breaking change today. After publishing, removal requires a breaking-change bump.
- `AdaptiveCardsCanvasState` also exposes public mutable fields (`map`, `initData`, `onChange`); the doc comment is advisory only — a private class makes misuse structurally impossible.

By contrast, `RawAdaptiveCardState` **is** genuinely public API (`GlobalKey<RawAdaptiveCardState>` access across host_fs, charts_fs, widgetbook, and tests) — documenting it was the correct fix. `AdaptiveTappableState` has one test consumer (`test/select_action_tappable_key_test.dart` via `tester.state<AdaptiveTappableState>`), which could type against `State<AdaptiveTappable>` instead if privatization is ever wanted there too.

**Suggested fix:** privatize the two zero-reference State classes (or add `show`/`hide` to the barrel exports) instead of documenting them; keep the doc-comment approach for `RawAdaptiveCardState`.

**Resolution:** took the privatize option rather than narrowing the barrel exports — it is the stronger of the two, since a private class also removes reach to `AdaptiveCardsCanvasState`'s mutable `map` / `initData` / `onChange` fields, which a `show` clause would leave reachable through any other path. `AdaptiveCardsCanvasState` → `_AdaptiveCardsCanvasState`, `FadeAnimationState` → `_FadeAnimationState`, with both `createState()` signatures widened to `State<T>` (a private return type on a public method is not expressible). The explicit constructors PR #24 added are deleted, not privatized: pana only inspects public API, so the implicit default constructor is enough, and the "hosts should not construct this directly" doc lines would have contradicted the new private class.

Three follow-on edits the finding did not call out:

- `docs/action-payloads-reference.md:13` named `AdaptiveCardsCanvasState` in host-facing prose; the name is dropped (the surrounding claim — that action callbacks go through `InheritedAdaptiveCardHandlers`, not the canvas — is unchanged and still correct). Other `docs/` hits are frozen plan/review artifacts and historical changelog entries, correctly left alone.
- The 0.15.0 `### Fixed` pana bullet listed both classes among those that gained `///` docs. That is no longer true for the release being cut, so both names are removed from it.
- Added a `### Removed 0.15.0` section marking this **BREAKING (internal-only)**. Pre-1.0, the 0.14.0 → 0.15.0 minor bump legitimately carries it; no extra version bump is needed, but it must not ship silently.

**Verified:** `fvm flutter analyze` → `No issues found!` across the workspace, which includes widgetbook and adaptive_explorer and so proves no consumer referenced either class. Tests: cards 814 non-golden + 31 golden, charts 30, host 37, template 103 — all pass.

### 2. FIXED — New `const` API constructor misfiled in changelog as docs-only "Fixed"

**File:** `packages/flutter_adaptive_cards_fs/CHANGELOG.md:13`
**Category:** conventions (AGENTS.md changelog rule / Keep a Changelog)

The Unreleased bullet reads `docs: add missing /// on public default constructors reported by pana (…ElementOverlayExtension…)` under `### Fixed`. But pre-PR, `ElementOverlayExtension` had **no explicit constructor at all** — the PR adds a brand-new `const ElementOverlayExtension();`, an API capability change that enables const subclasses. It is the reason the charts package changed in the same PR, and the charts changelog correctly records that consequence under `### Changed` ("…now that `ElementOverlayExtension` has a documented `const` constructor"). The two changelogs contradict each other about the same change.

**Suggested fix:** split the `ElementOverlayExtension` const-constructor addition into its own bullet under `### Changed` (or `### Added`) in the cards changelog; keep the docs-only items under a docs bullet.

**Resolution (`18c96e7`):** the `ElementOverlayExtension` const constructor is now its own bullet under `### Added 0.15.0`, filed as the API capability change it is; the docs-only pana items stay under `### Fixed 0.15.0`. Both changelogs now agree. While here, both packages' `## [Unreleased]` sections were folded into their `## [0.15.0]` sections — 0.15.0 is the in-progress unpublished release, so the split was redundant.

### 3. FIXED — `FullCircleClipper()` left non-const though `const` was achievable

**File:** `packages/flutter_adaptive_cards_fs/lib/src/utils/utils.dart:119`
**Category:** efficiency / consistency

The PR adds a **non-const** `FullCircleClipper();` to a fieldless `CustomClipper<Rect>` subclass. Verified against the FVM Flutter 3.44.0 SDK: `const CustomClipper({Listenable? reclip})` — so `const FullCircleClipper()` compiles cleanly. The same PR const-ifies the structurally analogous `ElementOverlayExtension`, so this is inconsistent with the PR's own direction. Cost: every rebuild of a `style: person` image (`lib/src/cards/elements/image.dart:111`, `ClipOval(clipper: FullCircleClipper(), child: image)`) heap-allocates a fresh clipper instead of reusing a canonical const instance.

**Suggested fix:** `const FullCircleClipper();` and `const FullCircleClipper()` at the image.dart call site.

**Resolution (`18c96e7`):** both applied. One consequence the review did not anticipate: making the constructor `const` caused `prefer_const_constructors` to fire on two **test** call sites (`test/utils/utils_test.dart:37,42`), taking `fvm flutter analyze` to 2 issues. Both are now `const`, which is safe because `shouldReclip` ignores its argument and unconditionally returns `false`, so the two sites collapsing to one canonical instance does not weaken the assertion. Verified: `fvm flutter analyze` → `No issues found!`; 814 non-golden + 31 golden tests pass.

### 4. PLAUSIBLE — `AdaptiveUriValidationResult` constructor doc restates structure, omits caller contract

**File:** `packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_validation.dart:8`
**Category:** conventions (AGENTS.md: "Public API comments should explain why an API exists and how callers use it. They should not reiterate the steps the code is taking.")

"Shared constructor for allowed/denied validation outcomes." restates what the `sealed class` declaration already shows. The PR's six other constructor docs all state a caller contract ("hosts should not construct this directly", "obtain via [GlobalKey]…"), making this an outlier. A contract-stating one-liner was available, e.g. "Not called directly; the sealed subtypes invoke this via `super()`."

### 5. PLAUSIBLE — `FullCircleClipper` constructor doc duplicates the `getClip` doc

**File:** `packages/flutter_adaptive_cards_fs/lib/src/utils/utils.dart:118`
**Category:** conventions (same AGENTS.md rule)

"Creates a clipper that fills the child's layout bounds." duplicates the `getClip()` doc two lines below ("Returns full-bounds clip rect for the child") nearly word-for-word. Fixing finding 3 is the natural moment to rewrite this doc with the constructor's actual contract (stateless; safe to construct per-build or const).

**Still open.** Finding 3's fix (`18c96e7`) edited this exact line but deliberately left the doc text unchanged, to keep that commit scoped to the two findings requested.

## Notable refuted candidates (checked and dismissed)

- **`static final` → `static const` on `CardChartsRegistry.overlayExtensions` breaks in-place list mutation** — REFUTED. The Dart semantics are real (the backing list becomes unmodifiable), but `CardOverlayExtensionRegistry` is `@immutable` with a first-class `merge()` composition API, its constructor already defaulted to a const empty list, and the docs direct consumers to pass the registry whole. In-place mutation was never a supported pattern; no in-repo code does it.
- **charts↔cards publish-ordering risk (`^0.15.0` with no version bump)** — REFUTED. The release runbook (`.agents/skills/adaptive-cards-release-engineer/SKILL.md`) mandates identical versions, tagging one commit, publishing charts _after_ cards from that same tag, and a joint post-release bump — the split-publish scenario is contrary to documented process. (Human-followed, not CI-enforced, but directly addresses the risk.)
- **`AdaptiveCardContentProvider()` should also be const** — REFUTED. All subclasses use `implements` (not `extends`) with mutable fields, so a const super-constructor benefits nobody; pure style.
- **"Explicit constructors are unnecessary boilerplate / 11 sibling State classes untouched"** — REFUTED. The lint/pana surface only covers barrel-exported classes; the 11 siblings live in unexported `lib/src/cards/**`. Post-PR, every class in the two barrel files has a documented explicit constructor — coverage of the actual pana-checked surface is complete.
- **"`FullCircleClipper` misnamed / doc wrong about circle vs rectangle"** — REFUTED. `ClipOval` derives the circular clip from the returned bounding `Rect`; the docs are factually accurate.

## Verification notes

- Server-side semantics of the PR verified by applying the diff to a scratch clone: `fvm flutter pub get` + `fvm flutter analyze` → `No issues found!` across root, both packages, and widgetbook.
- No `identical()` / reference-equality dependencies on `ChartElementOverlayExtension.instance` anywhere in the repo; const-ification only widens identity guarantees.
- Both packages' `pubspec.yaml` remain at unreleased 0.15.0; pub.dev latest is 0.14.0 for each.
