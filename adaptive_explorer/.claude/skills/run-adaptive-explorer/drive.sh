#!/usr/bin/env bash
# Build, launch, screenshot, and quit adaptive_explorer with no human input.
#
# Runs the real macOS desktop app via `flutter run -d macos` against
# driver_main.dart, which boots the app with a card already loaded and
# rasterises itself to a PNG from inside the process (see driver_main.dart for
# why we do not use macOS `screencapture`). Then it quits the app cleanly.
#
# Usage (from the adaptive_explorer/ directory):
#   .claude/skills/run-adaptive-explorer/drive.sh [out.png]
#
# Default screenshot path: ./adaptive_explorer_screenshot.png
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$HERE/../../.." && pwd)"   # -> adaptive_explorer/ (skill is 3 levels deep)
cd "$APP_DIR"

OUT="${1:-$APP_DIR/adaptive_explorer_screenshot.png}"
LOG="$(mktemp -t ae_drive.XXXXXX.log)"
rm -f "$OUT"

echo "[drive] app dir : $APP_DIR"
echo "[drive] out png : $OUT"
echo "[drive] run log : $LOG"

# Launch the app detached; flutter run stays attached to the app lifetime.
SCREENSHOT_OUT="$OUT" fvm flutter run -d macos \
  -t .claude/skills/run-adaptive-explorer/driver_main.dart >"$LOG" 2>&1 &
RUN_PID=$!

cleanup() {
  # Quit the app: ask flutter run to terminate, then hard-kill if needed.
  kill "$RUN_PID" 2>/dev/null || true
  pkill -f 'Debug/adaptive_explorer.app/Contents/MacOS/adaptive_explorer' 2>/dev/null || true
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
