# AI Rules for Flutter - FlutterAdaptiveCards

Explain Dart-specific features (null safety, futures, streams) when they come up — assume programming fluency, not Dart fluency.

## Language preference for new projects

This repository is **all Dart and Flutter** for executable programs, examples, and libraries. Before scaffolding a **new** project, script, or tool in a non-Dart language, ask the user to confirm. Default recommendation: Dart (CLI/server) or Dart + Flutter (UI). Existing non-Dart projects stay as they are unless the user asks otherwise.

## AI Instructions Organization

1. **Root `CLAUDE.md`** — this file. Always-on guardrails; Claude Code loads it every session.
2. **`.claude/skills/`** — project-authored playbooks, loaded when a task matches.
3. **Claude Code plugins** — the Dart and Flutter team skills come from the `dart-flutter` plugin ([`flutter/agent-plugins`](https://github.com/flutter/agent-plugins)), enabled at project scope in `.claude/settings.json`. They are not in this repo.

**Claude Code is the only supported agent.** Do not add per-agent config directories, mirror `.claude/skills/` elsewhere, or re-vendor the plugin's skills.

## Documentation scope

- **`docs/`** describes the four published packages under `packages/` (`flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, `flutter_adaptive_template_fs`, `flutter_adaptive_cards_host_fs`). See [`docs/documentation-scope.md`](docs/documentation-scope.md).
- **`widgetbook/`** is a **sample app**, not package architecture. Tag widgetbook references in canonical docs as **Example (widgetbook sample)**; widgetbook-only guides use **`widgetbook` in the filename** (e.g. [`docs/widgetbook-overlay-demos.md`](docs/widgetbook-overlay-demos.md)).

## Flutter Style Guide

- **SOLID principles** throughout.
- **Composition** over inheritance for complex widgets.
- **Immutability** — `const` constructors where possible.
- **Widgets are for UI** — keep business logic out of `build()`.

## Semantic Labels and Widget Keys

- **Semantic labels:** author text is the accessible name — use `altText` from card JSON for images, icons, and media. An **absent `altText` means decorative**: pass `null` so the element is excluded from the semantics tree; never substitute a placeholder.
- **Inputs:** link the visible label to its control with `labelInputSemantics()` **and** wrap the visible label in `ExcludeSemantics` — both, or the name is announced twice.
- **Widget keys:** use `generateAdaptiveWidgetKey()` and `generateWidgetKey()` — see [`docs/AdaptiveWidget-Key-Generation.md`](docs/AdaptiveWidget-Key-Generation.md) and [`docs/form-inputs.md`](docs/form-inputs.md).

Full contract (live regions, heading levels, `tester.ensureSemantics()` testing, known gaps): **`adaptive-cards-accessibility`** skill.

## Localization

Three kinds of text, only one of which is ours: **card content** (author-owned — render verbatim, never translate), **formatted values** (dates/numbers — format locale-correctly via `intl`), and **library chrome** (~10 strings we own).

- **Packages ship no `.arb` files** and must not depend on `flutter_localizations`. An `intl` dependency is for formatting only — not evidence that strings are localized.
- **Do not add a new hardcoded user-visible string** to a package under `packages/` — including a `semanticsLabel:`, which a screen reader speaks. Library chrome is host-overridable via an injected `AdaptiveStrings` object (agreed design; **not yet implemented**).
- **Sample apps are different.** `widgetbook/` and the examples are ordinary Flutter apps — use `flutter_localizations` + `.arb` there, per **`flutter-setup-localization`**.

Rationale, existing debt, and review checklist: **`adaptive-cards-localization`** skill.

## Package Management

- **FVM:** prefix every `flutter` and `dart` command with `fvm` (`fvm flutter pub get`, `fvm dart run …`) — the repo pins its SDK via FVM and the bare aliases may not point at it. This covers formatting (`fvm dart format`), fixes (`fvm dart fix --apply`), and analysis (`fvm flutter analyze`).
- **Bare commands elsewhere:** the `dart-flutter` plugin's skills and its `dart-mcp-server` MCP entry invoke bare `flutter`/`dart`. They live in the plugin cache, so there is nothing here to patch — translate at the moment you run the command. See **`adaptive-cards-dart-flutter-fvm`**.
- **Dev dependencies:** `fvm flutter pub add dev:<package>`.
- **Changelog:** any file changed under `packages/<name>/` needs a bullet in that package's `## [Unreleased]` section before the work is complete. Format details: **`adaptive-cards-monorepo-workspace`**.

## State management (`flutter_adaptive_cards_fs`)

The library uses **Riverpod** (v3.x) internally for reactive document + UI state, scoped per rendered card subtree — it installs its own `ProviderScope`, so host apps don't need one. See [`docs/reactive-riverpod.md`](docs/reactive-riverpod.md).

When working in **`packages/flutter_adaptive_cards_fs`**:

- **Do** use `ProviderScope` + overrides for card-scoped registries, resolver (HostConfig only), and document state.
- **Do** keep registries and `ReferenceResolver` as **separate** scoped providers (`cardTypeRegistryProvider` / `actionTypeRegistryProvider` vs `styleReferenceResolverProvider`).
- **Do** model reactive behaviors (visibility, inputs, TextBlock text, validation, action `isEnabled`, show-card UI) with `Notifier`s + `ref.watch` / `container.listen` on resolved providers — not element-tree walks or widget instance registries.
- **Do** keep host callbacks (`onSubmit`, `onExecute`, `onOpenUrl`, `onChange`, …) on **`InheritedAdaptiveCardHandlers`**, which is a public-API boundary rather than a Riverpod detail.
- **Do not** mutate the host-provided JSON map in place for runtime state. Store overlays in the document notifier (`setInputValue`, `setVisibility`, `setChoices`, `setText`, `setInputError`, `setActionEnabled`, …) and read merged state via `resolvedElementProvider(id)` / `resolvedActionProvider(id)` ([details](docs/reactive-riverpod.md#how-overlays-change-values-initialized-from-the-adaptive-map)).

Sample apps and `adaptive_explorer` use normal Flutter state patterns (`StatefulWidget`, etc.).

## Optional extension packages (charts, host, templating)

`flutter_adaptive_cards_fs` is the **lean core**. Optional capabilities live in sibling packages and are **injected at runtime** — the core must not depend on them.

| Extension                           | Package                          | How hosts opt in                                                                                                                       |
| ----------------------------------- | -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `Chart.*` elements + chart overlays | `flutter_adaptive_charts_fs`     | `CardTypeRegistry(addedElements: CardChartsRegistry.additionalChartElements, overlayExtensions: CardChartsRegistry.overlayExtensions)` |
| Templating                          | `flutter_adaptive_template_fs`   | Expand JSON before render                                                                                                              |
| Backend invoke                      | `flutter_adaptive_cards_host_fs` | Wrap card with `AdaptiveCardBackendHandlers`                                                                                           |

**When editing `flutter_adaptive_cards_fs`:**

- **Do not** add chart-specific types, widgets, overlay fields, or merge logic (`chartData`, `Chart.*` branches, fl_chart imports).
- **Do** use the generic extension hooks (`ElementOverlayExtension`, `CardTypeRegistry.addedElements`, `CardTypeRegistry.overlayExtensions`, `patchExtensionOverlay`) so optional packages register behavior the way chart widgets do.
- **Do** put chart widgets, chart overlay extensions, and chart-only tests in `flutter_adaptive_charts_fs`.

See [`docs/optional-packages-and-extensions.md`](docs/optional-packages-and-extensions.md) and the **`adaptive-cards-monorepo-workspace`** / **`adaptive-cards-element-registry`** skills.

## Code Quality

- **Naming:** `PascalCase` (classes), `camelCase` (members), `snake_case` (files).
- **Functions:** short (<20 lines) and single-purpose.
- **Logging:** `dart:developer` `log`, never `print`.
- **Serialization:** models are **hand-written** — `factory X.fromJson(Map<String, dynamic>)` + manual `toJson()`. No `json_serializable`/`json_annotation`, no `@JsonSerializable`, no `.g.dart`. The plugin's `flutter-implement-json-serialization` skill is directionally right, but follow this repo's conventions (Adaptive Cards camelCase keys, null-safe defaults, immutable value types) per **`adaptive-cards-flutter-standard-practices`** — which also covers theming elements from HostConfig rather than `ThemeData`. Element theming detail: **`adaptive-cards-hostconfig-theme`**.

## Git commit and push gate

**Never commit or push without explicit user confirmation.** Before any `git commit` or `git push` (including tag pushes):

1. Show the `git diff` (or `git diff --stat` for large change sets) of everything that will be committed.
2. Summarize what the commit contains and why.
3. Wait for the user to say to proceed.

This holds even when the task description appears to authorize the full workflow (e.g. "tag and push a release"). A broad task authorizes the _work_; each commit and push still needs a moment-of-action confirmation.

**Standing exception — subagent-driven plan execution.** When an approved plan (`docs/superpowers/plans/`) is executed via subagents (`superpowers:subagent-driven-development` or similar), each subagent may commit its completed, verified task to the current feature branch without per-commit confirmation. This covers `git commit` to the feature branch only — not `git push`, merging, force-push, or anything touching `main`.

## Local tooling permissions

`curl` and other local/loopback calls — including a local Ollama instance (`http://127.0.0.1:11434`) — do not need permission first. Remote and third-party services still do.

## Plan completion gate

When executing an implementation plan (`docs/superpowers/plans/`) or claiming work is complete:

- **Do** run the plan's final verification section (`Final Task: Full verification` or `## Verification (full suite)`) — not only per-task or targeted tests.
- **Do** invoke **`superpowers:verification-before-completion`** and paste command output (exit code, pass/fail counts) before any success claim.
- **Do not** invoke **`superpowers:finishing-a-development-branch`** or report "plan complete" until the full suite passes.

**Minimum verification** (from affected package directories; at minimum the main library):

```bash
fvm flutter analyze                                   # repo root
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden
fvm dart run tool/coverage/check_coverage.dart        # repo root, after a --coverage run
```

If the plan touched other packages, run their suites too. Directory and tagging details: **`adaptive-cards-monorepo-workspace`** and **`adaptive-cards-testing`**.

**Format gates.** CI enforces Dart and Markdown formatting separately from lint, so a build can pass `analyze` and the tests and still fail. Run the checks matching what you touched, before committing:

```bash
npm run check:md        # docs/**, packages/**, root *.md
npm run check:md:chat   # adaptive_chat_client/**, adaptive_chat_server_dart/**

fvm dart format --output=none --set-exit-if-changed packages/ tool/
fvm dart format --output=none --set-exit-if-changed adaptive_chat_client/ adaptive_chat_server_dart/
```

Both are mechanically fixable — drop the flags for Dart, or run `npm run format:md` / `format:md:chat`. Two traps:

- **The two Markdown scripts do not overlap.** A change under `adaptive_chat_*` is invisible to `check:md`, which is the one most people run.
- **Prettier rewrites `*italic*` to `_italic_`** and normalizes list markers and table padding, so hand-written Markdown usually needs one `format:md` pass.

**Coverage gate:** CI enforces a per-package line-coverage floor (`tool/coverage_floors.yaml`) measured with a golden-excluded pass. Don't lower a floor to pass — add tests. See [`docs/testing-coverage.md`](docs/testing-coverage.md).

## Architecture documentation sync gate

Canonical docs under `docs/` describe how the library is wired and drift silently when code changes. Before marking work complete, if a change does any of the following, grep `docs/` for the affected symbols and update the docs in the same change:

- **Adds / removes / renames a Riverpod provider or `ProviderScope`** (including nested scopes), or changes which scope hosts one.
- **Changes a mixin's reactive contract** (what `AdaptiveVisibilityMixin.isVisible` / `AdaptiveInputMixin` watch, or how effective state is computed).
- **Adds / removes / renames a HostConfig section**, element/action type, or overlay field, or changes an element's public contract.

Procedure:

1. `git grep -n '<old-or-new-symbol>' docs/` — also grep the human name (`CardWidthScope`, `cardWidthBucketProvider`, `targetWidth`).
2. Update the matching docs, most often [`reactive-riverpod.md`](docs/reactive-riverpod.md) (scopes, overlay merge, visibility), [`Architecture-Overview.md`](docs/Architecture-Overview.md) (scope diagram), and [`hostconfig.md`](docs/hostconfig.md). Keep mermaid diagrams in sync.
3. **Component status lives in the owning package's README**, not a central matrix — update the `## Implementation status` table in [`flutter_adaptive_cards_fs`](packages/flutter_adaptive_cards_fs/README.md#implementation-status) (charts → [`flutter_adaptive_charts_fs`](packages/flutter_adaptive_charts_fs/README.md#implementation-status), templating → [`flutter_adaptive_template_fs`](packages/flutter_adaptive_template_fs/README.md#feature-coverage)) so it publishes to pub.dev. Each README owns its own legend and `### Known gaps`. [`docs/Implementation-Status.md`](docs/Implementation-Status.md) is an **index** — edit it only for the roadmap, history, or pointers.

A stale doc reference (a deleted class still named in `docs/`) is a blocker, not a nice-to-have. The **`adaptive-cards-code-review`** skill enforces this at the review gate.

## Documentation Philosophy

- **Public APIs:** document public classes and methods with `///`.
- **Why and how to use:** explain why an API exists and how callers use it — not the steps the code takes.
- **Why, not What:** when behavior is non-obvious, give rationale and caller contract, not the algorithm.

Examples, anti-patterns, and a review checklist: **`adaptive-cards-public-api-docs`**.

## Documentation tone

Write findings and prose documentation in a flat analytical register — **sound like an analyst, not a publicist**. Applies to `docs/`, package READMEs, every `CHANGELOG.md`, and the measurement notebooks (`adaptive_chat_server_dart/ModelBehavior.md`). Amplified prose blurs the line between what was measured and what was inferred, which is the opposite of what these documents are for.

- **State results plainly** — no amplifying adverbs, no "without exception", no collapse-or-triumph verbs.
- **Replace vague superlatives with the figure they stand for.**
- **Reserve bold for a section's load-bearing claim and for figures** — never for adverbs, never to mark which table rows matter.
- **Hedge inferred mechanisms.** Counts are measured; the explanation for them usually is not.
- **Write headings as findings, not verdicts.**
- **End on the last factual sentence.**

Wording only: never change a figure, date, or claim while adjusting register — verify by diffing a document's numeric tokens against the previous commit. Strip amplification, not substance: a claim the data supports is not hype, and structural bold on topic sentences is what makes a long file scannable.

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

> [!NOTE] > **Layout** guidance is in the `flutter-build-responsive-layout` and `flutter-fix-layout-issues` skills; **routing** in `flutter-setup-declarative-routing`. Both come from the `dart-flutter` plugin and show bare `flutter`/`dart` commands — run them with `fvm`.
