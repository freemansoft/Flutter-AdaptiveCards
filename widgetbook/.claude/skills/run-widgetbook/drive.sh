#!/usr/bin/env bash
# Build, launch, screenshot, and quit the widgetbook sample app with no human
# input.
#
# Launches the real WidgetbookApp via `flutter run -d macos` against
# driver_main.dart, which rasterises the widgetbook shell to a PNG from inside
# the (sandboxed) process and prints where it landed; this script copies it
# out and then quits the app.
#
# Usage (from the widgetbook/ directory):
#   .claude/skills/run-widgetbook/drive.sh [out.png]
#
# Default screenshot path: ./widgetbook_screenshot.png
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$HERE/../../.." && pwd)"   # -> widgetbook/ (skill is 3 levels deep)
cd "$APP_DIR"

OUT="${1:-$APP_DIR/widgetbook_screenshot.png}"
LOG="$(mktemp -t wb_drive.XXXXXX.log)"
rm -f "$OUT"

echo "[drive] app dir : $APP_DIR"
echo "[drive] out png : $OUT"
echo "[drive] run log : $LOG"

# Widgetbook is code-generated: main.dart imports main.directories.g.dart, which
# indexes every @widgetbook.UseCase. Regenerate it so a fresh clone compiles.
if [ ! -f lib/main.directories.g.dart ]; then
  echo "[drive] generating widgetbook directories (build_runner)…"
  fvm dart run build_runner build --delete-conflicting-outputs
fi

SCREENSHOT_OUT="$OUT" fvm flutter run -d macos \
  -t .claude/skills/run-widgetbook/driver_main.dart >"$LOG" 2>&1 &
RUN_PID=$!

cleanup() {
  kill "$RUN_PID" 2>/dev/null || true
  pkill -f 'Debug/widgetbook.app/Contents/MacOS/widgetbook' 2>/dev/null || true
}
trap cleanup EXIT

echo "[drive] building + launching (first macOS build can take a few minutes)…"
for _ in $(seq 1 210); do   # up to ~7 min
  if grep -q 'SCREENSHOT_WRITTEN:' "$LOG"; then break; fi
  if grep -q 'SCREENSHOT_FAILED:' "$LOG"; then
    echo "[drive] capture failed:"; grep 'SCREENSHOT_FAILED:' "$LOG"; exit 1
  fi
  if grep -qE 'Error: |BUILD FAILED|Target .* failed|Exception:' "$LOG"; then
    echo "[drive] build/launch error — tail of log:"; tail -30 "$LOG"; exit 1
  fi
  if ! kill -0 "$RUN_PID" 2>/dev/null; then
    echo "[drive] flutter run exited early — tail of log:"; tail -30 "$LOG"; exit 1
  fi
  sleep 2
done

# The sandboxed app wrote the PNG inside its container temp dir; copy it out.
SANDBOX_PNG="$(grep 'SCREENSHOT_WRITTEN:' "$LOG" | tail -1 | sed 's/.*SCREENSHOT_WRITTEN: //')"
if [ -z "$SANDBOX_PNG" ] || [ ! -f "$SANDBOX_PNG" ]; then
  echo "[drive] capture path not found — tail of log:"; tail -30 "$LOG"; exit 1
fi
cp "$SANDBOX_PNG" "$OUT"

echo "[drive] screenshot written: $OUT"
ls -la "$OUT"
echo "[drive] done — quitting app."
