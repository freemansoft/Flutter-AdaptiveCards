# Migration to `material_ui` and `cupertino_ui` — design note

Status: deferred. Written 2026-09-13 while the repo sat on Flutter 3.47.4 / Dart 3.13.3. This note records what was learned about the migration so the task plan can be written when the work is scheduled; it is not the plan.

## Why this exists

Flutter 3.47 published `material_ui` 1.x and `cupertino_ui` 1.x on pub.dev as standalone copies of the Material and Cupertino libraries. The 3.47 announcement says the copies inside the core SDK "are scheduled for formal deprecation in the upcoming Fall stable release in November", and tells package authors to "treat this move to the standalone packages as a major release". Apps can opt in now; nothing in 3.47 forces the move.

Source: https://flutter.dev/blog/whats-new-in-flutter-3-47

## What the migration touches here

Files importing `package:flutter/material.dart` or `package:flutter/cupertino.dart`, measured on 2026-09-13:

| Tree                                         | material | cupertino |
| -------------------------------------------- | -------- | --------- |
| packages/flutter_adaptive_cards_fs           | 196      | 1         |
| packages/flutter_adaptive_charts_fs          | 12       | 0         |
| packages/flutter_adaptive_cards_host_fs      | 5        | 0         |
| packages/flutter_adaptive_template_fs        | 1        | 0         |
| packages/flutter_adaptive_cards_test_support | 2        | 0         |
| widgetbook                                   | 22       | 0         |
| adaptive_explorer                            | 3        | 0         |
| adaptive_chat_client                         | 6        | 0         |

`adaptive_chat_server_dart` has no Flutter dependency and is out of scope. No tree uses `dart:html` or `dart:js`, so the companion `package:web` item from the same announcement needs no work.

## Mechanism

The pinned SDK (Dart 3.13.3) ships the quick-fix the announcement names:

```bash
fvm dart fix --apply --code=migrate_design_widgets   # per tree
fvm flutter pub add material_ui                       # where the fix leaves imports unresolved
fvm flutter pub add cupertino_ui                      # core package only (one file)
```

In the three Flutter apps, `localizationsDelegates` moves to `GlobalMaterialLocalizations.delegates` from the new package. `material_ui` 1.2.0 requires Dart `^3.12.0` and Flutter `>=3.44.0`, so the current pins already satisfy it.

## Gating factors

The task plan is not written, and the migration is not started, until every item below has a recorded answer. Each one changes the shape of the work.

| #   | Gate                                                                                                                                                                                                                            | How to check                                                                                       | Effect on the plan                                                                                                                                                                          |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | The November stable (the release that formally deprecates the SDK Material and Cupertino libraries) has shipped, or a decision has been made to move ahead of it                                                                | Flutter release notes; `fvm releases`                                                              | Before it: opt-in, no analyzer pressure. After it: every `package:flutter/material.dart` import warns, and the SDK bump PR and this migration have to land together or in quick succession. |
| 2   | widgetbook, fl_chart, and chewie have published releases that import `material_ui`                                                                                                                                              | The pub-cache grep in the readiness section below, run against the versions the lock file resolves | Yes: no bridge, the fix is mechanical. No: `MaterialUiCompatibilityBridge` in all three apps, a consumer note in every package README, and a widgetbook-4 decision (see open question 1).   |
| 3   | The remaining five dependencies (accessibility_tools, flutter_markdown_plus, flutter_riverpod, json_editor_flutter, video_player) have moved, or their one-to-five SDK-Material files are known to be harmless under the bridge | Same grep; read the importing files for widgets that need a `Theme` or `Material` ancestor         | Decides whether the bridge can be removed at the end of the migration or stays until a later release.                                                                                       |
| 4   | The 0.17.0 release has been cut and published                                                                                                                                                                                   | `git tag`, pub.dev                                                                                 | The migration is a release boundary for the packages ("treat as a major release"). It goes into the release after 0.17.0, never into a release that also carries unrelated changes.         |
| 5   | The `flutter_localizations` rule in CLAUDE.md and the `adaptive-cards-localization` skill has been amended to "no direct dependency"                                                                                            | Read both files                                                                                    | Without the amendment, adding `material_ui` (which depends on `flutter_localizations`) contradicts a repo rule the review gate enforces.                                                    |
| 6   | Goldens are green on both platforms on the SDK the migration will run on                                                                                                                                                        | Latest CI run on main                                                                              | A golden failure during the migration must be attributable to the migration, not to an SDK bump that landed in the same window.                                                             |
| 7   | `dart fix --code=migrate_design_widgets` on the SDK in use converts a scratch copy of `packages/flutter_adaptive_cards_fs` without leaving unresolved imports beyond the pubspec additions                                      | Spike on a throwaway copy, as the primary-constructor migration did                                | Decides whether the conversion is one `dart fix` per tree or needs hand edits, which sets the task count.                                                                                   |

Gates 1 and 2 decide the timing. Gates 3 to 7 are preconditions the plan's Task 0 verifies before any code moves.

## Readiness gate

Every Flutter-facing direct dependency still imported the SDK library on 2026-09-13, and none imported `material_ui`:

| Dependency            | Version | Files importing SDK Material |
| --------------------- | ------- | ---------------------------- |
| widgetbook            | 3.25.0  | 67                           |
| fl_chart              | 1.2.0   | 41                           |
| accessibility_tools   | 2.8.0   | 17                           |
| chewie                | 1.13.1  | 17                           |
| flutter_markdown_plus | 1.0.12  | 5                            |
| flutter_riverpod      | 3.4.3   | 1                            |
| json_editor_flutter   | 1.4.2   | 1                            |
| video_player          | 2.14.0  | 1                            |

Until a dependency moves, an app that has migrated must wrap itself in the `MaterialUiCompatibilityBridge` the announcement describes so SDK-Material widgets inside those packages still find a `Theme` and `Material` ancestor. Consumers of our published packages face the same choice.

This is the check behind gates 2 and 3. For each resolved version in the lock file:

```bash
grep -rl "package:material_ui" ~/.pub-cache/hosted/pub.dev/<dep>-<version>/lib | wc -l
```

Decision rule: migrate the packages and apps together once widgetbook, fl_chart, and chewie have published `material_ui` releases. If the November SDK deprecates the SDK copies before that happens, migrate anyway and ship the bridge in the three apps, and document it for package consumers.

## Consequences for the published packages

- The announcement's "major release" guidance applies. These packages are 0.x, so the honest signal is a minor bump (0.17 to 0.18) with a changelog entry that names the change of import origin for Material types in the public API and points consumers at the bridge if their own tree has not moved.
- `material_ui` depends on `flutter_localizations`. CLAUDE.md says the packages "must not depend on `flutter_localizations`". The rule's intent, that the library ships no localized strings and no `.arb` files, is unaffected by a transitive dependency; amend the rule text to "must not depend on it directly" in CLAUDE.md and in the `adaptive-cards-localization` skill in the same change.
- HostConfig-driven theming (`adaptive-cards-hostconfig-theme`) reads `ThemeData` only as a fallback source of colors. Confirm `ThemeColorFallbacks` and the `Theme.of(context)` call sites resolve to the `material_ui` `ThemeData` after migration, since the bridge is what maps one to the other when a host app has not migrated.

## Verification when executed

The gates from the SDK-upgrade and primary-constructor branches, unchanged: `fvm flutter analyze` in both trees, the three `dart format --set-exit-if-changed` invocations, both Prettier checks, all eight suites at their current counts, the coverage gate, plus the golden passes for cards and charts on both macOS and Linux. Goldens matter more here than usual because theme plumbing changes can move pixels without any source change of ours; bisect any failure against unmodified sources under the same SDK before regenerating, as the SDK-upgrade skill describes.

## Open questions to settle when the plan is written

1. Whether widgetbook 4 (still a beta on 2026-09-13) migrates to `material_ui`; the sample app is the heaviest consumer and may need the bridge longest.
2. Whether `flutter_adaptive_cards_test_support` should export the bridge so consumer test suites can render our widgets without their own setup.
3. Whether the `Theme.of(context)`-based fallbacks in `ThemeColorFallbacks` need a `material_ui`-specific path or the bridge covers them.
