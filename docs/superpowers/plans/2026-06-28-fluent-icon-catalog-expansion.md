# Fluent Icon Catalog Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Grow the `Icon` element's Fluent-name → Material-icon table from 69 entries to ~150–200, plus common aliases, with no change to the lookup path or fallback.

**Architecture:** Data-only edits to `lib/src/utils/fluent_icon_map.dart` (a `const Map<String, FluentIconEntry>` keyed by normalized name). The resolver (`resolveFluentIcon`), normalization, filled/regular selection, and `Icons.help_outline` fallback are untouched. The Dart analyzer is the safety net for icon-constant validity: any non-existent `Icons.*` constant fails `fvm flutter analyze`.

**Tech Stack:** Flutter (Material Icons), Dart, `package:test`/`flutter_test`, FVM.

**Spec:** [2026-06-28-fluent-icon-catalog-expansion-design.md](../specs/2026-06-28-fluent-icon-catalog-expansion-design.md)

> **Git gate (project rule):** Every `git commit` requires showing the diff and explicit user confirmation first (per `AGENTS.md`). Commit steps are the intended commit points; do not run them unattended.

> **Working directory:** Run all `fvm` commands from `packages/flutter_adaptive_cards_fs/`. Always prefix `flutter`/`dart` with `fvm`. `cd` within the repo is allowed.

> **Existing normalized keys (DO NOT re-add — `const` maps forbid duplicate keys):**
> `accesstime add arrowdown arrowleft arrowright arrowup attach bell bug calendar call camera chat checkmark chevrondown chevronleft chevronright chevronup clock close cloud code copy database delete dismiss document download edit errorcircle eye filter flag folder globe heart home image info link location lock mail map menu more open people person pin print refresh save search send settings share sort star sync thumbdislike thumblike unlock upload video visibility warning`

---

## File Structure

- **Modify:** `lib/src/utils/fluent_icon_map.dart` — add canonical entries (Task 1) and an aliases block (Task 2).
- **Create:** `test/utils/fluent_icon_map_test.dart` — pure resolver tests (Tasks 1–2).
- **Create:** `test/samples/v1.6/icon_catalog.json` + golden in `test/golden_icon_test.dart` (Task 3).
- **Modify (docs):** `README.md`, `docs/Implementation-Status.md`, `CHANGELOG.md` (Task 4).

---

## Task 1: Add canonical Fluent-name entries

**Files:**
- Modify: `lib/src/utils/fluent_icon_map.dart`
- Test: `test/utils/fluent_icon_map_test.dart` (new)

- [ ] **Step 1: Write the failing test**

Create `test/utils/fluent_icon_map_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/fluent_icon_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveFluentIcon — newly added canonical names', () {
    // A representative sample of the expanded catalog (Task 1).
    const sample = <String>[
      'play', 'pause', 'stop', 'mic', 'bookmark', 'favorite', 'cart',
      'work', 'school', 'book', 'dashboard', 'analytics', 'chart',
      'lightbulb', 'verified', 'shield', 'account', 'trophy', 'comment',
      'reply', 'archive', 'cloudupload', 'clouddownload', 'checkcircle',
      'visibilityoff', 'calendarevent', 'timer', 'palette', 'tag',
      'restaurant', 'coffee', 'car', 'wifi', 'weather',
    ];

    test('each sample name resolves to a non-fallback icon (filled & regular)',
        () {
      for (final name in sample) {
        final filled = resolveFluentIcon(name, filled: true);
        final regular = resolveFluentIcon(name, filled: false);
        expect(filled, isNotNull, reason: '$name (filled) should resolve');
        expect(filled, isNot(Icons.help_outline), reason: '$name not fallback');
        expect(regular, isNotNull, reason: '$name (regular) should resolve');
      }
    });

    test('unknown name returns null (caller falls back to help_outline)', () {
      expect(resolveFluentIcon('definitely-not-an-icon', filled: true), isNull);
    });

    test('normalization variants resolve identically', () {
      expect(
        resolveFluentIcon('CloudUpload', filled: true),
        resolveFluentIcon('cloud_upload', filled: true),
      );
      expect(
        resolveFluentIcon('cloud-upload', filled: true),
        resolveFluentIcon('cloudupload', filled: true),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/utils/fluent_icon_map_test.dart`
Expected: FAIL — most sample names are not in the map yet (resolve to `null`).

- [ ] **Step 3: Add canonical entries**

In `lib/src/utils/fluent_icon_map.dart`, inside the `kFluentIconMap` literal (before
the closing `};`), add the following block. These use widely-available Material
constants; `regular` is set only where a Material outlined variant is known to exist.

```dart
  // --- expanded canonical Fluent names (2026-06-28) ---
  'play': FluentIconEntry(filled: Icons.play_arrow),
  'pause': FluentIconEntry(filled: Icons.pause),
  'stop': FluentIconEntry(filled: Icons.stop),
  'next': FluentIconEntry(filled: Icons.skip_next),
  'previous': FluentIconEntry(filled: Icons.skip_previous),
  'fastforward': FluentIconEntry(filled: Icons.fast_forward),
  'rewind': FluentIconEntry(filled: Icons.fast_rewind),
  'volume': FluentIconEntry(filled: Icons.volume_up),
  'mute': FluentIconEntry(filled: Icons.volume_off),
  'mic': FluentIconEntry(filled: Icons.mic, regular: Icons.mic_none),
  'micoff': FluentIconEntry(filled: Icons.mic_off),
  'bookmark': FluentIconEntry(
    filled: Icons.bookmark,
    regular: Icons.bookmark_border,
  ),
  'bookmarks': FluentIconEntry(
    filled: Icons.bookmarks,
    regular: Icons.bookmarks_outlined,
  ),
  'favorite': FluentIconEntry(
    filled: Icons.favorite,
    regular: Icons.favorite_border,
  ),
  'cart': FluentIconEntry(
    filled: Icons.shopping_cart,
    regular: Icons.shopping_cart_outlined,
  ),
  'store': FluentIconEntry(filled: Icons.store, regular: Icons.store_outlined),
  'creditcard': FluentIconEntry(filled: Icons.credit_card),
  'money': FluentIconEntry(filled: Icons.attach_money),
  'wallet': FluentIconEntry(
    filled: Icons.account_balance_wallet,
    regular: Icons.account_balance_wallet_outlined,
  ),
  'bank': FluentIconEntry(filled: Icons.account_balance),
  'work': FluentIconEntry(filled: Icons.work, regular: Icons.work_outline),
  'school': FluentIconEntry(filled: Icons.school, regular: Icons.school_outlined),
  'book': FluentIconEntry(filled: Icons.book, regular: Icons.book_outlined),
  'dashboard': FluentIconEntry(
    filled: Icons.dashboard,
    regular: Icons.dashboard_outlined,
  ),
  'analytics': FluentIconEntry(
    filled: Icons.analytics,
    regular: Icons.analytics_outlined,
  ),
  'chart': FluentIconEntry(
    filled: Icons.insert_chart,
    regular: Icons.insert_chart_outlined,
  ),
  'piechart': FluentIconEntry(
    filled: Icons.pie_chart,
    regular: Icons.pie_chart_outline,
  ),
  'barchart': FluentIconEntry(filled: Icons.bar_chart),
  'linechart': FluentIconEntry(filled: Icons.show_chart),
  'trendingup': FluentIconEntry(filled: Icons.trending_up),
  'trendingdown': FluentIconEntry(filled: Icons.trending_down),
  'table': FluentIconEntry(
    filled: Icons.table_chart,
    regular: Icons.table_chart_outlined,
  ),
  'grid': FluentIconEntry(
    filled: Icons.grid_view,
    regular: Icons.grid_view_outlined,
  ),
  'list': FluentIconEntry(filled: Icons.format_list_bulleted),
  'numberedlist': FluentIconEntry(filled: Icons.format_list_numbered),
  'lightbulb': FluentIconEntry(
    filled: Icons.lightbulb,
    regular: Icons.lightbulb_outline,
  ),
  'verified': FluentIconEntry(
    filled: Icons.verified,
    regular: Icons.verified_outlined,
  ),
  'shield': FluentIconEntry(filled: Icons.shield, regular: Icons.shield_outlined),
  'security': FluentIconEntry(filled: Icons.security),
  'fingerprint': FluentIconEntry(filled: Icons.fingerprint),
  'key': FluentIconEntry(filled: Icons.vpn_key, regular: Icons.vpn_key_outlined),
  'badge': FluentIconEntry(filled: Icons.badge, regular: Icons.badge_outlined),
  'account': FluentIconEntry(
    filled: Icons.account_circle,
    regular: Icons.account_circle_outlined,
  ),
  'personadd': FluentIconEntry(filled: Icons.person_add),
  'trophy': FluentIconEntry(
    filled: Icons.emoji_events,
    regular: Icons.emoji_events_outlined,
  ),
  'emoji': FluentIconEntry(
    filled: Icons.emoji_emotions,
    regular: Icons.emoji_emotions_outlined,
  ),
  'comment': FluentIconEntry(
    filled: Icons.comment,
    regular: Icons.comment_outlined,
  ),
  'forum': FluentIconEntry(filled: Icons.forum, regular: Icons.forum_outlined),
  'feedback': FluentIconEntry(
    filled: Icons.feedback,
    regular: Icons.feedback_outlined,
  ),
  'reply': FluentIconEntry(filled: Icons.reply),
  'forward': FluentIconEntry(filled: Icons.forward),
  'inbox': FluentIconEntry(filled: Icons.inbox),
  'archive': FluentIconEntry(filled: Icons.archive, regular: Icons.archive_outlined),
  'drafts': FluentIconEntry(filled: Icons.drafts, regular: Icons.drafts_outlined),
  'cloudupload': FluentIconEntry(
    filled: Icons.cloud_upload,
    regular: Icons.cloud_upload_outlined,
  ),
  'clouddownload': FluentIconEntry(
    filled: Icons.cloud_download,
    regular: Icons.cloud_download_outlined,
  ),
  'clouddone': FluentIconEntry(
    filled: Icons.cloud_done,
    regular: Icons.cloud_done_outlined,
  ),
  'backup': FluentIconEntry(filled: Icons.backup),
  'restore': FluentIconEntry(filled: Icons.restore),
  'history': FluentIconEntry(filled: Icons.history),
  'remove': FluentIconEntry(
    filled: Icons.remove_circle,
    regular: Icons.remove_circle_outline,
  ),
  'cancel': FluentIconEntry(filled: Icons.cancel),
  'block': FluentIconEntry(filled: Icons.block),
  'checkcircle': FluentIconEntry(
    filled: Icons.check_circle,
    regular: Icons.check_circle_outline,
  ),
  'pending': FluentIconEntry(filled: Icons.pending, regular: Icons.pending_outlined),
  'visibilityoff': FluentIconEntry(
    filled: Icons.visibility_off,
    regular: Icons.visibility_off_outlined,
  ),
  'notificationsoff': FluentIconEntry(
    filled: Icons.notifications_off,
    regular: Icons.notifications_off_outlined,
  ),
  'calendarevent': FluentIconEntry(filled: Icons.event),
  'alarm': FluentIconEntry(filled: Icons.alarm),
  'timer': FluentIconEntry(filled: Icons.timer, regular: Icons.timer_outlined),
  'update': FluentIconEntry(filled: Icons.update),
  'label': FluentIconEntry(filled: Icons.label, regular: Icons.label_outline),
  'tag': FluentIconEntry(filled: Icons.sell, regular: Icons.sell_outlined),
  'gift': FluentIconEntry(filled: Icons.card_giftcard),
  'cake': FluentIconEntry(filled: Icons.cake),
  'celebration': FluentIconEntry(filled: Icons.celebration),
  'palette': FluentIconEntry(filled: Icons.palette, regular: Icons.palette_outlined),
  'color': FluentIconEntry(
    filled: Icons.color_lens,
    regular: Icons.color_lens_outlined,
  ),
  'brush': FluentIconEntry(filled: Icons.brush),
  'text': FluentIconEntry(filled: Icons.text_fields),
  'bold': FluentIconEntry(filled: Icons.format_bold),
  'italic': FluentIconEntry(filled: Icons.format_italic),
  'underline': FluentIconEntry(filled: Icons.format_underlined),
  'build': FluentIconEntry(filled: Icons.build, regular: Icons.build_outlined),
  'handyman': FluentIconEntry(filled: Icons.handyman),
  'qrcode': FluentIconEntry(filled: Icons.qr_code),
  'scan': FluentIconEntry(filled: Icons.document_scanner),
  'wifi': FluentIconEntry(filled: Icons.wifi),
  'bluetooth': FluentIconEntry(filled: Icons.bluetooth),
  'battery': FluentIconEntry(filled: Icons.battery_full),
  'power': FluentIconEntry(filled: Icons.power_settings_new),
  'desktop': FluentIconEntry(filled: Icons.desktop_windows),
  'laptop': FluentIconEntry(filled: Icons.laptop),
  'mobile': FluentIconEntry(filled: Icons.smartphone),
  'tablet': FluentIconEntry(filled: Icons.tablet),
  'tv': FluentIconEntry(filled: Icons.tv),
  'keyboard': FluentIconEntry(filled: Icons.keyboard),
  'mouse': FluentIconEntry(filled: Icons.mouse),
  'compass': FluentIconEntry(filled: Icons.explore, regular: Icons.explore_outlined),
  'navigation': FluentIconEntry(filled: Icons.navigation),
  'directions': FluentIconEntry(filled: Icons.directions),
  'car': FluentIconEntry(
    filled: Icons.directions_car,
    regular: Icons.directions_car_outlined,
  ),
  'flight': FluentIconEntry(filled: Icons.flight),
  'train': FluentIconEntry(filled: Icons.train),
  'bus': FluentIconEntry(
    filled: Icons.directions_bus,
    regular: Icons.directions_bus_outlined,
  ),
  'walk': FluentIconEntry(filled: Icons.directions_walk),
  'bike': FluentIconEntry(filled: Icons.directions_bike),
  'hotel': FluentIconEntry(filled: Icons.hotel),
  'restaurant': FluentIconEntry(filled: Icons.restaurant),
  'coffee': FluentIconEntry(
    filled: Icons.local_cafe,
    regular: Icons.local_cafe_outlined,
  ),
  'apartment': FluentIconEntry(filled: Icons.apartment),
  'business': FluentIconEntry(filled: Icons.business),
  'weather': FluentIconEntry(filled: Icons.wb_sunny, regular: Icons.wb_sunny_outlined),
  'rain': FluentIconEntry(filled: Icons.water_drop, regular: Icons.water_drop_outlined),
  'snow': FluentIconEntry(filled: Icons.ac_unit),
  'temperature': FluentIconEntry(filled: Icons.thermostat),
```

> This block plus the existing 69 entries reaches ~140 canonical keys; aliases
> (Task 2) carry the total to ~150–200. If `fvm flutter analyze` (Step 4) reports an
> unknown `Icons.*` constant on any line, replace it with a valid Material constant
> (search the [Material Icons gallery](https://fonts.google.com/icons)) or drop the
> `regular:` to leave it `null` — the analyzer is the source of truth for validity.

- [ ] **Step 4: Verify constant validity (analyzer)**

Run: `fvm flutter analyze lib/src/utils/fluent_icon_map.dart`
Expected: No issues. (Fix any "undefined name 'Icons.xxx'" per the note above.)

- [ ] **Step 5: Run the test to verify it passes**

Run: `fvm flutter test test/utils/fluent_icon_map_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/utils/fluent_icon_map.dart \
  packages/flutter_adaptive_cards_fs/test/utils/fluent_icon_map_test.dart
git commit -m "feat(icon): expand Fluent name catalog to ~140 canonical entries"
```

---

## Task 2: Add common aliases

**Files:**
- Modify: `lib/src/utils/fluent_icon_map.dart`
- Test: `test/utils/fluent_icon_map_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/utils/fluent_icon_map_test.dart`:

```dart
  group('resolveFluentIcon — aliases', () {
    // alias -> canonical name; both must resolve to the same icon.
    const aliases = <String, String>{
      'trash': 'delete',
      'bin': 'delete',
      'gear': 'settings',
      'options': 'settings',
      'pencil': 'edit',
      'find': 'search',
      'email': 'mail',
      'envelope': 'mail',
      'user': 'person',
      'contact': 'person',
      'group': 'people',
      'team': 'people',
      'photo': 'image',
      'picture': 'image',
      'information': 'info',
      'alert': 'warning',
      'error': 'errorcircle',
      'accept': 'checkmark',
      'check': 'checkmark',
      'date': 'calendar',
      'house': 'home',
      'star_filled': 'star',
      'house2': 'home',
      'question': 'help',
      'idea': 'lightbulb',
      'trophy_award': 'trophy',
    };

    test('each alias resolves to the same icon as its canonical name', () {
      aliases.forEach((alias, canonical) {
        expect(
          resolveFluentIcon(alias, filled: true),
          resolveFluentIcon(canonical, filled: true),
          reason: '"$alias" should match "$canonical"',
        );
      });
    });
  });
```

> NOTE: the `help` canonical name is in the existing map; `idea`→`lightbulb` and
> `trophy_award`→`trophy` reference Task 1 entries. `star_filled`/`house2` are extra
> duplicate-alias sanity checks — keep or drop, but every key on the left must exist
> in the map after Step 3.

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/utils/fluent_icon_map_test.dart --plain-name "alias"`
Expected: FAIL — aliases not in map.

- [ ] **Step 3: Add the aliases block**

In `kFluentIconMap`, add (each alias points at the same `FluentIconEntry` value as
its canonical name; copy the canonical entry's `IconData`s):

```dart
  // --- aliases (author name variants) ---
  'trash': FluentIconEntry(filled: Icons.delete, regular: Icons.delete_outline),
  'bin': FluentIconEntry(filled: Icons.delete, regular: Icons.delete_outline),
  'gear': FluentIconEntry(filled: Icons.settings, regular: Icons.settings_outlined),
  'options': FluentIconEntry(
    filled: Icons.settings,
    regular: Icons.settings_outlined,
  ),
  'pencil': FluentIconEntry(filled: Icons.edit, regular: Icons.edit_outlined),
  'find': FluentIconEntry(filled: Icons.search),
  'email': FluentIconEntry(filled: Icons.mail, regular: Icons.mail_outline),
  'envelope': FluentIconEntry(filled: Icons.mail, regular: Icons.mail_outline),
  'user': FluentIconEntry(filled: Icons.person, regular: Icons.person_outline),
  'contact': FluentIconEntry(filled: Icons.person, regular: Icons.person_outline),
  'group': FluentIconEntry(filled: Icons.people, regular: Icons.people_outline),
  'team': FluentIconEntry(filled: Icons.people, regular: Icons.people_outline),
  'photo': FluentIconEntry(filled: Icons.image, regular: Icons.image_outlined),
  'picture': FluentIconEntry(filled: Icons.image, regular: Icons.image_outlined),
  'information': FluentIconEntry(filled: Icons.info, regular: Icons.info_outline),
  'alert': FluentIconEntry(filled: Icons.warning, regular: Icons.warning_outlined),
  'error': FluentIconEntry(filled: Icons.error, regular: Icons.error_outline),
  'accept': FluentIconEntry(filled: Icons.check),
  'check': FluentIconEntry(filled: Icons.check),
  'date': FluentIconEntry(
    filled: Icons.calendar_today,
    regular: Icons.calendar_today,
  ),
  'house': FluentIconEntry(filled: Icons.home, regular: Icons.home_outlined),
  'house2': FluentIconEntry(filled: Icons.home, regular: Icons.home_outlined),
  'starfilled': FluentIconEntry(filled: Icons.star, regular: Icons.star_border),
  'question': FluentIconEntry(filled: Icons.help, regular: Icons.help_outline),
  'idea': FluentIconEntry(
    filled: Icons.lightbulb,
    regular: Icons.lightbulb_outline,
  ),
  'trophyaward': FluentIconEntry(
    filled: Icons.emoji_events,
    regular: Icons.emoji_events_outlined,
  ),
```

> The alias `IconData`s must match the canonical entry exactly (the test compares
> `resolveFluentIcon(alias)` to `resolveFluentIcon(canonical)`). Confirm against the
> canonical rows (existing map for `delete`/`settings`/`edit`/`search`/`mail`/`person`/
> `people`/`image`/`info`/`warning`/`checkmark`/`calendar`/`home`/`star`/`help`;
> Task 1 for `errorcircle`→`error`-style, `lightbulb`, `trophy`). If a canonical entry
> uses different `IconData`, copy *those* values so the equality holds.
>
> `error` alias must equal the canonical `errorcircle` entry — check the existing
> `errorcircle` row's `IconData`s and reuse them here (adjust the `error` line so
> `resolveFluentIcon('error')` == `resolveFluentIcon('errorcircle')`). Same idea for
> `accept`/`check` vs the existing `checkmark` row.

- [ ] **Step 4: Reconcile alias values with canonical rows**

Open the existing `checkmark` and `errorcircle` rows and the Task 1 rows; set each
alias's `filled`/`regular` equal to its canonical entry. Then:

Run: `fvm flutter analyze lib/src/utils/fluent_icon_map.dart`
Expected: No issues (no undefined constants, no duplicate keys).

- [ ] **Step 5: Run the test to verify it passes**

Run: `fvm flutter test test/utils/fluent_icon_map_test.dart`
Expected: PASS (canonical + alias groups).

- [ ] **Step 6: Add the catalog guard test**

Append to `test/utils/fluent_icon_map_test.dart`:

```dart
  test('catalog has >= 150 keys and every entry has a non-null filled icon', () {
    expect(kFluentIconMap.length, greaterThanOrEqualTo(150));
    for (final entry in kFluentIconMap.values) {
      // `filled` is non-nullable IconData; this asserts the map is well-formed
      // and documents the invariant relied on by resolveFluentIcon.
      expect(entry.filled, isA<IconData>());
    }
  });
```

Run: `fvm flutter test test/utils/fluent_icon_map_test.dart`
Expected: PASS (if `< 150` keys, add a few more canonical entries from the spec's
categories until the count is met).

- [ ] **Step 7: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/utils/fluent_icon_map.dart \
  packages/flutter_adaptive_cards_fs/test/utils/fluent_icon_map_test.dart
git commit -m "feat(icon): add common Fluent name aliases + catalog guard test"
```

---

## Task 3: Sample card + golden

**Files:**
- Create: `test/samples/v1.6/icon_catalog.json`
- Modify: `test/golden_icon_test.dart`

- [ ] **Step 1: Create the sample**

Create `test/samples/v1.6/icon_catalog.json` (a row of newly-added icons):

```json
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "body": [
    {
      "type": "ColumnSet",
      "columns": [
        { "type": "Column", "width": "auto", "items": [ { "type": "Icon", "name": "play", "size": "Large" } ] },
        { "type": "Column", "width": "auto", "items": [ { "type": "Icon", "name": "bookmark", "size": "Large" } ] },
        { "type": "Column", "width": "auto", "items": [ { "type": "Icon", "name": "cart", "size": "Large" } ] },
        { "type": "Column", "width": "auto", "items": [ { "type": "Icon", "name": "dashboard", "size": "Large" } ] },
        { "type": "Column", "width": "auto", "items": [ { "type": "Icon", "name": "trophy", "size": "Large" } ] },
        { "type": "Column", "width": "auto", "items": [ { "type": "Icon", "name": "wifi", "size": "Large" } ] },
        { "type": "Column", "width": "auto", "items": [ { "type": "Icon", "name": "car", "size": "Large" } ] },
        { "type": "Column", "width": "auto", "items": [ { "type": "Icon", "name": "lightbulb", "size": "Large" } ] }
      ]
    }
  ]
}
```

- [ ] **Step 2: Add the golden test**

In `test/golden_icon_test.dart`, add inside `main()`:

```dart
  testWidgets('Icon catalog golden — expanded names', (tester) async {
    configureTestView(size: const Size(420, 120));
    const ValueKey key = ValueKey('paint');
    await tester.pumpWidget(getSampleForGoldenTest(key, 'v1.6/icon_catalog'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_icon_catalog.png')),
    );
  }, tags: ['golden']);
```

> If `golden_icon_test.dart` does not already import the golden helpers, they come
> from `import 'utils/test_utils.dart';` (re-exports `configureTestView`,
> `getSampleForGoldenTest`, `getGoldenPath`). Match the existing imports in that file.

- [ ] **Step 3: Generate macOS baseline + verify**

Run: `fvm flutter test --update-goldens --tags=golden test/golden_icon_test.dart`
then `fvm flutter test --tags=golden test/golden_icon_test.dart`
Expected: creates `gold_files/macos/v1_6_icon_catalog.png`; second run PASS. Inspect
the image to confirm the eight icons render (not `help_outline`).

> Linux baseline must be regenerated on a Linux runner before merge (this repo keeps
> `macos/` and `linux/` golden dirs). Optionally copy the macOS file into
> `gold_files/linux/` as a placeholder meanwhile.

- [ ] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/test/samples/v1.6/icon_catalog.json \
  packages/flutter_adaptive_cards_fs/test/golden_icon_test.dart \
  packages/flutter_adaptive_cards_fs/test/gold_files
git commit -m "test(icon): golden for expanded icon catalog sample"
```

---

## Task 4: Documentation + changelog

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/README.md`
- Modify: `docs/Implementation-Status.md`
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`

- [ ] **Step 1: README Icon row**

In `packages/flutter_adaptive_cards_fs/README.md`, find the **Icon** row in the Card
Elements table and update its Notes from the “~68 Fluent names” wording to:

```
~150–200 Fluent names + common aliases via Material icons; unknown → `help_outline`; `selectAction` supported
```

Also flip the Icon row's Implementation cell from ⚠️ Partial to ✅ Complete only if it
currently reads Partial *because of* the catalog size; otherwise leave the status and
just update the note. (Keep it ⚠️ Partial if other Icon gaps remain — the catalog is
still an approximation, not the full Fluent font.)

- [ ] **Step 2: Implementation-Status roadmap**

In `docs/Implementation-Status.md`:
- Remove “**`Icon` element**: Expand Fluent name catalog…” from **Medium priority**.
- Add to **Recently completed**:

```
### Fluent icon catalog expansion (2026-06-28)

Plan: [2026-06-28-fluent-icon-catalog-expansion.md](./superpowers/plans/2026-06-28-fluent-icon-catalog-expansion.md) — design: [2026-06-28-fluent-icon-catalog-expansion-design.md](./superpowers/specs/2026-06-28-fluent-icon-catalog-expansion-design.md).

- Grew `kFluentIconMap` from 69 to ~150–200 Fluent-name → Material-icon entries plus common aliases (filled/regular where available); unknown names still fall back to `help_outline`. The full Fluent-font approach (`fluentui_system_icons` / opt-in extension package) remains a deferred option.
```

- [ ] **Step 3: CHANGELOG**

In `packages/flutter_adaptive_cards_fs/CHANGELOG.md`, under `### Added 0.13.0`:

```
- **Icon catalog expanded** — `kFluentIconMap` grew from 69 to ~150–200 Fluent-name → Material-icon mappings (filled/regular where available) plus common aliases (`trash`/`bin`, `gear`, `pencil`, `email`/`envelope`, `user`/`contact`, etc.). Unknown names still fall back to `help_outline`. Material approximation remains intentionally partial; the full Fluent font is a deferred option.
```

- [ ] **Step 4: Commit**

```bash
git add packages/flutter_adaptive_cards_fs/README.md docs/Implementation-Status.md \
  packages/flutter_adaptive_cards_fs/CHANGELOG.md
git commit -m "docs(icon): record catalog expansion; update roadmap"
```

---

## Final Task: Full verification

- [ ] **Step 1: Analyze (repo root)**

Run: `cd /Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards && fvm flutter analyze`
Expected: No issues.

- [ ] **Step 2: Core non-golden tests**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`
Expected: all pass (including the existing `test/elements/icon_test.dart`).

- [ ] **Step 3: Golden tests**

Run: `fvm flutter test --tags=golden test/golden_icon_test.dart`
Expected: PASS (macOS baseline; linux regenerated on a Linux runner before merge).

- [ ] **Step 4: Coverage gate**

Run from repo root:
```bash
cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden --coverage && cd ../..
fvm dart run tool/coverage/check_coverage.dart
```
Expected: coverage floor met.

- [ ] **Step 5: Invoke `verification-before-completion`**

Paste exit codes + pass/fail counts before claiming completion.

---

## Self-Review notes (author)

- **Spec coverage:** catalog growth to ~150–200 (Task 1 + the guard in Task 2 Step 6);
  aliases (Task 2); curation criteria + analyzer safety net (Task 1 Step 3–4); golden
  sample (Task 3); docs incl. roadmap move (Task 4). Lookup/normalization/fallback
  untouched (no task changes `icon.dart` or `resolveFluentIcon`).
- **No-placeholder note:** the canonical batch is concrete and verified-by-analyzer;
  the only open-ended instruction is "add a few more if `< 150`," bounded by the
  Task 2 Step 6 count guard and the spec's category list — an explicit, testable
  target, not a vague TODO.
- **Type consistency:** uses the existing `FluentIconEntry{filled, regular}` and
  `resolveFluentIcon(name, {required bool filled})` throughout; no new types.
- **Risk:** a few `Icons.*_outlined` constants may not exist in the pinned Flutter
  version; Task 1 Step 4 / Task 2 Step 4 (`flutter analyze`) catch these before tests,
  with explicit remediation (use a valid constant or `regular: null`).
```
