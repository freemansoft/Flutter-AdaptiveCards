---
name: adaptive-cards-public-api-docs
description: >
  Write public `///` documentation for exported Dart APIs. Use when adding or
  editing public classes, methods, getters, or fields in library packages
  (flutter_adaptive_cards_fs, flutter_adaptive_charts_fs, flutter_adaptive_cards_host_fs,
  flutter_adaptive_template_fs) or when reviewing doc-comment quality on exported APIs.
---

# Public API Documentation (`///`)

Public API comments should explain **why an API exists** and **how callers use it**.
They should **not** reiterate the steps the code is taking.

## Scope

Apply to every member exported from a package barrel file (for example
`lib/flutter_adaptive_cards_fs.dart`, `lib/flutter_adaptive_charts_fs.dart`).

**Lint enforcement:** `packages/flutter_adaptive_cards_fs` sets
`public_member_api_docs: error` in `analysis_options.yaml` — every public member
under `lib/` must have a `///` summary (`fvm dart analyze lib`).

Internal `lib/src/` helpers may use shorter docs, but follow the same principles when
the helper is part of a public contract (for example callback typedefs or sealed variants).

## What to write

Each public `///` block should answer, in order of priority:

1. **Purpose** — What problem does this API solve for the caller?
2. **Usage** — When to call it, what to pass, what you get back, and side effects.
3. **Constraints** — Spec behavior, thread/async expectations, null semantics, or
   invariants that are not obvious from the signature.
4. **Links** — `[OtherType]` dartdoc references and markdown links to project docs
   when integration context matters.

Parameter and return docs (`[id]`, `[uri]`) should clarify **caller intent**, not
restated parameter types already visible in the signature.

## What to avoid

Do **not**:

- Narrate implementation ("first parses JSON, then validates, then returns…").
- Duplicate the method body in prose ("loops over facts and builds widgets").
- Restate obvious signatures ("Returns a [String]" when the return type is `String`).
- Use filler ("This method is used to…", "Gets the value of…") without adding context.

Implementation details belong in private helpers, tests, or plan docs — not on public
API surfaces unless callers must know them to use the API correctly (for example security
policy rules or Adaptive Cards spec edge cases).

## Patterns

### Class or type

Lead with the caller-facing role, not the file it lives in.

```dart
/// Validates card-controlled URLs before launch or HTTP fetch.
class AdaptiveUriPolicy { ... }
```

### Factory, preset, or constant

Explain **when** a caller should pick this variant.

```dart
/// Default production policy: https/http only, no private networks.
static const standard = AdaptiveUriPolicy();

/// Relaxed policy for local widget tests and dev servers.
static const development = AdaptiveUriPolicy(
  allowLoopback: true,
  allowPrivateHosts: true,
);
```

### Method with non-obvious behavior

Document contract and caller workflow, not algorithm steps.

```dart
/// Parses an Adaptive Card [Input.Date] value from host `initData` or JSON.
///
/// Accepts `yyyy-MM-dd` (spec) and ISO-8601 datetimes. For datetimes, only
/// the calendar date portion is used; time and timezone offsets are ignored.
DateTime? parseAdaptiveDateValue(Object? raw) { ... }
```

### Result / sealed variants

Tell the caller what to do with each outcome.

```dart
/// [url] passed policy checks; use [uri] for launch/fetch.
class AdaptiveUriAllowed extends AdaptiveUriValidationResult { ... }

/// [url] was rejected; [reason] is safe to log (no secrets).
class AdaptiveUriDenied extends AdaptiveUriValidationResult { ... }
```

### Document notifier / overlay APIs

Explain host vs runtime state and when to call.

```dart
/// Replaces effective `"facts"` for `FactSet` [id].
///
/// Call from host refresh handlers or tests; baseline JSON is unchanged until
/// [clearFactsOverlay] is called.
void setFactsOverlay(String id, List<Fact> facts) { ... }
```

## Good vs bad

**Bad** (narrates implementation):

```dart
/// Parses the raw value by trimming it, checking for T or space, splitting,
/// then calling [DateFormat.parseStrict] on the date portion.
DateTime? parseAdaptiveDateValue(Object? raw);
```

**Good** (caller contract):

```dart
/// Parses an Adaptive Card [Input.Date] value from host `initData` or JSON.
///
/// Accepts `yyyy-MM-dd` (spec) and ISO-8601 datetimes. For datetimes, only
/// the calendar date portion is used; time and timezone offsets are ignored.
DateTime? parseAdaptiveDateValue(Object? raw);
```

**Bad** (restates signature):

```dart
/// Returns the resolved element map for the given id.
Map<String, dynamic>? getResolvedElement(String id);
```

**Good** (why + how):

```dart
/// Merged element JSON for [id]: baseline card map plus runtime overlays.
///
/// Use when building submit payloads or custom host logic outside widget
/// rebuilds. Returns `null` when [id] is unknown.
Map<String, dynamic>? getResolvedElement(String id);
```

## Review checklist

When reviewing or authoring public API docs:

- [ ] Every new/changed exported member has a `///` summary.
- [ ] Summary states purpose or caller workflow, not algorithm steps.
- [ ] Non-obvious spec, security, or async behavior is documented.
- [ ] Presets/factories explain when to choose them.
- [ ] No comment would become wrong if the implementation were refactored
      (sign of narrating "how" instead of "why/how to use").

See also **`adaptive-cards-code-review`** (Exports / public API section) and root **`AGENTS.md`**
(Documentation Philosophy).
