---
trigger: always_on
---

# AI Rules for Flutter - FlutterAdaptiveCards

You are an expert Flutter and Dart developer. Your goal is to build beautiful, performant, and maintainable applications following modern best practices.

## AI Instructions Organization

The project's AI instructions are organized into two layers to keep context efficient:

1. **Root `AGENTS.md`**: Always-on project guardrails (FVM, monorepo hygiene, analysis).
2. **`.agents/skills/`**: Modular, task-specific playbooks (spec compliance, UI best practices, code review).

## Documentation scope

- **`docs/`** describes the four published packages under `packages/` (`flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, `flutter_adaptive_template_fs`, `flutter_adaptive_cards_host_fs`). See [`docs/documentation-scope.md`](docs/documentation-scope.md).
- **`widgetbook/`** is a **sample / demonstration** app — not package architecture. Tag widgetbook references in canonical docs as **Example (widgetbook sample)**; widgetbook-only guides use **`widgetbook` in the filename** (e.g. [`docs/widgetbook-overlay-demos.md`](docs/widgetbook-overlay-demos.md)).

- **User Persona:** Assume the user is familiar with programming concepts but may be new to Dart.
- **Explanations:** Provide explanations for Dart-specific features like null safety, futures, and streams.
- **Clarification:** If a request is ambiguous, ask for clarification.
- **Formatting:** ALWAYS use the `dart_format` tool.
- **Fixes:** Use `dart_fix` to automatically fix common errors.
- **Linting:** Use `fvm flutter analyze` to catch issues.

## Flutter Style Guide

- **SOLID Principles:** Apply throughout the codebase.
- **Monorepo Hygiene:** Executing all commands (`flutter`, `dart`) via `fvm`.
- **Composition:** Favor composition for building complex widgets.
- **Immutability:** Widgets should be immutable (`const` constructors where possible).
- **Widgets are for UI:** Keep business logic out of `build()` methods.

## Semantic Labels and Widget Keys

- **Semantic labels:** Author text is the accessible name — use `altText` from card JSON for images, icons, and media. An **absent `altText` means decorative**: pass `null` so the element is excluded from the semantics tree; never substitute a placeholder string.
- **Inputs:** Link the visible label to its control with `labelInputSemantics()` **and** wrap the visible label in `ExcludeSemantics` — both, or the name is announced twice. See the **`adaptive-cards-accessibility`** skill for the full contract (live regions, heading levels, `tester.ensureSemantics()` testing, known gaps).
- **Widget keys:** Use deterministic keys via `generateAdaptiveWidgetKey()` and `generateWidgetKey()` — see [`docs/AdaptiveWidget-Key-Generation.md`](docs/AdaptiveWidget-Key-Generation.md) and [`docs/form-inputs.md`](docs/form-inputs.md).

## Localization

Three kinds of text, only one of which is ours: **card content** (author-owned — render verbatim, never translate), **formatted values** (dates/numbers — format locale-correctly via `intl`), and **library chrome** (~10 strings we own).

- **Packages ship no `.arb` files** and must not depend on `flutter_localizations`. `intl` is a dependency for **date/number formatting only** — it is not evidence that strings are localized.
- **Do not add a new hardcoded user-visible string** to a package under `packages/` — including a `semanticsLabel:`, which is text a screen reader speaks. Library chrome is host-overridable via an injected `AdaptiveStrings` object (agreed design; **not yet implemented**).
- **Sample apps are different.** `widgetbook/` and the examples are ordinary Flutter apps — use `flutter_localizations` + `.arb` there per **`flutter-setup-localization`**.

See the **`adaptive-cards-localization`** skill for the rationale, the existing debt, and the review checklist.

## Package Management

- **FVM:** Always prefix every `flutter` and `dart` command with `fvm` (e.g. `fvm flutter pub get`, `fvm dart run …`) — the repo pins its SDK via FVM and the bare `flutter`/`dart` aliases may not point at it.
- **Bare commands in vendored skills:** The vendored `dart-*`/`flutter-*` skills under `.agents/skills/` show bare `flutter`/`dart` commands and are kept verbatim so they diff cleanly against upstream. **Do not** rewrite those files to add `fvm`; instead translate to the `fvm`-prefixed form when you actually run the command. See the `adaptive-cards-dart-flutter-fvm` skill.
- **Dev Dependencies:** Use `fvm flutter pub add dev:<package>`.
- **Changelog:** Whenever any file under a `packages/<name>/` directory changes, add a bullet to the `## [Unreleased]` section of that package's `CHANGELOG.md` before marking work complete. See `adaptive-cards-monorepo-workspace` skill for format details.

## State management (`flutter_adaptive_cards_fs`)

`flutter_adaptive_cards_fs` uses **Riverpod** (v3.x) internally for **reactive** document + UI state, scoped per rendered card subtree (the library installs its own `ProviderScope` so host apps don't need to).
Host callbacks remain on **`InheritedAdaptiveCardHandlers`**. See [`docs/reactive-riverpod.md`](docs/reactive-riverpod.md).

When working in **`packages/flutter_adaptive_cards_fs`**:

- **Do** use `ProviderScope` + provider overrides for card-scoped registries, resolver (HostConfig only), and document state.
- **Do** keep registries and `ReferenceResolver` as **separate** scoped providers (`cardTypeRegistryProvider` / `actionTypeRegistryProvider` vs `styleReferenceResolverProvider`).
- **Do** model reactive behaviors (visibility, inputs, TextBlock text, validation, action `isEnabled`, show-card UI) with Riverpod `Notifier`s + `ref.watch` / `container.listen` on resolved providers (avoid element-tree walks and widget instance registries).
- **Do** keep host callbacks (`onSubmit`, `onExecute`, `onOpenUrl`, `onChange`, …) on `InheritedAdaptiveCardHandlers`.
- **Do not** mutate the host-provided JSON map in place for runtime state; store runtime overlays in the document notifier (`setInputValue`, `setVisibility`, `setChoices`, `setText`, `setInputError`, `setActionEnabled`, …) and read merged state via `resolvedElementProvider(id)` / `resolvedActionProvider(id)` (see [`docs/reactive-riverpod.md`](docs/reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map)).

For **sample apps and `adaptive_explorer`**, use normal Flutter state patterns (`StatefulWidget`, etc.).

## Optional extension packages (charts, host, templating)

`flutter_adaptive_cards_fs` is the **lean core**. Optional capabilities live in sibling packages and are **injected at runtime** — the core must not depend on them.

| Extension | Package | How hosts opt in |
| --------- | ------- | ---------------- |
| `Chart.*` elements + chart overlays | `flutter_adaptive_charts_fs` | `CardTypeRegistry(addedElements: CardChartsRegistry.additionalChartElements, overlayExtensions: CardChartsRegistry.overlayExtensions)` |
| Templating | `flutter_adaptive_template_fs` | Expand JSON before render |
| Backend invoke | `flutter_adaptive_cards_host_fs` | Wrap card with `AdaptiveCardBackendHandlers` |

**When editing `flutter_adaptive_cards_fs`:**

- **Do not** add chart-specific types, widgets, overlay fields, or merge logic (`chartData`, `Chart.*` branches, fl_chart imports, etc.).
- **Do** use generic extension hooks (`ElementOverlayExtension`, `CardTypeRegistry.addedElements`, `CardTypeRegistry.overlayExtensions`, `patchExtensionOverlay`) so optional packages register behavior the same way chart widgets are registered.
- **Do** put chart widgets, chart overlay extensions, and chart-only tests in `flutter_adaptive_charts_fs`.

See [`docs/optional-packages-and-extensions.md`](docs/optional-packages-and-extensions.md) and **`adaptive-cards-monorepo-workspace`** / **`adaptive-cards-element-registry`** skills.

## Code Quality

- **Naming:** `PascalCase` (classes), `camelCase` (members), `snake_case` (files).
- **Functions:** Short (<20 lines) and single-purpose.
- **Logging:** Use `dart:developer` `log` instead of `print`.

## Git commit and push gate

**Never commit or push without explicit user confirmation.**

Before running any `git commit` or `git push` (including tag pushes):

1. Show the full `git diff` (or `git diff --stat` for large change sets) of everything that will be committed.
2. Summarize what the commit contains and why.
3. Wait for the user to explicitly say to proceed before running the commit or push command.

This rule applies even when the overall task description appears to authorize the full workflow (e.g. "tag and push a release"). A broad task description authorizes the *work*; each commit and push still requires a moment-of-action confirmation so the user can review before changes land in the shared repo.

## Plan completion gate

When executing an implementation plan (`docs/superpowers/plans/`) or claiming work is complete:

- **Do** run the plan's final verification section (`Final Task: Full verification` or `## Verification (full suite)`) — not only per-task or targeted tests.
- **Do** invoke **`verification-before-completion`** and paste command output (exit code, pass/fail counts) before any success claim.
- **Do not** invoke **`finishing-a-development-branch`** or report "plan complete" until the full suite passes.
- **Do not** skip the full suite because per-task tests already passed.

**Minimum verification commands** (run from affected package directories; at minimum the main library):

```bash
# Repo root
fvm flutter analyze

# Main library (required for any flutter_adaptive_cards_fs change)
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden

# Coverage gate (from repo root, after generating coverage with --coverage)
fvm dart run tool/coverage/check_coverage.dart
```

If the plan touched other packages, run their suites too (`flutter_adaptive_template_fs`, `flutter_adaptive_charts_fs`, `flutter_adaptive_cards_host_fs`, etc.). See **`adaptive-cards-monorepo-workspace`** and **`adaptive-cards-testing`** skills for directory and tagging details.

**Coverage gate:** CI enforces a per-package line-coverage floor (`tool/coverage_floors.yaml`) measured with a golden-excluded pass. Don't lower a floor to pass — add tests. See [`docs/testing-coverage.md`](docs/testing-coverage.md).

## Architecture documentation sync gate

Canonical architecture docs under `docs/` describe how the library is wired and drift silently when code changes. **Before marking work complete**, when a change does any of the following, grep `docs/` for the affected symbols and update the canonical docs in the same change:

- **Adds / removes / renames a Riverpod provider or `ProviderScope`** (including nested scopes), or changes which scope hosts a provider.
- **Changes a mixin's reactive contract** (e.g. what `AdaptiveVisibilityMixin.isVisible` / `AdaptiveInputMixin` watch or how effective state is computed).
- **Adds / removes / renames a HostConfig section**, element/action type, or overlay field, or changes an element's public contract.

Procedure:

1. `git grep -n '<old-or-new-symbol>' docs/` (also grep the human name, e.g. `CardWidthScope`, `cardWidthBucketProvider`, `targetWidth`).
2. Update the matching canonical docs — most commonly [`docs/reactive-riverpod.md`](docs/reactive-riverpod.md) (provider scopes, overlay merge, visibility), [`docs/Architecture-Overview.md`](docs/Architecture-Overview.md) (scope diagram), and [`docs/hostconfig.md`](docs/hostconfig.md) (HostConfig sections). Keep mermaid diagrams in sync.
   - **Component status (element/input/action/container/HostConfig implemented-tests-notes) now lives in the owning package's README**, not the central matrix — update the `## Implementation status` table in [`packages/flutter_adaptive_cards_fs/README.md`](packages/flutter_adaptive_cards_fs/README.md#implementation-status) (charts → [`flutter_adaptive_charts_fs`](packages/flutter_adaptive_charts_fs/README.md#implementation-status), templating → [`flutter_adaptive_template_fs`](packages/flutter_adaptive_template_fs/README.md#feature-coverage)) so it publishes to pub.dev. Each of those READMEs owns its own status **legend** and **`### Known gaps`** too. [`docs/Implementation-Status.md`](docs/Implementation-Status.md) is now an **index**; edit it only for the project-level roadmap (Priority Recommendations), history (Recently completed), or pointers.
3. A stale doc reference (e.g. a deleted class still named in `docs/`) is a blocker, not a nice-to-have. The **`adaptive-cards-code-review`** skill's "Documentation impact" check enforces this at the review gate.

## Documentation Philosophy

- **Public APIs:** ALWAYS document public classes and methods with `///`.
- **Why and how to use:** Public API comments should explain why an API exists and how callers use it. They should not reiterate the steps the code is taking.
- **Why, not What:** When behavior is non-obvious, explain rationale and caller contract — not the implementation algorithm.

For examples and a review checklist, see the **`adaptive-cards-public-api-docs`** skill.

## Analysis Options

Strictly follow `very_good_analysis`.

```yaml
include: package:very_good_analysis/analysis_options.yaml
linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
    always_use_package_imports: true
```

---
> [!NOTE]
> **Public API `///` comments** — purpose, usage, and anti-patterns are in the `adaptive-cards-public-api-docs` skill.
> **Theming** and **Serialization (code-gen)** guidelines are in the `adaptive-cards-flutter-standard-practices` skill.
> **Layout** guidance is in the `flutter-build-responsive-layout` and `flutter-fix-layout-issues` skills.
> **Routing** guidance is in the `flutter-setup-declarative-routing` skill.
>
> **Serialization conflict:** This project uses `json_serializable` code-gen. The `flutter-implement-json-serialization`
> skill (installed from flutter/skills) teaches manual `dart:convert` — do **not** follow it for model classes in this repo.
