# Golden files

CI runs golden tests on **Linux** and compares against `test/gold_files/linux/`.
Local development on macOS uses `test/gold_files/macos/` via `getGoldenPath()`.

Packages with golden tests:

- `packages/flutter_adaptive_cards_fs/test/gold_files/`
- `packages/flutter_adaptive_charts_fs/test/gold_files/`

## Creating new golden images

When you add a new golden test or intentionally change rendering:

1. **Generate the baseline on your machine** (from the package directory):

   ```bash
   cd packages/flutter_adaptive_cards_fs   # or flutter_adaptive_charts_fs
   fvm flutter test test/golden_my_feature_test.dart --update-goldens --tags=golden
   ```

   `--update-goldens` writes PNGs under `test/gold_files/macos/` on macOS (or the matching platform folder on your host).

2. **Seed Linux baselines for CI** — copy each new or updated PNG from `macos/` to `linux/`:

   ```bash
   cp test/gold_files/macos/v1_5_icon_demo.png test/gold_files/linux/v1_5_icon_demo.png
   ```

   Repeat for every new or changed golden filename. CI has no macOS runner for these tests; without a Linux copy the build fails on missing golden files.

3. **Commit both** the macOS and Linux copies (plus the test and sample JSON).

4. **If CI still fails** on pixel diff (Linux rendering can differ slightly from macOS), use the workflow below to replace Linux files from CI artifacts.

## Updating Linux goldens from a failed CI build

The most accurate Linux-aligned images come from CI when pixel comparison fails:

1. Download the artifacts zip file created from a failed build.
2. Examine the failed test images to make sure the changes are expected.
3. Rename the `xxx_testImage.png` files to `xxx.png` for any of the failed tests.
4. Copy the renamed files to the `test/gold_files/linux/` directory.
5. Commit the changes to the repository.

The next build should pass.

## File naming convention

- `xxx-base.png` — The base image for the test
- `xxx-yyy.png` — The image after some action has been performed
- etc.
