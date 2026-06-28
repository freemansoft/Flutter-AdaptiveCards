# Expand the Fluent icon catalog (design)

**Date:** 2026-06-28
**Status:** Approved (brainstorming) — pending implementation plan
**Package:** `flutter_adaptive_cards_fs`
**Element:** `Icon` (hub/Teams extension) — [`lib/src/cards/elements/icon.dart`], data in [`lib/src/utils/fluent_icon_map.dart`]

## Summary

The `Icon` element maps a Fluent icon `name` to a Material `IconData` via a
hand-maintained table (`kFluentIconMap`), currently **69 entries**, falling back
to `Icons.help_outline` for unknown names. This change grows that table to
**~150–200 entries** plus a small set of common aliases, so more authored Fluent
names render a sensible glyph instead of the fallback.

This is a deliberately **low-risk, data-only** change: the lookup, normalization,
filled/regular selection, and fallback are unchanged; only the lookup *data*
grows.

### Approach decision (recorded)

The faithful-but-heavier options — Microsoft's `fluentui_system_icons` package or a
dedicated opt-in Fluent-icons **extension package** (bundling the real Fluent font,
~2000+ glyphs) — were **considered and declined** to keep the core lean and the
change isolated (consistent with keeping `fl_chart` out of core). Material
approximation is therefore intentionally **partial**: Fluent names with no faithful
Material equivalent keep falling back. Revisit the font approach if/when complete
catalog fidelity becomes a priority.

## Goals / non-goals

**Goals**
- Raise the Fluent-name hit rate by expanding `kFluentIconMap` to ~150–200 curated
  entries with faithful Material equivalents (filled + regular where available).
- Resolve common author name-guesses via a small alias set.
- **Zero behavior change** for the existing 69 names, the lookup path, and the
  `help_outline` fallback.

**Non-goals**
- Bundling the real Fluent font or reaching the full ~2000-icon catalog (declined).
- Any change to `icon.dart` (size/color/style/selectAction handling) or the
  resolver API.
- Forcing a glyph for names with no faithful Material match — those still fall back.

## Current state (for the implementer)

- `kFluentIconMap` (`lib/src/utils/fluent_icon_map.dart`): `const Map<String,
  FluentIconEntry>` keyed by **normalized** name. `FluentIconEntry{ IconData filled;
  IconData? regular; }`.
- `normalizeFluentIconName(name)` strips spaces/`_`/`-` and lowercases, so
  `AccessTime`, `access_time`, `access-time` collide to one key.
- `resolveFluentIcon(name, {required bool filled})` looks up the normalized name and
  returns `entry.filled` (or `entry.regular ?? entry.filled` when `filled == false`);
  unknown → `null`. `icon.dart` then uses `Icons.help_outline`.
- Existing coverage: `test/elements/icon_test.dart`, `test/golden_icon_test.dart`,
  sample `test/samples/v1.5/icon_demo.json`, goldens `gold_files/{macos,linux}/v1_5_icon_demo.png`.

## Design

### Catalog expansion

- Add ~80–130 new `FluentIconEntry` rows (target total ~150–200), curated against the
  Fluent UI System Icons names and grouped by category with comments:
  navigation/arrows, actions (edit, delete, share, save, copy, download, upload),
  status (info, warning, error/dismiss, success/checkmark), communication (mail,
  chat, call, video), files/folders, media (play/pause/stop, image, document),
  people (person, people, contact), time/calendar, shapes, devices.
- **Criteria per row:** include only when a Material icon is a faithful match; set
  `regular` to the Material outlined variant when it exists, else `null`. Skip names
  with no faithful match (documented — they keep falling back).
- Keep the single `const` map, alphabetical within category blocks, so the file stays
  scannable. No new file unless the map becomes unwieldy (then an alias sub-map split
  is acceptable — see below).

### Aliases

- A small **alias** set maps common author variants to a canonical entry, e.g.:
  `delete`/`trash`/`bin`; `settings`/`gear`/`options`; `edit`/`pencil`;
  `search`/`find`; `mail`/`email`/`envelope`; `phone`/`call`; `person`/`user`/`contact`;
  `people`/`group`; `image`/`photo`/`picture`; `info`/`information`;
  `warning`/`alert`; `error`/`dismisscircle`; `checkmark`/`check`/`accept`;
  `calendar`/`date`; `home`/`house`; `star`/`favorite`.
- **Mechanism:** add the alias keys directly into `kFluentIconMap` pointing at the
  same `FluentIconEntry` value (simplest; normalization already applies to lookups).
  Aliases live in a clearly-commented `// --- aliases ---` block (or a `const
  _aliases` sub-map merged into `kFluentIconMap`) so they're visibly distinct from
  canonical names.

### Isolation

All edits are confined to `fluent_icon_map.dart` (data). `icon.dart`,
`normalizeFluentIconName`, `resolveFluentIcon`, and the fallback are unchanged. This
keeps the change reviewable and the blast radius to the lookup table only.

## Error handling / edge cases

- **Unknown / garbage name** → `null` from `resolveFluentIcon` → `Icons.help_outline`
  (unchanged).
- **`style: "Regular"` on an entry with `regular: null`** → uses `filled` (current
  behavior; preserved).
- **Alias collision with a future canonical name** → guarded by a test asserting no
  duplicate keys silently diverge (Dart const maps already forbid duplicate literal
  keys at compile time; the test documents intent).

## Testing

- **Unit** (`test/elements/icon_test.dart`, or new `test/utils/fluent_icon_map_test.dart`):
  - A representative sample (~15–20) of newly-added names resolves to a non-`help_outline`
    `IconData` for both `filled: true` and `filled: false`.
  - Every alias resolves to the **same** `FluentIconEntry` as its canonical name.
  - A garbage name (`"definitely-not-an-icon"`) still returns `null` →
    callers fall back.
  - Normalization variants (`AccessTime` / `access_time` / `access-time`) still resolve.
  - Guard: every entry has a non-null `filled`.
- **Golden** (tagged `golden`): a new small sample (`test/samples/v1.6/icon_catalog.json`)
  rendering a grid of ~12 newly-added icons; new golden `icon_catalog.png`. macOS baseline
  generated; linux regenerated on a Linux runner before merge. The existing
  `v1_5_icon_demo` golden is untouched.
- **Verification:** `fvm flutter analyze` clean; `fvm flutter test --exclude-tags=golden`
  green; coverage gate PASS.

## Documentation impact

- **README** (`packages/flutter_adaptive_cards_fs/README.md`): update the **Icon** row
  note from “~68 Fluent names” to “~150–200 Fluent names + common aliases; unknown →
  `help_outline`”.
- **`docs/Implementation-Status.md`**: move “Icon element: expand Fluent name catalog”
  from Medium-priority into Recently completed; note the full-font approach remains a
  deferred option.
- **`CHANGELOG.md`**: `## [0.13.0]` Added bullet.
