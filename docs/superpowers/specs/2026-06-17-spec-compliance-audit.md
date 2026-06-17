# Independent Spec-Compliance Audit — Flutter-AdaptiveCards

_Date: 2026-06-17_
_Baseline: Microsoft Adaptive Cards v1.6 schema + common Teams / Bot Framework extensions_
_Method: code read directly and verified against the spec — **not** derived from `docs/Implementation-Status.md`. Every finding cites `file:line`._

## Purpose

This is a fresh, independent validation of the implementation against the
Microsoft Adaptive Cards specification, covering all five packages
(`flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`,
`flutter_adaptive_template_fs`, `flutter_adaptive_cards_host_fs`,
`flutter_adaptive_cards_test_support`). It exists to (a) confirm or correct the
existing status matrix and (b) re-prioritize the shortcomings by real-world
interop risk.

**Headline:** `docs/Implementation-Status.md` is current and largely accurate.
The `adaptive-cards-spec-compliance` **skill's** Known-Gaps table is **stale**.
Both are corrected in §B.

---

## A. Confirmed real gaps (code-verified)

### Graceful degradation — highest production risk

The weakest area for any host receiving cards authored for a newer or different
renderer. These produce broken or dead UI, not merely sub-optimal layout.

1. **Action `fallback` — not implemented.** `lib/src/registry.dart:292` and
   `lib/src/action/action_type_registry.dart:61` both `assert(false)` then return
   `AdaptiveUnknown` / `null`. An unknown action — or a known-but-newer one — never
   walks its `fallback`. Spec requires fallback-or-drop.
2. **`requires` capability gating — not implemented.** Parsed only on `TableCell`
   (`lib/src/models/table_cell.dart:23,46,89`), enforced nowhere. Every element
   renders regardless of declared feature requirements, so `requires`-guarded
   fallback never triggers.
3. **Version gating / `fallbackText` — not implemented.**
   `lib/src/cards/adaptive_card_element.dart:78` reads `version` into a field that
   is never consulted; `fallbackText` is never shown. A higher-version card
   degrades silently/incorrectly instead of showing fallback text.
4. **`removedElements` skips `fallback`** (spec deviation). `registry.dart:102,126`
   returns `AdaptiveUnknown` for host-removed types instead of attempting the
   element's `fallback` first. Per spec an unsupported type should fall back.

### Responsive layout — high for modern cards

5. **`targetWidth`, `Layout.AreaGrid`, `grid.area` — absent.** No implementation.
   Modern Teams / Copilot width-adaptive cards will not reflow.

### Card-root + container properties — medium

6. **Card root: `minHeight`, `rtl`, `verticalContentAlignment`, `authentication`
   — absent** (verified absent in `lib/src/cards/adaptive_card_element.dart`).
7. **`bleed` — absent.** Zero references in `lib/src`. Affects full-bleed
   container / column / table-cell layouts.
8. **Block `height: stretch` — only `auto` generally honored.**
9. **Table** — column `width` `auto`/`stretch` not supported (numeric flex and
   `px` only); cell-level `rtl` parsed in `TableCellModel` but not rendered.

### Content fidelity — low / medium

10. **TextBlock markdown path ignores `maxLines`**
    (`lib/src/cards/elements/text_block.dart:184-186`, deliberately commented
    out). The plain (non-markdown) path honors it.
11. **Chart line datetime axes — broken.** `flutter_adaptive_charts_fs/lib/src/
    charts/line_chart.dart:99`: a non-numeric `x` (ISO datetime string) collapses
    to `0.0`. Time-series line charts render incorrectly.
12. **`CaptionSource` (Media) — not registered.**
13. **Templating** — missing collection functions (`select`, `where`, `join`,
    `first`, `last`, `sum`, `average`) and most date functions (`utcNow`,
    `addDays`, `formatEpoch`, `getFutureTime`, …). See §B for what _is_ present.

---

## B. Documentation corrections (over / under-claims)

Places the existing docs disagree with the code. Fixing these keeps the team's
own status tracking trustworthy.

| Claim | Source | Reality (code) | Verdict |
| --- | --- | --- | --- |
| Card-root `selectAction` "❌ Missing — not wired" | `Implementation-Status.md:79` | `adaptive_card_element.dart:275` wraps the card map in `AdaptiveTappable`, which honors `selectAction` (`additional.dart:121,132-136`). | **Under-claim — it works** |
| Templating "Date/Time functions missing" | matrix:210 + skill | `formatDateTime` is implemented (`flutter_adaptive_template_fs/lib/src/evaluator.dart:407`). Only the _other_ date funcs are missing. | **Under-claim** |
| "Dark mode — `HostConfigs.current` always returns light config" | `adaptive-cards-spec-compliance` **skill**, Known Gaps | `lib/src/flutter_raw_adaptive_card.dart:133-145` selects light/dark `HostConfigs`; `AdaptiveCardBrightnessMode.auto` follows `Theme` brightness. | **Skill stale — implemented** |
| `backgroundImage` "✅ Complete" | matrix:228 | Object form maps `fillMode`→fit/repeat (`adaptive_mixins.dart:147-152`) but ignores `horizontalAlignment` / `verticalAlignment`. | **Minor over-claim** |

The `adaptive-cards-spec-compliance` skill's Known-Gaps table also still flags
`Action.Execute` and action `fallback` as "verify" — `Action.Execute` is
complete; action `fallback` is confirmed missing (§A.1).

---

## C. What was verified as correctly implemented

Spot-checked ✅ claims that held up: `Image` `selectAction` (via
`AdaptiveTappable`, `cards/elements/image.dart:77`); the element-level `fallback`
chain (`drop` and recursive substitute, `registry.dart:237-244`); `refresh`
(manual affordance + auto-expire + `userIds` gating,
`adaptive_card_element.dart:111-161`); the full template operator set and the
`json`/`if`/`length`/`concat`/`empty`/`toUpper`/`toLower`/`trim`/`substring`/
`replace`/`min`/`max`/`round`/`floor`/`ceil`/`formatDateTime` function set
(`evaluator.dart:272-407`).

---

## D. Prioritized remediation ranking

This ranking weights **graceful degradation above responsive layout** — a missing
`targetWidth` yields a readable-but-non-ideal card, whereas missing action
`fallback` / `requires` / version gating yields broken or dead UI when a host
sends a card built for a newer schema (the most common real-world interop
failure). This is the one place this audit's priority order differs from
`Implementation-Status.md`.

| Priority | Theme | Items |
| --- | --- | --- |
| **P0** | Interop / graceful degradation | Action `fallback` (#1), `requires` gating (#2), version gating + `fallbackText` (#3), removed-element fallback (#4) — one coherent workstream |
| **P1** | Responsive layout | `targetWidth` + `Layout.AreaGrid` / `grid.area` (#5) |
| **P2** | Layout fidelity | `bleed` (#7), `height: stretch` (#8), card-root `minHeight`/`rtl`/`verticalContentAlignment` (#6), Table widths + cell `rtl` (#9) |
| **P3** | Content fidelity | Chart datetime axes (#11), markdown `maxLines` (#10), `CaptionSource` (#12), templating collection/date functions (#13) |
| **P4** | Doc hygiene | Correct the four over/under-claims in §B in `Implementation-Status.md` and the stale `adaptive-cards-spec-compliance` skill |

---

## Verification commands used

```bash
# Element / action registration
grep -nE "case '" packages/flutter_adaptive_cards_fs/lib/src/registry.dart

# Gap confirmations
grep -rn "requires" packages/flutter_adaptive_cards_fs/lib/src
grep -rn "bleed"     packages/flutter_adaptive_cards_fs/lib/src
grep -rn "selectAction" packages/flutter_adaptive_cards_fs/lib/src/additional.dart

# Templating functions
grep -rn "if (name ==" packages/flutter_adaptive_template_fs/lib/src/evaluator.dart

# Dark mode
grep -rn "Brightness.dark\|brightnessMode" packages/flutter_adaptive_cards_fs/lib/src
```
