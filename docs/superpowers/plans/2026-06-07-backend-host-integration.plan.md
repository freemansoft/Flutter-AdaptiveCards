# Backend Host Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phase 1 adds Teams `associatedInputs` support in `flutter_adaptive_cards_fs`; Phase 2 adds optional `flutter_adaptive_cards_host_fs` for serialize → POST → parse → `applyTo` backend round-trips.

**Architecture:** Phase 1 extends `DataQuery` and `DefaultSubmitAction`/`DefaultExecuteAction` with shared merge helpers in `associated_inputs.dart`. Phase 2 is a new workspace package exporting request/response models, PlainJson + Teams adapters, `HttpAdaptiveCardBackendClient`, and `AdaptiveCardBackendHandlers` wired to `InheritedAdaptiveCardHandlers`.

**Tech Stack:** Dart 3.12+, Flutter (FVM), Riverpod 3.x, `flutter_adaptive_cards_fs`, `http`, `package:flutter_test`, `very_good_analysis`.

**Spec:** [`docs/superpowers/specs/2026-06-07-backend-host-integration-design.md`](../specs/2026-06-07-backend-host-integration-design.md)

---

## File map

### Phase 1 — `flutter_adaptive_cards_fs`

| File | Role |
| --- | --- |
| `lib/src/utils/associated_inputs.dart` | **Create** — merge helpers |
| `lib/src/models/data_query.dart` | `associatedInputs` + `withMergedSiblingInputs` |
| `lib/src/cards/inputs/choice_set.dart` | Enrich `dataQuery` before `changeValue` |
| `lib/src/action/default_actions.dart` | Honor Submit/Execute `associatedInputs` |
| `lib/flutter_adaptive_cards_fs.dart` | Export `associated_inputs.dart` if public helpers needed (optional — keep internal unless exported) |
| `test/utils/associated_inputs_test.dart` | **Create** — unit tests |
| `test/inputs/choice_set_data_query_test.dart` | associatedInputs merge widget test |
| `test/inputs/dependent_choice_set_test.dart` | city branch uses `parameters['country']` |
| `test/actions/submit_action_invoke_test.dart` | `associatedInputs: none` test |
| `test/actions/execute_verb_test.dart` | `associatedInputs: none` test |
| `test/utils/dependent_choice_set_handler.dart` | Phase 2 city branch uses `dataQuery.parameters` |
| `widgetbook/lib/dependent_choice_set_demo_page.dart` | Simplify Option 2 handler |
| `docs/form-inputs.md` | Close gap paragraphs |
| `docs/Implementation-Status.md` | Remove Known Gaps entries |
| `docs/reactive-riverpod.md` | associatedInputs note |
| `docs/actions-architecture.md` | Submit/Execute associatedInputs |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md` | 0.10.0 entry |

### Phase 2 — `flutter_adaptive_cards_host_fs`

| File | Role |
| --- | --- |
| `packages/flutter_adaptive_cards_host_fs/pubspec.yaml` | **Create** — workspace package |
| `packages/flutter_adaptive_cards_host_fs/analysis_options.yaml` | **Create** — `very_good_analysis` |
| `packages/flutter_adaptive_cards_host_fs/lib/flutter_adaptive_cards_host_fs.dart` | Barrel export |
| `lib/src/models/invoke_kind.dart` | `AdaptiveCardInvokeKind` enum |
| `lib/src/models/invoke_request.dart` | `AdaptiveCardInvokeRequest` + factories |
| `lib/src/models/invoke_effect.dart` | Sealed effect types |
| `lib/src/models/invoke_response.dart` | `AdaptiveCardInvokeResponse` + `applyTo` |
| `lib/src/adapters/plain_json_invoke_adapter.dart` | Flat request/response maps |
| `lib/src/adapters/teams_invoke_adapter.dart` | Teams-shaped maps |
| `lib/src/client/backend_client.dart` | Abstract client |
| `lib/src/client/http_backend_client.dart` | HTTP POST implementation |
| `lib/src/handlers/backend_handlers.dart` | `AdaptiveCardBackendHandlers` |
| `test/models/invoke_request_test.dart` | Request factory tests |
| `test/adapters/plain_json_invoke_adapter_test.dart` | Adapter round-trip |
| `test/adapters/teams_invoke_adapter_test.dart` | Teams adapter tests |
| `test/models/invoke_response_test.dart` | Parser + `applyTo` tests |
| `test/handlers/backend_handlers_test.dart` | End-to-end handler widget test |
| `pubspec.yaml` (repo root) | Add package to `workspace:` |
| `packages/flutter_adaptive_cards_host_fs/README.md` | Usage + response contract |
| `packages/flutter_adaptive_cards_host_fs/CHANGELOG.md` | Initial release notes |

---

## Phase 1 — Renderer `associatedInputs`

### Task 1: Shared merge helpers

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/utils/associated_inputs.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/utils/associated_inputs_test.dart`

- [ ] **Step 1: Write failing unit tests**

Create `associated_inputs_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldMergeAssociatedInputs', () {
    test('null defaults to auto', () {
      expect(shouldMergeAssociatedInputs(null), isTrue);
    });
    test('auto merges', () {
      expect(shouldMergeAssociatedInputs('auto'), isTrue);
    });
    test('none skips merge', () {
      expect(shouldMergeAssociatedInputs('none'), isFalse);
    });
  });

  group('mergeSiblingInputParameters', () {
    test('excludes firing input and preserves author parameters', () {
      final result = mergeSiblingInputParameters(
        siblingValues: {'country': 'usa', 'city': 'nyc'},
        excludeInputId: 'city',
        existingParameters: {'dataset': 'cities'},
      );
      expect(result, {
        'dataset': 'cities',
        'country': 'usa',
      });
      expect(result.containsKey('city'), isFalse);
    });
  });

  group('mergeActionData', () {
    test('none returns action data only', () {
      final data = mergeActionData(
        actionData: {'foo': 'bar'},
        inputValues: {'email': 'a@b.com'},
        associatedInputs: 'none',
      );
      expect(data, {'foo': 'bar'});
    });

    test('auto merges inputs over action data keys', () {
      final data = mergeActionData(
        actionData: {'foo': 'bar', 'email': 'old'},
        inputValues: {'email': 'new'},
        associatedInputs: null,
      );
      expect(data, {'foo': 'bar', 'email': 'new'});
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/utils/associated_inputs_test.dart`

Expected: FAIL — library/file not found

- [ ] **Step 3: Implement helpers**

Create `associated_inputs.dart`:

```dart
/// Whether sibling inputs should be merged (Teams default: auto when omitted).
bool shouldMergeAssociatedInputs(String? associatedInputs) {
  return associatedInputs != 'none';
}

/// Merges [siblingValues] into [existingParameters], excluding [excludeInputId].
Map<String, dynamic> mergeSiblingInputParameters({
  required Map<String, dynamic> siblingValues,
  required String excludeInputId,
  Map<String, dynamic>? existingParameters,
}) {
  final params = Map<String, dynamic>.from(existingParameters ?? {});
  for (final entry in siblingValues.entries) {
    if (entry.key == excludeInputId) continue;
    params[entry.key] = entry.value;
  }
  return params;
}

/// Builds Submit/Execute invoke `data` honoring [associatedInputs].
Map<String, dynamic> mergeActionData({
  required Map<String, dynamic> actionData,
  required Map<String, dynamic> inputValues,
  required String? associatedInputs,
}) {
  if (!shouldMergeAssociatedInputs(associatedInputs)) {
    return Map<String, dynamic>.from(actionData);
  }
  final merged = Map<String, dynamic>.from(actionData);
  merged.addAll(inputValues);
  return merged;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/utils/associated_inputs_test.dart`

Expected: PASS (all tests)

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/utils/associated_inputs.dart \
  packages/flutter_adaptive_cards_fs/test/utils/associated_inputs_test.dart
git commit -m "feat: add associatedInputs merge helpers for backend invoke payloads"
```

---

### Task 2: `DataQuery.associatedInputs` model

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/data_query.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/models/data_query_test.dart` (**Create** if missing, else extend)

- [ ] **Step 1: Write failing test**

```dart
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson parses associatedInputs', () {
    final q = DataQuery.fromJson({
      'type': 'Data.Query',
      'dataset': 'cities',
      'associatedInputs': 'none',
    });
    expect(q.associatedInputs, 'none');
  });

  test('withMergedSiblingInputs merges when auto', () {
    final q = DataQuery.fromJson({
      'type': 'Data.Query',
      'dataset': 'cities',
      'associatedInputs': 'auto',
    });
    final merged = q.withMergedSiblingInputs(
      {'country': 'usa', 'city': 'nyc'},
      excludeInputId: 'city',
    );
    expect(merged.parameters?['country'], 'usa');
    expect(merged.parameters?.containsKey('city'), isFalse);
    expect(merged.dataset, 'cities');
  });

  test('withMergedSiblingInputs no-op when none', () {
    final q = DataQuery.fromJson({
      'type': 'Data.Query',
      'dataset': 'cities',
      'associatedInputs': 'none',
      'parameters': {'x': 1},
    });
    final merged = q.withMergedSiblingInputs(
      {'country': 'usa'},
      excludeInputId: 'city',
    );
    expect(merged.parameters, {'x': 1});
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/models/data_query_test.dart`

- [ ] **Step 3: Extend `DataQuery`**

Add to `data_query.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';

// In class:
final String? associatedInputs;

// fromJson:
associatedInputs: json['associatedInputs'] as String?,

// toJson:
if (associatedInputs != null) 'associatedInputs': associatedInputs,

DataQuery withMergedSiblingInputs(
  Map<String, dynamic> siblingValues, {
  required String excludeInputId,
}) {
  if (!shouldMergeAssociatedInputs(associatedInputs)) {
    return this;
  }
  return DataQuery(
    dataset: dataset,
    count: count,
    skip: skip,
    associatedInputs: associatedInputs,
    parameters: mergeSiblingInputParameters(
      siblingValues: siblingValues,
      excludeInputId: excludeInputId,
      existingParameters: parameters,
    ),
  );
}
```

- [ ] **Step 4: Run test — expect PASS**

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/data_query.dart \
  packages/flutter_adaptive_cards_fs/test/models/data_query_test.dart
git commit -m "feat: parse Data.Query associatedInputs and merge sibling inputs"
```

---

### Task 3: Wire ChoiceSet → enriched `dataQuery` on `onChange`

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/choice_set.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/inputs/choice_set_data_query_test.dart`

- [ ] **Step 1: Write failing widget test**

Add to `choice_set_data_query_test.dart`:

```dart
testWidgets('Data.Query associatedInputs auto merges country into parameters', (
  WidgetTester tester,
) async {
  DataQuery? captured;
  final map = {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'Input.ChoiceSet',
        'id': 'country',
        'choices': [
          {'title': 'USA', 'value': 'usa'},
        ],
        'value': 'usa',
      },
      {
        'type': 'Input.ChoiceSet',
        'id': 'city',
        'choices': [
          {'title': 'NYC', 'value': 'nyc'},
        ],
        'choices.data': {
          'type': 'Data.Query',
          'dataset': 'cities',
          'associatedInputs': 'auto',
        },
      },
    ],
  };

  await tester.pumpWidget(
    getTestWidgetFromMap(
      map: map,
      title: 'associatedInputs merge',
      onChange: (invoke) {
        if (invoke.inputId == 'city') captured = invoke.dataQuery;
      },
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(
      generateWidgetKey(
        (map['body'] as List)[1] as Map<String, dynamic>,
        suffix: 'NYC',
      ),
    ),
  );
  await tester.pump();

  expect(captured, isNotNull);
  expect(captured!.parameters?['country'], 'usa');
});
```

- [ ] **Step 2: Run test — expect FAIL** (`parameters` null or missing `country`)

- [ ] **Step 3: Implement in `choice_set.dart` `select` path**

Before `rawRootCardWidgetState.changeValue(id, choice, dataQuery: dataQuery)`:

```dart
DataQuery? queryForHost = dataQuery;
if (dataQuery != null) {
  final values = ref
      .read(adaptiveCardDocumentProvider.notifier)
      .collectInputValues();
  queryForHost = dataQuery!.withMergedSiblingInputs(
    values,
    excludeInputId: id,
  );
}
rawRootCardWidgetState.changeValue(id, choice, dataQuery: queryForHost);
```

Update class doc comment: remove "not applied yet" note.

- [ ] **Step 4: Run test — expect PASS**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/choice_set_data_query_test.dart`

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/choice_set.dart \
  packages/flutter_adaptive_cards_fs/test/inputs/choice_set_data_query_test.dart
git commit -m "feat: merge associatedInputs into Data.Query on ChoiceSet onChange"
```

---

### Task 4: Submit / Execute `associatedInputs`

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/actions/submit_action_invoke_test.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/actions/execute_verb_test.dart`

- [ ] **Step 1: Write failing tests**

In `submit_action_invoke_test.dart`, add:

```dart
testWidgets('associatedInputs none excludes input values from invoke.data', (
  WidgetTester tester,
) async {
  SubmitActionInvoke? captured;
  final map = {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {'type': 'Input.Text', 'id': 'email', 'value': 'secret@x.com'},
    ],
    'actions': [
      {
        'type': 'Action.Submit',
        'title': 'Go',
        'associatedInputs': 'none',
        'data': {'actionOnly': true},
      },
    ],
  };
  await tester.pumpWidget(
    getTestWidgetFromMap(
      map: map,
      onSubmit: (invoke) => captured = invoke,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Go'));
  await tester.pump();
  expect(captured!.data, {'actionOnly': true});
  expect(captured!.data.containsKey('email'), isFalse);
});
```

Mirror for Execute in `execute_verb_test.dart` with `associatedInputs: 'none'`.

- [ ] **Step 2: Run tests — expect FAIL**

- [ ] **Step 3: Update `DefaultSubmitAction` and `DefaultExecuteAction`**

Replace manual `data.addAll(values)` with:

```dart
import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';

final data = mergeActionData(
  actionData: (adaptiveMap['data'] as Map<String, dynamic>?) != null
      ? Map<String, dynamic>.from(adaptiveMap['data'] as Map)
      : <String, dynamic>{},
  inputValues: values,
  associatedInputs: adaptiveMap['associatedInputs'] as String?,
);
```

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart \
  packages/flutter_adaptive_cards_fs/test/actions/submit_action_invoke_test.dart \
  packages/flutter_adaptive_cards_fs/test/actions/execute_verb_test.dart
git commit -m "feat: honor associatedInputs on Action.Submit and Action.Execute"
```

---

### Task 5: Dependent ChoiceSet tests + handler + Widgetbook

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/test/utils/dependent_choice_set_handler.dart`
- Modify: `packages/flutter_adaptive_cards_fs/test/inputs/dependent_choice_set_test.dart`
- Modify: `widgetbook/lib/dependent_choice_set_demo_page.dart`

- [ ] **Step 1: Update test handler city branch**

In `dependent_choice_set_handler.dart`, replace empty city branch with:

```dart
if (invoke.inputId == 'city' && invoke.dataQuery?.dataset == 'cities') {
  final countryCode = invoke.dataQuery?.parameters?['country']?.toString();
  final choices = countryCode == null
      ? const <Choice>[]
      : citiesByCountry[countryCode] ?? const <Choice>[];
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (!invoke.cardState.mounted) return;
    invoke.cardState.applyUpdates(
      elements: [
        AdaptiveElementUpdate(
          id: 'city',
          choices: choices,
          clearValue: true,
          clearError: true,
        ),
      ],
    );
  });
}
```

Keep country branch as fallback for cards without `associatedInputs` or for reset timing.

- [ ] **Step 2: Add widget test asserting `parameters['country']`**

In `dependent_choice_set_test.dart`, pump `value_changed_action_dependent_query.json`, select country then city, assert city `onChange` received `dataQuery.parameters['country']`.

- [ ] **Step 3: Sync Widgetbook demo page** with same handler logic; update doc comment (Phase 2 complete).

- [ ] **Step 4: Run tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/dependent_choice_set_test.dart`

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/test/utils/dependent_choice_set_handler.dart \
  packages/flutter_adaptive_cards_fs/test/inputs/dependent_choice_set_test.dart \
  widgetbook/lib/dependent_choice_set_demo_page.dart
git commit -m "feat: dependent ChoiceSet handler uses Data.Query associatedInputs parameters"
```

---

### Task 6: Phase 1 documentation

**Files:**

- Modify: `docs/form-inputs.md`, `docs/Implementation-Status.md`, `docs/reactive-riverpod.md`, `docs/actions-architecture.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [ ] **Step 1: Remove Known Gaps** for `Data.Query.associatedInputs` and Submit/Execute `associatedInputs` in `Implementation-Status.md`.

- [ ] **Step 2: Update `form-inputs.md`** — replace "Gap (planned)" with implemented behavior; document `parameters['country']` in Option 2 handler example.

- [ ] **Step 3: Update `actions-architecture.md`** — document `associatedInputs: none` on Submit/Execute.

- [ ] **Step 4: CHANGELOG** under 0.10.0:

```markdown
- **Data.Query `associatedInputs`:** sibling input values merged into `DataQuery.parameters` on `InputChangeInvoke` when `auto` (default).
- **Action.Submit / Action.Execute `associatedInputs`:** `"none"` skips input merge into invoke `data`.
```

- [ ] **Step 5: Commit**

```bash
git add docs/form-inputs.md docs/Implementation-Status.md docs/reactive-riverpod.md \
  docs/actions-architecture.md packages/flutter_adaptive_cards_fs/CHANGELOG.md
git commit -m "docs: document associatedInputs backend invoke support"
```

---

## Phase 2 — `flutter_adaptive_cards_host_fs`

### Task 7: Scaffold host package

**Files:**

- Create: `packages/flutter_adaptive_cards_host_fs/pubspec.yaml`
- Create: `packages/flutter_adaptive_cards_host_fs/analysis_options.yaml`
- Create: `packages/flutter_adaptive_cards_host_fs/lib/flutter_adaptive_cards_host_fs.dart`
- Modify: `pubspec.yaml` (repo root)

- [ ] **Step 1: Create `pubspec.yaml`**

```yaml
name: flutter_adaptive_cards_host_fs
description: Backend invoke bridge for Flutter Adaptive Cards — request serialization, response parsing, and handler wiring.
version: 0.1.0
homepage: https://github.com/freemansoft/Flutter-AdaptiveCards
repository: https://github.com/freemansoft/Flutter-AdaptiveCards

environment:
  sdk: ^3.12.0
resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  flutter_adaptive_cards_fs: ^0.10.0
  http: ^1.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^10.2.0
```

- [ ] **Step 2: `analysis_options.yaml`**

```yaml
include: package:very_good_analysis/analysis_options.yaml
linter:
  rules:
    public_member_api_docs: false
```

- [ ] **Step 3: Barrel file**

```dart
library;

export 'package:flutter_adaptive_cards_host_fs/src/adapters/plain_json_invoke_adapter.dart';
export 'package:flutter_adaptive_cards_host_fs/src/adapters/teams_invoke_adapter.dart';
export 'package:flutter_adaptive_cards_host_fs/src/client/backend_client.dart';
export 'package:flutter_adaptive_cards_host_fs/src/client/http_backend_client.dart';
export 'package:flutter_adaptive_cards_host_fs/src/handlers/backend_handlers.dart';
export 'package:flutter_adaptive_cards_host_fs/src/models/invoke_effect.dart';
export 'package:flutter_adaptive_cards_host_fs/src/models/invoke_kind.dart';
export 'package:flutter_adaptive_cards_host_fs/src/models/invoke_request.dart';
export 'package:flutter_adaptive_cards_host_fs/src/models/invoke_response.dart';
```

- [ ] **Step 4: Add to root workspace**

In repo root `pubspec.yaml`:

```yaml
workspace:
  - packages/flutter_adaptive_cards_host_fs
```

- [ ] **Step 5: Pub get**

Run: `fvm flutter pub get` (from repo root)

Expected: resolves without error

- [ ] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_host_fs pubspec.yaml
git commit -m "feat: scaffold flutter_adaptive_cards_host_fs package"
```

---

### Task 8: `AdaptiveCardInvokeRequest`

**Files:**

- Create: `lib/src/models/invoke_kind.dart`
- Create: `lib/src/models/invoke_request.dart`
- Create: `test/models/invoke_request_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromExecute maps verb actionId and data', () {
    const invoke = ExecuteActionInvoke(
      data: {'x': 1},
      verb: 'save',
      actionId: 'act1',
    );
    final req = AdaptiveCardInvokeRequest.fromExecute(invoke);
    expect(req.kind, AdaptiveCardInvokeKind.execute);
    expect(req.verb, 'save');
    expect(req.actionId, 'act1');
    expect(req.data, {'x': 1});
  });

  test('fromInputChange maps inputId value and dataQuery', () {
    final invoke = InputChangeInvoke(
      inputId: 'city',
      value: 'nyc',
      dataQuery: DataQuery(dataset: 'cities', parameters: {'country': 'usa'}),
      cardState: throw UnimplementedError(),
    );
    // Use a minimal mock or test-only stub — for unit test, only read fields
    // before cardState access; alternatively test factory with nullable cardState
    // by making fromInputChange not touch cardState.
    final req = AdaptiveCardInvokeRequest.fromInputChange(invoke);
    expect(req.kind, AdaptiveCardInvokeKind.inputChange);
    expect(req.inputId, 'city');
    expect(req.value, 'nyc');
    expect(req.dataQuery?.dataset, 'cities');
  });
}
```

Note: `InputChangeInvoke` requires `cardState` — factory must only copy fields, not use `cardState`.

- [ ] **Step 2: Implement `invoke_kind.dart` and `invoke_request.dart`**

```dart
// invoke_kind.dart
enum AdaptiveCardInvokeKind {
  submit,
  execute,
  inputChange,
  openUrl,
  openUrlDialog,
}

// invoke_request.dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_kind.dart';

class AdaptiveCardInvokeRequest {
  const AdaptiveCardInvokeRequest({
    required this.kind,
    this.actionId,
    this.verb,
    this.data = const {},
    this.inputId,
    this.value,
    this.dataQuery,
    this.url,
  });

  final AdaptiveCardInvokeKind kind;
  final String? actionId;
  final String? verb;
  final Map<String, dynamic> data;
  final String? inputId;
  final Object? value;
  final DataQuery? dataQuery;
  final String? url;

  factory AdaptiveCardInvokeRequest.fromSubmit(SubmitActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.submit,
      actionId: invoke.actionId,
      data: invoke.data,
    );
  }

  factory AdaptiveCardInvokeRequest.fromExecute(ExecuteActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.execute,
      actionId: invoke.actionId,
      verb: invoke.verb,
      data: invoke.data,
    );
  }

  factory AdaptiveCardInvokeRequest.fromInputChange(InputChangeInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.inputChange,
      inputId: invoke.inputId,
      value: invoke.value,
      dataQuery: invoke.dataQuery,
      data: invoke.dataQuery?.parameters ?? const {},
    );
  }

  factory AdaptiveCardInvokeRequest.fromOpenUrl(OpenUrlActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.openUrl,
      actionId: invoke.actionId,
      url: invoke.url,
    );
  }

  factory AdaptiveCardInvokeRequest.fromOpenUrlDialog(
    OpenUrlDialogActionInvoke invoke,
  ) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.openUrlDialog,
      actionId: invoke.actionId,
      url: invoke.url,
    );
  }
}
```

Fix `fromInputChange` test: build invoke with a dummy — use `flutter_test` + minimal widget to obtain `cardState`, or split test to only test Submit/Execute factories in unit test and cover InputChange in widget test in Task 14.

- [ ] **Step 3: Run tests — PASS**

- [ ] **Step 4: Commit**

---

### Task 9: `PlainJsonInvokeAdapter`

**Files:**

- Create: `lib/src/adapters/plain_json_invoke_adapter.dart`
- Create: `test/adapters/plain_json_invoke_adapter_test.dart`

- [ ] **Step 1: Write failing round-trip test**

```dart
test('toMap and fromMap round-trip execute request', () {
  const req = AdaptiveCardInvokeRequest(
    kind: AdaptiveCardInvokeKind.execute,
    verb: 'save',
    actionId: 'a1',
    data: {'k': 'v'},
  );
  final map = PlainJsonInvokeAdapter.toMap(req);
  expect(map['kind'], 'execute');
  expect(map['verb'], 'save');
  final parsed = PlainJsonInvokeAdapter.requestFromMap(map);
  expect(parsed.verb, 'save');
  expect(parsed.data, {'k': 'v'});
});
```

- [ ] **Step 2: Implement adapter**

```dart
class PlainJsonInvokeAdapter {
  const PlainJsonInvokeAdapter._();

  static Map<String, dynamic> toMap(AdaptiveCardInvokeRequest request) {
    return {
      'kind': request.kind.name,
      if (request.actionId != null) 'actionId': request.actionId,
      if (request.verb != null) 'verb': request.verb,
      if (request.data.isNotEmpty) 'data': request.data,
      if (request.inputId != null) 'inputId': request.inputId,
      if (request.value != null) 'value': request.value,
      if (request.dataQuery != null) 'dataQuery': request.dataQuery!.toJson(),
      if (request.url != null) 'url': request.url,
    };
  }

  static AdaptiveCardInvokeRequest requestFromMap(Map<String, dynamic> map) {
    final kindName = map['kind'] as String;
    final kind = AdaptiveCardInvokeKind.values.byName(kindName);
    DataQuery? dataQuery;
    final dq = map['dataQuery'];
    if (dq is Map<String, dynamic>) {
      dataQuery = DataQuery.fromJson(dq);
    }
    return AdaptiveCardInvokeRequest(
      kind: kind,
      actionId: map['actionId'] as String?,
      verb: map['verb'] as String?,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
      inputId: map['inputId'] as String?,
      value: map['value'],
      dataQuery: dataQuery,
      url: map['url'] as String?,
    );
  }

  static AdaptiveCardInvokeResponse responseFromMap(Map<String, dynamic> map) {
    // implemented in Task 10 — stub throws UnimplementedError initially
    return PlainJsonInvokeResponseParser.parse(map);
  }
}
```

Split: create `plain_json_invoke_response_parser.dart` in Task 10 if cleaner.

- [ ] **Step 3: Run tests — PASS**

- [ ] **Step 4: Commit**

---

### Task 10: `AdaptiveCardInvokeResponse` + PlainJson parser

**Files:**

- Create: `lib/src/models/invoke_effect.dart`
- Create: `lib/src/models/invoke_response.dart`
- Create: `lib/src/adapters/plain_json_invoke_response_parser.dart`
- Create: `test/models/invoke_response_test.dart`

- [ ] **Step 1: Write failing parser tests**

```dart
test('parses applyPatches and setInputErrors', () {
  final response = PlainJsonInvokeResponseParser.parse({
    'type': 'adaptiveCard.invokeResponse',
    'effects': [
      {
        'type': 'applyPatches',
        'elements': [
          {'id': 'city', 'choices': [{'title': 'Paris', 'value': 'paris'}]},
        ],
      },
      {
        'type': 'setInputErrors',
        'errors': {'email': 'Bad'},
      },
    ],
  });
  expect(response.effects, hasLength(2));
  expect(response.effects[0], isA<ApplyPatchesEffect>());
  expect(response.effects[1], isA<SetInputErrorsEffect>());
});

test('parses top-level card shorthand', () {
  final card = {'type': 'AdaptiveCard', 'version': '1.5', 'body': []};
  final response = PlainJsonInvokeResponseParser.parse({
    'type': 'adaptiveCard.invokeResponse',
    'card': card,
  });
  expect(response.effects.single, isA<ReplaceCardEffect>());
});
```

- [ ] **Step 2: Implement effects + parser**

`invoke_effect.dart` — sealed classes per spec.

`invoke_response.dart`:

```dart
class AdaptiveCardInvokeResponse {
  const AdaptiveCardInvokeResponse(this.effects);
  final List<AdaptiveCardInvokeEffect> effects;

  void applyTo(
    RawAdaptiveCardState cardState, {
    void Function(Map<String, dynamic> card)? onCardReplaced,
  }) {
    for (final effect in effects) {
      switch (effect) {
        case ApplyPatchesEffect(:final elements):
          cardState.applyUpdates(elements: elements);
        case SetInputErrorsEffect(:final errors):
          cardState.applyUpdates(
            elements: errors.entries.map(
              (e) => AdaptiveElementUpdate(
                id: e.key,
                errorMessage: e.value,
                isInvalid: true,
              ),
            ),
          );
        case ReplaceCardEffect(:final card):
          if (onCardReplaced == null) {
            throw StateError('onCardReplaced required for ReplaceCardEffect');
          }
          onCardReplaced(card);
        case NoOpEffect():
          break;
      }
    }
  }
}
```

Parser maps `choices` JSON arrays to `List<Choice>` via `Choice.fromJson` / existing helpers.

- [ ] **Step 3: Wire `PlainJsonInvokeAdapter.responseFromMap`**

- [ ] **Step 4: Run tests — PASS**

- [ ] **Step 5: Commit**

---

### Task 11: `TeamsInvokeAdapter`

**Files:**

- Create: `lib/src/adapters/teams_invoke_adapter.dart`
- Create: `test/adapters/teams_invoke_adapter_test.dart`

- [ ] **Step 1: Write failing test for Execute shape**

```dart
test('execute toMap matches Teams action envelope', () {
  const req = AdaptiveCardInvokeRequest(
    kind: AdaptiveCardInvokeKind.execute,
    verb: 'saveProfile',
    data: {'name': 'Ada'},
  );
  final map = TeamsInvokeAdapter.toMap(req);
  expect(map['type'], 'invoke');
  expect(map['name'], 'adaptiveCard/action');
  final action = (map['value'] as Map)['action'] as Map;
  expect(action['verb'], 'saveProfile');
  expect(action['data'], {'name': 'Ada'});
});
```

- [ ] **Step 2: Implement `TeamsInvokeAdapter.toMap`** for `execute` and `inputChange` (input change → `value.action.data` + dataset fields per Teams search invoke docs).

- [ ] **Step 3: Implement `TeamsInvokeAdapter.responseFromMap`** — map attachment with `contentType: application/vnd.microsoft.card.adaptive` to `ReplaceCardEffect`; delegate unknown to PlainJson parser.

- [ ] **Step 4: Run tests — PASS**

- [ ] **Step 5: Commit**

---

### Task 12: `HttpAdaptiveCardBackendClient`

**Files:**

- Create: `lib/src/client/backend_client.dart`
- Create: `lib/src/client/http_backend_client.dart`

- [ ] **Step 1: Implement abstract + HTTP client**

```dart
abstract class AdaptiveCardBackendClient {
  Future<Map<String, dynamic>> post(Map<String, dynamic> body);
}

class HttpAdaptiveCardBackendClient implements AdaptiveCardBackendClient {
  HttpAdaptiveCardBackendClient({
    required this.endpoint,
    http.Client? client,
    Map<String, String> headers = const {},
  }) : _client = client ?? http.Client(),
       _headers = {'Content-Type': 'application/json', ...headers};

  final Uri endpoint;
  final http.Client _client;
  final Map<String, String> _headers;

  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    final response = await _client.post(
      endpoint,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdaptiveCardBackendException(
        'HTTP ${response.statusCode}',
        body: response.body,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
```

- [ ] **Step 2: Unit test with `MockClient` or mock `http.Client`** — verify POST body and decode.

- [ ] **Step 3: Commit**

---

### Task 13: `AdaptiveCardBackendHandlers`

**Files:**

- Create: `lib/src/handlers/backend_handlers.dart`
- Create: `test/handlers/backend_handlers_test.dart`

- [ ] **Step 1: Write failing widget test**

Pump `AdaptiveCardsCanvas` wrapped with handlers from:

```dart
final handlers = AdaptiveCardBackendHandlers(
  client: _MockClient(),
  onCardReplaced: (card) => replaced = card,
).build(
  onCardReplaced: (c) => replaced = c,
);
```

Mock client returns:

```json
{
  "type": "adaptiveCard.invokeResponse",
  "effects": [{"type": "setInputErrors", "errors": {"email": "Required"}}]
}
```

Tap Submit → assert overlay error applied.

- [ ] **Step 2: Implement `AdaptiveCardBackendHandlers`**

```dart
class AdaptiveCardBackendHandlers {
  AdaptiveCardBackendHandlers({
    required this.client,
    this.requestAdapter = PlainJsonInvokeAdapter.toMap,
    this.responseParser = PlainJsonInvokeResponseParser.parse,
    this.onError,
  });

  final AdaptiveCardBackendClient client;
  final Map<String, dynamic> Function(AdaptiveCardInvokeRequest) requestAdapter;
  final AdaptiveCardInvokeResponse Function(Map<String, dynamic>) responseParser;
  final void Function(Object error)? onError;

  InheritedAdaptiveCardHandlers build({
    required Widget child,
    void Function(Map<String, dynamic> card)? onCardReplaced,
    void Function(OpenUrlActionInvoke invoke)? onOpenUrlOverride,
  }) {
    return InheritedAdaptiveCardHandlers(
      onSubmit: (invoke) => _handle(
        AdaptiveCardInvokeRequest.fromSubmit(invoke),
        invoke.cardState, // need cardState — extend: pass from invoke via closure
        onCardReplaced: onCardReplaced,
      ),
      // ...
      child: child,
    );
  }

  Future<void> _handle(
    AdaptiveCardInvokeRequest request,
    RawAdaptiveCardState cardState, {
    void Function(Map<String, dynamic> card)? onCardReplaced,
  }) async {
    try {
      final body = requestAdapter(request);
      final json = await client.post(body);
      final response = responseParser(json);
      response.applyTo(cardState, onCardReplaced: onCardReplaced);
    } on Object catch (e, st) {
      onError?.call(e);
      assert(() {
        // log in debug
        return true;
      }());
    }
  }
}
```

**Important:** `SubmitActionInvoke` does not carry `cardState`. Handler signature options:

1. Wrap canvas and capture `GlobalKey<RawAdaptiveCardState>` in `AdaptiveCardBackendHandlers`.
2. Add optional `cardStateLookup` callback.

**Plan choice:** `AdaptiveCardBackendHandlers` takes `GlobalKey<RawAdaptiveCardState> cardKey` set by host on `RawAdaptiveCard`. Document in README.

- [ ] **Step 3: Run widget test — PASS**

- [ ] **Step 4: Commit**

---

### Task 14: Phase 2 README + CHANGELOG

**Files:**

- Create: `packages/flutter_adaptive_cards_host_fs/README.md`
- Create: `packages/flutter_adaptive_cards_host_fs/CHANGELOG.md`

- [ ] **Step 1: README** — quick start:

```dart
final cardKey = GlobalKey<RawAdaptiveCardState>();

AdaptiveCardBackendHandlers(
  client: HttpAdaptiveCardBackendClient(
    endpoint: Uri.parse('https://api.example.com/adaptive-card/invoke'),
  ),
  cardKey: cardKey,
  onError: (e) => log('invoke failed', error: e),
).wrap(
  AdaptiveCardsCanvas(
    key: cardKey, // or pass key to RawAdaptiveCard inside canvas
    ...
  ),
  onCardReplaced: (map) => setState(() => _cardJson = map),
);
```

Document PlainJson response contract with examples from spec.

- [ ] **Step 2: CHANGELOG** initial 0.1.0 entry.

- [ ] **Step 3: Commit**

---

## Final Task: Full verification

- [ ] **Step 1: Analyze monorepo**

Run: `fvm flutter analyze`

Expected: No issues found

- [ ] **Step 2: Test core package**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`

Expected: All tests passed

- [ ] **Step 3: Test host package**

Run: `cd packages/flutter_adaptive_cards_host_fs && fvm flutter test`

Expected: All tests passed

- [ ] **Step 4: Widgetbook analyze (handler import check)**

Run: `cd widgetbook && fvm flutter analyze`

Expected: No issues found

- [ ] **Step 5: Commit any remaining fixes**

```bash
git commit -m "chore: verify backend host integration phase 1 and 2"
```

---

## Plan self-review (completed)

| Spec requirement | Task |
| --- | --- |
| Data.Query associatedInputs parse + merge | Tasks 1–3 |
| Submit/Execute associatedInputs | Task 4 |
| Dependent demo update | Task 5 |
| Phase 1 docs | Task 6 |
| Host package scaffold | Task 7 |
| InvokeRequest | Task 8 |
| PlainJson adapter | Task 9 |
| InvokeResponse + applyTo | Task 10 |
| Teams adapter | Task 11 |
| HTTP client | Task 12 |
| BackendHandlers | Task 13 |
| Host package docs | Task 14 |
| Full verification | Final Task |

**Deferred (documented in spec, no task):** container-scoped auto, typeahead keystroke onChange, OAuth.

**Type consistency note:** `AdaptiveCardBackendHandlers` uses `GlobalKey<RawAdaptiveCardState> cardKey` — Task 13 implementation must match README in Task 14.
