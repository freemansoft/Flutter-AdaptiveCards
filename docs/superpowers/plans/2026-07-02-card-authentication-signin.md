# Adaptive Card `authentication` (sign-in button path) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Adaptive Cards v1.4 root `authentication` object (sign-in button path only) so a card can render sign-in buttons that hand off to a host, and add a host-package round-trip that POSTs the sign-in and swaps in the returned card.

**Architecture:** Two phases mirroring existing precedents. Phase 1 (`flutter_adaptive_cards_fs`, the lean core) parses `authentication` into a typed model, renders a sign-in region like the `refresh` affordance, and forwards a typed `SigninActionInvoke` to a new nullable `onSignin` handler — no network I/O, no new dependencies. Phase 2 (`flutter_adaptive_cards_host_fs`) wires `onSignin` into `AdaptiveCardBackendHandlers`, opens the sign-in URL via an app-supplied opener, and exposes `completeSignin(...)` which POSTs an invoke and applies the response through the existing effect pipeline (`ReplaceCardEffect`).

**Tech Stack:** Dart / Flutter (FVM-pinned), `package:test` + `flutter_test`, Riverpod (unchanged here), json-driven card rendering. All commands run via `fvm`.

**Spec:** `docs/superpowers/specs/2026-07-02-card-authentication-signin-design.md`

---

## ⚠️ Commit / review gate

This repo requires explicit user review before **every** commit or push (see `AGENTS.md` → "Git commit and push gate"), and the user has explicitly said **do not commit any code until they review it**. The `git commit` steps below are part of the intended TDD rhythm, but when executing this plan you MUST first show the diff, summarize it, and wait for the user to say "commit" before running each commit. Do not auto-commit.

---

## Scope note

Sign-in **button** path only (`buttons[].type == "signin"`). SSO `tokenExchangeResource` is parsed and preserved on the model but not acted on. This is a single cohesive feature across two packages; keep the two phases as separate commits but one plan.

## File map

**Phase 1 — `packages/flutter_adaptive_cards_fs/`**
- Create `lib/src/models/authentication_config.dart` — `AuthenticationConfig` + `AuthCardButton` (pure Dart, parsing).
- Modify `lib/src/models/action_invoke.dart` — add `SigninActionInvoke`.
- Modify `lib/src/action/action_handler.dart` — add nullable `onSignin` to `InheritedAdaptiveCardHandlers`.
- Modify `lib/src/cards/adaptive_card_element.dart` — parse `authentication`, render `_AuthenticationRegion`, dispatch on tap.
- Modify `lib/flutter_adaptive_cards_fs.dart` — export `authentication_config.dart`.
- Tests: `test/models/authentication_config_test.dart`, `test/cards/authentication_region_test.dart`, plus a golden.
- Docs: `README.md`, `CHANGELOG.md`; repo `docs/actions-architecture.md`, `docs/Implementation-Status.md`.

**Phase 2 — `packages/flutter_adaptive_cards_host_fs/`**
- Modify `lib/src/models/invoke_kind.dart` — add `signin`.
- Modify `lib/src/models/invoke_request.dart` — add `connectionName` field + `fromSignin` factory.
- Modify `lib/src/adapters/plain_json_invoke_adapter.dart` — serialize/parse `connectionName`.
- Modify `lib/src/adapters/teams_invoke_adapter.dart` — add `signin` case (`signin/verifyState`).
- Modify `lib/src/handlers/backend_handlers.dart` — `onSignin` wiring + `completeSignin`.
- Tests: `test/models/invoke_request_signin_test.dart`, `test/adapters/*_signin_test.dart`, `test/handlers/backend_handlers_signin_test.dart`.
- Docs: `README.md`, `CHANGELOG.md`; repo `docs/backend-host-integration.md`.

---

# Phase 1 — core (`flutter_adaptive_cards_fs`)

Run all Phase 1 commands from `packages/flutter_adaptive_cards_fs/` unless noted.

### Task 1: `AuthenticationConfig` + `AuthCardButton` model

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/lib/src/models/authentication_config.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/models/authentication_config_test.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/authentication_config_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthenticationConfig.fromJson', () {
    test('parses text, connectionName, tokenExchangeResource and buttons', () {
      final config = AuthenticationConfig.fromJson({
        'text': 'Please sign in',
        'connectionName': 'myConnection',
        'tokenExchangeResource': {
          'id': 'res-id',
          'uri': 'api://example',
          'providerId': 'aad',
        },
        'buttons': [
          {
            'type': 'signin',
            'title': 'Sign in',
            'image': 'https://example.com/i.png',
            'value': 'https://login.example.com/oauth',
          },
        ],
      });

      expect(config.text, 'Please sign in');
      expect(config.connectionName, 'myConnection');
      expect(config.tokenExchangeResource?['uri'], 'api://example');
      expect(config.buttons, hasLength(1));
      expect(config.buttons.first.type, 'signin');
      expect(config.buttons.first.title, 'Sign in');
      expect(config.buttons.first.image, 'https://example.com/i.png');
      expect(config.buttons.first.value, 'https://login.example.com/oauth');
    });

    test('tolerates missing buttons and malformed entries', () {
      final config = AuthenticationConfig.fromJson({
        'text': 'Sign in',
        'buttons': [
          'not-a-map',
          {'type': 'signin', 'title': 'Go', 'value': 'https://x'},
        ],
      });

      expect(config.connectionName, isNull);
      expect(config.tokenExchangeResource, isNull);
      expect(config.buttons, hasLength(1));
      expect(config.buttons.first.value, 'https://x');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/models/authentication_config_test.dart`
Expected: FAIL — `AuthenticationConfig` is undefined (compile error).

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/models/authentication_config.dart`:

```dart
/// Root-level `authentication` object on an Adaptive Card (v1.4+).
///
/// Drives the Bot Framework sign-in affordance. This library implements the
/// **sign-in button** path (`buttons[].type == "signin"`); the
/// [tokenExchangeResource] map is preserved for callers but SSO token exchange
/// is not performed by the renderer.
///
/// See [Authentication](https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/authentication).
class AuthenticationConfig {
  /// Creates authentication metadata from parsed JSON fields.
  const AuthenticationConfig({
    this.text,
    this.connectionName,
    this.tokenExchangeResource,
    this.buttons = const [],
  });

  /// Parses a card `authentication` object map, tolerating malformed fields.
  factory AuthenticationConfig.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? tokenExchangeResource;
    final ter = json['tokenExchangeResource'];
    if (ter is Map) {
      tokenExchangeResource = Map<String, dynamic>.from(ter);
    }

    final buttons = <AuthCardButton>[];
    final buttonsRaw = json['buttons'];
    if (buttonsRaw is List) {
      for (final entry in buttonsRaw) {
        if (entry is Map) {
          buttons.add(
            AuthCardButton.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return AuthenticationConfig(
      text: json['text']?.toString(),
      connectionName: json['connectionName']?.toString(),
      tokenExchangeResource: tokenExchangeResource,
      buttons: buttons,
    );
  }

  /// Prompt shown above the sign-in buttons.
  final String? text;

  /// OAuth connection name the host uses to complete sign-in.
  final String? connectionName;

  /// Raw `tokenExchangeResource` object; preserved but not acted on (SSO is a
  /// future phase).
  final Map<String, dynamic>? tokenExchangeResource;

  /// Sign-in buttons rendered for the auth affordance.
  final List<AuthCardButton> buttons;
}

/// A single button inside an [AuthenticationConfig.buttons] list.
class AuthCardButton {
  /// Creates a sign-in button descriptor.
  const AuthCardButton({
    required this.type,
    this.title,
    this.image,
    this.value,
  });

  /// Parses one `authentication.buttons` entry.
  factory AuthCardButton.fromJson(Map<String, dynamic> json) {
    return AuthCardButton(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString(),
      image: json['image']?.toString(),
      value: json['value']?.toString(),
    );
  }

  /// Button type; the renderer only actions `"signin"`.
  final String type;

  /// Button label.
  final String? title;

  /// Optional leading image URL.
  final String? image;

  /// Sign-in URL / action value forwarded to the host on tap.
  final String? value;
}
```

Add the export to `lib/flutter_adaptive_cards_fs.dart` next to the other model
exports (near the `refresh_config.dart` export):

```dart
export 'package:flutter_adaptive_cards_fs/src/models/authentication_config.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/models/authentication_config_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit** (show diff + get user approval first — see gate)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/authentication_config.dart \
        packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart \
        packages/flutter_adaptive_cards_fs/test/models/authentication_config_test.dart
git commit -m "feat(cards): parse root authentication object into typed model"
```

---

### Task 2: `SigninActionInvoke` payload

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/models/signin_action_invoke_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/signin_action_invoke_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SigninActionInvoke.fromButton copies value and connectionName', () {
    const button = AuthCardButton(
      type: 'signin',
      title: 'Sign in',
      value: 'https://login.example.com/oauth',
    );

    final invoke = SigninActionInvoke.fromButton(
      button,
      connectionName: 'myConnection',
    );

    expect(invoke.value, 'https://login.example.com/oauth');
    expect(invoke.connectionName, 'myConnection');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/models/signin_action_invoke_test.dart`
Expected: FAIL — `SigninActionInvoke` is undefined.

- [ ] **Step 3: Write minimal implementation**

Append to `lib/src/models/action_invoke.dart` (after `OpenUrlDialogActionInvoke`).
The file already imports `authentication_config.dart` transitively via the
barrel, but add a direct import at the top to be safe:

```dart
import 'package:flutter_adaptive_cards_fs/src/models/authentication_config.dart';
```

Then append:

```dart
/// Payload delivered to the host `onSignin` callback for a card
/// `authentication` sign-in button.
///
/// [value] is the sign-in URL the host opens; [connectionName] is the OAuth
/// connection the host uses to complete sign-in. When no `onSignin` handler is
/// installed, the library falls back to `onOpenUrl` for an http(s) [value].
class SigninActionInvoke {
  /// Creates a sign-in callback payload.
  const SigninActionInvoke({
    required this.value,
    this.connectionName,
    this.actionId,
  });

  /// Builds from an [AuthCardButton] and the parent
  /// [AuthenticationConfig.connectionName].
  factory SigninActionInvoke.fromButton(
    AuthCardButton button, {
    String? connectionName,
  }) {
    return SigninActionInvoke(
      value: button.value ?? '',
      connectionName: connectionName,
    );
  }

  /// Sign-in URL / action value from the button JSON.
  final String value;

  /// OAuth connection name from the parent `authentication` object.
  final String? connectionName;

  /// Author-defined action `id`, when present. Reserved for future use.
  final String? actionId;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/models/signin_action_invoke_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/models/action_invoke.dart \
        packages/flutter_adaptive_cards_fs/test/models/signin_action_invoke_test.dart
git commit -m "feat(cards): add SigninActionInvoke payload"
```

---

### Task 3: `onSignin` handler field

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart`
- Test: covered by Task 4's widget test (this task is a pure additive field).

- [ ] **Step 1: Add the nullable handler field**

In `lib/src/action/action_handler.dart`, add to the constructor parameter list
(after `this.onHttp,`):

```dart
    this.onSignin,
```

And add the field (after the `onHttp` field, before the closing `of`):

```dart
  /// Called when a card `authentication` sign-in button is pressed.
  ///
  /// `invoke.value` is the sign-in URL and `invoke.connectionName` is the OAuth
  /// connection. When null, a button with an http(s) `value` falls back to
  /// [onOpenUrl]; a non-URL value is a no-op.
  final void Function(SigninActionInvoke invoke)? onSignin;
```

- [ ] **Step 2: Verify it compiles**

Run: `fvm flutter analyze lib/src/action/action_handler.dart`
Expected: No new errors. (`SigninActionInvoke` resolves via the existing
`action_invoke.dart` import.)

- [ ] **Step 3: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/action/action_handler.dart
git commit -m "feat(cards): add onSignin host handler"
```

---

### Task 4: Parse + render the authentication region

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/cards/authentication_region_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/cards/authentication_region_test.dart`. Use the repo's test support
harness for pumping a card. Check an existing card widget test (e.g.
`test/cards/` siblings) for the exact `pumpAdaptiveCard`-style helper and match
it; the structure below assumes a helper that wraps the card in
`InheritedAdaptiveCardHandlers`. If the helper differs, adapt the wrapping but
keep the three assertions.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cardJson = <String, dynamic>{
    'type': 'AdaptiveCard',
    'version': '1.4',
    'body': <dynamic>[
      {'type': 'TextBlock', 'text': 'Body'},
    ],
    'authentication': {
      'text': 'Please sign in',
      'connectionName': 'myConnection',
      'buttons': [
        {
          'type': 'signin',
          'title': 'Sign in',
          'value': 'https://login.example.com/oauth',
        },
      ],
    },
  };

  Widget wrap({
    void Function(SigninActionInvoke)? onSignin,
    void Function(OpenUrlActionInvoke)? onOpenUrl,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: InheritedAdaptiveCardHandlers(
          onSubmit: (_) {},
          onExecute: (_) {},
          onOpenUrl: onOpenUrl ?? (_) {},
          onOpenUrlDialog: (_) {},
          onChange: (_) {},
          onSignin: onSignin,
          child: AdaptiveCardsCanvas(
            adaptiveCardContentMap: cardJson,
          ),
        ),
      ),
    );
  }

  testWidgets('renders sign-in text and button', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Please sign in'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('tapping sign-in fires onSignin with value + connectionName',
      (tester) async {
    SigninActionInvoke? captured;
    await tester.pumpWidget(wrap(onSignin: (i) => captured = i));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.value, 'https://login.example.com/oauth');
    expect(captured!.connectionName, 'myConnection');
  });

  testWidgets('falls back to onOpenUrl when onSignin is null', (tester) async {
    OpenUrlActionInvoke? opened;
    await tester.pumpWidget(wrap(onOpenUrl: (i) => opened = i));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(opened, isNotNull);
    expect(opened!.url, 'https://login.example.com/oauth');
  });
}
```

> Before writing implementation, open one existing widget test under
> `packages/flutter_adaptive_cards_fs/test/cards/` and confirm the canvas entry
> widget name (`AdaptiveCardsCanvas`) and its content-map parameter name. Adjust
> the `wrap` helper if the real API differs (e.g. `RawAdaptiveCard`). Keep the
> assertions identical.

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/cards/authentication_region_test.dart`
Expected: FAIL — no sign-in text/button rendered; `onSignin` unused.

- [ ] **Step 3: Parse `authentication` in `initState`**

In `lib/src/cards/adaptive_card_element.dart`, add the import near the top with
the other model imports:

```dart
import 'package:flutter_adaptive_cards_fs/src/models/authentication_config.dart';
```

Add a field near `_refreshConfig` (around line 80):

```dart
  AuthenticationConfig? _authConfig;
```

In `initState`, after the `refresh` parse block (around line 99), add:

```dart
    final authRaw = adaptiveMap['authentication'];
    if (authRaw is Map) {
      _authConfig = AuthenticationConfig.fromJson(
        Map<String, dynamic>.from(authRaw),
      );
    }
```

- [ ] **Step 4: Add the dispatch method**

Add a method near `_triggerRefresh` (after it, around line 170):

```dart
  void _triggerSignin(AuthCardButton button) {
    if (button.type.toLowerCase() != 'signin') {
      assert(() {
        developer.log(
          'Ignoring non-signin authentication button: ${button.type}',
          name: runtimeType.toString(),
        );
        return true;
      }());
      return;
    }

    final invoke = SigninActionInvoke.fromButton(
      button,
      connectionName: _authConfig?.connectionName,
    );

    final handlers = InheritedAdaptiveCardHandlers.of(context);
    if (handlers?.onSignin != null) {
      handlers!.onSignin!(invoke);
      return;
    }

    final value = invoke.value;
    if (handlers != null && value.startsWith('http')) {
      handlers.onOpenUrl(OpenUrlActionInvoke(url: value));
      return;
    }

    assert(() {
      developer.log(
        'authentication sign-in tapped but no onSignin handler '
        'and value is not a URL: $value',
        name: runtimeType.toString(),
      );
      return true;
    }());
  }
```

> If `developer` is not already imported in this file, add
> `import 'dart:developer' as developer;` at the top. Check the existing imports
> first — the file logs elsewhere, so it is likely already present.

- [ ] **Step 5: Render the region in `build`**

In `build`, after the `_refreshConfig?.action != null` block (around line 321)
and before the `backgroundImage` block, add:

```dart
    if (_authConfig != null && _authConfig!.buttons.isNotEmpty) {
      final auth = _authConfig!;
      result = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          result,
          _AuthenticationRegion(
            config: auth,
            onSignin: _triggerSignin,
          ),
        ],
      );
    }
```

- [ ] **Step 6: Add the `_AuthenticationRegion` widget**

Add near `_RefreshAffordance` (end of file, around line 433):

```dart
/// Sign-in affordance shown when root card JSON defines `authentication`.
///
/// Renders the optional prompt text and one button per
/// [AuthenticationConfig.buttons] entry.
class _AuthenticationRegion extends StatelessWidget {
  const _AuthenticationRegion({
    required this.config,
    required this.onSignin,
  });

  final AuthenticationConfig config;
  final void Function(AuthCardButton button) onSignin;

  @override
  Widget build(BuildContext context) {
    final text = config.text;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text != null && text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(text),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final button in config.buttons)
                Semantics(
                  button: true,
                  label: button.title ?? button.type,
                  child: ElevatedButton.icon(
                    icon: (button.image != null && button.image!.isNotEmpty)
                        ? Image.network(
                            button.image!,
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          )
                        : const SizedBox.shrink(),
                    label: Text(button.title ?? 'Sign in'),
                    onPressed: () => onSignin(button),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Run the widget test to verify it passes**

Run: `fvm flutter test test/cards/authentication_region_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 8: Analyze**

Run: `fvm flutter analyze lib/src/cards/adaptive_card_element.dart`
Expected: No new errors/warnings.

- [ ] **Step 9: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart \
        packages/flutter_adaptive_cards_fs/test/cards/authentication_region_test.dart
git commit -m "feat(cards): render authentication sign-in region and dispatch onSignin"
```

---

### Task 5: Golden test for the authentication region

**Files:**
- Test: `packages/flutter_adaptive_cards_fs/test/goldens/authentication_signin_test.dart` (match the repo's existing golden test location/pattern)
- Golden fixture JSON: add under the repo's golden card fixtures directory used by other golden tests.

- [ ] **Step 1: Find the golden pattern**

Run: `ls packages/flutter_adaptive_cards_fs/test/**/gold_files 2>/dev/null; grep -rl "matchesGoldenFile\|@Tags(\['golden'\])" packages/flutter_adaptive_cards_fs/test | head`
Expected: identifies an existing golden test file + the `gold_files/<platform>/`
baseline layout referenced in `docs/Implementation-Status.md`.

- [ ] **Step 2: Write the golden test mirroring an existing one**

Copy the smallest existing golden test (e.g. an icon or rating golden), rename
to `authentication_signin_test.dart`, tag it `@Tags(['golden'])`, and point it
at a new fixture card containing the `authentication` object from Task 4's
`cardJson`. Use the same `loadBundledTestFonts()` / `adaptiveCardsTestExecutable`
setup the sibling golden uses (see the "Load icon font in golden tests" note in
`docs/Implementation-Status.md`). Name the golden `v1_4_authentication_signin`.

- [ ] **Step 3: Generate the baseline (affected platform only)**

Run: `fvm flutter test --update-goldens test/goldens/authentication_signin_test.dart`
Expected: PASS; a new `v1_4_authentication_signin-*.png` baseline is written.

- [ ] **Step 4: Re-run without updating to confirm determinism**

Run: `fvm flutter test test/goldens/authentication_signin_test.dart`
Expected: PASS against the just-generated baseline.

- [ ] **Step 5: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_fs/test/goldens/authentication_signin_test.dart \
        packages/flutter_adaptive_cards_fs/test/**/v1_4_authentication_signin*
git commit -m "test(cards): golden for authentication sign-in region"
```

---

### Task 6: Phase 1 docs + verification

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/README.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`
- Modify: `docs/actions-architecture.md`
- Modify: `docs/Implementation-Status.md`

- [ ] **Step 1: Update the core README Implementation status**

In `packages/flutter_adaptive_cards_fs/README.md` → Root `AdaptiveCard`
Properties table, change the `authentication` row from `❌ Missing` to
`⚠️ Partial` with the note: "Sign-in button path (`buttons[].type: signin`) via
`onSignin` handler; SSO `tokenExchangeResource` parsed but not exchanged." Update
the `### Known gaps` `AdaptiveCard root` row to drop `authentication` from the
missing list (leave `rtl`, `minHeight`, `verticalContentAlignment`).

- [ ] **Step 2: Document the handler in actions-architecture.md**

Run: `grep -n "onRefresh\|onHttp" docs/actions-architecture.md`
Then add an `onSignin` / `SigninActionInvoke` subsection alongside the existing
handler docs, describing the tap → `onSignin` handoff and the `onOpenUrl`
fallback.

- [ ] **Step 3: Update the status index**

In `docs/Implementation-Status.md`, remove root `authentication` from any
"missing/deferred" phrasing and add a `### Root authentication sign-in
(2026-07-02)` bullet under **Recently completed** (button path; SSO deferred).

- [ ] **Step 4: Add CHANGELOG entry**

In `packages/flutter_adaptive_cards_fs/CHANGELOG.md` under `## [Unreleased]`:

```markdown
- Add root `authentication` sign-in button support: parse the `authentication`
  object, render a sign-in region, and forward a `SigninActionInvoke` to the new
  nullable `onSignin` handler (falls back to `onOpenUrl` for URL values). SSO
  `tokenExchangeResource` is parsed but not exchanged.
```

- [ ] **Step 5: Run the Phase 1 verification suite**

Run (from `packages/flutter_adaptive_cards_fs/`):

```bash
fvm flutter analyze
fvm flutter test --exclude-tags=golden
fvm flutter test --tags=golden test/goldens/authentication_signin_test.dart
```

Expected: analyze clean; non-golden suite passes with no regressions; the new
golden passes. Record the pass/fail counts.

- [ ] **Step 6: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_fs/README.md \
        packages/flutter_adaptive_cards_fs/CHANGELOG.md \
        docs/actions-architecture.md docs/Implementation-Status.md
git commit -m "docs(cards): document authentication sign-in support"
```

---

# Phase 2 — host transport (`flutter_adaptive_cards_host_fs`)

Run all Phase 2 commands from `packages/flutter_adaptive_cards_host_fs/` unless noted.

### Task 7: Invoke request `signin` kind + `fromSignin`

**Files:**
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/models/invoke_kind.dart`
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/models/invoke_request.dart`
- Test: `packages/flutter_adaptive_cards_host_fs/test/models/invoke_request_signin_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/invoke_request_signin_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromSignin carries connectionName, url, and state', () {
    const invoke = SigninActionInvoke(
      value: 'https://login.example.com/oauth',
      connectionName: 'myConnection',
    );

    final request = AdaptiveCardInvokeRequest.fromSignin(
      invoke,
      state: 'magic-123',
    );

    expect(request.kind, AdaptiveCardInvokeKind.signin);
    expect(request.connectionName, 'myConnection');
    expect(request.url, 'https://login.example.com/oauth');
    expect(request.value, 'magic-123');
  });
}
```

> Confirm `AdaptiveCardInvokeRequest`, `AdaptiveCardInvokeKind`, and
> `SigninActionInvoke` are all exported from
> `flutter_adaptive_cards_host_fs.dart` (host barrel re-exports the core). If
> `AdaptiveCardInvokeKind` is not exported, import it or add the export.

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/models/invoke_request_signin_test.dart`
Expected: FAIL — `signin` enum value and `fromSignin` do not exist.

- [ ] **Step 3: Add the enum value**

In `lib/src/models/invoke_kind.dart`, add:

```dart
  /// Card `authentication` sign-in completion (Bot Framework `signin/*`).
  signin,
```

- [ ] **Step 3a: Keep the package compiling — add the Teams `switch` case now**

Adding the enum value makes `TeamsInvokeAdapter.toMap`'s exhaustive `switch`
non-exhaustive, a **package-wide compile error**. Add the `signin` case in the
same task so every subsequent test builds. In
`lib/src/adapters/teams_invoke_adapter.dart`, add inside the `switch` in `toMap`:

```dart
      case AdaptiveCardInvokeKind.signin:
        return {
          'type': 'invoke',
          'name': 'signin/verifyState',
          'value': {
            'state': request.value?.toString(),
          },
        };
```

(Task 9 adds the test that pins this behavior.)

- [ ] **Step 4: Add the field + factory**

In `lib/src/models/invoke_request.dart`, add `this.connectionName,` to the
constructor, add the factory after `fromOpenUrlDialog`:

```dart
  /// Sign-in completion payload from a card `authentication` button.
  ///
  /// [state] is the magic code / verification state the app captured from the
  /// OAuth redirect.
  factory AdaptiveCardInvokeRequest.fromSignin(
    SigninActionInvoke invoke, {
    required String state,
  }) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.signin,
      connectionName: invoke.connectionName,
      url: invoke.value,
      value: state,
    );
  }
```

And add the field (near `url`):

```dart
  /// OAuth connection name for [AdaptiveCardInvokeKind.signin].
  final String? connectionName;
```

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/models/invoke_request_signin_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_host_fs/lib/src/models/invoke_kind.dart \
        packages/flutter_adaptive_cards_host_fs/lib/src/models/invoke_request.dart \
        packages/flutter_adaptive_cards_host_fs/lib/src/adapters/teams_invoke_adapter.dart \
        packages/flutter_adaptive_cards_host_fs/test/models/invoke_request_signin_test.dart
git commit -m "feat(host): add signin invoke kind, fromSignin factory, Teams case"
```

---

### Task 8: PlainJson adapter — serialize `connectionName`

**Files:**
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/adapters/plain_json_invoke_adapter.dart`
- Test: `packages/flutter_adaptive_cards_host_fs/test/adapters/plain_json_signin_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/adapters/plain_json_signin_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlainJson round-trips a signin request', () {
    const invoke = SigninActionInvoke(
      value: 'https://login.example.com/oauth',
      connectionName: 'myConnection',
    );
    final request = AdaptiveCardInvokeRequest.fromSignin(
      invoke,
      state: 'magic-123',
    );

    final map = PlainJsonInvokeAdapter.toMap(request);
    expect(map['kind'], 'signin');
    expect(map['connectionName'], 'myConnection');
    expect(map['url'], 'https://login.example.com/oauth');
    expect(map['value'], 'magic-123');

    final restored = PlainJsonInvokeAdapter.requestFromMap(map);
    expect(restored.kind, AdaptiveCardInvokeKind.signin);
    expect(restored.connectionName, 'myConnection');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/adapters/plain_json_signin_test.dart`
Expected: FAIL — `connectionName` missing from serialized map / restored request.

- [ ] **Step 3: Add `connectionName` to serialize + parse**

In `lib/src/adapters/plain_json_invoke_adapter.dart`, in `toMap` add (after the
`url` line):

```dart
      if (request.connectionName != null)
        'connectionName': request.connectionName,
```

In `requestFromMap`, add to the constructor call:

```dart
      connectionName: map['connectionName'] as String?,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/adapters/plain_json_signin_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_host_fs/lib/src/adapters/plain_json_invoke_adapter.dart \
        packages/flutter_adaptive_cards_host_fs/test/adapters/plain_json_signin_test.dart
git commit -m "feat(host): serialize signin connectionName in PlainJson adapter"
```

---

### Task 9: Teams adapter — pin `signin/verifyState`

> The `signin` case was added in Task 7 Step 3a to keep the package compiling.
> This task adds the test that locks its behavior in. If Task 7 was somehow done
> without the case, add it here (see Task 7 Step 3a) before Step 2.

**Files:**
- Test: `packages/flutter_adaptive_cards_host_fs/test/adapters/teams_signin_test.dart`
- (Implementation already added in Task 7 Step 3a.)

- [ ] **Step 1: Write the test**

Create `test/adapters/teams_signin_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Teams adapter emits signin/verifyState with state', () {
    const invoke = SigninActionInvoke(
      value: 'https://login.example.com/oauth',
      connectionName: 'myConnection',
    );
    final request = AdaptiveCardInvokeRequest.fromSignin(
      invoke,
      state: 'magic-123',
    );

    final map = TeamsInvokeAdapter.toMap(request);
    expect(map['type'], 'invoke');
    expect(map['name'], 'signin/verifyState');
    expect((map['value'] as Map)['state'], 'magic-123');
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `fvm flutter test test/adapters/teams_signin_test.dart`
Expected: PASS (the `signin` case from Task 7 Step 3a produces
`signin/verifyState`).

- [ ] **Step 3: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_host_fs/test/adapters/teams_signin_test.dart
git commit -m "test(host): pin Teams signin/verifyState mapping"
```

---

### Task 10: `AdaptiveCardBackendHandlers` — `onSignin` wiring + `completeSignin`

**Files:**
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/handlers/backend_handlers.dart`
- Test: `packages/flutter_adaptive_cards_host_fs/test/handlers/backend_handlers_signin_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/handlers/backend_handlers_signin_test.dart`. Reuse the existing
backend-handler test's mock client + card harness (open a sibling test under
`test/handlers/` to copy the `AdaptiveCardBackendClient` fake and the
`cardKey`/`RawAdaptiveCard` setup). The test:

```dart
// imports: flutter, flutter_test, both packages, plus the sibling test's
// fake client. See an existing test/handlers/*_test.dart for the fake.

void main() {
  testWidgets('sign-in tap opens URL; completeSignin replaces the card',
      (tester) async {
    final opened = <String>[];
    Map<String, dynamic>? replacement;

    // Fake client returns a plain-json replaceCard response.
    final client = FakeBackendClient(
      response: {
        'effects': [
          {
            'type': 'replaceCard',
            'card': {
              'type': 'AdaptiveCard',
              'version': '1.4',
              'body': [
                {'type': 'TextBlock', 'text': 'Signed in'},
              ],
            },
          },
        ],
      },
    );

    final cardKey = GlobalKey<RawAdaptiveCardState>();
    final handlers = AdaptiveCardBackendHandlers(
      client: client,
      cardKey: cardKey,
      urlOpener: (url) async => opened.add(url),
    );

    // ... pump a RawAdaptiveCard(cardKey, authentication card json) wrapped in
    //     handlers.wrap(child, onCardReplaced: (c) => replacement = c) ...

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(opened, ['https://login.example.com/oauth']);

    await handlers.completeSignin(state: 'magic-123');
    await tester.pumpAndSettle();
    expect(replacement, isNotNull);
    expect(replacement!['body'], isNotEmpty);
  });
}
```

> Match the exact `AdaptiveCardBackendClient` interface and the plain-json
> `replaceCard` response shape from an existing handler test; the snippet above
> shows intent, not verbatim fixtures. Keep the two assertions (URL opened, card
> replaced) and add one asserting `onError` fires when the client throws.

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/handlers/backend_handlers_signin_test.dart`
Expected: FAIL — `urlOpener` param and `completeSignin` do not exist.

- [ ] **Step 3: Add constructor params + fields**

In `lib/src/handlers/backend_handlers.dart`, add to the constructor:

```dart
    this.urlOpener,
    this.onSignin,
```

Add fields (near `onOpenUrl`):

```dart
  /// Opens the sign-in URL from a card `authentication` button.
  ///
  /// The app owns the browser/redirect; when null, sign-in taps are ignored.
  final Future<void> Function(String url)? urlOpener;

  /// Optional override for the sign-in handoff (defaults to [urlOpener]).
  final void Function(SigninActionInvoke invoke)? onSignin;
```

Add a private field to remember the in-flight sign-in:

```dart
  SigninActionInvoke? _pendingSignin;
```

- [ ] **Step 4: Wire `onSignin` in `wrap`**

In `wrap(...)`, add to the `InheritedAdaptiveCardHandlers(...)` argument list:

```dart
      onSignin: (invoke) {
        _pendingSignin = invoke;
        final override = onSignin;
        if (override != null) {
          override(invoke);
          return;
        }
        final opener = urlOpener;
        if (opener != null && invoke.value.isNotEmpty) {
          unawaited(opener(invoke.value));
        }
      },
```

- [ ] **Step 5: Add `completeSignin`**

Add a public method (after `wrap`, before `_handleHttp`). It reuses the private
`_handle` used by Submit/Execute:

```dart
  /// Completes a card sign-in after the app captures the OAuth redirect.
  ///
  /// POSTs a sign-in invoke (built from the last `onSignin` payload plus
  /// [state]) and applies the response — a `replaceCard` effect swaps in the
  /// real card. Call after [urlOpener]'s flow returns.
  Future<void> completeSignin({
    required String state,
    void Function(Map<String, dynamic> card)? onCardReplaced,
    AdaptiveCardValidator? cardValidator,
  }) async {
    final pending = _pendingSignin;
    if (pending == null) {
      onError?.call(
        StateError('completeSignin called with no pending sign-in'),
      );
      return;
    }
    await _handle(
      AdaptiveCardInvokeRequest.fromSignin(pending, state: state),
      onCardReplaced: onCardReplaced,
      cardValidator: cardValidator,
    );
    _pendingSignin = null;
  }
```

> `wrap`'s `onCardReplaced`/`cardValidator` are captured in its closure, not on
> the instance. Expose them: store `wrap`'s `onCardReplaced` and `cardValidator`
> in instance fields when `wrap` is called, and have `completeSignin` default its
> optional params to those fields. Add:
> ```dart
>   void Function(Map<String, dynamic> card)? _onCardReplaced;
>   AdaptiveCardValidator? _cardValidator;
> ```
> set them at the top of `wrap`, and in `completeSignin` use
> `onCardReplaced ?? _onCardReplaced` and `cardValidator ?? _cardValidator`.

- [ ] **Step 6: Run test to verify it passes**

Run: `fvm flutter test test/handlers/backend_handlers_signin_test.dart`
Expected: PASS.

- [ ] **Step 7: Analyze**

Run: `fvm flutter analyze lib/src/handlers/backend_handlers.dart`
Expected: no new issues (`unawaited` is already imported in this file).

- [ ] **Step 8: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_host_fs/lib/src/handlers/backend_handlers.dart \
        packages/flutter_adaptive_cards_host_fs/test/handlers/backend_handlers_signin_test.dart
git commit -m "feat(host): wire onSignin and add completeSignin round-trip"
```

---

### Task 11: Phase 2 docs + full verification

**Files:**
- Modify: `packages/flutter_adaptive_cards_host_fs/README.md`
- Modify: `packages/flutter_adaptive_cards_host_fs/CHANGELOG.md`
- Modify: `docs/backend-host-integration.md`

- [ ] **Step 1: Update host README + CHANGELOG**

Add a sign-in bullet to `packages/flutter_adaptive_cards_host_fs/README.md`
(Implementation status / features) and to `CHANGELOG.md` under `## [Unreleased]`:

```markdown
- Add card `authentication` sign-in support: `AdaptiveCardBackendHandlers` opens
  the sign-in URL via `urlOpener` and `completeSignin(state:)` POSTs a signin
  invoke (`signin/verifyState` for Teams) whose `replaceCard` response swaps in
  the returned card.
```

- [ ] **Step 2: Update backend-host-integration doc**

Run: `grep -n "onRefresh\|ReplaceCardEffect\|completeS" docs/backend-host-integration.md`
Then add a "Sign-in (authentication)" subsection documenting the
`urlOpener` → tap → `completeSignin` → `replaceCard` flow.

- [ ] **Step 3: Full verification suite (completion gate)**

Run (repo root):

```bash
fvm flutter analyze
```

Run (from `packages/flutter_adaptive_cards_fs/`):

```bash
fvm flutter test --exclude-tags=golden
fvm flutter test --tags=golden
```

Run (from `packages/flutter_adaptive_cards_host_fs/`):

```bash
fvm flutter test --exclude-tags=golden
```

Run (repo root, coverage gate — generate coverage first per repo convention):

```bash
fvm dart run tool/coverage/check_coverage.dart
```

Expected: analyze clean; all suites pass with no regressions; coverage floors
hold for both packages (add tests rather than lowering floors). Invoke the
`verification-before-completion` skill and paste the command output (exit codes,
pass/fail counts) before claiming completion.

- [ ] **Step 4: Commit** (gate)

```bash
git add packages/flutter_adaptive_cards_host_fs/README.md \
        packages/flutter_adaptive_cards_host_fs/CHANGELOG.md \
        docs/backend-host-integration.md
git commit -m "docs(host): document authentication sign-in round-trip"
```

---

## Self-review checklist (for the plan author — already done)

- **Spec coverage:** Phase 1 model (T1), invoke payload (T2), handler (T3),
  parse+render+dispatch+fallback (T4), golden (T5), docs (T6). Phase 2 invoke
  kind/factory (T7), PlainJson (T8), Teams (T9), handler round-trip (T10), docs +
  full verification (T11). Non-goals (SSO token exchange, bundled webview) are
  explicitly excluded. ✅
- **No placeholders:** every code step shows real code; test bodies are complete.
  Two tasks (T4 widget harness, T10 fake client) instruct copying the exact
  existing test harness rather than inventing one — with the required assertions
  spelled out. ✅
- **Type consistency:** `AuthenticationConfig` / `AuthCardButton` /
  `SigninActionInvoke` (core) and `AdaptiveCardInvokeKind.signin` /
  `AdaptiveCardInvokeRequest.fromSignin(..., state:)` / `connectionName` /
  `completeSignin(state:)` / `urlOpener` (host) are used identically across
  tasks. The Teams `switch` exhaustiveness hazard is handled by adding both the
  enum value and its `signin` case in T7 (Step 3a) so the package never stops
  compiling; T9 only adds the pinning test. ✅
