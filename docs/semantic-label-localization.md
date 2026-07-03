# Hardcoded Semantic Labels — Current State & Localization Proposal

> **Status:** Proposal / findings. No code has been changed for this document.
> **Scope:** `packages/flutter_adaptive_cards_fs` (core library). Charts/host/template
> packages are not surveyed here.
> **Related project rule (`AGENTS.md`):** _"Localization: Use the `intl` package.
> All UI strings must be localized in `.arb` files."_

## 1. Summary

The core library injects a small number of **hardcoded English strings** into the
accessibility (semantics) tree and into visual tooltips. These are the only
user-facing strings the library authors itself — every other label is derived
from the card JSON (`altText`, input `label`, action `title`, fact `title`/`value`,
etc.) and therefore already follows the card author's language.

There is currently **no message-localization infrastructure** in the package:

- `intl: ^0.20.2` is a dependency, but it is used **only for date/number
  formatting** (`DateFormat`), not for translatable messages.
- There is **no** `flutter_localizations`, `l10n.yaml`, `.arb` file,
  `generate: true`, or generated `AppLocalizations` in the package.

So the hardcoded strings below are the gap between the current code and the
`AGENTS.md` localization rule.

## 2. Current-state inventory

### 2.1 Fully hardcoded English literals

These are complete English strings baked into widget code.

| #   | String                       | Kind                                     | File                                       | Line |
| --- | ---------------------------- | ---------------------------------------- | ------------------------------------------ | ---- |
| 1   | `'Refresh card'`             | Semantics `label`                        | `lib/src/cards/adaptive_card_element.dart` | 549  |
| 2   | `'Refresh card'`             | `IconButton` `tooltip`                   | `lib/src/cards/adaptive_card_element.dart` | 552  |
| 3   | `'More actions'`             | `tooltip` (overflow menu)                | `lib/src/cards/adaptive_card_element.dart` | 301  |
| 4   | `'More actions'`             | `tooltip` (overflow menu)                | `lib/src/cards/elements/action_set.dart`   | 111  |
| 5   | `'Progress'`                 | `LinearProgressIndicator.semanticsLabel` | `lib/src/cards/elements/progress_bar.dart` | 86   |
| 6   | `'Progress'`                 | `LinearProgressIndicator.semanticsLabel` | `lib/src/cards/elements/progress_bar.dart` | 99   |
| 7   | `'Rating'`                   | Semantics `label` (read-only display)    | `lib/src/widgets/rating_stars.dart`        | 164  |
| 8   | `'Rating'`                   | Semantics `label` (interactive input)    | `lib/src/widgets/rating_stars.dart`        | 176  |
| 9   | `'Go to slide ${index + 1}'` | Semantics `label` (carousel dot)         | `lib/src/cards/elements/carousel.dart`     | 177  |

**4 unique message templates** across these 9 sites: _Refresh card_, _More
actions_, _Progress_, _Rating_, plus the carousel _Go to slide N_ pattern.

### 2.2 Composed strings (English words + interpolated data)

These mix hardcoded English words with runtime values. They are also not
localized, and additionally bake in **English word order and pluralization**.

| String template                                | Meaning                                            | File                                                            | Line     |
| ---------------------------------------------- | -------------------------------------------------- | --------------------------------------------------------------- | -------- |
| `'$label, required'`                           | Appends spoken "required" state to an input's name | `lib/src/utils/utils.dart`                                      | 230      |
| `'${_formatValue(v)} of ${max.toInt()} stars'` | Rating value, e.g. "3 of 5 stars"                  | `lib/src/widgets/rating_stars.dart`                             | 158      |
| `'${(percent * 100).round()}%'`                | Progress percent value                             | `lib/src/cards/elements/progress_bar.dart` `progress_ring.dart` | 75 / 116 |

> The `%` percent string is numeric and largely locale-neutral, but the `, required`
> suffix and `N of M stars` phrase contain English words and grammar and should be
> treated as translatable messages.

### 2.3 What is **already** localized-by-authoring (no action needed)

For completeness, these labels are correct as-is because they come from the card
JSON, i.e. the card author supplies the language:

- Image / Icon `altText`
- `Input.*` `label` (Text, Number, Date, Time, ChoiceSet, Toggle, Rating)
- Action `title` / `tooltip` on `selectAction` wrappers
- `FactSet` `title: value`
- `ProgressRing` author `label`

## 3. Problem statement

1. **Non-conformance with `AGENTS.md`** — the rule requires all UI strings in
   `.arb` files; §2.1/§2.2 violate it.
2. **Screen-reader output is English-only** regardless of the host app's locale.
   A German host app renders German card content but announces "Rating",
   "Refresh card", "3 of 5 stars".
3. **Tooltips are English-only** (`More actions`, `Refresh card`) — visible UI,
   not just semantics.
4. **Grammar is baked in** (word order of "N of M stars", the "required" suffix),
   which naive per-word translation cannot fix.

## 4. Design constraints

This is a **library package rendered inside a host app**, not an app itself. That
shapes the solution:

- The library cannot assume the host registered any particular
  `LocalizationsDelegate`. It must **degrade gracefully to English** when the host
  has not wired up localization.
- The core package **must stay lean** and must not take on heavy optional
  dependencies (`AGENTS.md`: core must not depend on chart/host/template packages;
  same spirit applies to keeping the dependency surface small).
- Strings must be reachable from deep in the widget tree, where a `BuildContext`
  is available (all sites above build inside `build()` and have context, except
  `rating_stars.dart`/`utils.dart` helpers which currently take no context — see
  §6 risks).

## 5. Proposed solution

**Recommended: package-owned generated localizations with an English fallback,
plus an optional host string-override hook.**

### 5.1 Approach A (recommended) — gen-l10n delegate owned by the library

1. Add `flutter_localizations` (SDK) to the package and enable Flutter's
   `gen-l10n` tool:
   - `pubspec.yaml`: `flutter: generate: true`
   - `l10n.yaml` pointing at `lib/src/l10n/` with an output class such as
     `AdaptiveCardsLocalizations` (namespaced so it never collides with a host
     app's own `AppLocalizations`).
2. Author `lib/src/l10n/adaptive_cards_en.arb` (the template) with keys for the
   §2.1/§2.2 messages, using ICU placeholders/plurals for the composed ones:
   - `refreshCard`, `moreActions`, `progress`, `rating`
   - `carouselGoToSlide` → `"Go to slide {number}"` with `{number}` param
   - `inputRequiredSuffix` → `"{label}, required"`
   - `ratingValue` → ICU plural: `"{value} of {max, plural, one{# star} other{# stars}}"`
3. Expose the delegate publicly: `AdaptiveCardsLocalizations.delegate`. Document
   that hosts **may** add it to `MaterialApp.localizationsDelegates` to get
   translations; if they don't, the library resolves against its bundled English
   template (fallback), so behavior is unchanged for current users.
4. Replace each literal with a lookup, e.g.
   `AdaptiveCardsLocalizations.of(context).refreshCard`, with a `.maybeOf` +
   English default helper for the no-delegate path.

**Pros:** idiomatic Flutter, matches the `AGENTS.md` `.arb` rule, handles
ICU plurals/word-order, host opt-in is one line. **Cons:** adds
`flutter_localizations`; requires a `context` at each call site.

### 5.2 Approach B — host-injected string table (no gen-l10n)

Add a small immutable value object (e.g. `AdaptiveCardsStrings`) with a field per
message and English defaults, provided via a Riverpod scoped provider (consistent
with the package's existing card-scoped provider pattern) or an
`InheritedWidget`. Hosts override individual strings; unset fields fall back to
English.

**Pros:** zero new dependency; trivially overridable; no build-runner step.
**Cons:** doesn't satisfy the `.arb` rule; the host, not the library, owns the
translations and the ICU/plural logic; more boilerplate for many locales.

### 5.3 Approach C — hybrid (defer)

gen-l10n delegate (A) **and** an override object (B) layered on top, so hosts can
either ship locales or spot-override a single string. More surface area than is
justified for ~5 messages today; revisit only if demand appears.

### 5.4 Recommendation

Adopt **Approach A**. It is the only option that satisfies the project's stated
localization rule, correctly models plural/word-order, and still leaves existing
hosts working with no changes (English fallback). Keep the message set tiny and
namespaced.

## 6. Risks / open questions

- **Context-less helpers.** `rating_stars.dart` (`starsLabel`) and `utils.dart`
  (`inputSemanticsLabel`, the `, required` suffix) currently build strings without
  a `BuildContext`. Approach A requires threading `context` (or a resolved strings
  object) into these helpers, or moving the string construction up to the widget
  `build()`. This is the main refactor cost.
- **Tests pin the English text.** `test/accessibility_semantics_test.dart` asserts
  literals like `find.bySemanticsLabel('Go to slide 1')` and
  `value: '3 of 5 stars'`. Tests should resolve the same key (or continue asserting
  the English default under the fallback path) rather than hardcoding, to avoid
  breaking when locales are added.
- **Percent formatting.** If we localize the `%` value, use `intl`
  `NumberFormat.percentPattern(locale)` rather than manual `${...}%` so digit
  grouping/RTL is correct; otherwise leave it as-is and document it as
  intentionally numeric.
- **No `.arb` today.** This is greenfield localization for the package — CI, the
  coverage gate, and the docs-sync gate (`AGENTS.md`) will all need the new
  `l10n` wiring accounted for.

## 7. Suggested next steps (if approved)

1. Confirm Approach A vs B with the maintainer.
2. Write an implementation plan under `docs/plans/` (per the plan-completion gate)
   covering: l10n scaffolding, the ~5 message keys, call-site refactors
   (incl. context threading for the two helpers), test updates, and a CHANGELOG
   entry for `flutter_adaptive_cards_fs`.
3. Update the **Architecture documentation sync gate** targets if a new public
   delegate (`AdaptiveCardsLocalizations`) is added.

## 8. Appendix — reproduction commands

```bash
# Fully hardcoded English literals in semantics/labels/tooltips
grep -rnE "(semanticsLabel|semanticLabel|label|tooltip|hint):\s*'[A-Za-z]" \
  packages/flutter_adaptive_cards_fs/lib --include="*.dart"

# Composed English strings
grep -rn "', required'\|of .* stars\|semanticsLabel: 'Progress'" \
  packages/flutter_adaptive_cards_fs/lib --include="*.dart"

# Confirm no message-localization infra yet
find packages/flutter_adaptive_cards_fs -name "*.arb" -o -name "l10n.yaml"
grep -n "flutter_localizations\|generate: true" \
  packages/flutter_adaptive_cards_fs/pubspec.yaml
```
