# Pub score gate (pana)

CI scores each **published** package with [`pana`](https://pub.dev/packages/pana),
the same tool pub.dev uses, and enforces a **ratchet floor** per package so the
score cannot silently regress. This page documents how the gate works, why two
packages have deliberately low floors, and how to update it.

## How the score is measured (CI == local)

```bash
fvm dart pub global activate pana 0.23.14
fvm dart run tool/pana/check_pana.dart --report-only
```

`tool/pana/check_pana.dart` runs `pana --json --no-dartdoc` once per package
listed in `tool/pana_floors.yaml`, sums `report.sections[].grantedPoints`, and
compares the total against that package's floor.

Two properties keep CI and local identical:

- **`--no-dartdoc` is always passed.** It drops pana's 10 dartdoc-coverage
  points, so the **maximum is 150, not 160**. Dartdoc is by far the slowest part
  of a pana run; skipping it keeps a four-package sweep near 5–8 minutes.
- **pana runs under the script's own Dart SDK.** The script spawns
  `Platform.resolvedExecutable pub global run pana`, so it uses fvm's pinned
  Dart locally and flutter-action's Dart in CI. pana derives the Flutter SDK
  from the Dart SDK path — never pass `--flutter-sdk` or `--dart-sdk`.

pana's version is pinned (0.23.14) in the workflow and the setup scripts. Bump it
deliberately, in its own commit, and re-measure the floors — a new pana release
can change how points are awarded.

## Formatting is worth 10 points, and `flutter analyze` will not tell you

pana folds `dart format` compliance into its 50-point static-analysis section:
**one** unformatted file under `lib/` zeroes 10 of those points. This is not a
lint, so `fvm flutter analyze` reports `No issues found!` on a package that is
losing the points. This gate is the only check in the repo that catches it.

`flutter_adaptive_cards_fs` scored 130 rather than 140 for exactly this reason —
a single needlessly-wrapped line in `lib/src/cards/adaptive_card_element.dart`.

The reverse also holds: **pana only inspects `lib/`.** Drifted files under
`test/` cost nothing, so a full-marks static-analysis score is not evidence the
package is `dart format`-clean. Before a release, check the whole package:

```bash
fvm dart format --output=none --set-exit-if-changed packages/
```

## Why charts and host score 40

**pana resolves every package as if it were already published.** It copies the
package into a temp directory, ignores the pub workspace, and strips
`pubspec_overrides.yaml`. So `flutter_adaptive_charts_fs` and
`flutter_adaptive_cards_host_fs`, which depend on
`flutter_adaptive_cards_fs: ^<current version>`, fail version solving for the
entire development cycle — the core package at that version is not on pub.dev yet:

```text
Because flutter_adaptive_cards_host_fs depends on flutter_adaptive_cards_fs ^<version>
which doesn't match any versions, version solving failed.
```

That failure costs the static-analysis and dependency sections about 110 points.
There is no workaround — `dependency_overrides` do not survive into pana's copy,
which is correct, because pub.dev would score the published archive the same way.

Consequences:

- Their floors in `tool/pana_floors.yaml` are set to the failing-resolution
  baseline (40), not to an aspirational number. The gate still catches a
  regression **below** that baseline.
- **Their real score is only observable right after the core package is
  published** at the matching version. The `adaptive-cards-release-engineer`
  skill has a step for exactly that moment.

## Updating a floor

Raise a floor in its own commit, after landing the change that lifted the score.
**Never lower a floor to make a red build pass** — the point of a ratchet is that
it only moves one way. If a package legitimately drops (for example, a dependency
you do not control stops supporting the latest SDK), say so in the commit message.

## Running it locally

| Goal                          | Command                                                                   |
| ----------------------------- | ------------------------------------------------------------------------- |
| Score everything, never fail  | `fvm dart run tool/pana/check_pana.dart --report-only`                    |
| Score everything, enforcing   | `fvm dart run tool/pana/check_pana.dart`                                  |
| Score one package             | `fvm dart run tool/pana/check_pana.dart --only flutter_adaptive_cards_fs` |
| Verify the gate's own parsers | `fvm dart run tool/pana/check_pana.dart --self-test`                      |

From VS Code, use **Tasks: Run Task** → **pana: all packages** or
**pana: one package**. `Setup pana` activates the pinned CLI;
`scripts/setup-workspace.sh` does it too on a fresh clone.

Never run bare `pana` in the repo root — the root `pubspec.yaml` is a workspace
manifest (`name: _`), and pana will happily score it and report a meaningless
number.

## Current state

The CI job is **report-only** (`--report-only` in
`.github/workflows/validate.yaml`), matching the rollout the coverage gate used.
Drop the flag to make it enforcing once the plumbing has proven itself.

`flutter_adaptive_cards_test_support` is not scored: it is `publish_to: none`.

## Known gaps

- Neither `flutter_adaptive_cards_fs` nor `flutter_adaptive_template_fs` ships an
  `example/` directory, costing each 10 points in pana's documentation section.
  That is real authoring work and is tracked separately from this gate.
- Dartdoc coverage (10 points) is never scored in CI. Check it manually before a
  release by dropping `--no-dartdoc` from a one-off `pana` invocation.

See also: [`docs/testing-coverage.md`](testing-coverage.md), the sibling
line-coverage gate this one is modelled on.
