# Host callback invoke payloads Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** **Phase 1 (Tasks 1–9)** — implemented (`SubmitActionInvoke`, `ExecuteActionInvoke`, canvas handler cleanup, docs). **Phase 2 (Tasks 10–17)** — pending (`OpenUrlActionInvoke`, `OpenUrlDialogActionInvoke`, `InputChangeInvoke`).

**Goal:** Deliver typed invoke payloads for **all** host callbacks on **`InheritedAdaptiveCardHandlers`** (and matching **`RawAdaptiveCard`** / **`AdaptiveCardsCanvas.onChange`** wiring):

| Callback | Invoke type | Key fields |
| --- | --- | --- |
| `onSubmit` | **`SubmitActionInvoke`** | `data`, `actionId` |
| `onExecute` | **`ExecuteActionInvoke`** | `data`, `actionId`, `verb` |
| `onOpenUrl` | **`OpenUrlActionInvoke`** | `url`, `actionId` |
| `onOpenUrlDialog` | **`OpenUrlDialogActionInvoke`** | `url`, `actionId` |
| `onChange` | **`InputChangeInvoke`** | `inputId`, `value`, `dataQuery`, `cardState` |

Remove dead action handler fields from **`AdaptiveCardsCanvasState`** (Phase 1). Reconcile **`docs/`** and package README/CHANGELOG after each phase.

**Architecture:** Extend **`action_invoke.dart`** with OpenUrl / OpenUrlDialog / InputChange invoke types, reusing **`actionIdFromMap`** for action-backed callbacks. Action defaults build invoke objects from `adaptiveMap` at tap time (including **`selectAction`**). Input changes build **`InputChangeInvoke`** in **`RawAdaptiveCardState`** (single notification path) before calling the host. **`AdaptiveCardsCanvas.onChange`** uses the same **`InputChangeInvoke`** type as **`InheritedAdaptiveCardHandlers.onChange`**. Author-defined **`actionId`** only (auto-injected ids excluded — same rule as Submit/Execute).

**Tech Stack:** Dart 3.12+, Flutter (FVM), `flutter_adaptive_cards_fs`, `package:test` / `flutter_test`, `very_good_analysis`.

**Spec reference:**

- [Action.Submit](https://adaptivecards.io/explorer/Action.Submit.html) — `data` + optional action `id`; merged with input values.
- [Action.OpenUrl](https://adaptivecards.io/explorer/Action.OpenUrl.html) — `url` + optional action `id`.
- [Action.OpenUrlDialog](https://adaptivecards.io/explorer/Action.OpenUrlDialog.html) — Teams extension; `url` + optional action `id`.
- [Universal Action Model / Action.Execute](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/universal-action-model) — invoke `value.action` includes `verb`, `id`, and merged `data`.
- **Input `onChange`** — library extension; not an action type. Payload carries input id, value, optional **`DataQuery`**, and **`RawAdaptiveCardState`** for host **`applyUpdates`**.
- **`associatedInputs`** and full invoke envelope (`trigger`, etc.) remain out of scope.

---

## Phase 1 — Submit / Execute (implemented)

See tasks below. Checkboxes left as `- [ ]` for historical record; work is done in the codebase.

---

## File map

| File                                                                             | Role                                                                     |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart`           | **Create** — `SubmitActionInvoke`, `ExecuteActionInvoke`, shared helpers |
| `packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart`          | Export new models                                                        |
| `packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart`          | Change `onSubmit` + `onExecute` callback types                           |
| `packages/flutter_adaptive_cards_fs/lib/src/action/generic_action.dart`          | Remove `verb` param from `GenericExecuteAction.tap`                      |
| `packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`         | Build + forward both invoke types                                        |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/actions/execute.dart`          | Stop passing `verb:` into `tap()`                                        |
| `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart`        | Remove unused `AdaptiveCardsCanvasState.onSubmit` / `onExecute` / `onOpenUrl` |
| `packages/flutter_adaptive_cards_fs/test/actions/submit_action_invoke_test.dart` | **Create** — Submit id/data tests                                        |
| `packages/flutter_adaptive_cards_fs/test/actions/execute_verb_test.dart`         | **Create** — Execute verb/id/data tests                                  |
| `packages/flutter_adaptive_cards_fs/test/select_action_tappable_test.dart`       | Update Submit + Execute selectAction tests                               |
| `packages/flutter_adaptive_cards_fs/test/utils/test_utils.dart`                  | Update both handler typedefs                                             |
| `packages/flutter_adaptive_charts_fs/test/utils/test_utils.dart`                 | Mirror test_utils change                                                 |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md`                                | Breaking change note                                                     |
| `packages/flutter_adaptive_cards_fs/README.md`                                   | Fix handler example (not on canvas constructors)                         |
| `docs/actions-architecture.md`                                                   | Submit + Execute payload sections                                        |
| `docs/Architecture-Overview.md`                                                  | Consumer API + handler wiring                                            |
| `docs/form-inputs.md`                                                            | `onSubmit` validation example                                            |
| `docs/Implementation-Status.md`                                                  | Action.Submit + Action.Execute rows + Known Gaps                         |
| `docs/reactive-riverpod.md`                                                      | Invoke payload note on host callbacks                                    |

### Phase 2 file map (OpenUrl / OpenUrlDialog / onChange)

| File | Role |
| --- | --- |
| `packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart` | Add `OpenUrlActionInvoke`, `OpenUrlDialogActionInvoke`, `InputChangeInvoke` |
| `packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart` | Type `onOpenUrl`, `onOpenUrlDialog`, `onChange` |
| `packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart` | Build OpenUrl invoke types in default handlers |
| `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart` | Emit `InputChangeInvoke` from input notification path; update `onChange` typedef |
| `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart` | Align widget/state `onChange` typedef with `InputChangeInvoke` |
| `packages/flutter_adaptive_cards_fs/test/actions/open_url_action_invoke_test.dart` | **Create** — OpenUrl url + actionId tests |
| `packages/flutter_adaptive_cards_fs/test/actions/open_url_dialog_action_invoke_test.dart` | **Create** — OpenUrlDialog tests |
| `packages/flutter_adaptive_cards_fs/test/models/input_change_invoke_test.dart` | **Create** — optional unit test for type; widget coverage in choice_set tests |
| `packages/flutter_adaptive_cards_fs/test/select_action_tappable_test.dart` | Extend OpenUrl selectAction test for `actionId` |
| `packages/flutter_adaptive_cards_fs/test/utils/test_utils.dart` | Update OpenUrl / onChange handler typedefs |
| `packages/flutter_adaptive_cards_fs/test/utils/dependent_choice_set_handler.dart` | Migrate `handleDependentChoiceSetChange` to `InputChangeInvoke` |
| `packages/flutter_adaptive_cards_fs/test/inputs/choice_set_data_query_test.dart` | Update onChange assertions |
| `packages/flutter_adaptive_cards_fs/test/inputs/dependent_choice_set_test.dart` | Update inline onChange lambdas |
| `widgetbook/lib/dependent_choice_set_demo_page.dart` | Migrate demo `onChange` handler |
| `packages/flutter_adaptive_charts_fs/test/utils/test_utils.dart` | Mirror handler typedef changes |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md` | Phase 2 breaking-change notes |
| `docs/actions-architecture.md` | OpenUrl + InputChange payload sections |
| `docs/form-inputs.md` | Dependent ChoiceSet / onChange examples |
| `docs/Architecture-Overview.md`, `docs/reactive-riverpod.md`, `docs/Implementation-Status.md` | Full invoke-type coverage |

---

### Task 1: Invoke payload models

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart`

- [ ] **Step 1: Add both models + shared helper**

```dart
/// Reads action `id` from card JSON as a string, or null when absent.
String? actionIdFromMap(Map<String, dynamic> actionMap) {
  final idRaw = actionMap['id'];
  return idRaw == null ? null : idRaw.toString();
}

/// Payload delivered to host [InheritedAdaptiveCardHandlers.onSubmit].
class SubmitActionInvoke {
  const SubmitActionInvoke({
    required this.data,
    this.actionId,
  });

  /// Merged `Action.Submit.data` and collected input values (inputs win on
  /// key collision — same rule as [DefaultSubmitAction] today).
  final Map<String, dynamic> data;

  /// Action `id` from card JSON, when present.
  final String? actionId;

  factory SubmitActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> data,
  ) {
    return SubmitActionInvoke(
      data: data,
      actionId: actionIdFromMap(actionMap),
    );
  }
}

/// Payload delivered to host [InheritedAdaptiveCardHandlers.onExecute].
class ExecuteActionInvoke {
  const ExecuteActionInvoke({
    required this.data,
    this.verb,
    this.actionId,
  });

  /// Merged `Action.Execute.data` and collected input values (inputs win on
  /// key collision — same rule as [DefaultExecuteAction] today).
  final Map<String, dynamic> data;

  /// Card author-defined verb from action JSON (`verb` property).
  final String? verb;

  /// Action `id` from card JSON, when present.
  final String? actionId;

  factory ExecuteActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> data,
  ) {
    final verbRaw = actionMap['verb'];
    return ExecuteActionInvoke(
      data: data,
      verb: verbRaw == null ? null : verbRaw.toString(),
      actionId: actionIdFromMap(actionMap),
    );
  }
}
```

Add `///` doc references to `DefaultSubmitAction` / `DefaultExecuteAction` (import not required in model file — reference by name in docs only).

- [ ] **Step 2: Export from public library**

In `flutter_adaptive_cards_fs.dart`, add:

```dart
export 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
```

- [ ] **Step 3: Analyze**

Run: `cd packages/flutter_adaptive_cards_fs && fvm dart analyze lib/src/models/action_invoke.dart`

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart \
        packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart
git commit -m "feat: add SubmitActionInvoke and ExecuteActionInvoke payload types"
```

---

### Task 2: Handler callback types + GenericExecuteAction

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/generic_action.dart`

- [ ] **Step 1: Update both callbacks in `action_handler.dart`**

Add import:

```dart
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
```

Change fields + docs:

```dart
  /// Called when an [Action.Submit] is pressed and default action handlers run.
  ///
  /// [invoke.data] contains merged action `data` and input values;
  /// [invoke.actionId] comes from the action JSON `id` property.
  final void Function(SubmitActionInvoke invoke) onSubmit;

  /// Called when an [Action.Execute] is pressed and default action handlers run.
  ///
  /// [invoke.data] contains merged action `data` and input values;
  /// [invoke.verb] and [invoke.actionId] come from the action JSON.
  final void Function(ExecuteActionInvoke invoke) onExecute;
```

- [ ] **Step 2: Align `GenericExecuteAction.tap` with Submit**

In `generic_action.dart`, replace the Execute override with:

```dart
abstract class GenericExecuteAction extends GenericAction {
  const GenericExecuteAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}
```

Remove the `String? verb` parameter entirely (read from `adaptiveMap` in default impl).

- [ ] **Step 3: Analyze**

Run: `cd packages/flutter_adaptive_cards_fs && fvm dart analyze lib/src/action/`

Expected: errors in `default_actions.dart`, `execute.dart`, and tests — fixed in next tasks.

- [ ] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart \
        packages/flutter_adaptive_cards_fs/lib/src/action/generic_action.dart
git commit -m "refactor: type onSubmit/onExecute invoke callbacks; simplify GenericExecuteAction.tap"
```

---

### Task 3: DefaultSubmitAction + tests (TDD)

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/test/actions/submit_action_invoke_test.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`
- Modify: `packages/flutter_adaptive_cards_fs/test/utils/test_utils.dart`

- [ ] **Step 1: Write failing Submit tests**

Create `test/actions/submit_action_invoke_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Action.Submit forwards action id and merged data to onSubmit', (
    tester,
  ) async {
    SubmitActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'firstName',
          'value': 'Ada',
        },
      ],
      'actions': [
        {
          'type': 'Action.Submit',
          'id': 'submit-1',
          'title': 'Send',
          'data': {'x': 13},
        },
      ],
    };

    await tester.pumpWidget(
      buildCard(
        card,
        onOpenUrl: (_) {},
        onSubmit: (invoke) => captured = invoke,
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.actionId, 'submit-1');
    expect(captured!.data['x'], 13);
    expect(captured!.data['firstName'], 'Ada');
  });

  testWidgets('Action.Submit without id passes null actionId', (tester) async {
    SubmitActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'actions': [
        {
          'type': 'Action.Submit',
          'title': 'Send',
          'data': {'only': 'data'},
        },
      ],
    };

    await tester.pumpWidget(
      buildCard(
        card,
        onOpenUrl: (_) {},
        onSubmit: (invoke) => captured = invoke,
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(captured!.actionId, isNull);
    expect(captured!.data['only'], 'data');
  });
}
```

- [ ] **Step 2: Update `test_utils.dart` — `onSubmit` typedef**

Change `onSubmit` from `Function(Map<dynamic, dynamic>)?` to `void Function(SubmitActionInvoke invoke)?` (import `action_invoke.dart`).

Update defaults:

```dart
onSubmit: onSubmit ?? (_) {},
onExecute: onExecute ?? (_) {},
```

(`onExecute` typedef updated in Task 4 Step 2 — do both in one edit if preferred.)

- [ ] **Step 3: Run tests — expect FAIL**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/actions/submit_action_invoke_test.dart`

Expected: compile errors or FAIL.

- [ ] **Step 4: Implement `DefaultSubmitAction`**

In `default_actions.dart`, add import for `action_invoke.dart`.

Replace Submit handler tail (after validation):

```dart
    final invoke = SubmitActionInvoke.fromActionMap(adaptiveMap, data);

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onSubmit(invoke);
    } else if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No custom handler found for onSubmit: '
            'id: ${invoke.actionId}\n ${invoke.data}',
          ),
        ),
      );
    }
```

- [ ] **Step 5: Run tests — expect PASS**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/actions/submit_action_invoke_test.dart`

Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart \
        packages/flutter_adaptive_cards_fs/test/actions/submit_action_invoke_test.dart \
        packages/flutter_adaptive_cards_fs/test/utils/test_utils.dart
git commit -m "feat: deliver Action.Submit actionId and data via SubmitActionInvoke"
```

---

### Task 4: DefaultExecuteAction + Execute widget (TDD)

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/test/actions/execute_verb_test.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/actions/execute.dart`

- [ ] **Step 1: Write failing Execute tests**

Create `test/actions/execute_verb_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Action.Execute forwards verb and action id to onExecute', (
    tester,
  ) async {
    ExecuteActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'firstName',
          'value': 'Ada',
        },
      ],
      'actions': [
        {
          'type': 'Action.Execute',
          'id': 'exec-1',
          'title': 'Run',
          'verb': 'accepted',
          'data': {'x': 13},
        },
      ],
    };

    await tester.pumpWidget(
      buildCard(
        card,
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (invoke) => captured = invoke,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.verb, 'accepted');
    expect(captured!.actionId, 'exec-1');
    expect(captured!.data['x'], 13);
    expect(captured!.data['firstName'], 'Ada');
  });

  testWidgets('Action.Execute without verb passes null verb', (tester) async {
    ExecuteActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'actions': [
        {
          'type': 'Action.Execute',
          'title': 'Run',
          'data': {'only': 'data'},
        },
      ],
    };

    await tester.pumpWidget(
      buildCard(
        card,
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (invoke) => captured = invoke,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(captured!.verb, isNull);
    expect(captured!.actionId, isNull);
    expect(captured!.data['only'], 'data');
  });
}
```

- [ ] **Step 2: Ensure `test_utils.dart` has both invoke typedefs**

If not done in Task 3:

```dart
void Function(SubmitActionInvoke invoke)? onSubmit,
void Function(ExecuteActionInvoke invoke)? onExecute,
```

- [ ] **Step 3: Run tests — expect FAIL**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/actions/execute_verb_test.dart`

Expected: compile errors or FAIL.

- [ ] **Step 4: Implement `DefaultExecuteAction`**

Replace Execute handler tail:

```dart
    final invoke = ExecuteActionInvoke.fromActionMap(adaptiveMap, data);

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onExecute(invoke);
    } else if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No custom handler found for onExecute: '
            'verb: ${invoke.verb} id: ${invoke.actionId}\n ${invoke.data}',
          ),
        ),
      );
    }
```

Remove the unused `String? verb` parameter from `tap()`.

- [ ] **Step 5: Fix `execute.dart` call site**

Remove `verb: adaptiveMap['verb']?.toString(),` from the `action.tap(...)` call.

- [ ] **Step 6: Run tests — expect PASS**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/actions/execute_verb_test.dart`

Expected: PASS (2 tests).

- [ ] **Step 7: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart \
        packages/flutter_adaptive_cards_fs/lib/src/cards/actions/execute.dart \
        packages/flutter_adaptive_cards_fs/test/actions/execute_verb_test.dart
git commit -m "feat: deliver Action.Execute verb and id via ExecuteActionInvoke"
```

---

### Task 5: `selectAction` Submit + Execute + charts test_utils

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/test/select_action_tappable_test.dart`
- Modify: `packages/flutter_adaptive_charts_fs/test/utils/test_utils.dart`

- [ ] **Step 1: Update selectAction helper + Submit test**

In `select_action_tappable_test.dart`:

- Add import for `action_invoke.dart`.
- Change local helper signatures:

```dart
required void Function(SubmitActionInvoke invoke) onSubmit,
required void Function(ExecuteActionInvoke invoke) onExecute,
```

- Replace Submit selectAction test:

```dart
  testWidgets(
    'AdaptiveContainer selectAction (Submit) calls onSubmit with actionId and data',
    (tester) async {
      SubmitActionInvoke? captured;

      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'Container',
            'selectAction': {
              'type': 'Action.Submit',
              'id': 'container-submit',
              'data': {'foo': 'bar'},
            },
            'items': [
              {'type': 'TextBlock', 'text': 'Submit container'},
            ],
          },
        ],
      };

      await tester.pumpWidget(
        buildCard(
          map,
          onOpenUrl: (_) {},
          onSubmit: (invoke) => captured = invoke,
          onExecute: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit container'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.actionId, 'container-submit');
      expect(captured!.data['foo'], 'bar');
    },
  );
```

- [ ] **Step 2: Update Execute selectAction test**

```dart
  testWidgets(
    'AdaptiveContainer selectAction (Execute) calls onExecute with verb and data',
    (tester) async {
      ExecuteActionInvoke? captured;

      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'Container',
            'selectAction': {
              'type': 'Action.Execute',
              'verb': 'containerTap',
              'data': {'foo': 'bar'},
            },
            'items': [
              {'type': 'TextBlock', 'text': 'Execute container'},
            ],
          },
        ],
      };

      await tester.pumpWidget(
        buildCard(
          map,
          onOpenUrl: (_) {},
          onSubmit: (_) {},
          onExecute: (invoke) => captured = invoke,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Execute container'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.verb, 'containerTap');
      expect(captured!.data['foo'], 'bar');
    },
  );
```

- [ ] **Step 3: Mirror charts `test_utils.dart`**

Apply both `onSubmit` / `onExecute` typedef + import changes.

- [ ] **Step 4: Run affected tests**

Run:

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/select_action_tappable_test.dart test/actions/submit_action_invoke_test.dart test/actions/execute_verb_test.dart --exclude-tags=golden
cd ../flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden
```

Expected: PASS (fix compile errors in tests that still use `onSubmit: (_) {}` — no change needed if `_` accepts any single arg).

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/test/select_action_tappable_test.dart \
        packages/flutter_adaptive_charts_fs/test/utils/test_utils.dart
git commit -m "test: cover Submit/Execute invoke payloads via selectAction"
```

---

### Task 6: Remove dead `AdaptiveCardsCanvasState` handler fields

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart`

**Context:** `AdaptiveCardsCanvasState` declares **`onSubmit`**, **`onExecute`**, and **`onOpenUrl`** but never assigns or passes them to `RawAdaptiveCard.fromMap`. Submit, Execute, and OpenUrl routing goes through **`InheritedAdaptiveCardHandlers`** inside **`DefaultSubmitAction`**, **`DefaultExecuteAction`**, and **`DefaultOpenUrlAction`**. The canvas wires **`onChange`** only (from widget prop or inherited handlers). Host apps should wrap the card tree with **`InheritedAdaptiveCardHandlers`** for all action callbacks.

- [ ] **Step 1: Delete unused fields from `AdaptiveCardsCanvasState`**

Remove these lines (approx. 209–216):

```dart
  /// Environment specific function that knows how to handle submission to remote APIs
  Function(Map map)? onSubmit;

  /// Environment specific function that knows how to handle execution to remote APIs
  Function(Map map)? onExecute;

  /// Environment specific function that knows how to open a URL on this platform
  Function(String url)? onOpenUrl;
```

Leave **`onChange`** resolution in `didChangeDependencies` unchanged.

- [ ] **Step 2: Grep for references**

Run:

```bash
rg 'AdaptiveCardsCanvasState.*on(Submit|Execute|OpenUrl)|canvasState\\.on(Submit|Execute|OpenUrl)' packages/flutter_adaptive_cards_fs
```

Expected: no matches (fields were never referenced outside the declaration).

- [ ] **Step 3: Analyze**

Run: `cd packages/flutter_adaptive_cards_fs && fvm dart analyze lib/src/adaptive_cards_canvas.dart`

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart
git commit -m "chore: remove unused action handler fields from AdaptiveCardsCanvasState"
```

---

### Task 7: Full package verification

- [ ] **Step 1: Run library test suite**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`

Expected: all pass. Tests that only increment a counter (`onSubmit: (_) => submitCount++`) remain valid.

- [ ] **Step 2: Analyze**

Run: `cd packages/flutter_adaptive_cards_fs && fvm dart analyze`

Expected: no errors.

- [ ] **Step 3: Commit** (only if analyzer/format fixes were needed)

---

### Task 8: CHANGELOG + package README

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`
- Modify: `packages/flutter_adaptive_cards_fs/README.md`

- [ ] **Step 1: CHANGELOG (under new `## [0.10.0]` or next release section)**

```markdown
### Changed

- **`onSubmit` callback** now receives **`SubmitActionInvoke`** instead of a bare `Map`. Use `invoke.actionId` and `invoke.data` (merged action `data` + input values).
- **`onExecute` callback** now receives **`ExecuteActionInvoke`** instead of a bare `Map`. Use `invoke.verb`, `invoke.actionId`, and `invoke.data`.
- **`GenericExecuteAction.tap`** no longer takes a separate `verb` argument; read action metadata from `adaptiveMap` in custom implementations (or delegate to `ExecuteActionInvoke.fromActionMap`).

### Removed

- Unused **`onSubmit`**, **`onExecute`**, and **`onOpenUrl`** fields on **`AdaptiveCardsCanvasState`** (`adaptive_cards_canvas.dart`). Use **`InheritedAdaptiveCardHandlers`** for Submit, Execute, and OpenUrl callbacks.

### Added

- **`SubmitActionInvoke`** and **`ExecuteActionInvoke`** public models exported from `flutter_adaptive_cards_fs.dart`.
- Tests: `test/actions/submit_action_invoke_test.dart`, `test/actions/execute_verb_test.dart`.
```

- [ ] **Step 2: Fix misleading README example**

`packages/flutter_adaptive_cards_fs/README.md` shows `onSubmit` and `onOpenUrl` on `AdaptiveCardsCanvas.network(...)`, but those are not widget constructor parameters — handlers belong on **`InheritedAdaptiveCardHandlers`**. Update the example to wrap the canvas:

```dart
InheritedAdaptiveCardHandlers(
  onSubmit: (SubmitActionInvoke invoke) {
    sendToServer(invoke.data, actionId: invoke.actionId);
  },
  onExecute: (ExecuteActionInvoke invoke) {
    routeExecute(invoke.verb, invoke.data);
  },
  onOpenUrl: (url) { /* open url */ },
  onOpenUrlDialog: (_) {},
  onChange: (_, __, ___, ____) {},
  child: AdaptiveCardsCanvas.network(
    url: 'https://example.com/card.json',
    hostConfigs: HostConfigs(),
  ),
)
```

- [ ] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/CHANGELOG.md \
        packages/flutter_adaptive_cards_fs/README.md
git commit -m "docs: changelog and README for action invoke payload migration"
```

---

### Task 9: Reconcile `docs/` reference documentation

**Scope:** Update **living reference docs** under `docs/` so they match the invoke payload types, **`InheritedAdaptiveCardHandlers`** as the sole Submit/Execute/OpenUrl entry point, and removal of dead **`AdaptiveCardsCanvasState`** handler fields.

**Out of scope for this task:** Historical snapshots in `docs/plans/` and `docs/superpowers/specs/` — do not rewrite completed design/plan archives unless a doc is explicitly linked as current API reference.

**Files:**
- Modify: `docs/actions-architecture.md`
- Modify: `docs/Architecture-Overview.md`
- Modify: `docs/form-inputs.md`
- Modify: `docs/Implementation-Status.md`
- Modify: `docs/reactive-riverpod.md`

- [ ] **Step 1: Audit for stale references**

Run:

```bash
rg -n 'onSubmit|onExecute|onOpenUrl|Function\(Map|gathered input data as a Map|AdaptiveCardsCanvasState' docs \
  --glob '*.md' \
  --glob '!docs/plans/**' \
  --glob '!docs/superpowers/plans/**' \
  --glob '!docs/superpowers/specs/**'
```

Expected hits to fix (minimum set):

| File | Stale content | Fix |
| --- | --- | --- |
| `docs/actions-architecture.md` | No Submit/Execute payload section | Add sections (Step 2) |
| `docs/Architecture-Overview.md` | “receive gathered input data as a `Map`” | Invoke types + `InheritedAdaptiveCardHandlers` (Step 3) |
| `docs/form-inputs.md` | `onSubmit: (data) async` bare Map | `SubmitActionInvoke` + `invoke.data` (Step 4) |
| `docs/Implementation-Status.md` | Action.Submit / Execute notes | Rows + Known Gaps (Step 5) |
| `docs/reactive-riverpod.md` | Host callbacks paragraph | Invoke payload note (Step 6) |

- [ ] **Step 2: `docs/actions-architecture.md` — add after "Typical Flow"**

```markdown
## Host action callbacks

Submit, Execute, and OpenUrl are **not** configured on `AdaptiveCardsCanvas` or `AdaptiveCardsCanvasState`. Wrap the card with **`InheritedAdaptiveCardHandlers`**.

## Action.Submit payload

When **`DefaultSubmitAction`** runs:

1. Start from action JSON **`data`** (object or empty).
2. Merge **`collectInputValues()`** (input ids overwrite duplicate keys in `data`).
3. Build **`SubmitActionInvoke`** with merged **`data`** and action **`id`** (`actionId`).
4. Call **`InheritedAdaptiveCardHandlers.onSubmit(invoke)`**.

## Action.Execute payload

When **`DefaultExecuteAction`** runs:

1. Start from action JSON **`data`** (object or empty).
2. Merge **`collectInputValues()`** (input ids overwrite duplicate keys in `data`).
3. Build **`ExecuteActionInvoke`** with merged **`data`**, action **`verb`**, and action **`id`** (`actionId`).
4. Call **`InheritedAdaptiveCardHandlers.onExecute(invoke)`**.

Hosts route Teams-style Execute actions on **`invoke.verb`**. **`associatedInputs`** is not yet honored for Submit or Execute — all card inputs are always collected (see [Implementation-Status.md](./Implementation-Status.md#known-gaps)).
```

- [ ] **Step 3: `docs/Architecture-Overview.md`**

Replace Consumer API step 3 (approx. line 60):

```markdown
3. Wrap the card with **`InheritedAdaptiveCardHandlers`** for Submit, Execute, OpenUrl, and input **`onChange`** callbacks. **`onSubmit`** receives **`SubmitActionInvoke`** (`actionId` + merged input/`data` map); **`onExecute`** receives **`ExecuteActionInvoke`** (`verb`, `actionId`, merged map). **`AdaptiveCardsCanvas`** accepts **`onChange`** directly; it does **not** expose Submit/Execute/OpenUrl handlers on the widget or its state.
```

In the **Actions** bullet (step 7), optionally add: “Submit/Execute payloads are typed invoke objects, not raw maps.”

Fix broken link if present: [`doc/reactive-riverpod.md`](reactive-riverpod.md) → [`reactive-riverpod.md`](reactive-riverpod.md) (file lives under `docs/`).

- [ ] **Step 4: `docs/form-inputs.md` — remote validation example**

Replace the example block (approx. lines 25–39):

```dart
onSubmit: (SubmitActionInvoke invoke) async {
  final errors = await validate(invoke.data);
  cardState.applyUpdates(
    elements: errors.entries.map(
      (e) => AdaptiveElementUpdate(
        id: e.key,
        errorMessage: e.value,
        isInvalid: true,
      ),
    ),
  );
},
```

Add one sentence above the example: “Wire this on **`InheritedAdaptiveCardHandlers`**, not on **`AdaptiveCardsCanvas`**. Use **`invoke.data`** for merged input values; use **`invoke.actionId`** when routing by action `id`.”

- [ ] **Step 5: `docs/Implementation-Status.md`**

**Actions table** — update Submit and Execute **Notes** columns:

```markdown
| Action.Submit  | ... | ✅ Complete | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | **`id`** as **`actionId`** via **`SubmitActionInvoke`** on `onSubmit`; merged `data` + inputs. **`associatedInputs`** not implemented — see [Known Gaps](#known-gaps). |
| Action.Execute | ... | ✅ Complete | ✅ Yes | [actions-architecture.md](./actions-architecture.md) | **`verb`** and **`id`** via **`ExecuteActionInvoke`** on `onExecute`; merged `data` + inputs. **`associatedInputs`** not implemented — see [Known Gaps](#known-gaps). |
```

**Known Gaps** — add:

```markdown
- **`Action.Submit.associatedInputs`** / **`Action.Execute.associatedInputs`**: All inputs on the card are always collected and merged into invoke `data`; per-action `associatedInputs` (`auto` / `none`) is not implemented.
```

- [ ] **Step 6: `docs/reactive-riverpod.md`**

Expand the host callbacks sentence (approx. line 227):

```markdown
Host callbacks (`onSubmit`, `onExecute`, `onOpenUrl`, `onChange`, …) remain on **`InheritedAdaptiveCardHandlers`**. These are host integration points, not reactive document state. **`onSubmit`** receives **`SubmitActionInvoke`** (`actionId`, merged `data`); **`onExecute`** receives **`ExecuteActionInvoke`** (`verb`, `actionId`, merged `data`). *(Phase 2 Task 17 documents **`OpenUrlActionInvoke`**, **`OpenUrlDialogActionInvoke`**, and **`InputChangeInvoke`**.)*
```

- [ ] **Step 7: Re-run audit — expect clean**

Run the Step 1 `rg` command again.

Expected: no remaining stale “bare Map” handler docs in scoped files (grep hits inside this plan file or code blocks describing migration “Before” are OK).

- [ ] **Step 8: Commit**

```bash
git add docs/actions-architecture.md \
        docs/Architecture-Overview.md \
        docs/form-inputs.md \
        docs/Implementation-Status.md \
        docs/reactive-riverpod.md
git commit -m "docs: reconcile docs/ with SubmitActionInvoke and ExecuteActionInvoke"
```

---

## Phase 2 — OpenUrl / OpenUrlDialog / onChange

### Task 10: OpenUrl + InputChange invoke models

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart`

- [ ] **Step 1: Add three invoke types to `action_invoke.dart`**

```dart
/// Payload delivered to the host `onOpenUrl` callback.
class OpenUrlActionInvoke {
  const OpenUrlActionInvoke({
    required this.url,
    this.actionId,
  });

  factory OpenUrlActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap, {
    String? altUrl,
  }) {
    final urlFromMap = actionMap['url'] as String?;
    return OpenUrlActionInvoke(
      url: altUrl ?? urlFromMap ?? '',
      actionId: actionIdFromMap(actionMap),
    );
  }

  final String url;
  final String? actionId;
}

/// Payload delivered to the host `onOpenUrlDialog` callback.
class OpenUrlDialogActionInvoke {
  const OpenUrlDialogActionInvoke({
    required this.url,
    this.actionId,
  });

  factory OpenUrlDialogActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap, {
    String? altUrl,
  }) {
    final urlFromMap = actionMap['url'] as String?;
    return OpenUrlDialogActionInvoke(
      url: altUrl ?? urlFromMap ?? '',
      actionId: actionIdFromMap(actionMap),
    );
  }

  final String url;
  final String? actionId;
}

/// Payload delivered to the host `onChange` callback when an input value changes.
class InputChangeInvoke {
  const InputChangeInvoke({
    required this.inputId,
    required this.value,
    required this.cardState,
    this.dataQuery,
  });

  final String inputId;
  final dynamic value;
  final DataQuery? dataQuery;
  final RawAdaptiveCardState cardState;
}
```

Add import for `DataQuery` and `RawAdaptiveCardState` at top of `action_invoke.dart`.

- [ ] **Step 2: Analyze**

Run: `cd packages/flutter_adaptive_cards_fs && fvm dart analyze lib/src/models/action_invoke.dart`

- [ ] **Step 3: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart
git commit -m "feat: add OpenUrl and InputChange invoke payload types"
```

---

### Task 11: Handler + RawAdaptiveCard + canvas typedefs

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart`

- [ ] **Step 1: Update `InheritedAdaptiveCardHandlers`**

```dart
  final void Function(OpenUrlActionInvoke invoke) onOpenUrl;
  final void Function(OpenUrlDialogActionInvoke invoke) onOpenUrlDialog;
  final void Function(InputChangeInvoke invoke) onChange;
```

- [ ] **Step 2: Update `RawAdaptiveCard` / `RawAdaptiveCardState` `onChange` field**

Replace the four-parameter function type with:

```dart
  final void Function(InputChangeInvoke invoke)? onChange;
```

In the input notification method (approx. line 264), replace:

```dart
widget.onChange?.call(id, value, dataQuery, this);
```

with:

```dart
widget.onChange?.call(
  InputChangeInvoke(
    inputId: id,
    value: value,
    dataQuery: dataQuery,
    cardState: this,
  ),
);
```

- [ ] **Step 3: Update `AdaptiveCardsCanvas` widget + state `onChange`**

Change both the widget constructor field and `AdaptiveCardsCanvasState.onChange` to:

```dart
  void Function(InputChangeInvoke invoke)? onChange;
```

Update the debug fallback in `didChangeDependencies`:

```dart
onChange = (invoke) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'No custom handler found for onChange: \n ${invoke.inputId}',
      ),
    ),
  );
};
```

- [ ] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart \
        packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart \
        packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart
git commit -m "refactor: type onOpenUrl/onOpenUrlDialog/onChange invoke callbacks"
```

---

### Task 12: DefaultOpenUrl handlers (TDD)

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/test/actions/open_url_action_invoke_test.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/actions/open_url_dialog_action_invoke_test.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`
- Modify: `packages/flutter_adaptive_cards_fs/test/utils/test_utils.dart`

- [ ] **Step 1: Write failing OpenUrl tests**

```dart
// open_url_action_invoke_test.dart — Action.OpenUrl with id + url
// Expect captured.actionId == 'open-1', captured.url == 'https://example.com'
```

```dart
// open_url_dialog_action_invoke_test.dart — Action.OpenUrlDialog with id + url
// Same shape; hits onOpenUrlDialog callback
```

- [ ] **Step 2: Update `test_utils.dart` typedefs**

```dart
void Function(OpenUrlActionInvoke invoke)? onOpenUrl,
void Function(OpenUrlDialogActionInvoke invoke)? onOpenUrlDialog,
void Function(InputChangeInvoke invoke)? onChange,
```

Defaults: `onOpenUrl ?? (_) {}`, etc.

- [ ] **Step 3: Implement `DefaultOpenUrlAction` / `DefaultOpenUrlDialogAction`**

```dart
    final invoke = OpenUrlActionInvoke.fromActionMap(
      adaptiveMap,
      altUrl: altUrl,
    );
    if (invoke.url.isEmpty) return;

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onOpenUrl(invoke);
    }
```

(Same pattern for `OpenUrlDialogActionInvoke` → `onOpenUrlDialog`.)

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/actions/open_url_action_invoke_test.dart test/actions/open_url_dialog_action_invoke_test.dart
```

- [ ] **Step 5: Commit**

---

### Task 13: selectAction OpenUrl + test_utils migration

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/test/select_action_tappable_test.dart`
- Modify: `packages/flutter_adaptive_charts_fs/test/utils/test_utils.dart`

- [ ] **Step 1: Update `buildCard` helper signatures**

```dart
required void Function(OpenUrlActionInvoke invoke) onOpenUrl,
required void Function(InputChangeInvoke invoke)? onChange, // optional if unused
```

- [ ] **Step 2: Add selectAction OpenUrl test with `actionId`**

Container `selectAction`: `{ "type": "Action.OpenUrl", "id": "container-open", "url": "https://example.com/container" }` — assert `actionId` and `url`.

- [ ] **Step 3: Update existing OpenUrl tests** — callbacks receive invoke types (`invoke.url` instead of bare url param where captured).

- [ ] **Step 4: Mirror charts `test_utils.dart`**

- [ ] **Step 5: Commit**

---

### Task 14: InputChangeInvoke — tests + call sites

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/test/inputs/choice_set_data_query_test.dart`
- Modify: `packages/flutter_adaptive_cards_fs/test/inputs/choice_set_test.dart`
- Modify: `packages/flutter_adaptive_cards_fs/test/inputs/dependent_choice_set_test.dart`
- Modify: `packages/flutter_adaptive_cards_fs/test/utils/dependent_choice_set_handler.dart`
- Modify: `widgetbook/lib/dependent_choice_set_demo_page.dart`

- [ ] **Step 1: Migrate `handleDependentChoiceSetChange`**

```dart
void handleDependentChoiceSetChange(InputChangeInvoke invoke) {
  if (invoke.inputId == 'country') {
    final countryCode = countryCodeFromOnChangeValue(invoke.value);
    // ...
    invoke.cardState.applyUpdates(...)
  }
  if (invoke.inputId == 'city' && invoke.dataQuery?.dataset == 'cities') {
    // ...
  }
}
```

Apply the same change in **`widgetbook/lib/dependent_choice_set_demo_page.dart`**.

- [ ] **Step 2: Update widget tests**

Replace `(id, value, dataQuery, cardState)` lambdas with `(invoke) => ...` using `invoke.inputId`, `invoke.value`, `invoke.dataQuery`, `invoke.cardState`.

Key files: `choice_set_data_query_test.dart`, `choice_set_test.dart`, `dependent_choice_set_test.dart`.

- [ ] **Step 3: Run affected tests**

```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/choice_set_data_query_test.dart test/inputs/choice_set_test.dart test/inputs/dependent_choice_set_test.dart test/select_action_tappable_test.dart --exclude-tags=golden
```

- [ ] **Step 4: Commit**

---

### Task 15: Full package verification

- [ ] **Step 1:** `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`
- [ ] **Step 2:** `cd packages/flutter_adaptive_cards_fs && fvm dart analyze lib/`
- [ ] **Step 3:** `cd ../flutter_adaptive_charts_fs && fvm flutter test --exclude-tags=golden` (if any tests exist beyond goldens)

---

### Task 16: CHANGELOG + README (Phase 2)

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`
- Modify: `packages/flutter_adaptive_cards_fs/README.md`

- [ ] **Step 1: Extend CHANGELOG under `## [0.10.0]` (or next release)**

```markdown
### Changed (Phase 2)

- **`onOpenUrl`** now receives **`OpenUrlActionInvoke`** (`url`, optional `actionId`) instead of a bare `String`.
- **`onOpenUrlDialog`** now receives **`OpenUrlDialogActionInvoke`** (`url`, optional `actionId`) instead of a bare `String`.
- **`onChange`** now receives **`InputChangeInvoke`** (`inputId`, `value`, `dataQuery`, `cardState`) instead of four separate parameters.
- **`AdaptiveCardsCanvas.onChange`** and **`RawAdaptiveCard.onChange`** use the same **`InputChangeInvoke`** type.

### Added (Phase 2)

- **`OpenUrlActionInvoke`**, **`OpenUrlDialogActionInvoke`**, **`InputChangeInvoke`** exported from `flutter_adaptive_cards_fs.dart`.
```

- [ ] **Step 2: Update README handler example** — show all five invoke types on `InheritedAdaptiveCardHandlers`.

- [ ] **Step 3: Commit**

---

### Task 17: Reconcile `docs/` (Phase 2)

**Files:** `docs/actions-architecture.md`, `docs/form-inputs.md`, `docs/Architecture-Overview.md`, `docs/reactive-riverpod.md`, `docs/Implementation-Status.md`

- [ ] **Step 1: Audit**

```bash
rg -n 'onOpenUrl|onOpenUrlDialog|onChange.*String id|Function\(String url\)' docs \
  --glob '*.md' \
  --glob '!docs/plans/**' \
  --glob '!docs/superpowers/plans/**' \
  --glob '!docs/superpowers/specs/**'
```

- [ ] **Step 2: `docs/actions-architecture.md`** — add sections:

```markdown
## Action.OpenUrl payload
`DefaultOpenUrlAction` → `OpenUrlActionInvoke` (`url`, `actionId`) → `onOpenUrl`.

## Action.OpenUrlDialog payload
`DefaultOpenUrlDialogAction` → `OpenUrlDialogActionInvoke` → `onOpenUrlDialog`.

## Input onChange payload
`RawAdaptiveCardState` → `InputChangeInvoke` (`inputId`, `value`, `dataQuery`, `cardState`) → `onChange`.
```

- [ ] **Step 3: `docs/form-inputs.md`** — update dependent ChoiceSet handler example to `InputChangeInvoke`; update remote validation note if it references old onChange shape.

- [ ] **Step 4: `docs/reactive-riverpod.md` + `Architecture-Overview.md`** — document all five invoke types; note `AdaptiveCardsCanvas.onChange` accepts `InputChangeInvoke` directly.

- [ ] **Step 5: `docs/Implementation-Status.md`** — optional Notes tweak on Action.OpenUrl / Action.OpenUrlDialog rows mentioning invoke types.

- [ ] **Step 6: Commit**

---

## Out of scope (document only)

| Item                                                         | Reason                                                     |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| `associatedInputs` on Submit/Execute                         | Separate feature; note remains in Known Gaps               |
| Full UAM invoke envelope (`trigger`, nested `action` object) | YAGNI until a host requests Bot Framework parity           |
| Async invoke return / card refresh response                  | Existing non-goal from dynamic-updates design              |

---

## Self-review (spec coverage)

| Requirement | Task |
| --- | --- |
| Submit `actionId` + merged `data` on `onSubmit` | Phase 1: Tasks 1, 3 |
| Execute `verb` + `actionId` + merged `data` on `onExecute` | Phase 1: Tasks 1, 4 |
| `selectAction` Submit gets `actionId` | Phase 1: Task 5 |
| `selectAction` Execute gets `verb` | Phase 1: Task 5 |
| Remove dead canvas action handler fields | Phase 1: Task 6 |
| OpenUrl `url` + `actionId` on `onOpenUrl` | Phase 2: Tasks 10, 12 |
| OpenUrlDialog `url` + `actionId` on `onOpenUrlDialog` | Phase 2: Tasks 10, 12 |
| `selectAction` OpenUrl gets `actionId` | Phase 2: Task 13 |
| Input `onChange` typed as `InputChangeInvoke` | Phase 2: Tasks 11, 14 |
| Canvas / RawAdaptiveCard `onChange` aligned | Phase 2: Task 11 |
| CHANGELOG + README (both phases) | Tasks 8, 16 |
| `docs/` reconciled (both phases) | Tasks 9, 17 |

No placeholders remain; all code blocks are copy-paste ready.

---

## Host migration snippets

### Phase 1 — Submit / Execute

```dart
// Before
onSubmit: (Map map) => sendToServer(map),
onExecute: (Map map) => route(map),

// After
onSubmit: (SubmitActionInvoke invoke) =>
    sendToServer(invoke.data, actionId: invoke.actionId),
onExecute: (ExecuteActionInvoke invoke) =>
    routeExecute(invoke.verb, invoke.data),
```

### Phase 2 — OpenUrl / OpenUrlDialog / onChange

```dart
// Before
onOpenUrl: (String url) => launchUrl(Uri.parse(url)),
onOpenUrlDialog: (String url) => showDialogFor(url),
onChange: (String id, dynamic value, DataQuery? dq, RawAdaptiveCardState s) {
  if (id == 'country') s.applyUpdates(...);
},

// After
onOpenUrl: (OpenUrlActionInvoke invoke) =>
    launchUrl(Uri.parse(invoke.url)),
onOpenUrlDialog: (OpenUrlDialogActionInvoke invoke) =>
    showDialogFor(invoke.url),
onChange: (InputChangeInvoke invoke) {
  if (invoke.inputId == 'country') {
    invoke.cardState.applyUpdates(...);
  }
  final query = invoke.dataQuery;
},
```
