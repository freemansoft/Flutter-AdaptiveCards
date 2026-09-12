#!/bin/zsh
# Runs context_fill_probe.dart against the eight 16GB-capable models, at a
# fixed --fill-tokens target, so this host's run is directly comparable to
# the M5 one already recorded under context_fill_results/. See
# ModelBehavior.md's context-fill section for why this exists: on a 16GB
# M5, five of eight models silently dropped the entire filler message
# rather than trimming it, independent of num_ctx size or load freshness,
# and Ollama's own /api/ps showed the runner clamped to a smaller context
# than requested. The open question this run answers is whether that is a
# memory-availability effect a 64GB host does not reproduce.
#
# Self-caffeinates: a >1 hour unattended sweep on a laptop that goes to
# sleep mid-run is exactly what corrupted the first M5 attempt at this --
# a timeout pending when the machine sleeps reports the sleep duration as
# elapsed time once it wakes, which reads as a stalled model rather than
# an idle machine.
#
#   cd adaptive_chat_server_dart
#   export CONTEXT_FILL_RESULTS=tool/model_probes/context_fill_results/m1max-64gb-ollama0333-fill28000
#   tool/model_probes/context_fill_sweep.sh                 # every model
#   tool/model_probes/context_fill_sweep.sh granite4.1:8b    # just one
#
# CONTEXT_FILL_RESULTS is required, not defaulted, the same way
# sweep.sh's SWEEP_RESULTS is: a wrong default is worse than none, since a
# run aimed at the wrong directory files one host's numbers under
# another's name and nothing catches it. Name it after this host's RAM
# and `ollama --version` output, matching the results-*/ convention.
#
# Resumable: a model whose JSON already exists is skipped, so an
# interrupted sweep continues rather than restarting.
set -u

# Re-exec under caffeinate exactly once, guarded so this does not loop.
if [[ -z ${CONTEXT_FILL_CAFFEINATED:-} ]] && command -v caffeinate >/dev/null 2>&1; then
  export CONTEXT_FILL_CAFFEINATED=1
  exec caffeinate -i "$0" "$@"
fi

cd "$(dirname "$0")/../.." || exit 1

if [[ -z ${CONTEXT_FILL_RESULTS:-} ]]; then
  echo "context_fill_sweep.sh: set CONTEXT_FILL_RESULTS to this host's results directory, e.g."
  echo "  CONTEXT_FILL_RESULTS=tool/model_probes/context_fill_results/m1max-64gb-ollama0333-fill28000 $0 $*"
  exit 2
fi
RES=$CONTEXT_FILL_RESULTS
FILL_TOKENS=${CONTEXT_FILL_TOKENS:-28000}
LOG=${CONTEXT_FILL_LOG:-/tmp/context-fill-sweep-logs}
mkdir -p "$LOG"

# The eight models the M5 run measured, fastest/smallest first so a
# partial run still says something.
MODELS=(
  "llama3.2:latest" "nemotron-3-nano:4b" "llama3-groq-tool-use:8b"
  "llama3-chatqa:8b" "granite4.1:8b" "granite4.1:3b" "qwen2.5-coder:7b"
  "qwen3.5:9b"
)
[[ $# -gt 0 ]] && MODELS=("$@")

slug() { print -r -- "${1//\//__}" | sed 's/:/_/g'; }

# Block until Ollama reports nothing resident. Borrowed from sweep.sh:
# `ollama stop` returns before the model actually evicts, and eviction
# competes for the GPU, so without this the next model's first calls race
# the previous one's teardown.
wait_for_idle() {
  local waited=0
  while ollama ps 2>/dev/null | tail -n +2 | grep -q .; do
    if (( waited >= 120 )); then
      echo ">>> WARN still resident after ${waited}s: $(ollama ps | tail -n +2 | awk '{print $1, $NF}' | tr '\n' ' ')"
      return
    fi
    sleep 2
    (( waited += 2 ))
  done
  (( waited > 0 )) && echo ">>> idle after ${waited}s"
}

for M in $MODELS; do
  S=$(slug "$M")
  OUT="$RES/$S/context_fill_probe.json"
  if [[ -f "$OUT" ]]; then
    echo ">>> SKIP  $M (already recorded)"
    continue
  fi
  mkdir -p "$RES/$S"
  echo "##### MODEL $M $(date +%T) #####"
  wait_for_idle
  fvm dart run tool/model_probes/context_fill_probe.dart \
    --model "$M" --fill-tokens "$FILL_TOKENS" --json "$OUT" \
    >"$LOG/$(slug $M).log" 2>&1
  echo ">>> DONE  $M rc=$? $(date +%T)"
  ollama stop "$M" >/dev/null 2>&1
  wait_for_idle
  echo "##### MODEL $M COMPLETE $(date +%T) #####"
done
echo "##### CONTEXT FILL SWEEP COMPLETE $(date +%T) #####"
