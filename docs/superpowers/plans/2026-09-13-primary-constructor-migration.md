# Primary Constructor Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish migrating every Dart tree in the monorepo to Dart 3.13 primary constructors: fix the one dangling doc reference the mechanical conversion left, update the code samples in docs and skills, and record the change in every changelog.

**Architecture:** Task 0 (already applied on the branch, awaiting commit) ran `dart fix` with `use_primary_constructors` and `use_declaring_parameters` enabled, then dropped `use_primary_constructors` again and stripped the empty `()` header it had added to 86 classes that never declared a constructor. `use_declaring_parameters` stays on permanently in every `analysis_options.yaml`. Tasks 5 and 6 are the hand cleanup that remains after the ruling below, one subagent per task, each ending in a green analyze, format, and test run and its own commit to the feature branch.

**Tech Stack:** Dart 3.13.3 / Flutter 3.47.4 via FVM, `very_good_analysis` 11, Prettier for Markdown.

**Spec:** Design was approved in chat on 2026-09-13; there is no separate spec file. The decisions were: (1) migrate every Dart tree, (2) keep `use_declaring_parameters` on, run `use_primary_constructors` once and turn it off, (3) fold orphaned constructor docs into class docs and delete the bare `this;`, later withdrawn by the ruling below.

## Global Constraints

- Every `flutter` and `dart` command is prefixed with `fvm`.
- Branch: `feat/dart-3.13-primary-constructors`. Each task commits to it (standing exception in root `CLAUDE.md`); nothing is pushed by a subagent.
- `packages/flutter_adaptive_cards_fs` has `public_member_api_docs: error`. Never delete a doc comment from a member that still exists.
- Only touch bare `this;` lines (regex `^\s+this;$`). Never touch `this : ...` initializer-list forms or `this { ... }` bodies; those are real in-body constructor parts and their doc comments stay.
- After deleting a `this;`, if the class body is now empty (`{` followed only by whitespace and `}`), replace the braces with `;` so `empty_container_bodies` does not fire.
- Markdown edits must pass `npm run check:md` (docs, packages, root) or `npm run check:md:chat` (chat apps). Run `npm run format:md` / `format:md:chat` after editing.
- Do not change any behavior. The suites must pass with the same counts: cards_fs 850, charts 32, host 37, template 103, widgetbook 1, explorer 24, chat client 25, chat server 400.

---

## Tasks 1-4 withdrawn: constructor docs stay on `this;`

The design decision to fold each constructor doc into the class doc and delete the bare `this;` cannot be implemented. `public_member_api_docs` treats a primary constructor as a public member that needs its own `///` comment, and the only place that comment can attach is the in-body `this;` declaration. Deleting it produces `Missing documentation for a public member` on the class header (reproduced on `TextBlockConfig`, 2026-09-13). The lint is an error in `flutter_adaptive_cards_fs` and on at default severity in host, template, and the three apps; only charts, test support, and widgetbook ignore it, and stripping bodies there alone would leave two styles in one repo.

Ruling: every converted class keeps its constructor doc on `this;`. This is how Dart 3.13 documents a primary constructor, and it is what the mechanical conversion in Task 0 already produced. The one genuine leftover from that conversion, the dangling `[theme]` reference in `theme_color_fallbacks.dart`, moves into Task 5.

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

### Task 5: Update code samples in docs and skills

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/theme_color_fallbacks.dart:16` (dangling doc reference)
- Modify: `docs/custom-action-recipe.md:16-17`
- Modify: `docs/AdaptiveWidget-Key-Generation.md:33-50`
- Modify: `.claude/skills/adaptive-cards-element-registry/SKILL.md:73-87` and `:216-220`
- Modify: `.claude/skills/adaptive-cards-flutter-standard-practices/SKILL.md:44-59`
- Modify: `.claude/skills/adaptive-cards-localization/SKILL.md:73-81`

- [ ] **Step 0: Fix the dangling doc reference**

In `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/theme_color_fallbacks.dart` the constructor doc on `this;` reads `/// Builds color fallbacks from [theme]'s [ColorScheme].` but the declaring parameter is now `_theme`, so `[theme]` does not resolve (`comment_references`). Change it to `/// Builds color fallbacks from the [ThemeData]'s [ColorScheme].` Keep the `this;` line. Then `fvm flutter analyze` from the repo root must report no issues.

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
  /// One ChoiceSet option; [title] is shown, [value] is submitted.
  this;

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
}) {
  /// All strings default to the library's English chrome.
  this;
}
```

- [ ] **Step 2: Add one sentence to the element-registry skill**

Directly under the widget skeleton, add: "Fields come from declaring parameters in the class header (`final` in the parameter list); `use_declaring_parameters` is enforced, so never write `this.adaptiveMap` in a primary constructor. The in-body `this : super(...) { ... }` part is where the key and `id` are set, and its `///` comment documents the constructor: `public_member_api_docs` requires one, and a bare `this;` with a doc comment is the form for classes that need nothing else in the body."

- [ ] **Step 3: Verify**

```bash
npm run format:md && npm run check:md
grep -rnE "^\s+(const )?[A-Z][A-Za-z]+\(\{|^\s+(const )?[A-Z][A-Za-z]+\(\)" docs/*.md .claude/skills/*/SKILL.md   # nothing outside docs/plans and docs/archive
```

- [ ] **Step 4: Commit**

```bash
git add docs .claude/skills packages/flutter_adaptive_cards_fs/lib/src/hostconfig/theme_color_fallbacks.dart
git commit -m "docs: show the primary-constructor form in element, action, and model samples"
```

---

### Task 6: Changelogs and full verification

**Files:** Modify the nine `CHANGELOG.md` files: `packages/flutter_adaptive_cards_fs`, `packages/flutter_adaptive_cards_host_fs`, `packages/flutter_adaptive_charts_fs`, `packages/flutter_adaptive_template_fs`, `packages/flutter_adaptive_cards_test_support`, `widgetbook`, `adaptive_explorer`, `adaptive_chat_client`, `adaptive_chat_server_dart`.

- [ ] **Step 1: Add a new `## [Unreleased]` section above `## [0.17.0]` in each file**

```markdown
## [Unreleased]

- refactor: classes use Dart 3.13 primary constructors with declaring parameters; field docs sit on the parameters in the class header and constructor docs on the in-body `this` declaration. `use_declaring_parameters` is enforced by `analysis_options.yaml`. No behavior change; public constructor signatures are unchanged.
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
