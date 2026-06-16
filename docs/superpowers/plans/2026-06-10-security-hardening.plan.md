# Security Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the Flutter-AdaptiveCards monorepo against untrusted card JSON and backend responses by introducing shared URL/fetch policies, wiring them into default action and content-loading paths, and adding bounded deserialization in the host package — delivered in six incremental phases.

**Architecture:** Introduce a small, testable `AdaptiveUriPolicy` + `AdaptiveFetchPolicy` layer in `flutter_adaptive_cards_fs` (scheme allowlists, private-network blocking, response byte caps). Wire policies into default `Action.OpenUrl`, markdown link taps, `Action.OpenUrlDialog` fetches, and `NetworkAdaptiveCardContentProvider` via an `InheritedAdaptiveCardSecurityPolicy` widget and explicit constructor parameters where `BuildContext` is unavailable. Extend `flutter_adaptive_cards_host_fs` with bounded JSON decoding and optional response validation hooks. Phase 5–6 cover lower-severity resource loading and template `json()` bounds.

**Tech Stack:** Dart 3.12+, Flutter (FVM), `flutter_adaptive_cards_fs`, `flutter_adaptive_cards_host_fs`, `flutter_adaptive_template_fs`, `http`, `url_launcher`, `package:flutter_test`, `very_good_analysis`.

**Source:** Security review (2026-06-10) — High: OpenUrlDialog SSRF, NetworkAdaptiveCardContentProvider SSRF; Medium: unvalidated OpenUrl/markdown links, trusted-backend assumptions, unbounded backend JSON; Low: image/media URLs, template `json()`.

## Status (2026-06-16)

| Phase | Status     | Notes                                                   |
| ----- | ---------- | ------------------------------------------------------- |
| 1     | ❌ Pending | Policy utilities not yet started                        |
| 2     | ❌ Pending | OpenUrl and markdown wiring not yet started             |
| 3     | ❌ Pending | Remote fetch guards not yet started                     |
| 4     | ❌ Pending | Backend response hardening not yet started              |
| 5     | ❌ Pending | Resource URL policy not yet started                     |
| 6     | ❌ Pending | Template bounds, docs, and verification not yet started |

**Current Codebase Verification:**

- Evaluated against `main` branch (working tree clean).
- No stashes or branch changes contain partial security implementations.
- Codebase structure is ready for integration: `default_actions.dart`, `text_block.dart`, `rich_text_block.dart`, `media.dart`, `adaptive_image_utils.dart`, and `evaluator.dart` contain the exact targeted hooks and line mappings defined in this plan.

---

## Phase overview

| Phase | Scope                                                        | Addresses                             | Packages                             |
| ----- | ------------------------------------------------------------ | ------------------------------------- | ------------------------------------ |
| **1** | `AdaptiveUriPolicy` + `AdaptiveFetchPolicy` utilities        | Foundation for all URL/fetch guards   | `flutter_adaptive_cards_fs`          |
| **2** | Wire URI policy into OpenUrl, markdown, OpenUrlDialog launch | Medium OpenUrl + markdown findings    | `flutter_adaptive_cards_fs`          |
| **3** | Guard remote card/content fetches (SSRF + size caps)         | High OpenUrlDialog + Network provider | `flutter_adaptive_cards_fs`          |
| **4** | Bounded backend JSON decode + optional card validator        | Medium backend trust / DoS            | `flutter_adaptive_cards_host_fs`     |
| **5** | Resource URL policy for images, SVG, media                   | Low image/media findings              | `flutter_adaptive_cards_fs`          |
| **6** | Template `json()` bounds + docs + full verification          | Low template + host integration docs  | `flutter_adaptive_template_fs`, docs |

Each phase ships working, testable software. Phases 1–3 are the highest priority for untrusted card JSON.

---

## File map

### Phase 1 — Policy utilities

| File                                                                                 | Role                                    |
| ------------------------------------------------------------------------------------ | --------------------------------------- |
| `packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_policy.dart`       | **Create** — scheme/host validation     |
| `packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_fetch_policy.dart`     | **Create** — fetch byte cap + timeout   |
| `packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_validation.dart`   | **Create** — sealed result types        |
| `packages/flutter_adaptive_cards_fs/lib/src/security/inherited_security_policy.dart` | **Create** — `InheritedWidget` resolver |
| `packages/flutter_adaptive_cards_fs/test/security/adaptive_uri_policy_test.dart`     | **Create** — unit tests                 |
| `packages/flutter_adaptive_cards_fs/test/security/adaptive_fetch_policy_test.dart`   | **Create** — unit tests                 |

### Phase 2 — Action + markdown wiring

| File                                                                                    | Role                                          |
| --------------------------------------------------------------------------------------- | --------------------------------------------- |
| `packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`                | Validate before `launchUrl`                   |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/text_block.dart`             | Validate markdown `href`                      |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/rich_text_block.dart`        | Validate `selectAction` URLs if present       |
| `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`             | Install `InheritedAdaptiveCardSecurityPolicy` |
| `packages/flutter_adaptive_cards_fs/lib/flutter_adaptive_cards_fs.dart`                 | Export public policy types                    |
| `packages/flutter_adaptive_cards_fs/test/actions/open_url_policy_test.dart`             | **Create** — blocked scheme tests             |
| `packages/flutter_adaptive_cards_fs/test/elements/text_block_markdown_policy_test.dart` | **Create** — blocked link tests               |

### Phase 3 — Remote fetch guards

| File                                                                                        | Role                                |
| ------------------------------------------------------------------------------------------- | ----------------------------------- |
| `packages/flutter_adaptive_cards_fs/lib/src/action/open_url_dialog_executor.dart`           | Policy check + bounded fetch        |
| `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart`                     | Pass policy into network provider   |
| `packages/flutter_adaptive_cards_fs/test/elements/actions/open_url_dialog_policy_test.dart` | **Create** — blocked fetch tests    |
| `packages/flutter_adaptive_cards_fs/test/adaptive_cards_canvas_network_policy_test.dart`    | **Create** — network provider tests |

### Phase 4 — Host package bounds

| File                                                                                | Role                                  |
| ----------------------------------------------------------------------------------- | ------------------------------------- |
| `packages/flutter_adaptive_cards_host_fs/lib/src/security/bounded_json.dart`        | **Create** — `decodeJsonMapWithLimit` |
| `packages/flutter_adaptive_cards_host_fs/lib/src/client/http_backend_client.dart`   | Use bounded decode                    |
| `packages/flutter_adaptive_cards_host_fs/lib/src/models/invoke_response.dart`       | Optional `cardValidator` on `applyTo` |
| `packages/flutter_adaptive_cards_host_fs/lib/src/handlers/backend_handlers.dart`    | Thread `cardValidator`                |
| `packages/flutter_adaptive_cards_host_fs/lib/flutter_adaptive_cards_host_fs.dart`   | Export bounded JSON helper            |
| `packages/flutter_adaptive_cards_host_fs/test/security/bounded_json_test.dart`      | **Create**                            |
| `packages/flutter_adaptive_cards_host_fs/test/client/http_backend_client_test.dart` | Add oversize body test                |

### Phase 5 — Resource loading

| File                                                                            | Role                                     |
| ------------------------------------------------------------------------------- | ---------------------------------------- |
| `packages/flutter_adaptive_cards_fs/lib/src/utils/adaptive_image_utils.dart`    | Optional policy gate before network load |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/media.dart`          | Validate `sourceUrl` before player init  |
| `packages/flutter_adaptive_cards_fs/test/utils/adaptive_image_policy_test.dart` | **Create**                               |
| `packages/flutter_adaptive_cards_fs/test/elements/media_policy_test.dart`       | **Create**                               |

### Phase 6 — Template + docs

| File                                                                              | Role                                     |
| --------------------------------------------------------------------------------- | ---------------------------------------- |
| `packages/flutter_adaptive_template_fs/lib/src/evaluator.dart`                    | Cap `json()` input length + decode depth |
| `packages/flutter_adaptive_template_fs/test/unit/evaluator_json_bounds_test.dart` | **Create**                               |
| `docs/backend-host-integration.md`                                                | Trust-boundary + policy guidance         |
| `packages/flutter_adaptive_cards_fs/README.md`                                    | `AdaptiveUriPolicy` usage                |
| `packages/flutter_adaptive_cards_host_fs/README.md`                               | Response size limits + `cardValidator`   |
| `packages/flutter_adaptive_cards_fs/CHANGELOG.md`                                 | `[Unreleased]` security entries          |
| `packages/flutter_adaptive_cards_host_fs/CHANGELOG.md`                            | `[Unreleased]` security entries          |

---

## Phase 1 — Policy utilities

### Task 1: URI validation types and policy

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_validation.dart`
- Create: `packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_policy.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/security/adaptive_uri_policy_test.dart`

- [ ] **Step 1: Write failing unit tests**

```dart
// packages/flutter_adaptive_cards_fs/test/security/adaptive_uri_policy_test.dart
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = AdaptiveUriPolicy.standard;

  group('AdaptiveUriPolicy.standard', () {
    test('allows https public host', () {
      final result = policy.validate('https://example.com/path');
      expect(result, isA<AdaptiveUriAllowed>());
      expect((result as AdaptiveUriAllowed).uri.host, 'example.com');
    });

    test('denies javascript scheme', () {
      final result = policy.validate('javascript:alert(1)');
      expect(result, isA<AdaptiveUriDenied>());
      expect((result as AdaptiveUriDenied).reason, contains('scheme'));
    });

    test('denies file scheme', () {
      final result = policy.validate('file:///etc/passwd');
      expect(result, isA<AdaptiveUriDenied>());
    });

    test('denies loopback when disabled', () {
      final result = policy.validate('http://127.0.0.1/admin');
      expect(result, isA<AdaptiveUriDenied>());
      expect((result as AdaptiveUriDenied).reason, contains('loopback'));
    });

    test('denies RFC1918 private IPv4', () {
      final result = policy.validate('http://192.168.1.1/internal');
      expect(result, isA<AdaptiveUriDenied>());
      expect((result as AdaptiveUriDenied).reason, contains('private'));
    });

    test('denies empty url', () {
      final result = policy.validate('');
      expect(result, isA<AdaptiveUriDenied>());
    });

    test('permits loopback when policy allows', () {
      const devPolicy = AdaptiveUriPolicy(
        allowedSchemes: {'http', 'https'},
        allowLoopback: true,
        allowPrivateHosts: true,
      );
      final result = devPolicy.validate('http://127.0.0.1:8080');
      expect(result, isA<AdaptiveUriAllowed>());
    });

    test('permits mailto and tel schemes when added to allowedSchemes', () {
      const customPolicy = AdaptiveUriPolicy(
        allowedSchemes: {'https', 'http', 'mailto', 'tel'},
      );
      final mailtoResult = customPolicy.validate('mailto:someone@example.com');
      expect(mailtoResult, isA<AdaptiveUriAllowed>());

      final telResult = customPolicy.validate('tel:123-456-7890');
      expect(telResult, isA<AdaptiveUriAllowed>());
    });

    test('denies mailto when not in allowedSchemes', () {
      const policy = AdaptiveUriPolicy.standard;
      final result = policy.validate('mailto:someone@example.com');
      expect(result, isA<AdaptiveUriDenied>());
      expect((result as AdaptiveUriDenied).reason, contains('scheme'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/security/adaptive_uri_policy_test.dart`
Expected: FAIL — files/classes not found.

- [ ] **Step 3: Implement validation types and policy**

```dart
// packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_validation.dart
/// Outcome of [AdaptiveUriPolicy.validate].
sealed class AdaptiveUriValidationResult {
  const AdaptiveUriValidationResult();
}

/// [url] passed policy checks; use [uri] for launch/fetch.
class AdaptiveUriAllowed extends AdaptiveUriValidationResult {
  const AdaptiveUriAllowed(this.uri);
  final Uri uri;
}

/// [url] was rejected; [reason] is safe to log (no secrets).
class AdaptiveUriDenied extends AdaptiveUriValidationResult {
  const AdaptiveUriDenied(this.reason);
  final String reason;
}
```

```dart
// packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_policy.dart
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';

/// Validates card-controlled URLs before launch or HTTP fetch.
class AdaptiveUriPolicy {
  const AdaptiveUriPolicy({
    this.allowedSchemes = const {'https', 'http'},
    this.allowLoopback = false,
    this.allowPrivateHosts = false,
    this.allowedHosts,
  });

  /// Default production policy: https/http only, no private networks.
  static const standard = AdaptiveUriPolicy();

  /// Relaxed policy for local widget tests and dev servers.
  static const development = AdaptiveUriPolicy(
    allowLoopback: true,
    allowPrivateHosts: true,
  );

  final Set<String> allowedSchemes;
  final bool allowLoopback;
  final bool allowPrivateHosts;

  /// When non-null, only these hosts (case-insensitive) are permitted.
  final Set<String>? allowedHosts;

  AdaptiveUriValidationResult validate(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return const AdaptiveUriDenied('URL is empty');
    }

    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on Object {
      return const AdaptiveUriDenied('URL is not parseable');
    }

    final scheme = uri.scheme.toLowerCase();
    if (!allowedSchemes.contains(scheme)) {
      return AdaptiveUriDenied('Scheme "$scheme" is not allowed');
    }

    final host = uri.host.toLowerCase();
    final isHttpOrHttps = scheme == 'http' || scheme == 'https';
    if (isHttpOrHttps && host.isEmpty) {
      return const AdaptiveUriDenied('URL host is missing');
    }

    if (host.isNotEmpty) {
      if (allowedHosts != null && !allowedHosts!.contains(host)) {
        return AdaptiveUriDenied('Host "$host" is not in the allowlist');
      }

      if (!allowLoopback && _isLoopback(host)) {
        return const AdaptiveUriDenied('Loopback hosts are not allowed');
      }

      if (!allowPrivateHosts && _isPrivateHost(host)) {
        return const AdaptiveUriDenied('Private network hosts are not allowed');
      }
    }

    return AdaptiveUriAllowed(uri);
  }

  bool _isLoopback(String host) {
    if (host == 'localhost') return true;
    if (host == '::1') return true;
  // IPv4 loopback 127.0.0.0/8
    final parts = host.split('.');
    if (parts.length == 4) {
      final first = int.tryParse(parts[0]);
      if (first == 127) return true;
    }
    return false;
  }

  bool _isPrivateHost(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((o) => o == null || o < 0 || o > 255)) return false;
    final a = octets[0]!;
    final b = octets[1]!;
    if (a == 10) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 192 && b == 168) return true;
    if (a == 169 && b == 254) return true; // link-local
    return false;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/security/adaptive_uri_policy_test.dart`
Expected: PASS (all tests green).

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_validation.dart \
        packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_uri_policy.dart \
        packages/flutter_adaptive_cards_fs/test/security/adaptive_uri_policy_test.dart
git commit -m "feat(cards): add AdaptiveUriPolicy for card-controlled URLs"
```

---

### Task 2: Fetch policy + inherited resolver

**Files:**

- Create: `packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_fetch_policy.dart`
- Create: `packages/flutter_adaptive_cards_fs/lib/src/security/inherited_security_policy.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/security/adaptive_fetch_policy_test.dart`

- [ ] **Step 1: Write failing unit test for byte cap helper**

```dart
// packages/flutter_adaptive_cards_fs/test/security/adaptive_fetch_policy_test.dart
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readBodyWithLimit throws when body exceeds cap', () {
    final body = List<int>.filled(AdaptiveFetchPolicy.standard.maxBytes + 1, 0x41);
    expect(
      () => readBodyWithLimit(body, AdaptiveFetchPolicy.standard.maxBytes),
      throwsA(isA<AdaptiveFetchTooLargeException>()),
    );
  });

  test('readBodyWithLimit returns body when within cap', () {
    final body = [72, 73]; // "HI"
    expect(readBodyWithLimit(body, 10), body);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/security/adaptive_fetch_policy_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement fetch policy and inherited widget**

```dart
// packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_fetch_policy.dart
/// Thrown when a remote response body exceeds [AdaptiveFetchPolicy.maxBytes].
class AdaptiveFetchTooLargeException implements Exception {
  const AdaptiveFetchTooLargeException(this.maxBytes);
  final int maxBytes;

  @override
  String toString() => 'AdaptiveFetchTooLargeException: exceeded $maxBytes bytes';
}

/// Limits for card-initiated HTTP GETs.
class AdaptiveFetchPolicy {
  const AdaptiveFetchPolicy({
    this.maxBytes = 1024 * 1024,
    this.timeout = const Duration(seconds: 15),
  });

  static const standard = AdaptiveFetchPolicy();

  final int maxBytes;
  final Duration timeout;
}

List<int> readBodyWithLimit(List<int> body, int maxBytes) {
  if (body.length > maxBytes) {
    throw AdaptiveFetchTooLargeException(maxBytes);
  }
  return body;
}
```

```dart
// packages/flutter_adaptive_cards_fs/lib/src/security/inherited_security_policy.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';

/// Supplies [uriPolicy] and [fetchPolicy] to descendant adaptive widgets.
class InheritedAdaptiveCardSecurityPolicy extends InheritedWidget {
  const InheritedAdaptiveCardSecurityPolicy({
    required this.uriPolicy,
    required this.fetchPolicy,
    required super.child,
    super.key,
  });

  final AdaptiveUriPolicy uriPolicy;
  final AdaptiveFetchPolicy fetchPolicy;

  static AdaptiveUriPolicy uriPolicyOf(BuildContext context) {
    return maybeOf(context)?.uriPolicy ?? AdaptiveUriPolicy.standard;
  }

  static AdaptiveFetchPolicy fetchPolicyOf(BuildContext context) {
    return maybeOf(context)?.fetchPolicy ?? AdaptiveFetchPolicy.standard;
  }

  static InheritedAdaptiveCardSecurityPolicy? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
        InheritedAdaptiveCardSecurityPolicy>();
  }

  @override
  bool updateShouldNotify(InheritedAdaptiveCardSecurityPolicy oldWidget) {
    return uriPolicy != oldWidget.uriPolicy ||
        fetchPolicy != oldWidget.fetchPolicy;
  }
}
```

- [ ] **Step 4: Run tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/security/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/security/adaptive_fetch_policy.dart \
        packages/flutter_adaptive_cards_fs/lib/src/security/inherited_security_policy.dart \
        packages/flutter_adaptive_cards_fs/test/security/adaptive_fetch_policy_test.dart
git commit -m "feat(cards): add fetch byte caps and inherited security policy"
```

---

## Phase 2 — OpenUrl and markdown wiring

### Task 3: Block disallowed URLs in DefaultOpenUrlAction

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/actions/open_url_policy_test.dart`

- [ ] **Step 1: Write failing widget test**

```dart
// packages/flutter_adaptive_cards_fs/test/actions/open_url_policy_test.dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('DefaultOpenUrl blocks javascript: when no host handler', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.OpenUrl',
          'title': 'Evil',
          'url': 'javascript:alert(1)',
        },
      ],
    };

    await tester.pumpWidget(
      InheritedAdaptiveCardSecurityPolicy(
        uriPolicy: AdaptiveUriPolicy.standard,
        fetchPolicy: AdaptiveFetchPolicy.standard,
        child: getTestWidgetFromMap(
          map: card,
          title: 'open url policy test',
          onOpenUrl: (_) => fail('host handler should not run'),
          onSubmit: (_) {},
          onExecute: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Evil'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not allowed'), findsOneWidget);
  });

  testWidgets('DefaultOpenUrl allows mailto: when scheme is allowed', (
    tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.OpenUrl',
          'title': 'Mail',
          'url': 'mailto:someone@example.com',
        },
      ],
    };

    var called = false;
    await tester.pumpWidget(
      InheritedAdaptiveCardSecurityPolicy(
        uriPolicy: const AdaptiveUriPolicy(
          allowedSchemes: {'https', 'http', 'mailto'},
        ),
        fetchPolicy: AdaptiveFetchPolicy.standard,
        child: getTestWidgetFromMap(
          map: card,
          title: 'open url policy test',
          onOpenUrl: (invoke) {
            called = true;
            expect(invoke.url, 'mailto:someone@example.com');
          },
          onSubmit: (_) {},
          onExecute: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mail'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/actions/open_url_policy_test.dart`

- [ ] **Step 3: Wire policy in default action and RawAdaptiveCard**

In `default_actions.dart`, import security types and gate `DefaultOpenUrlAction.tap`:

```dart
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
import 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';

// inside DefaultOpenUrlAction.tap, before launchUrl / onOpenUrl:
final validation = InheritedAdaptiveCardSecurityPolicy.uriPolicyOf(context)
    .validate(invoke.url);
switch (validation) {
  case AdaptiveUriDenied(:final reason):
    if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL blocked: $reason')),
      );
    }
    return;
  case AdaptiveUriAllowed():
    break;
}
```

In `flutter_raw_adaptive_card.dart`, wrap the card subtree:

```dart
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';

// Add optional constructor params with defaults:
// this.uriPolicy = AdaptiveUriPolicy.standard,
// this.fetchPolicy = AdaptiveFetchPolicy.standard,

// In build(), wrap child:
return InheritedAdaptiveCardSecurityPolicy(
  uriPolicy: widget.uriPolicy,
  fetchPolicy: widget.fetchPolicy,
  child: /* existing ProviderScope / card body */,
);
```

- [ ] **Step 4: Run test — expect PASS**

- [ ] **Step 5: Export public types from barrel**

Add to `flutter_adaptive_cards_fs.dart`:

```dart
export 'package:flutter_adaptive_cards_fs/src/security/adaptive_fetch_policy.dart';
export 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
export 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
export 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';
```

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(cards): validate Action.OpenUrl URLs against AdaptiveUriPolicy"
```

---

### Task 4: Validate markdown link hrefs

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/text_block.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/elements/text_block_markdown_policy_test.dart`

- [ ] **Step 1: Write failing widget test** — card with markdown link `[x](javascript:alert(1))`, tap link, expect snackbar "URL blocked" and no `onOpenUrl` call.

- [ ] **Step 2: Run test — FAIL**

- [ ] **Step 3: In `getMarkdownText` `onTapLink`, validate `href` before `action.tap`:**

```dart
onTapLink: (text, href, title) {
  if (href == null) return;
  final validation =
      InheritedAdaptiveCardSecurityPolicy.uriPolicyOf(context).validate(href);
  if (validation is AdaptiveUriDenied) {
    if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL blocked: ${validation.reason}')),
      );
    }
    return;
  }
  action.tap(
    context: context,
    rawAdaptiveCardState: rawRootCardWidgetState,
    adaptiveMap: adaptiveMap,
    altUrl: href,
  );
},
```

- [ ] **Step 4: Run test — PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(cards): validate markdown link hrefs against URI policy"
```

---

## Phase 3 — Remote fetch guards (SSRF)

### Task 5: Guard OpenUrlDialog fetch

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/action/open_url_dialog_executor.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/elements/actions/open_url_dialog_policy_test.dart`

- [ ] **Step 1: Write failing test** — mock `http.Client` or use `HttpOverrides` from `flutter_adaptive_cards_test_support` to assert `fetchOpenUrlDialogContent('http://192.168.1.1/x')` throws `AdaptiveUriDenied` equivalent without issuing GET.

Refactor `fetchOpenUrlDialogContent` signature:

```dart
Future<dynamic> fetchOpenUrlDialogContent(
  String url, {
  AdaptiveUriPolicy uriPolicy = AdaptiveUriPolicy.standard,
  AdaptiveFetchPolicy fetchPolicy = AdaptiveFetchPolicy.standard,
  http.Client? client,
}) async {
  final validation = uriPolicy.validate(url);
  if (validation is AdaptiveUriDenied) {
    throw AdaptiveUriPolicyException(validation.reason);
  }
  final uri = (validation as AdaptiveUriAllowed).uri;
  final response = await (client ?? http.Client())
      .get(uri)
      .timeout(fetchPolicy.timeout);
  readBodyWithLimit(response.bodyBytes, fetchPolicy.maxBytes);
  // existing content-type / json.decode logic on utf8 body
}
```

Add `AdaptiveUriPolicyException` in `adaptive_uri_validation.dart`.

Update `showOpenUrlDialog` to read policies from `InheritedAdaptiveCardSecurityPolicy` via `context` and pass into fetch.

- [ ] **Step 2–4: Red/green cycle**

- [ ] **Step 5: Commit**

```bash
git commit -m "fix(cards): block SSRF in OpenUrlDialog remote fetch"
```

---

### Task 6: Guard NetworkAdaptiveCardContentProvider

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/adaptive_cards_canvas.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/adaptive_cards_canvas_network_policy_test.dart`

- [ ] **Step 1: Add policy fields to `NetworkAdaptiveCardContentProvider`:**

```dart
class NetworkAdaptiveCardContentProvider implements AdaptiveCardContentProvider {
  NetworkAdaptiveCardContentProvider({
    required this.url,
    this.uriPolicy = AdaptiveUriPolicy.standard,
    this.fetchPolicy = AdaptiveFetchPolicy.standard,
    http.Client? client,
  }) : _client = client;

  final String url;
  final AdaptiveUriPolicy uriPolicy;
  final AdaptiveFetchPolicy fetchPolicy;
  final http.Client? _client;

  @override
  Future<Map<String, dynamic>> loadAdaptiveCardContent() async {
    final validation = uriPolicy.validate(url);
    if (validation is AdaptiveUriDenied) {
      throw AdaptiveUriPolicyException(validation.reason);
    }
    final uri = (validation as AdaptiveUriAllowed).uri;
    final response = await (_client ?? http.Client())
        .get(uri)
        .timeout(fetchPolicy.timeout);
    final bytes = readBodyWithLimit(response.bodyBytes, fetchPolicy.maxBytes);
    return json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
  }
}
```

- [ ] **Step 2: Extend `AdaptiveCardsCanvas` with optional `uriPolicy` / `fetchPolicy`; pass into `.network()` constructor.**

- [ ] **Step 3: Widget test** — `AdaptiveCardsCanvas.network(url: 'http://127.0.0.1/card.json')` shows error placeholder, does not render card.

- [ ] **Step 4: Commit**

```bash
git commit -m "fix(cards): validate URLs in NetworkAdaptiveCardContentProvider"
```

---

## Phase 4 — Backend response hardening

### Task 7: Bounded JSON decode in HTTP client

**Files:**

- Create: `packages/flutter_adaptive_cards_host_fs/lib/src/security/bounded_json.dart`
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/client/http_backend_client.dart`
- Create: `packages/flutter_adaptive_cards_host_fs/test/security/bounded_json_test.dart`
- Modify: `packages/flutter_adaptive_cards_host_fs/test/client/http_backend_client_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// bounded_json_test.dart
test('decodeJsonMapWithLimit throws on oversized body', () {
  final huge = '{"a":${'"x"' * 2_000_000}}';
  expect(
    () => decodeJsonMapWithLimit(huge, maxBytes: 1024),
    throwsA(isA<AdaptiveJsonTooLargeException>()),
  );
});
```

```dart
// http_backend_client_test.dart — add case
test('rejects response body over maxBytes', () async {
  final client = HttpAdaptiveCardBackendClient(
    endpoint: Uri.parse('https://api.example.com/invoke'),
    maxResponseBytes: 64,
    client: _FakeClient(statusCode: 200, body: '{"key":"' + 'x' * 200 + '"}'),
  );
  expect(() => client.post({}), throwsA(isA<AdaptiveJsonTooLargeException>()));
});
```

- [ ] **Step 2: Implement**

```dart
// bounded_json.dart
class AdaptiveJsonTooLargeException implements Exception {
  const AdaptiveJsonTooLargeException(this.maxBytes);
  final int maxBytes;
}

Map<String, dynamic> decodeJsonMapWithLimit(
  String body, {
  int maxBytes = 1024 * 1024,
}) {
  final byteLength = utf8.encode(body).length;
  if (byteLength > maxBytes) {
    throw AdaptiveJsonTooLargeException(maxBytes);
  }
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Expected JSON object');
  }
  return decoded;
}
```

Add `maxResponseBytes` param to `HttpAdaptiveCardBackendClient` (default `1024 * 1024`), replace bare `jsonDecode` with `decodeJsonMapWithLimit`.

- [ ] **Step 3: Export from `flutter_adaptive_cards_host_fs.dart`**

- [ ] **Step 4: Run host package tests — PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(host): bound backend invoke response JSON size"
```

---

### Task 8: Optional card validator on ReplaceCardEffect

**Files:**

- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/models/invoke_response.dart`
- Modify: `packages/flutter_adaptive_cards_host_fs/lib/src/handlers/backend_handlers.dart`
- Modify: `packages/flutter_adaptive_cards_host_fs/test/models/invoke_response_test.dart`

- [ ] **Step 1: Add typedef and applyTo parameter**

```dart
/// Returns false to reject a backend-supplied replacement card.
typedef AdaptiveCardValidator = bool Function(Map<String, dynamic> card);

void applyTo(
  RawAdaptiveCardState cardState, {
  void Function(Map<String, dynamic> card)? onCardReplaced,
  AdaptiveCardValidator? cardValidator,
}) {
  // In ReplaceCardEffect branch:
  if (cardValidator != null && !cardValidator(card)) {
    throw AdaptiveCardInvokeResponseParseException(
      'Backend card rejected by cardValidator',
    );
  }
  onCardReplaced!(card);
}
```

Thread `cardValidator` through `AdaptiveCardBackendHandlers.wrap` / `_invoke`.

- [ ] **Step 2: Unit test** — validator returns false → `applyTo` throws, card not replaced.

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(host): optional cardValidator for ReplaceCardEffect"
```

---

## Phase 5 — Resource URL policy

### Task 9: Gate image and media network loads

**Files:**

- Modify: `packages/flutter_adaptive_cards_fs/lib/src/utils/adaptive_image_utils.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/elements/media.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/utils/adaptive_image_policy_test.dart`
- Create: `packages/flutter_adaptive_cards_fs/test/elements/media_policy_test.dart`

- [ ] **Step 1: Add optional `AdaptiveUriPolicy? uriPolicy` to `getImage` / `getImageProvider`**

When policy is non-null and URL is not a `data:` URI, call `policy.validate(url)`; on deny return a placeholder `Icon(Icons.broken_image)` (or `SizedBox.shrink()` with semantics error label — match existing error UX in image widgets).

- [ ] **Step 2: In `AdaptiveMediaState.initializePlayer`, read `InheritedAdaptiveCardSecurityPolicy.uriPolicyOf(context)` before `VideoPlayerController.networkUrl`.**

- [ ] **Step 3: Widget tests** — private IP image URL renders placeholder; valid https renders image widget.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(cards): optional URI policy for images and media sources"
```

---

## Phase 6 — Template bounds, docs, verification

### Task 10: Cap template `json()` builtin

**Files:**

- Modify: `packages/flutter_adaptive_template_fs/lib/src/evaluator.dart`
- Create: `packages/flutter_adaptive_template_fs/test/unit/evaluator_json_bounds_test.dart`

- [ ] **Step 1: Write failing test** — `json()` with 2MB string returns null (or throws controlled error per existing `json()` error behavior).

- [ ] **Step 2: Implement in evaluator `json` branch:**

```dart
if (name == 'json') {
  if (args.isEmpty || args[0] == null) return null;
  final input = args[0].toString();
  const maxChars = 256 * 1024;
  if (input.length > maxChars) return null;
  try {
    return json.decode(input);
  } on Object catch (_) {
    return null;
  }
}
```

- [ ] **Step 3: Run template tests — PASS**

- [ ] **Step 4: Commit**

```bash
git commit -m "fix(template): cap json() builtin input size"
```

---

### Task 11: Documentation updates

**Files:**

- Modify: `docs/backend-host-integration.md`
- Modify: `packages/flutter_adaptive_cards_fs/README.md`
- Modify: `packages/flutter_adaptive_cards_host_fs/README.md`
- Modify: both packages' `CHANGELOG.md`

- [ ] **Step 1: Add "Security" section to cards README** — document `AdaptiveUriPolicy.standard` vs `.development`, `InheritedAdaptiveCardSecurityPolicy`, custom scheme configurations for custom protocols (e.g. `mailto:`, `tel:`), and recommendation to implement `onOpenUrl` for production.

- [ ] **Step 2: Add host README section** — `maxResponseBytes`, `cardValidator`, never log `AdaptiveCardBackendException.body` in production.

- [ ] **Step 3: Update `docs/backend-host-integration.md`** — trust boundary diagram: card JSON → renderer policies; backend response → host validation.

- [ ] **Step 4: Changelog `[Unreleased]` entries for both packages.**

- [ ] **Step 5: Commit**

```bash
git commit -m "docs: security hardening guidance for URI policy and backend trust"
```

---

## Final Task: Full verification

- [ ] **Step 1: Analyze monorepo**

```bash
fvm flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Run cards package tests**

```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden
```

Expected: all tests pass (note new count vs baseline).

- [ ] **Step 3: Run host package tests**

```bash
cd packages/flutter_adaptive_cards_host_fs
fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Run template package tests**

```bash
cd packages/flutter_adaptive_template_fs
fvm flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Invoke verification-before-completion skill** — paste exit codes and pass counts before claiming plan complete.

---

## Self-review (spec coverage)

| Security finding                                                          | Task                  |
| ------------------------------------------------------------------------- | --------------------- |
| OpenUrlDialog SSRF (`open_url_dialog_executor.dart:15`)                   | Task 5                |
| NetworkAdaptiveCardContentProvider SSRF (`adaptive_cards_canvas.dart:77`) | Task 6                |
| Unvalidated OpenUrl default (`default_actions.dart:179`)                  | Task 3                |
| Markdown href OpenUrl (`text_block.dart:212`)                             | Task 4                |
| Backend ReplaceCard trust (`plain_json_invoke_response_parser.dart:23`)   | Task 8 + docs Task 11 |
| Unbounded backend JSON (`http_backend_client.dart:41`)                    | Task 7                |
| Image URL loading (`adaptive_image_utils.dart:17`)                        | Task 9                |
| Media URL (`media.dart:97`)                                               | Task 9                |
| Template `json()` (`evaluator.dart:307`)                                  | Task 10               |

No placeholder steps remain. Type names (`AdaptiveUriPolicy`, `AdaptiveFetchPolicy`, `AdaptiveUriPolicyException`, `AdaptiveCardValidator`) are consistent across tasks.

---

## Execution handoff

**Plan complete and saved to `docs/superpowers/plans/2026-06-10-security-hardening.plan.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
