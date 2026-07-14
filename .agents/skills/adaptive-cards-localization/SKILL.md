---
name: adaptive-cards-localization
description: >
  What "localized" means for the published packages — who owns which strings,
  why the library ships no `.arb` files, the injected `AdaptiveStrings` seam for
  library-owned chrome, and locale-correct `intl` formatting. Use when adding any
  user-visible string to a package under `packages/`, or when tempted to add
  `flutter_localizations` to the core.
---

# Adaptive Cards Localization Skill

## Overview

Three kinds of text appear in a rendered card, and **only one of them is ours**.
Getting the wrong one is the mistake this skill exists to prevent.

| Text | Owner | Our job |
| --- | --- | --- |
| **Card content** — `TextBlock.text`, labels, choice titles, `altText` | The **card author** (the JSON) | Render it verbatim. **Never** translate, never substitute a default. |
| **Formatted values** — dates, times, numbers | The **data**, rendered by us | Format **locale-correctly** via `intl`. |
| **Library chrome** — `'Progress'`, `'OK'`, `'Close'`, `'URL blocked'` | **Us** | Make it **host-overridable**. ~10 strings total. |

Nearly all text a user sees is card content, which we never translate. The
library's own chrome is about ten strings. That ratio drives every decision below.

---

## Ground truth (read this before you believe any other doc)

**There are no `.arb` files in this repository.** No `flutter_localizations`
dependency, no `AppLocalizations`, no `l10n.yaml`, no gen-l10n. The packages ship
hardcoded English chrome today.

`intl` **is** a dependency of `flutter_adaptive_cards_fs`,
`flutter_adaptive_charts_fs`, and `flutter_adaptive_template_fs` — but it is used
for **date/number formatting only** (`DateFormat`, `NumberFormat`), never for
message translation. An `intl` dependency is *not* evidence that strings are
localized.

> The root `AGENTS.md` previously claimed "all UI strings must be localized in
> `.arb` files." That was aspirational and never true of the packages. This skill
> supersedes it.

The vendored **`flutter-setup-localization`** skill teaches app-level gen-l10n
setup (`l10n.yaml`, `AppLocalizations.of(context)`). That is correct for
**`widgetbook/` and the sample apps**, and **wrong for the published packages** —
see the decision below. (It also shows bare `flutter` commands; run them with
`fvm`.)

---

## Decision: the seam, not a delegate

**Library chrome is localized by an injected `AdaptiveStrings` value object with
English defaults. The core packages take on no localization dependency.**

The host resolves the locale using whatever l10n stack it already has and passes
already-resolved strings down:

```dart
// Host app — built inside build(), so a locale change rebuilds and new
// strings flow down automatically. No delegate to register.
AdaptiveCard(
  strings: AdaptiveStrings(
    progressLabel: AppLocalizations.of(context)!.progress,
  ),
)
```

```dart
// Core package — a dumb value holder. It does NO locale resolution.
class AdaptiveStrings {
  const AdaptiveStrings({
    this.progressLabel = 'Progress',
    this.dialogOk = 'OK',
    // ...
  });
  final String progressLabel;
  final String dialogOk;
}
```

**Why this shape:**

- **Zero new dependencies.** No `flutter_localizations`, no `.arb`, no gen-l10n in
  the packages. The host's l10n stack stays on the host's side of the seam.
- **Language switching is free.** The host reads its own localizations inside
  `build()`; that is an inherited-widget dependency, so a locale change rebuilds
  and fresh strings arrive without the library knowing what a locale is.
- **It is the reversible move.** The seam is where translations *plug in*. If we
  later ship `.arb` translations, they populate the same object and nothing
  breaks. Shipping a delegate first is the hard-to-reverse option: hosts must
  register it, and overriding one string means subclassing a generated abstract
  class and implementing every getter.

**Explicitly deferred:** whether we ship our own translations (`.arb` + a
delegate) is **open**, and additive. Revisit when a host actually asks for a
non-English locale. Do not stand up gen-l10n in a package on your own initiative.

> **Status: the seam does not exist yet.** `AdaptiveStrings` is not implemented —
> it is the agreed target. Until it lands, the rules below still bind: do not add
> new hardcoded strings, and prefer *not* adding user-visible chrome at all.

---

## Rules

1. **Never translate or default card content.** Author text renders verbatim. An
   absent `altText` means *decorative* — pass `null`, don't invent a placeholder
   (see **`adaptive-cards-accessibility`**).
2. **Do not add a new hardcoded user-visible string to a package.** This includes
   `semanticsLabel:` — a screen reader announcement is user-visible text. If you
   need one, route it through `AdaptiveStrings` (add the field), or push the text
   out to the host.
3. **Do not add `flutter_localizations`, `.arb` files, or gen-l10n to any package
   under `packages/`.** That is the deferred decision, not a free choice.
4. **Format, don't concatenate.** Locale-correct output comes from `intl`
   (`DateFormat`, `NumberFormat`), not string interpolation. Never build a
   sentence by gluing fragments — word order is not universal.
5. **Sample apps are different.** `widgetbook/` and the example apps are ordinary
   Flutter apps: use `flutter_localizations` + `.arb` there freely, per
   **`flutter-setup-localization`**.

---

## Existing debt

The hardcoded chrome to route through the seam when it lands. Verified
2026-07-13, all in `packages/flutter_adaptive_cards_fs/lib/src/`:

| String | Location |
| --- | --- |
| `'Progress'` (×2, a `semanticsLabel`) | `cards/elements/progress_bar.dart:86,99` |
| `'OK'` (×2), `'Debug show the JSON'` | `flutter_raw_adaptive_card.dart:464,573,624` |
| `'Close'` (×2), `'Opening in browser...'`, `'Error loading content: …'` | `action/open_url_dialog_executor.dart:134,138,160,178` |
| `'URL blocked: …'`, `'Action.Http URL blocked: …'` | `action/default_actions.dart:246,314` |
| `'must be after … and before …'` (validation) | `cards/inputs/time.dart:116` |

Note the last one is also **rule 4** debt: it is an interpolated sentence, so it
needs restructuring, not just extraction.

---

## Locale-correct formatting

`intl` formatting is locale-sensitive, and a `DateFormat` constructed without a
locale silently follows `Intl.defaultLocale` — which a host may never set. When
touching `utils/date_time_utils.dart`, `utils/date_input_utils.dart`,
`cards/inputs/date.dart`, or the template `evaluator.dart`, confirm the intended
locale is actually reaching the formatter rather than relying on a global default.

**Known deviation:** the `{{DATE}}` / `{{TIME}}` text macros use Dart `intl`
formatters as an approximation of the reference SDK's C#-style formatting; output
can differ from the Microsoft SDK. See **`adaptive-cards-spec-compliance`**.

---

## Review checklist

- [ ] No new hardcoded user-visible string in a package — **including `semanticsLabel:`**.
- [ ] Card-authored text rendered verbatim; no invented defaults or placeholders.
- [ ] No `flutter_localizations` / `.arb` / gen-l10n added to `packages/`.
- [ ] User-visible sentences are formatted, not concatenated from fragments.
- [ ] Date/number output goes through `intl` with the intended locale.
