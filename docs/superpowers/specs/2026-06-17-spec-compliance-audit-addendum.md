# Spec-Compliance Audit — Addendum (finer-grained gaps)

_Date: 2026-06-17_
_Baseline: Microsoft Adaptive Cards v1.6 schema + Teams / Bot Framework extensions_
_Companion to: [`2026-06-17-spec-compliance-audit.md`](./2026-06-17-spec-compliance-audit.md)_
_Method: code read directly, verified against the spec; every finding cites `file:line` in `packages/flutter_adaptive_cards_fs/`._

## Purpose

The main audit deliberately stayed at the level of whole-feature gaps (graceful
degradation, responsive layout, card-root properties). It treated the input,
action, and custom-element families as "complete." This addendum goes one level
deeper — **per-property** completeness inside elements/inputs/actions that the
matrix marks ✅ — and surfaces 10 additional findings, one of which is a
confirmed interop bug.

These findings are **additive**; nothing here contradicts the main audit. The
re-prioritization in §C folds them into the audit's P0–P4 ranking.

---

## A. New findings

### A1. Input `min`/`max` not validated on submit — **High (data integrity)**

`validateInputs()` is the real gate fired before Submit/Execute
(`lib/src/action/default_actions.dart:90,134`). It enforces only:

- `isRequired` (null/empty) for every input, and
- `regex` for `Input.Text` (`default_actions.dart:38-48`).

It does **not** enforce `Input.Number` `min`/`max`, `Input.Date` `min`/`max`, or
`Input.Time` `min`/`max` (`default_actions.dart:22-62`). The spec requires these
constraints to block submit and surface `errorMessage`. Today an out-of-range
number/date/time **submits silently** — the host receives invalid data with no
client-side signal. `docs/Implementation-Status.md` marks all three inputs
"✅ Complete."

### A2. `CodeBlock` reads `code`, not spec `codeSnippet` — **Medium (confirmed interop bug)**

`lib/src/cards/elements/code_block.dart:46` reads
`adaptiveMap['code']?.toString() ?? ''`. The official property is **`codeSnippet`**
(verified against the Teams cards-format schema: _"codeSnippet | String | Yes |
The code snippet to be displayed in an Adaptive Card"_). Any `CodeBlock` authored
to the real schema (`{"type":"CodeBlock","codeSnippet":"…","language":"java",
"startLineNumber":61}`) renders an **empty** block. `language` and
`startLineNumber` are read correctly. Matrix marks CodeBlock "✅ Complete."

### A3. Action `mode` + overflow menu — absent (v1.5) — **Medium**

`lib/src/cards/elements/action_set.dart:47` truncates the action list to
`maxActions` with `.take()` and **silently drops** the remainder. The action
`mode` property (`primary` / `secondary`) is never read anywhere in action
rendering. Per spec/Teams, `secondary` actions belong in an overflow "•••" menu
and `primary` actions render inline — so excess/secondary actions **disappear**
instead of becoming reachable.

### A4. `Badge` partial — **Medium** (matrix over-claim)

`lib/src/cards/elements/badge.dart` reads `text`, `appearance`, `size`,
`tooltip`. Missing hub properties: **`icon`**, **`shape`** (square / rounded /
circular), and color **`style`** variants. Matrix marks "✅ Complete."

### A5. `CompoundButton` partial — **Medium** (matrix over-claim)

`lib/src/cards/elements/compound_button.dart` reads `title`, `description`.
Missing hub properties: **`icon`** and **`badge`**. Matrix marks "✅ Complete."

### A6. `Carousel` partial — **Medium** (matrix over-claim)

`lib/src/cards/elements/carousel.dart` reads `pages`, `initialPage`. Missing hub
properties: **`timer`** (auto-advance), **`orientation`** (horizontal /
vertical), **`loop`**. Matrix marks "✅ Complete."

### A7. Orphaned `checkRequired()` validation path — **Low (code quality / drift)**

Every input implements `checkRequired()` (`text.dart:209`, `number.dart:200`,
`date.dart:208`, `time.dart:148`, `toggle.dart:139`, `choice_set.dart:217`,
`rating.dart:139`) and the mixin declares it abstract
(`lib/src/adaptive_mixins.dart:356`). **Nothing in `lib/src` calls it** — only a
single test (`test/inputs/date_edgecases_test.dart:114`). The live gate uses
`validateInputs()` (§A1) instead. Two divergent validation implementations; the
per-input one is dead code that will drift from the real gate (and is where the
missing min/max checks in §A1 would most naturally have lived).

### A8. `Image.backgroundColor` — absent — **Low**

`lib/src/cards/elements/image.dart` reads `width`, `height`, `size`, `style`,
`horizontalAlignment`, `altText`, but not **`backgroundColor`**. Transparent PNGs
that rely on a backing color render without it.

### A9. HostConfig `actions.iconPlacement: aboveTitle` ignored — **Low**

`lib/src/cards/actions/icon_button.dart:59-69` always builds
`ElevatedButton.icon` (icon left of label). The parsed `iconPlacement` config
(`hostconfig/actions_config.dart:39`) is never consulted, so `aboveTitle` is a
no-op.

### A10. `Media.captionSources` — absent — **Low**

`lib/src/cards/elements/media.dart` reads `sources` and `poster`, and **does**
set `altText` (`media.dart:52,177` — accessibility is fine here). It does not
read `captionSources`. This confirms the main audit's `CaptionSource` gap from
the Media side.

---

## B. Matrix corrections

Places `docs/Implementation-Status.md` disagrees with the code, found during this
deeper pass. (The main audit's §B corrections still stand and are not repeated.)

| Claim                                                              | Source       | Reality (code)                                                                               | Verdict                              |
| ------------------------------------------------------------------ | ------------ | -------------------------------------------------------------------------------------------- | ------------------------------------ |
| Badge "✅ Complete"                                                | matrix:266   | `badge.dart` ignores `icon`, `shape`, color `style`                                          | **Over-claim → ⚠️ Partial**          |
| CompoundButton "✅ Complete"                                       | matrix:274   | `compound_button.dart` ignores `icon`, `badge`                                               | **Over-claim → ⚠️ Partial**          |
| Carousel "✅ Complete"                                             | matrix:267   | `carousel.dart` ignores `timer`, `orientation`, `loop`                                       | **Over-claim → ⚠️ Partial**          |
| CodeBlock "✅ Complete"                                            | matrix:273   | reads wrong key (`code` vs `codeSnippet`) → empty render                                     | **Over-claim → ⚠️ Partial (bug)**    |
| Input.Number/Date/Time "✅ Complete"                               | matrix:91-93 | `min`/`max` not enforced on submit                                                           | **Over-claim → ⚠️ on validation**    |
| Card-root `verticalContentAlignment` "❌ Missing"                  | matrix:80    | Missing at **root only**; implemented at Container/Column/Table (`cards/containers/*.dart`)  | **Under-claim at element level**     |
| TextRun styling list (weight/color/italic/underline/highlight/tap) | matrix:34    | Also handles `strikethrough`, `fontType`, `size`, `isSubtle` (`rich_text_block.dart:78-166`) | **Under-claim — fuller than listed** |

---

## C. Re-prioritization (folded into the main audit's ranking)

| Priority | Theme                                               | Items (main audit + this addendum)                                                                                                                                                                                                                         |
| -------- | --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | Interop / graceful degradation **+ data integrity** | Action `fallback`, `requires` gating, version gating + `fallbackText`, removed-element fallback (main audit #1–4) **+ input `min`/`max` validation (A1)** **+ CodeBlock `codeSnippet` key fix (A2)**                                                       |
| **P1**   | Responsive layout                                   | `targetWidth` + `Layout.AreaGrid` / `grid.area` (main #5)                                                                                                                                                                                                  |
| **P2**   | Layout fidelity                                     | `bleed`, `height: stretch`, card-root `minHeight`/`rtl`/`verticalContentAlignment`, Table widths/cell `rtl` (main #6–9)                                                                                                                                    |
| **P3**   | Element completeness                                | Action `mode`/overflow (A3); Badge (A4), CompoundButton (A5), Carousel (A6) partials; chart datetime axes, markdown `maxLines`, `CaptionSource`/`captionSources` (A10), templating funcs (main #10–13); `Image.backgroundColor` (A8); `iconPlacement` (A9) |
| **P4**   | Code quality + doc hygiene                          | Orphaned `checkRequired()` (A7); matrix over/under-claims (§B + main §B)                                                                                                                                                                                   |

> [!NOTE]
> **Scheduling update (2026-06-27).** This table ranks **spec-compliance severity**, not the current build schedule. Since this audit, responsive `Layout.Flow` shipped (Container/root/Column/TableCell), and the maintainer **deferred** the P0 **`requires` + action `fallback` + version gating** workstream and **deprioritized all `rtl`** (cell + root). The active schedule is now `Layout.AreaGrid` (+ block `height: stretch`). The audit's P0 severity assessment still stands; it is simply not the next thing being built. See the live roadmap in [Implementation-Status.md → Priority Recommendations](../../Implementation-Status.md#priority-recommendations).

The two additions to **P0** are deliberate: A1 lets invalid data reach the host
silently (a data-integrity failure, not a layout nicety), and A2 is a flat bug
that breaks a documented element for any schema-correct author — both rank with
graceful degradation, above responsive layout.

---

## Verification commands used

```bash
# Input validation gate — what it actually checks
sed -n '22,62p' packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart

# checkRequired has no caller in lib/src
grep -rn "checkRequired" packages/flutter_adaptive_cards_fs/lib/src

# CodeBlock reads the wrong key
grep -n "codeSnippet\|'code'" packages/flutter_adaptive_cards_fs/lib/src/cards/elements/code_block.dart

# Action mode / overflow never read; actions truncated
grep -n "maxActions\|secondary\|'mode'" packages/flutter_adaptive_cards_fs/lib/src/cards/elements/action_set.dart

# Partial custom elements — properties actually parsed
grep -noE "'(icon|shape|style|badge|timer|orientation|loop)'" \
  packages/flutter_adaptive_cards_fs/lib/src/cards/elements/{badge,compound_button,carousel}.dart
```

_CodeBlock property name verified against Microsoft Teams `cards-format` schema documentation._
