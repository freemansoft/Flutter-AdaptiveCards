---
name: adaptive-cards-accessibility
description: >
  Semantics contract for Adaptive Card elements — how labels, headings, live
  regions, and decorative-vs-meaningful images are exposed to screen readers,
  and how to test them with `tester.ensureSemantics()`. Use when adding or
  changing any element, input, or action widget, and at code review.
---

# Adaptive Cards Accessibility Skill

## Overview

A rendered card is mostly **author-supplied content**, so accessibility here is
not "add a label" — it is deciding **whose text becomes the accessible name**,
and making sure the widget tree does not announce that text twice or not at all.

The library already has helpers for this. Use them rather than hand-rolling
`Semantics` widgets; a bespoke `Semantics` wrapper next to a visible label is the
most common way to introduce a **double announcement**.

---

## The four rules

### 1. Author text is the accessible name — never substitute a placeholder

`altText` from card JSON is the accessible name for images, icons, and media.
When the author omits it, the element is **decorative** and must be *excluded*
from the semantics tree.

**Pass `null` through. Do not invent a fallback string.**

```dart
// packages/flutter_adaptive_cards_fs/lib/src/utils/adaptive_image_utils.dart
AdaptiveImageUtils.getImage(url, semanticsLabel: adaptiveMap['altText']?.toString());
```

A `null` label makes Flutter drop the image from the semantics tree entirely,
which is the correct behavior for decoration. A fallback like
`'alt text not set'` or `'image'` is worse than nothing: it forces a screen
reader to read noise on every decorative image. There is a regression test
pinning this (`accessibility_semantics_test.dart` — *"Image without altText is
not labeled 'alt text not set'"*), so this is not a preference.

### 2. Inputs: link the visible label to the control, and exclude the duplicate

The visible label built by `loadLabel()` is a **sibling** widget. Assistive
technology reads it as an unrelated node, so focusing the field announces the
value with no idea what it is for. Two helpers in
`packages/flutter_adaptive_cards_fs/lib/src/utils/utils.dart` fix this:

- **`inputSemanticsLabel({label, isRequired})`** — builds the spoken name and
  appends `", required"`. The visible label marks required fields with a `*`
  glyph, which screen readers do not reliably convey.
- **`labelInputSemantics({field, label, isRequired})`** — wraps the control in
  `MergeSemantics(Semantics(label: ...))` so the label and the field's own value
  are announced as one node. Returns `field` unchanged when there is no label.

The **visible** label must then be wrapped in `ExcludeSemantics`, or the name is
announced twice. The pair is load-bearing — always apply both:

```dart
// see text.dart, number.dart, date.dart, time.dart for the canonical shape
ExcludeSemantics(child: loadLabel(context: context, label: label, isRequired: isRequired)),
labelInputSemantics(field: myTextField, label: label, isRequired: isRequired),
```

### 3. Validation errors are live regions

A validation message that appears after a failed submit is invisible to a screen
reader user who has already moved focus past the field. The error builder in
`utils.dart` wraps the message in `Semantics(liveRegion: true)` so assistive
technology announces it on appearance without re-focusing the control. Any new
transient, user-visible status message should do the same.

### 4. Headings are structural, not stylistic

A TextBlock with `"style": "heading"` sets `header: true` **and** a
`headingLevel` from HostConfig (defaulting to 2). Screen reader users navigate by
heading, so a heading that only *looks* big is not a heading. Never fake one with
font size alone.

---

## Reference: what is already wired

Read these before adding semantics to a new element — the pattern you need almost
certainly exists.

| Concern | Where |
| --- | --- |
| Input label + required, exclude duplicate | `utils.dart` → `inputSemanticsLabel`, `labelInputSemantics` |
| Error message live region | `utils.dart` (error builder) |
| Decorative vs meaningful image (null label) | `utils/adaptive_image_utils.dart` |
| Heading role + level | `cards/elements/text_block.dart`, `rich_text_block.dart` |
| Value semantics + `ExcludeSemantics` on the visual | `widgets/rating_stars.dart` |
| Merged control semantics | `cards/inputs/toggle.dart`, `rating.dart`, `choice_set.dart` |
| Progress announcement | `cards/elements/progress_bar.dart`, `progress_ring.dart` |
| Table header role + header-to-cell association | `cards/containers/table.dart` |

### Why `Table` annotates instead of merging

Flutter validates table roles strictly — a `SemanticsRole.table` node's children
must all be `row`s, and a `row`'s children must be `cell`/`columnHeader`. But
`TableRow` is a **data holder with no render object**, so there is no node to hang
a row role on; using the table roles would trip Flutter's own assertion, and
faking one row-node-per-cell would misreport the table's geometry to assistive
technology.

So `table.dart` does the thing that works on every platform today: header cells
get `Semantics(header: true)`, and each body cell is **annotated** with its column
header (`Semantics(label: 'Status')`), which Flutter absorbs into the same node as
the cell's text — announcing "Status Delayed" instead of a context-free "Delayed".

**Annotate, do not `MergeSemantics`.** Merging would flatten a cell's
`selectAction` or nested `Input.*` into the cell node and destroy its independent
focusability. Annotation leaves interactive descendants as their own nodes; there
is a regression test pinning exactly this (`table_semantics_test.dart` — *"a
selectAction cell stays an independently focusable button"*).

**Residual limitation:** a column whose header cell has no text (image-only) is
left unlabeled — correctly, since there is nothing to speak. And because Flutter
exposes no true table geometry, screen readers still cannot report "row 3 of 12"
or navigate cell-by-cell as a grid.

---

## Testing

Semantics are **not** built unless a test asks for them. Every accessibility test
must open a handle and dispose it:

```dart
testWidgets('heading-styled TextBlock exposes header + level', (tester) async {
  final handle = tester.ensureSemantics();          // REQUIRED
  await tester.pumpWidget(buildCard({'type': 'TextBlock', 'text': 'H', 'style': 'heading'}));
  await tester.pumpAndSettle();

  final data = tester.getSemantics(find.text('H')).getSemanticsData();
  expect(data.flagsCollection.isHeader, isTrue);
  expect(data.headingLevel, 2);

  handle.dispose();                                  // REQUIRED
});
```

Assertion styles, by what you are proving:

- **A name is announced** → `find.bySemanticsLabel('...')`.
- **A name is *not* announced** (decorative, or no double-read) →
  `expect(find.bySemanticsLabel('...'), findsNothing)`.
- **A role or flag** (`isHeader`, `isButton`, `isTextField`, `headingLevel`,
  `isLiveRegion`) → `tester.getSemantics(finder).getSemanticsData()`.

Existing suites to extend rather than duplicate:

- `test/accessibility_semantics_test.dart` — decorative images, `selectAction`
  button naming, rating values, carousel dots.
- `test/input_label_semantics_test.dart` — label + required, no double-read.
- `test/input_error_and_progress_a11y_test.dart` — live regions, progress.
- `test/textblock_heading_and_factset_semantics_test.dart` — heading roles.
- `test/inputs/choice_set_filtered_semantics_test.dart` — filtered choice sets.
- `test/containers/table_semantics_test.dart` — header cells, header-to-cell
  association, interactive cells staying focusable.

**A new element with a user-visible name, role, or value needs a semantics test.**
It is the only way these regressions get caught — they are invisible in goldens.

---

## Known gaps

These are the known holes at the time of writing — confirm each against the
current widget before acting, since one may already be fixed. Do not treat the
list as a backlog you must clear in passing, but **do not add to it**, and prefer
fixing the one you are already touching.

- **`flutter_adaptive_charts_fs` — no semantics anywhere.** A chart is a picture
  of data with no text alternative. It needs at least a summary label
  (title + series + notable values).
- **`CompoundButton`** — correctly an `ElevatedButton` (button role) with a
  correctly-unlabeled decorative icon, but `title` and `description` are separate
  `Text` nodes inside it. Verify they merge into one announcement; if they read as
  two nodes, wrap in `MergeSemantics`.
- **`CodeBlock`** — plain `Text`; `language` is parsed but never announced.

`Accordion` (`ExpansionTile`) and `TabSet` (`TabBar`/`Tab`) inherit Material's
built-in expand/collapse and tab semantics, so they are **not** gaps — do not
"fix" them by wrapping in redundant `Semantics`.

---

## Review checklist

- [ ] Author `altText` used as the accessible name; **absent `altText` → `null`**,
      never a placeholder string.
- [ ] Input control wrapped with `labelInputSemantics`, **and** the visible label
      wrapped in `ExcludeSemantics`.
- [ ] Required state reaches the accessible name (not conveyed by the `*` glyph alone).
- [ ] Transient status/validation text is a `liveRegion`.
- [ ] Headings use `header: true` + `headingLevel`, not just a large font.
- [ ] Interactive targets expose a **name** and a **role** (button/tab/checkbox).
- [ ] No double announcement — a bespoke `Semantics` next to a visible label is the
      usual cause.
- [ ] A semantics test exists, and it calls `tester.ensureSemantics()`.
