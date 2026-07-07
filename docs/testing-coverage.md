# Test coverage gate

CI measures **per-package line coverage** and enforces a **ratchet floor** for each
published package, so coverage cannot silently regress. This page documents how the
gate works and how to update it.

## How coverage is measured (CI == local)

Coverage is produced by a **dedicated test pass that excludes golden tests**:

```bash
fvm flutter test --coverage --exclude-tags=golden
```

`.github/workflows/test.yml` splits the suite into a **golden-only** pass
(`flutter test --tags=golden`, render validation) and a **non-golden coverage** pass
(`flutter test --coverage --exclude-tags=golden`, which owns the number). The two tag
selectors partition the suite, so every test runs exactly once. Because the coverage pass
runs the _same command_ a developer runs locally, the CI percentage equals the local one —
there is no platform/golden drift to reconcile.

## The pieces

| File                                | Role                                                                                                          |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `tool/coverage_floors.yaml`         | Flat `package_name: <int percent>` map of minimum line coverage per package.                                  |
| `tool/coverage/check_coverage.dart` | Dependency-free gate. Parses each package's `coverage/lcov.info`, prints a table, exits non-zero below floor. |
| `.github/workflows/test.yml`        | Adds the golden-excluded coverage passes + the gate step.                                                     |

`flutter_adaptive_cards_test_support` is intentionally **not** in the floors map — it is a
test helper package with no tests of its own.

## Running the gate locally

```bash
# 1. Generate coverage for the packages you touched (from each package dir)
cd packages/flutter_adaptive_cards_fs
fvm flutter test --coverage --exclude-tags=golden

# 2. Run the gate from the repo ROOT
cd ../..
fvm dart run tool/coverage/check_coverage.dart            # enforcing
fvm dart run tool/coverage/check_coverage.dart --report-only  # never fails
fvm dart run tool/coverage/check_coverage.dart --self-test    # verify the parsers
```

The gate only reads the `lcov.info` files already on disk; it does not run tests. If a
package's report is stale or missing, regenerate it with step 1 first.

## Updating a floor (the ratchet)

Floors are a **lower bound**, not a target. The rule:

- **Raise** a floor (in its own commit) after you land tests that lift a package's
  coverage. Re-measure with the commands above and set the new floor to the measured
  percentage rounded **down** to a whole percent (a ~1-point jitter buffer).
- **Never lower** a floor to make a red build pass. A drop means a regression — add the
  missing test instead. If a floor is genuinely wrong (e.g. code legitimately removed),
  lowering it is a deliberate, reviewed decision, not a quick fix.

## Report-only vs enforcing

The gate step ships in `--report-only` first to validate the CI plumbing (paths resolve,
`dart run` works). Once a CI run is green, drop `--report-only` in the workflow to make the
gate enforcing.

## Current floors

See `tool/coverage_floors.yaml` for the authoritative values. The seed baseline was
core 88, template 95, host 81, charts 83.
