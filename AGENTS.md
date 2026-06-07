---
trigger: always_on
---

# AI Rules for Flutter - FlutterAdaptiveCards

You are an expert Flutter and Dart developer. Your goal is to build beautiful, performant, and maintainable applications following modern best practices.

## AI Instructions Organization

The project's AI instructions are organized into two layers to keep context efficient:

1. **Root `AGENTS.md`**: Always-on project guardrails (FVM, monorepo hygiene, analysis).
2. **`.agents/skills/`**: Modular, task-specific playbooks (spec compliance, UI best practices, code review).

## Interaction Guidelines

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

- **Semantic labels:** Apply semantic labels for accessibility (for example, use `altText` from card JSON for images and icons).
- **Widget keys:** Use deterministic keys via `generateAdaptiveWidgetKey()` and `generateWidgetKey()` — see `doc/AdaptiveWidget-Key-Generation.md` and `doc/Using-Flutter-Form-Inputs.md`.

## Package Management

- **FVM:** Always prefix commands with `fvm` (e.g. `fvm flutter pub get`).
- **Dev Dependencies:** Use `fvm flutter pub add dev:<package>`.

## State management (`flutter_adaptive_cards_fs`)

`flutter_adaptive_cards_fs` uses **Riverpod** (v3.x) internally for **reactive** document + UI state, scoped per rendered card subtree (the library installs its own `ProviderScope` so host apps don't need to).
Host callbacks remain on **`InheritedAdaptiveCardHandlers`**. See [`doc/reactive-riverpod.md`](doc/reactive-riverpod.md).

When working in **`packages/flutter_adaptive_cards_fs`**:

- **Do** use `ProviderScope` + provider overrides for card-scoped registries, resolver (HostConfig only), and document state.
- **Do** keep registries and `ReferenceResolver` as **separate** scoped providers (`cardTypeRegistryProvider` / `actionTypeRegistryProvider` vs `styleReferenceResolverProvider`).
- **Do** model reactive behaviors (visibility, inputs, TextBlock text, validation, action `isEnabled`, show-card UI) with Riverpod `Notifier`s + `ref.watch` / `container.listen` on resolved providers (avoid element-tree walks and widget instance registries).
- **Do** keep host callbacks (`onSubmit`, `onExecute`, `onOpenUrl`, `onChange`, …) on `InheritedAdaptiveCardHandlers`.
- **Do not** mutate the host-provided JSON map in place for runtime state; store runtime overlays in the document notifier (`setInputValue`, `setVisibility`, `setChoices`, `setText`, `setInputError`, `setActionEnabled`, …) and read merged state via `resolvedElementProvider(id)` / `resolvedActionProvider(id)` (see [`doc/reactive-riverpod.md`](doc/reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map)).

For **sample apps and `adaptive_explorer`**, use normal Flutter state patterns (`StatefulWidget`, etc.).

## Code Quality

- **Naming:** `PascalCase` (classes), `camelCase` (members), `snake_case` (files).
- **Functions:** Short (<20 lines) and single-purpose.
- **Logging:** Use `dart:developer` `log` instead of `print`.

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
```

If the plan touched other packages, run their suites too (`flutter_adaptive_template_fs`, `flutter_adaptive_charts_fs`, etc.). See **`adaptive-cards-monorepo-workspace`** and **`adaptive-cards-testing`** skills for directory and tagging details.

## Documentation Philosophy

- **Public APIs:** ALWAYS document public classes and methods with `///`.
- **Why, not What:** Explain the rationale if it's not obvious.
- **Localization:** Use the `intl` package. All UI strings must be localized in `.arb` files.

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
> **Theming** and **Serialization (code-gen)** guidelines are in the `flutter-standard-practices` skill.
> **Layout** guidance is in the `flutter-build-responsive-layout` and `flutter-fix-layout-issues` skills.
> **Routing** guidance is in the `flutter-setup-declarative-routing` skill.
>
> **Serialization conflict:** This project uses `json_serializable` code-gen. The `flutter-implement-json-serialization`
> skill (installed from flutter/skills) teaches manual `dart:convert` — do **not** follow it for model classes in this repo.
