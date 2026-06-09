# Golden files

CI runs golden tests on **Linux** and compares against `test/gold_files/linux/`.
Local development on macOS uses `test/gold_files/macos/` via `getGoldenPath()`.

See also: [`packages/flutter_adaptive_cards_fs/test/gold_files/README.md`](../../../flutter_adaptive_cards_fs/test/gold_files/README.md) for the full workflow (same conventions in both packages).

## Creating new golden images

1. Generate on your machine:

   ```bash
   cd packages/flutter_adaptive_charts_fs
   fvm flutter test test/golden_v1_6_test.dart --name "Gauge Chart" --update-goldens --tags=golden
   ```

2. **Seed Linux for CI** — copy new or updated PNGs from `macos/` to `linux/`:

   ```bash
   cp test/gold_files/macos/v1_6_gauge.png test/gold_files/linux/v1_6_gauge.png
   ```

3. Commit macOS and Linux copies together.

4. If CI pixel comparison still fails, replace `linux/` files from CI failure artifacts (see core package README above).
