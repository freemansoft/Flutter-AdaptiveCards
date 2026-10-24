#!/bin/zsh
# Article 7 re-measure: 8 models x {empty, full} x {q8_0, f16}, --samples 2,
# --timeout 1800, flash attention on in both arms, same num_ctx in both fills.
# q8_0 half runs on the Homebrew service as configured; f16 half on a
# hand-started `ollama serve`; the Homebrew service is restarted at the end.
set -u
if [[ -z ${MATRIX_CAFFEINATED:-} ]]; then
  export MATRIX_CAFFEINATED=1
  exec caffeinate -i "$0" "$@"
fi

REPO=/Users/joefreeman/Documents/GitHub/freemansoft/Flutter-AdaptiveCards/adaptive_chat_server_dart
SCR=/private/tmp/claude-501/-Users-joefreeman-Documents-GitHub-freemansoft-Flutter-AdaptiveCards/8262257e-cee1-4e45-8d1a-2065789e36c8/scratchpad/matrix
BASE=$REPO/tool/model_probes/context_fill_results/m1max-64gb-ollama0351-fa1
mkdir -p "$SCR/logs"
cd "$REPO" || exit 1

typeset -A PARAMS=(
  "nemotron-3-nano:4b"          "65536 42000"
  "qwen3.5:9b"                  "65536 42000"
  "qwen2.5-coder:7b"            "32768 20000"
  "qwen3.8:27b-nvfp4"           "65536 42000"
  "qwen3.6:27b-coding-nvfp4"    "65536 42000"
  "qwen3-coder:30b"             "65536 42000"
  "nemotron-3-nano:30b"         "65536 42000"
  "nemotron-3.5-lightning:30b"  "65536 42000"
)
MODELS=(
  "nemotron-3-nano:4b" "qwen3.5:9b" "qwen2.5-coder:7b"
  "qwen3.8:27b-nvfp4" "qwen3.6:27b-coding-nvfp4"
  "qwen3-coder:30b" "nemotron-3-nano:30b" "nemotron-3.5-lightning:30b"
)
slug() { print -r -- "${1//\//__}" | sed 's/:/_/g'; }

wait_for_idle() {
  local waited=0
  while ollama ps 2>/dev/null | tail -n +2 | grep -q .; do
    (( waited >= 180 )) && { echo ">>> WARN still resident after ${waited}s"; return; }
    sleep 2; (( waited += 2 ))
  done
}

wait_for_server() {
  for i in {1..60}; do curl -s http://127.0.0.1:11434/api/version >/dev/null && return 0; sleep 1; done
  echo ">>> server did not come up"; exit 1
}

run_arm() {  # $1 = kv tag (kvq8|kvf16)
  local KV=$1
  for FILL in fill0 full; do
    local RES="$BASE-$KV-$FILL-samples2"
    for M in $MODELS; do
      local CTX=${PARAMS[$M]%% *} FT=${PARAMS[$M]##* } S=$(slug "$M")
      local OUT="$RES/$S/context_fill_probe.json"
      [[ -f "$OUT" ]] && { echo ">>> SKIP $KV $FILL $M"; continue; }
      mkdir -p "$RES/$S"
      echo "##### $KV $FILL $M num_ctx=$CTX $(date '+%F %T') #####"
      wait_for_idle
      if [[ $FILL == fill0 ]]; then
        fvm dart run tool/model_probes/context_fill_probe.dart --model "$M" \
          --fill-tokens 0 --num-ctx "$CTX" --no-calibrate --samples 2 \
          --timeout 1800 --json "$OUT" >"$SCR/logs/$KV-$FILL-$S.log" 2>&1
      else
        fvm dart run tool/model_probes/context_fill_probe.dart --model "$M" \
          --fill-tokens "$FT" --num-ctx "$CTX" --samples 2 \
          --timeout 1800 --json "$OUT" >"$SCR/logs/$KV-$FILL-$S.log" 2>&1
      fi
      echo ">>> DONE rc=$? $(date '+%F %T')"
      ollama stop "$M" >/dev/null 2>&1
      wait_for_idle
    done
  done
}

# --- q8_0 half: Homebrew service (OLLAMA_FLASH_ATTENTION=1, OLLAMA_KV_CACHE_TYPE=q8_0)
echo "##### q8_0 half start $(date '+%F %T') #####"
wait_for_server
LOGSTART=$(wc -l </opt/homebrew/var/log/ollama.log)
run_arm kvq8
tail -n +$((LOGSTART + 1)) /opt/homebrew/var/log/ollama.log >"$SCR/logs/serverlog-kvq8.txt"

# --- f16 half: hand-started serve, same flash attention, f16 cache
echo "##### f16 half start $(date '+%F %T') #####"
brew services stop ollama
sleep 5
OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=f16 \
  /opt/homebrew/opt/ollama/bin/ollama serve >"$SCR/logs/serverlog-kvf16.txt" 2>&1 &
SERVE_PID=$!
wait_for_server
run_arm kvf16
kill $SERVE_PID; wait $SERVE_PID 2>/dev/null
sleep 3
brew services start ollama
echo "##### MATRIX COMPLETE $(date '+%F %T') #####"
