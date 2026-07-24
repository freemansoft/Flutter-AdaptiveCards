# Teams Invoke Example App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Widgetbook demo plus local Dart HTTP mock server that exercises **Teams-shaped** invoke JSON (`application/search`, `adaptiveCard/action`) end-to-end through `AdaptiveCardBackendHandlers` and `TeamsInvokeAdapter`.

**Architecture:** A standalone `tool/teams_invoke_mock_server` Dart package accepts POST bodies produced by `TeamsInvokeAdapter.toMap`, routes on invoke `name`, and returns JSON parsed by `TeamsInvokeAdapter.responseFromMap` (`applyPatches` via PlainJson fallback, or adaptive-card `attachments`). A new Widgetbook page loads the existing dependent ChoiceSet sample JSON, wraps `RawAdaptiveCard` with `AdaptiveCardBackendHandlers`, and shows the last request/response for fidelity inspection. No real Teams client, Azure Bot, or OAuth.

**Tech Stack:** Dart 3.12+, `shelf` + `shelf_router`, `flutter_adaptive_cards_fs`, `flutter_adaptive_cards_host_fs`, Widgetbook, FVM.

**Parent context:** [`docs/archive/specs/2026-06-07-backend-host-integration-design.md`](../../archive/specs/2026-06-07-backend-host-integration-design.md) (Phase 2 host package — implemented). This plan closes the optional follow-up: _Widgetbook demo using `AdaptiveCardBackendHandlers` + mock client_ with **Teams JSON fidelity (option B)**.

**User choice:** Teams JSON fidelity via local HTTP server; **Widgetbook first** (standalone `host_invoke_demo/` app deferred).

---

## File map

| File                                                                 | Role                                                   |
| -------------------------------------------------------------------- | ------------------------------------------------------ |
| `tool/teams_invoke_mock_server/pubspec.yaml`                         | **Create** — shelf server package (`publish_to: none`) |
| `tool/teams_invoke_mock_server/lib/cities_data.dart`                 | Mock country → city choice lists                       |
| `tool/teams_invoke_mock_server/lib/invoke_router.dart`               | Route Teams invoke bodies → response maps              |
| `tool/teams_invoke_mock_server/bin/server.dart`                      | `dart run` entry (default `localhost:8080`)            |
| `tool/teams_invoke_mock_server/test/invoke_router_test.dart`         | Router unit tests                                      |
| `tool/teams_invoke_mock_server/README.md`                            | Start server + sample request/response JSON            |
| `widgetbook/lib/teams_backend_handlers_demo_page.dart`               | **Create** — Widgetbook demo page                      |
| `widgetbook/lib/adaptive_cards_use_cases.dart`                       | Register new use case                                  |
| `widgetbook/pubspec.yaml`                                            | Add `flutter_adaptive_cards_host_fs` dependency        |
| `widgetbook/README.md`                                               | Document demo + server startup                         |
| `docs/superpowers/plans/2026-06-07-backend-host-integration.plan.md` | Link follow-up to this plan                            |

---

## Non-goals

- Real Microsoft Teams client, Bot Framework Connector, or M365 Agents Playground integration
- Azure Bot registration, dev tunnels, or SSO on `Action.Execute`
- Parsing Bot Framework `statusCode` / `type` / `value` invoke envelopes (unless added in a follow-up adapter task)
- Standalone `host_invoke_demo/` Flutter app (optional later extraction)

---

## Server contract

### Endpoint

`POST http://localhost:8080/api/invoke`  
`Content-Type: application/json`

### Inbound (from `TeamsInvokeAdapter.toMap`)

| `name`                | When                 | Server reads                                                  |
| --------------------- | -------------------- | ------------------------------------------------------------- |
| `application/search`  | ChoiceSet `onChange` | `value.dataset`, `value.data`, `value.queryText`              |
| `adaptiveCard/action` | Submit / Execute     | `value.action.type`, `value.action.data`, `value.action.verb` |

**Note:** `TeamsInvokeAdapter` does not include `inputId` on `application/search`. Country selection is inferred when `dataset` is absent and `queryText` resolves to a known country code (`usa`, `france`, `india`).

### Outbound (parsed by `TeamsInvokeAdapter.responseFromMap`)

| Scenario                | Response shape                                                                                                                                                        |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| City choice patch       | PlainJson: `{ "type": "adaptiveCard.invokeResponse", "effects": [{ "type": "applyPatches", "elements": [{ "id": "city", "choices": [...], "clearValue": true }] }] }` |
| Submit success          | Teams attachment: `{ "attachments": [{ "contentType": "application/vnd.microsoft.card.adaptive", "content": { ... } }] }`                                             |
| Submit validation error | PlainJson `setInputErrors` effect                                                                                                                                     |
| No-op                   | `{ "type": "adaptiveCard.invokeResponse", "effects": [] }`                                                                                                            |

---

## Task 1: Mock server package scaffold

**Files:**

- Create: `tool/teams_invoke_mock_server/pubspec.yaml`
- Create: `tool/teams_invoke_mock_server/bin/server.dart`
- Create: `tool/teams_invoke_mock_server/README.md`

- [ ] **Step 1: Create `pubspec.yaml`**

```yaml
name: teams_invoke_mock_server
description: Local Teams-shaped invoke mock for flutter_adaptive_cards_host_fs demos.
publish_to: none

environment:
  sdk: ^3.12.0

dependencies:
  shelf: ^1.4.2
  shelf_router: ^1.1.4

dev_dependencies:
  test: ^1.26.2
  very_good_analysis: ^10.2.0
```

- [ ] **Step 2: Create minimal `bin/server.dart`**

```dart
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:teams_invoke_mock_server/invoke_router.dart';

Future<void> main(List<String> args) async {
  final port = int.tryParse(
        Platform.environment['PORT'] ?? '',
      ) ??
      8080;
  final router = Router()
    ..post('/api/invoke', (Request request) async {
      final body = await request.readAsString();
      final responseMap = InvokeRouter.route(body);
      return Response.ok(
        responseMap,
        headers: {'Content-Type': 'application/json'},
      );
    });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, port);
  // ignore: avoid_print
  print('Teams invoke mock server listening on http://localhost:${server.port}/api/invoke');
}
```

- [ ] **Step 3: Run pub get**

```bash
cd tool/teams_invoke_mock_server
fvm dart pub get
```

Expected: resolves `shelf` dependencies without error.

- [ ] **Step 4: Commit**

```bash
git add tool/teams_invoke_mock_server/pubspec.yaml tool/teams_invoke_mock_server/bin/server.dart tool/teams_invoke_mock_server/README.md
git commit -m "chore: scaffold Teams invoke mock server package"
```

---

## Task 2: Cities data + invoke router

**Files:**

- Create: `tool/teams_invoke_mock_server/lib/cities_data.dart`
- Create: `tool/teams_invoke_mock_server/lib/invoke_router.dart`
- Create: `tool/teams_invoke_mock_server/test/invoke_router_test.dart`

- [ ] **Step 1: Write failing router tests**

Create `test/invoke_router_test.dart`:

```dart
import 'dart:convert';

import 'package:test/test.dart';
import 'package:teams_invoke_mock_server/invoke_router.dart';

void main() {
  group('InvokeRouter', () {
    test('application/search with dataset cities returns city patches', () {
      final body = jsonEncode({
        'type': 'invoke',
        'name': 'application/search',
        'value': {
          'dataset': 'cities',
          'data': {'country': 'usa'},
        },
      });
      final response = InvokeRouter.route(body);
      final effects = response['effects'] as List<dynamic>;
      expect(effects, isNotEmpty);
      final patch = effects.first as Map<String, dynamic>;
      expect(patch['type'], 'applyPatches');
      final elements = patch['elements'] as List<dynamic>;
      final city = elements.first as Map<String, dynamic>;
      expect(city['id'], 'city');
      final choices = city['choices'] as List<dynamic>;
      expect(choices.length, 2);
    });

    test('application/search without dataset resolves country from queryText', () {
      final body = jsonEncode({
        'type': 'invoke',
        'name': 'application/search',
        'value': {
          'queryText': 'france',
        },
      });
      final response = InvokeRouter.route(body);
      final effects = response['effects'] as List<dynamic>;
      expect(effects, isNotEmpty);
    });

    test('adaptiveCard/action submit returns adaptive card attachment', () {
      final body = jsonEncode({
        'type': 'invoke',
        'name': 'adaptiveCard/action',
        'value': {
          'action': {
            'type': 'Action.Submit',
            'data': {'country': 'usa', 'city': 'nyc'},
          },
        },
      });
      final response = InvokeRouter.route(body);
      expect(response['attachments'], isNotNull);
      final attachments = response['attachments'] as List<dynamic>;
      final content = (attachments.first as Map)['content'] as Map<String, dynamic>;
      expect(content['type'], 'AdaptiveCard');
    });

    test('adaptiveCard/action submit with invalid email returns setInputErrors', () {
      final body = jsonEncode({
        'type': 'invoke',
        'name': 'adaptiveCard/action',
        'value': {
          'action': {
            'type': 'Action.Submit',
            'data': {'email': 'not-an-email'},
          },
        },
      });
      final response = InvokeRouter.route(body);
      final effects = response['effects'] as List<dynamic>;
      expect(effects.first['type'], 'setInputErrors');
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd tool/teams_invoke_mock_server
fvm dart test
```

Expected: FAIL — `invoke_router.dart` / `cities_data.dart` not found.

- [ ] **Step 3: Implement `lib/cities_data.dart`**

```dart
const citiesByCountry = <String, List<Map<String, String>>>{
  'usa': [
    {'title': 'New York', 'value': 'nyc'},
    {'title': 'Los Angeles', 'value': 'la'},
  ],
  'france': [
    {'title': 'Paris', 'value': 'paris'},
    {'title': 'Lyon', 'value': 'lyon'},
  ],
  'india': [
    {'title': 'Mumbai', 'value': 'mumbai'},
    {'title': 'Delhi', 'value': 'delhi'},
  ],
};

String? countryCodeFromQueryText(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (citiesByCountry.containsKey(raw)) return raw;
  final lower = raw.toLowerCase();
  if (citiesByCountry.containsKey(lower)) return lower;
  for (final entry in citiesByCountry.entries) {
    for (final choice in entry.value) {
      if (choice['title'] == raw) return entry.key;
    }
  }
  return null;
}

List<Map<String, String>> choicesForCountry(String? countryCode) {
  if (countryCode == null) return const [];
  return citiesByCountry[countryCode] ?? const [];
}
```

- [ ] **Step 4: Implement `lib/invoke_router.dart`**

```dart
import 'dart:convert';

import 'package:teams_invoke_mock_server/cities_data.dart';

/// Routes Teams-shaped invoke JSON bodies to response maps.
class InvokeRouter {
  const InvokeRouter._();

  /// Parses [body] (JSON string or already-encoded map) and returns a response map.
  static Map<String, dynamic> route(Object body) {
    final map = switch (body) {
      final String s => jsonDecode(s) as Map<String, dynamic>,
      final Map<String, dynamic> m => m,
      _ => throw ArgumentError('Expected JSON string or map'),
    };

    final name = map['name'] as String?;
    return switch (name) {
      'application/search' => _handleApplicationSearch(
          map['value'] as Map<String, dynamic>? ?? const {},
        ),
      'adaptiveCard/action' => _handleAdaptiveCardAction(
          map['value'] as Map<String, dynamic>? ?? const {},
        ),
      _ => _noOp(),
    };
  }

  static Map<String, dynamic> _handleApplicationSearch(
    Map<String, dynamic> value,
  ) {
    final dataset = value['dataset'] as String?;
    String? countryCode;

    if (dataset == 'cities') {
      final data = value['data'];
      if (data is Map<String, dynamic>) {
        countryCode = data['country']?.toString();
      }
    } else {
      countryCode = countryCodeFromQueryText(value['queryText']?.toString());
    }

    return _cityPatches(countryCode);
  }

  static Map<String, dynamic> _handleAdaptiveCardAction(
    Map<String, dynamic> value,
  ) {
    final action = value['action'];
    if (action is! Map<String, dynamic>) return _noOp();

    final type = action['type'] as String?;
    final data = action['data'];
    final fields = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    if (type == 'Action.Submit') {
      final email = fields['email']?.toString() ?? '';
      if (email.isNotEmpty && !email.contains('@')) {
        return {
          'type': 'adaptiveCard.invokeResponse',
          'effects': [
            {
              'type': 'setInputErrors',
              'errors': {'email': 'Invalid email format'},
            },
          ],
        };
      }

      final country = fields['country']?.toString() ?? '';
      final city = fields['city']?.toString() ?? '';
      return {
        'attachments': [
          {
            'contentType': 'application/vnd.microsoft.card.adaptive',
            'content': {
              'type': 'AdaptiveCard',
              'version': '1.5',
              'body': [
                {
                  'type': 'TextBlock',
                  'text': 'Submitted successfully',
                  'weight': 'Bolder',
                  'wrap': true,
                },
                {
                  'type': 'TextBlock',
                  'text': 'Country: $country, City: $city',
                  'wrap': true,
                },
              ],
            },
          },
        ],
      };
    }

    return _noOp();
  }

  static Map<String, dynamic> _cityPatches(String? countryCode) {
    final choices = choicesForCountry(countryCode);
    return {
      'type': 'adaptiveCard.invokeResponse',
      'effects': [
        {
          'type': 'applyPatches',
          'elements': [
            {
              'id': 'city',
              'choices': choices,
              'clearValue': true,
            },
          ],
        },
      ],
    };
  }

  static Map<String, dynamic> _noOp() => {
        'type': 'adaptiveCard.invokeResponse',
        'effects': <Map<String, dynamic>>[],
      };
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd tool/teams_invoke_mock_server
fvm dart test
```

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add tool/teams_invoke_mock_server/lib tool/teams_invoke_mock_server/test
git commit -m "feat: add Teams invoke mock router and city data"
```

---

## Task 3: Server README + manual smoke

**Files:**

- Modify: `tool/teams_invoke_mock_server/README.md`

- [ ] **Step 1: Document startup and sample curl**

````markdown
# Teams invoke mock server

Local HTTP server for Widgetbook `AdaptiveCardBackendHandlers` demos. Accepts JSON bodies from `TeamsInvokeAdapter.toMap` and returns shapes understood by `TeamsInvokeAdapter.responseFromMap`.

## Start

```bash
cd tool/teams_invoke_mock_server
fvm dart pub get
fvm dart run bin/server.dart
```
````

Listens on `http://localhost:8080/api/invoke` (override with `PORT` env var).

## Sample: application/search (cities dataset)

```bash
curl -s -X POST http://localhost:8080/api/invoke \
  -H 'Content-Type: application/json' \
  -d '{"type":"invoke","name":"application/search","value":{"dataset":"cities","data":{"country":"usa"}}}'
```

## Sample: adaptiveCard/action submit

```bash
curl -s -X POST http://localhost:8080/api/invoke \
  -H 'Content-Type: application/json' \
  -d '{"type":"invoke","name":"adaptiveCard/action","value":{"action":{"type":"Action.Submit","data":{"country":"usa","city":"nyc"}}}}'
```

````

- [ ] **Step 2: Manual smoke**

```bash
cd tool/teams_invoke_mock_server
fvm dart run bin/server.dart
````

In another terminal, run the cities `curl` above. Expected: JSON with `applyPatches` and two USA city choices.

- [ ] **Step 3: Commit**

```bash
git add tool/teams_invoke_mock_server/README.md
git commit -m "docs: add Teams invoke mock server README"
```

---

## Task 4: Widgetbook demo page

**Files:**

- Create: `widgetbook/lib/teams_backend_handlers_demo_page.dart`
- Modify: `widgetbook/pubspec.yaml`

- [ ] **Step 1: Add host package dependency to Widgetbook**

In `widgetbook/pubspec.yaml` under `dependencies:`:

```yaml
flutter_adaptive_cards_host_fs:
  path: ../packages/flutter_adaptive_cards_host_fs
```

Run:

```bash
cd widgetbook
fvm flutter pub get
```

- [ ] **Step 2: Create demo page**

Create `widgetbook/lib/teams_backend_handlers_demo_page.dart`:

```dart
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';

/// Default mock server URL (desktop / iOS simulator).
///
/// Android emulator: use `http://10.0.2.2:8080/api/invoke`.
const kTeamsMockServerEndpoint = 'http://localhost:8080/api/invoke';

const _assetPath =
    'lib/samples/inputs/input_choice_set/value_changed_action_dependent_query.json';

/// Widgetbook demo: dependent ChoiceSet via [AdaptiveCardBackendHandlers] +
/// [TeamsInvokeAdapter] against the local mock server.
class TeamsBackendHandlersDemoPage extends StatefulWidget {
  const TeamsBackendHandlersDemoPage({super.key});

  @override
  State<TeamsBackendHandlersDemoPage> createState() =>
      _TeamsBackendHandlersDemoPageState();
}

class _TeamsBackendHandlersDemoPageState
    extends State<TeamsBackendHandlersDemoPage> {
  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();
  late final CardTypeRegistry _cardTypeRegistry = CardTypeRegistry(
    addedElements: CardChartsRegistry.additionalChartElements,
  );

  Map<String, dynamic>? _cardMap;
  String? _lastRequestJson;
  String? _lastResponseJson;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    final json = await rootBundle.loadString(_assetPath);
    setState(() {
      _cardMap = jsonDecode(json) as Map<String, dynamic>;
    });
  }

  void _onCardReplaced(Map<String, dynamic> card) {
    setState(() => _cardMap = card);
  }

  @override
  Widget build(BuildContext context) {
    final cardMap = _cardMap;
    if (cardMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final loggingClient = _LoggingBackendClient(
      delegate: HttpAdaptiveCardBackendClient(
        endpoint: Uri.parse(kTeamsMockServerEndpoint),
      ),
      onExchange: (request, response) {
        setState(() {
          _lastRequestJson = const JsonEncoder.withIndent('  ').convert(request);
          _lastResponseJson =
              const JsonEncoder.withIndent('  ').convert(response);
          _lastError = null;
        });
      },
    );

    final handlers = AdaptiveCardBackendHandlers(
      client: loggingClient,
      cardKey: _cardKey,
      requestAdapter: TeamsInvokeAdapter.toMap,
      responseParser: TeamsInvokeAdapter.responseFromMap,
      onError: (error) {
        setState(() => _lastError = error.toString());
        developer.log('Teams backend demo error', error: error);
      },
    );

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Start tool/teams_invoke_mock_server (see README), then pick a '
              'country and city. Invoke JSON is Teams-shaped.',
            ),
            const SizedBox(height: 8),
            handlers.wrap(
              RawAdaptiveCard.fromMap(
                key: _cardKey,
                map: cardMap,
                hostConfigs: HostConfigs(),
                cardTypeRegistry: _cardTypeRegistry,
              ),
              onCardReplaced: _onCardReplaced,
            ),
            const SizedBox(height: 16),
            _JsonPanel(title: 'Last request', json: _lastRequestJson),
            _JsonPanel(title: 'Last response', json: _lastResponseJson),
            if (_lastError != null)
              Text(_lastError!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class _LoggingBackendClient implements AdaptiveCardBackendClient {
  _LoggingBackendClient({
    required this.delegate,
    required this.onExchange,
  });

  final AdaptiveCardBackendClient delegate;
  final void Function(
    Map<String, dynamic> request,
    Map<String, dynamic> response,
  ) onExchange;

  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    final response = await delegate.post(body);
    onExchange(body, response);
    return response;
  }
}

class _JsonPanel extends StatelessWidget {
  const _JsonPanel({required this.title, required this.json});

  final String title;
  final String? json;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title),
      children: [
        SelectableText(
          json ?? '(none yet)',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Analyze Widgetbook**

```bash
cd widgetbook
fvm dart analyze lib/teams_backend_handlers_demo_page.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add widgetbook/pubspec.yaml widgetbook/lib/teams_backend_handlers_demo_page.dart
git commit -m "feat(widgetbook): add Teams backend handlers demo page"
```

---

## Task 5: Register Widgetbook use case

**Files:**

- Modify: `widgetbook/lib/adaptive_cards_use_cases.dart`

- [ ] **Step 1: Add import**

```dart
import 'package:widgetbook_workspace/teams_backend_handlers_demo_page.dart';
```

- [ ] **Step 2: Add use case after existing dependent ChoiceSet cases**

```dart
@widgetbook.UseCase(
  name: 'Teams backend handlers (HTTP mock)',
  type: widget_types.InputChoiceSet,
  path: '[Components]',
)
Widget buildInputChoiceSetTeamsBackendHandlers(BuildContext context) {
  return const TeamsBackendHandlersDemoPage();
}
```

- [ ] **Step 3: Regenerate Widgetbook directories**

```bash
cd widgetbook
fvm dart run build_runner build --delete-conflicting-outputs
fvm dart analyze
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add widgetbook/lib/adaptive_cards_use_cases.dart widgetbook/lib/main.directories.g.dart
git commit -m "feat(widgetbook): register Teams backend handlers use case"
```

---

## Task 6: Widgetbook + plan documentation

**Files:**

- Modify: `widgetbook/README.md`
- Modify: `docs/superpowers/plans/2026-06-07-backend-host-integration.plan.md`

- [ ] **Step 1: Add Widgetbook README row**

In `widgetbook/README.md` interactive demos table, add:

| **Input.ChoiceSet** → Teams backend handlers (HTTP mock) | `lib/teams_backend_handlers_demo_page.dart` | `AdaptiveCardBackendHandlers` + `TeamsInvokeAdapter` against `tool/teams_invoke_mock_server`. Requires mock server running on `localhost:8080`. |

Add a short **Teams mock server** subsection under run instructions:

````markdown
### Teams invoke mock server (backend handlers demo)

```bash
cd tool/teams_invoke_mock_server
fvm dart pub get
fvm dart run bin/server.dart
```
````

Then open Widgetbook → Input.ChoiceSet → **Teams backend handlers (HTTP mock)**.

````

- [ ] **Step 2: Update backend integration plan follow-up**

In `docs/superpowers/plans/2026-06-07-backend-host-integration.plan.md`, replace the Widgetbook follow-up line with:

```markdown
- [ ] Widgetbook demo using `AdaptiveCardBackendHandlers` + mock client — see [`2026-06-07-teams-invoke-example-app.plan.md`](2026-06-07-teams-invoke-example-app.plan.md)
````

- [ ] **Step 3: Commit**

```bash
git add widgetbook/README.md docs/superpowers/plans/2026-06-07-backend-host-integration.plan.md
git commit -m "docs: document Teams backend handlers Widgetbook demo"
```

---

## Task 7 (optional): Submit card with email field

**Files:**

- Create: `widgetbook/lib/samples/inputs/input_choice_set/teams_backend_submit_demo.json`
- Modify: `widgetbook/lib/teams_backend_handlers_demo_page.dart` — add knob or second asset for submit + validation demo

Only implement if Task 4 manual testing shows submit path needs a dedicated sample. The dependent-query JSON already includes `Action.Submit`; success attachment is sufficient for MVP.

- [ ] **Step 1: Manual verify submit** — pick country + city, tap Submit, confirm attachment replacement card appears and request shows `adaptiveCard/action`.

---

## Final Task: Full verification

- [ ] **Step 1: Mock server tests**

```bash
cd tool/teams_invoke_mock_server
fvm dart test
```

Expected: All tests pass.

- [ ] **Step 2: Monorepo analyze**

```bash
fvm flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: Host package tests (regression)**

```bash
cd packages/flutter_adaptive_cards_host_fs
fvm flutter test
```

Expected: 15 tests pass.

- [ ] **Step 4: Manual Widgetbook**

1. Start mock server (`fvm dart run bin/server.dart`).
2. `cd widgetbook && fvm flutter run`.
3. Open **Input.ChoiceSet → Teams backend handlers (HTTP mock)**.
4. Select **France** → confirm request `name` is `application/search` and response patches city choices.
5. Select a city → confirm second `application/search` with `dataset: cities` and `data.country`.
6. Tap **Submit** → confirm `adaptiveCard/action` request and attachment response card.

- [ ] **Step 5: Commit** (only if verification fixes were needed)

---

## Success criteria

- [ ] Outbound POST bodies match shapes asserted in `teams_invoke_adapter_test.dart`
- [ ] Dependent country → city cascade works via HTTP only (no inline `onChange` handler on the demo page)
- [ ] Submit returns a parseable Teams attachment response
- [ ] Request/response JSON visible in Widgetbook expansion panels
- [ ] `tool/teams_invoke_mock_server/README.md` documents startup and curl samples

## Follow-up (out of scope)

- Standalone `host_invoke_demo/` workspace app
- `TeamsInvokeAdapter` support for Bot Framework `statusCode` / `type` / `value` envelope
- M365 Agents Playground + real Azure Bot for live Teams client testing
