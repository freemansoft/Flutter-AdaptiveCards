# Primary Constructor Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish migrating every Dart tree in the monorepo to Dart 3.13 primary constructors: fold the constructor doc comments that the mechanical conversion left on bare `this;` in-body parts into their class docs, fix the one dangling doc reference, update the code samples in docs and skills, and record the change in every changelog.

**Architecture:** Task 0 (already applied on the branch, awaiting commit) ran `dart fix` with `use_primary_constructors` and `use_declaring_parameters` enabled, then dropped `use_primary_constructors` again and stripped the empty `()` header it had added to 86 classes that never declared a constructor. `use_declaring_parameters` stays on permanently in every `analysis_options.yaml`. Tasks 1-6 are hand cleanup, one subagent per task, each ending in a green analyze, format, and test run and its own commit to the feature branch.

**Tech Stack:** Dart 3.13.3 / Flutter 3.47.4 via FVM, `very_good_analysis` 11, Prettier for Markdown.

**Spec:** Design was approved in chat on 2026-09-13; there is no separate spec file. The decisions were: (1) migrate every Dart tree, (2) keep `use_declaring_parameters` on, run `use_primary_constructors` once and turn it off, (3) fold orphaned constructor docs into class docs and delete the bare `this;`.

## Global Constraints

- Every `flutter` and `dart` command is prefixed with `fvm`.
- Branch: `feat/dart-3.13-primary-constructors`. Each task commits to it (standing exception in root `CLAUDE.md`); nothing is pushed by a subagent.
- `packages/flutter_adaptive_cards_fs` has `public_member_api_docs: error`. Never delete a doc comment from a member that still exists.
- Only touch bare `this;` lines (regex `^\s+this;$`). Never touch `this : ...` initializer-list forms or `this { ... }` bodies; those are real in-body constructor parts and their doc comments stay.
- After deleting a `this;`, if the class body is now empty (`{` followed only by whitespace and `}`), replace the braces with `;` so `empty_container_bodies` does not fire.
- Markdown edits must pass `npm run check:md` (docs, packages, root) or `npm run check:md:chat` (chat apps). Run `npm run format:md` / `format:md:chat` after editing.
- Do not change any behavior. The suites must pass with the same counts: cards_fs 850, charts 32, host 37, template 103, widgetbook 1, explorer 24, chat client 25, chat server 400.

---

## The folding rule (used by Tasks 1-4)

Every bare `this;` on the branch is preceded by a `///` block that used to document the constructor. For each one:

1. Read the class doc comment (the `///` block above `class ...(`) and the constructor doc block above `this;`.
2. Decide whether the constructor doc adds information that is not already in the class doc or in the declaring-parameter docs. Boilerplate is any sentence of the form "Creates a/an/the X", "Creates X from explicit values", "Creates X with the given fields", or a restatement of the class doc. Information is anything else: a caller contract ("inject `client` in tests"), a default ("defaults to 2"), a cross-reference, a precondition.
3. **Boilerplate:** delete the constructor doc block, the `this;` line, and the blank line that follows it.
4. **Information:** append it to the class doc as a new paragraph (a bare `///` line, then the sentence), rewritten as class-level prose, then delete the constructor doc block and `this;` as in step 3. Doc references in square brackets must resolve from the class: a declaring parameter is a field, so `[baseUrl]` is fine; a regular (non-declaring) parameter such as `client` is not a member, so write it in backticks.
5. If the body is now empty, collapse `{` `}` to `;`.

Before:

```dart
/// Base URL and HTTP client for the chat backend.
class ChatBackendClient({
  /// Base URL of the backend (e.g. `http://localhost:8000`).
  required final Uri baseUrl,
  http.Client? client,
}) {
  /// Creates a client posting to [baseUrl]; inject [client] in tests.
  this;

  final http.Client _client = client ?? http.Client();
```

After:

```dart
/// Base URL and HTTP client for the chat backend.
///
/// Inject `client` in tests; it defaults to a fresh [http.Client].
class ChatBackendClient({
  /// Base URL of the backend (e.g. `http://localhost:8000`).
  required final Uri baseUrl,
  http.Client? client,
}) {
  final http.Client _client = client ?? http.Client();
```

Before (boilerplate, body becomes empty):

```dart
/// HostConfig `textBlock` section controlling TextBlock heading defaults.
class TextBlockConfig({
  /// Default heading level (1-6) for TextBlock elements styled as headings.
  required final int headingLevel,
}) {
  /// Creates TextBlock settings from explicit values.
  this;

  /// Parses `textBlock` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) { ... }
}
```

After:

```dart
/// HostConfig `textBlock` section controlling TextBlock heading defaults.
class TextBlockConfig({
  /// Default heading level (1-6) for TextBlock elements styled as headings.
  required final int headingLevel,
}) {
  /// Parses `textBlock` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) { ... }
}
```

Verification for every folding task, run from the package directory named in the task:

```bash
grep -rnE "^\s+this;$" <task directories>      # must print nothing
fvm dart format .                               # from the package directory
cd <repo root> && fvm flutter analyze           # No issues found
cd <package directory> && fvm flutter test      # same pass count as before (fvm dart test for the chat server)
```

---

### Task 0: Mechanical conversion (already applied, needs its commit)

**Files:** 189 files across every Dart tree; nine `analysis_options.yaml` files gain `use_declaring_parameters: true`.

- [ ] **Step 1: Confirm the base is green**

Run from the repo root: `fvm flutter analyze` and expect exactly one issue, the `comment_references` info in `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/theme_color_fallbacks.dart:16` (Task 1 fixes it).

- [ ] **Step 2: Commit** (main session, after the user confirms the diff summary)

```bash
git add -A
git commit -m "refactor: migrate every Dart tree to Dart 3.13 primary constructors"
```

---

### Task 1: Fold constructor docs in `flutter_adaptive_cards_fs` hostconfig

**Files:**

- Modify: the 28 files under `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/` that contain a bare `this;` (45 sites). List them with `grep -rlE "^\s+this;$" packages/flutter_adaptive_cards_fs/lib/src/hostconfig`.
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/theme_color_fallbacks.dart:16` also has the dangling reference.

- [ ] **Step 1: Fix the dangling reference in `theme_color_fallbacks.dart`**

The constructor doc reads `/// Builds color fallbacks from [theme]'s [ColorScheme].` but the declaring parameter is `_theme`. Fold it into the class doc as `/// Built from the ambient [ThemeData]'s [ColorScheme].` and delete the `this;` per the folding rule.

- [ ] **Step 2: Apply the folding rule to every other `this;` in the directory**

`charts_layout_config.dart` has 7 sites, `actions_config.dart`, `badge_styles_config.dart`, `fact_set_config.dart`, `progress_config.dart` have 2 each, the rest have 1.

- [ ] **Step 3: Verify**

```bash
grep -rnE "^\s+this;$" packages/flutter_adaptive_cards_fs/lib/src/hostconfig   # nothing
cd packages/flutter_adaptive_cards_fs && fvm dart format . && cd ../.. && fvm flutter analyze
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden   # 819 passed
```

- [ ] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/hostconfig
git commit -m "refactor(cards): fold constructor docs into class docs in hostconfig"
```

---

### Task 2: Fold constructor docs in `flutter_adaptive_cards_fs` models, security, utils, widgets, and top-level files

**Files:** Modify every file under `packages/flutter_adaptive_cards_fs/lib/src/` that contains a bare `this;` and is **not** under `hostconfig/`, `action/`, `cards/`, `responsive/`, or `riverpod/`. That is: `models/` (11 files, 21 sites; `action_invoke.dart` alone has 9), `security/` (4 files, 8 sites), `utils/` (3 files, 5 sites), `widgets/` (2 files), `adaptive_cards_canvas.dart` (2), `additional.dart` (3), `flutter_raw_adaptive_card.dart` (2), `registry.dart` (1), `resolved_input_state.dart` (1). List with `grep -rlE "^\s+this;$" packages/flutter_adaptive_cards_fs/lib/src | grep -vE "/(hostconfig|action|cards|responsive|riverpod)/"`.

- [ ] **Step 1: Apply the folding rule to every site**

`models/action_invoke.dart` and `security/adaptive_uri_validation.dart` hold sealed hierarchies whose subclasses each had a one-line constructor doc; most are boilerplate against the subclass doc. Keep any sentence that states what a variant means for the caller.

- [ ] **Step 2: Verify**

```bash
grep -rlE "^\s+this;$" packages/flutter_adaptive_cards_fs/lib/src | grep -vE "/(hostconfig|action|cards|responsive|riverpod)/"   # nothing
cd packages/flutter_adaptive_cards_fs && fvm dart format . && cd ../.. && fvm flutter analyze
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden   # 819 passed
```

- [ ] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs
git commit -m "refactor(cards): fold constructor docs into class docs in models, security, utils, widgets"
```

---

### Task 3: Fold constructor docs in `flutter_adaptive_cards_fs` action, cards, responsive, riverpod

**Files:** Modify: `action/action_handler.dart` (1), `action/action_type_registry.dart` (2), `action/default_actions.dart` (8), `action/generic_action.dart` (9), `cards/actions/popover_container.dart` (1), `cards/inputs/choice_filter.dart` (1), `cards/stretchable_column.dart` (1), `responsive/adaptive_area_grid.dart` (3), `responsive/adaptive_flow_layout.dart` (1), `responsive/area_grid_model.dart` (3), `riverpod/adaptive_card_document.dart` (3), `riverpod/element_overlay_extension.dart` (2), `riverpod/overlay_capability_registry.dart` (3), all under `packages/flutter_adaptive_cards_fs/lib/src/`.

- [ ] **Step 1: Apply the folding rule to every site**

`generic_action.dart` and `default_actions.dart` are the abstract `Generic*Action` interfaces and their `Default*Action` implementations; each got `class const X() { /// Creates ... this; }`. After folding, most bodies still hold methods, so only collapse to `;` where the body is truly empty.

- [ ] **Step 2: Verify**

```bash
grep -rnE "^\s+this;$" packages/flutter_adaptive_cards_fs   # nothing left anywhere in the package
cd packages/flutter_adaptive_cards_fs && fvm dart format . && cd ../.. && fvm flutter analyze
cd packages/flutter_adaptive_cards_fs && fvm flutter test   # 850 passed, goldens included
```

- [ ] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs
git commit -m "refactor(cards): fold constructor docs into class docs in action, cards, responsive, riverpod"
```

---

### Task 4: Fold constructor docs in the four other packages and the four apps

**Files:** Modify every bare `this;` site outside `flutter_adaptive_cards_fs`:

- `packages/flutter_adaptive_cards_host_fs/lib/src/` (14 sites: `models/invoke_effect.dart` 5, `models/invoke_response.dart` 2, `client/http_action_executor.dart` 2, `client/backend_client.dart`, `client/http_backend_client.dart`, `handlers/backend_handlers.dart`, `models/invoke_request.dart`, `security/bounded_json.dart`)
- `packages/flutter_adaptive_charts_fs/lib/src/` (5: `charts/chart_chrome.dart` 2, `charts/gauge_painter.dart` 2, `chart_element_overlay_extension.dart`)
- `packages/flutter_adaptive_template_fs/lib/src/` (10: `ast.dart` 7, `expression_parser.dart` 2, `template.dart`)
- `packages/flutter_adaptive_cards_test_support/lib/src/http_overrides.dart` (1)
- `widgetbook/lib/` (5: `chart_knobs_page.dart` 2, `table_knobs_page.dart` 2, `rounded_corners_knobs_page.dart`)
- `adaptive_explorer/lib/main.dart` (2)
- `adaptive_chat_client/lib/` (7: `src/chat_models.dart` 3, `main.dart`, `src/chat_backend_client.dart`, `src/chat_page.dart`, `src/conversation_controller.dart`)
- `adaptive_chat_server_dart/` (17: `lib/src/store.dart` 2, `lib/src/ollama_responder.dart`, `lib/src/responder.dart`, `lib/src/stats.dart`, and under `tool/model_probes/`: `cascade_ab.dart` 2, `probe_results.dart` 2, `probe_support.dart` 2, `shape_cases.dart` 2, `sync_shape_table.dart` 2, `cascade_cases.dart`, `check_results.dart`)

- [ ] **Step 1: Apply the folding rule to every site**

`invoke_effect.dart` is a sealed hierarchy; keep the sentences that say how each effect is applied (`AdaptiveCardInvokeResponse.applyTo` references) because the class docs are one line. `bounded_json.dart`'s "Records the `maxBytes` cap that the body exceeded" is information; fold it.

- [ ] **Step 2: Verify**

```bash
grep -rnE "^\s+this;$" --include="*.dart" packages widgetbook adaptive_explorer adaptive_chat_client adaptive_chat_server_dart   # nothing
fvm dart format packages/ widgetbook/ adaptive_explorer/ adaptive_chat_client/ adaptive_chat_server_dart/
fvm flutter analyze                                             # No issues found
cd adaptive_chat_server_dart && fvm dart analyze && fvm dart test   # No issues, 400 passed
cd ../packages/flutter_adaptive_charts_fs && fvm flutter test    # 32
cd ../flutter_adaptive_cards_host_fs && fvm flutter test         # 37
cd ../flutter_adaptive_template_fs && fvm flutter test           # 103
cd ../../widgetbook && fvm flutter test                          # 1
cd ../adaptive_explorer && fvm flutter test                      # 24
cd ../adaptive_chat_client && fvm flutter test                   # 25
```

- [ ] **Step 3: Commit**

```bash
git add packages widgetbook adaptive_explorer adaptive_chat_client adaptive_chat_server_dart
git commit -m "refactor: fold constructor docs into class docs in host, charts, template, test support, and apps"
```

---

### Task 5: Update code samples in docs and skills

**Files:**

- Modify: `docs/custom-action-recipe.md:16-17`
- Modify: `docs/AdaptiveWidget-Key-Generation.md:33-50`
- Modify: `.claude/skills/adaptive-cards-element-registry/SKILL.md:73-87` and `:216-220`
- Modify: `.claude/skills/adaptive-cards-flutter-standard-practices/SKILL.md:44-59`
- Modify: `.claude/skills/adaptive-cards-localization/SKILL.md:73-81`

- [ ] **Step 1: Rewrite each sample in the primary-constructor form now used by the source**

`docs/custom-action-recipe.md`:

```dart
class const MySubmitAction() implements GenericSubmitAction {
  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    // custom behavior
  }
}
```

`docs/AdaptiveWidget-Key-Generation.md` standard element (the prose above it, "Load the `id` in the constructor body immediately after `super()`", stays true):

```dart
class AdaptiveFakeClassName({
  @override required final Map<String, dynamic> adaptiveMap,
}) extends StatefulWidget with AdaptiveElementWidgetMixin {
  this : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  late final String id;

  @override
  AdaptiveFakeClassNameState createState() => AdaptiveFakeClassNameState();
}
```

`.claude/skills/adaptive-cards-element-registry/SKILL.md` widget skeleton, same shape as above with `AdaptiveMyElement`, keeping the `/// Implements the MyElement Adaptive Card element type.` class doc and the inline comment `// load id after super()`. Its "Key Generation" snippet becomes:

```dart
// In the widget's in-body constructor part:
this : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
  id = loadId(adaptiveMap);
}
```

`.claude/skills/adaptive-cards-flutter-standard-practices/SKILL.md` model sample:

```dart
@immutable
class const Choice({
  /// Label shown in the ChoiceSet UI.
  required final String title,

  /// Submitted value when this choice is selected.
  required final String value,
}) {
  /// Parses an Adaptive Cards `Input.Choice` object from card JSON.
  factory fromJson(Map<String, dynamic> json) {
    return Choice(
      title: json['title'] as String? ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'value': value};
}
```

`.claude/skills/adaptive-cards-localization/SKILL.md`:

```dart
// Core package — a dumb value holder. It does NO locale resolution.
class const AdaptiveStrings({
  final String progressLabel = 'Progress',
  final String dialogOk = 'OK',
  // ...
});
```

- [ ] **Step 2: Add one sentence to the element-registry skill**

Directly under the widget skeleton, add: "Fields come from declaring parameters in the class header (`final` in the parameter list); `use_declaring_parameters` is enforced, so never write `this.adaptiveMap` in a primary constructor. The in-body `this : super(...) { ... }` part is where the key and `id` are set."

- [ ] **Step 3: Verify**

```bash
npm run format:md && npm run check:md
grep -rnE "^\s+(const )?[A-Z][A-Za-z]+\(\{|^\s+(const )?[A-Z][A-Za-z]+\(\)" docs/*.md .claude/skills/*/SKILL.md   # nothing outside docs/plans and docs/archive
```

- [ ] **Step 4: Commit**

```bash
git add docs .claude/skills
git commit -m "docs: show the primary-constructor form in element, action, and model samples"
```

---

### Task 6: Changelogs and full verification

**Files:** Modify the nine `CHANGELOG.md` files: `packages/flutter_adaptive_cards_fs`, `packages/flutter_adaptive_cards_host_fs`, `packages/flutter_adaptive_charts_fs`, `packages/flutter_adaptive_template_fs`, `packages/flutter_adaptive_cards_test_support`, `widgetbook`, `adaptive_explorer`, `adaptive_chat_client`, `adaptive_chat_server_dart`.

- [ ] **Step 1: Add a new `## [Unreleased]` section above `## [0.17.0]` in each file**

```markdown
## [Unreleased]

- refactor: classes use Dart 3.13 primary constructors with declaring parameters; field docs now sit on the parameters in the class header. `use_declaring_parameters` is enforced by `analysis_options.yaml`. No behavior change; public constructor signatures are unchanged.
```

- [ ] **Step 2: Run the full verification**

```bash
fvm flutter analyze                                   # No issues found
cd adaptive_chat_server_dart && fvm dart analyze && cd ..
fvm dart format --output=none --set-exit-if-changed packages/ tool/
fvm dart format --output=none --set-exit-if-changed adaptive_chat_client/ adaptive_chat_server_dart/
fvm dart format --output=none --set-exit-if-changed widgetbook/ adaptive_explorer/
npm run format:md && npm run check:md && npm run format:md:chat && npm run check:md:chat
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden --coverage && fvm flutter test --tags=golden && cd ../..
fvm dart run tool/coverage/check_coverage.dart        # PASS on all four floors
cd packages/flutter_adaptive_charts_fs && fvm flutter test && cd ../flutter_adaptive_cards_host_fs && fvm flutter test && cd ../flutter_adaptive_template_fs && fvm flutter test && cd ../..
cd widgetbook && fvm flutter test && cd ../adaptive_explorer && fvm flutter test && cd ../adaptive_chat_client && fvm flutter test && cd ../adaptive_chat_server_dart && fvm dart test && cd ..
```

- [ ] **Step 3: Commit**

```bash
git add '*/CHANGELOG.md'
git commit -m "docs: changelog entries for the primary constructor migration"
```
