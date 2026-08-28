#!/bin/zsh
# Runs every result-producing probe against every model, recording each run to
# $SWEEP_RESULTS (default tool/model_probes/results/).
#
# This exists because the methodology is easy to get wrong in ways that look
# like a bad model rather than a bad measurement. Two rules are load-bearing:
#
#   1. One model resident at a time. Interleaving makes Ollama evict and
#      reload weights between calls, and the reload costs roughly 20x a warm
#      load. Probes send `keep_alive: 30m`, so a finished model lingers unless
#      it is explicitly stopped.
#
#   2. `ollama stop` is asynchronous. It returns while the model is still
#      evicting, and eviction competes for the GPU: a probe started during
#      that window measured 3171 ms/call against 1324 ms for the same model
#      and the same 25 cases once the machine was quiet. Waiting is not
#      politeness, it is the difference between a latency figure and a
#      fiction.
#
# Resumable: a (model, probe) whose JSON already exists is skipped, so an
# interrupted sweep continues rather than restarting.
#
#   cd adaptive_chat_server_dart
#   tool/model_probes/sweep.sh                # every model
#   tool/model_probes/sweep.sh granite4.1:8b  # just one
#
#   # a different host: record beside the archive, never into it
#   SWEEP_RESULTS=tool/model_probes/results-m5-16gb tool/model_probes/sweep.sh
set -u

cd "$(dirname "$0")/../.." || exit 1
# Overridable so a second host records beside the archive rather than into it.
# `tool/model_probes/results/` holds the Apple M1 Max / 64 GB runs that
# check_results.dart re-derives ModelBehavior.md's shape table from, and run()
# skips any (model, probe) whose JSON already exists -- so a sweep on another
# machine pointed here would silently skip every model and record nothing.
RES=${SWEEP_RESULTS:-tool/model_probes/results}
LOG=${SWEEP_LOG:-/tmp/sweep-logs}
mkdir -p "$LOG"

# Ordered by *stall risk*, not by weight. Runtime tracks timeouts, not model
# size: granite4.1:3b is 2.0 GB and stalls, while qwen3.8:27b-nvfp4 is eight
# times its size and does not. Reliable models run first so that a slow tail
# cannot delay the data anyone is waiting on.
MODELS=(
  "qwen3.8:27b-nvfp4" "granite4.1:8b" "qwen2.5-coder:7b" "qwen3.5:9b"
  "gpt-oss:20b" "qwen3-coder:30b" "qwen3.6:27b-coding-nvfp4"
  "nemotron-3-nano:30b" "hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest"
  "nemotron-3.5-lightning:30b" "llama3.2:latest" "llama3-chatqa:8b"
  "llama3-groq-tool-use:8b" "nemotron-3-nano:4b" "granite4.1:3b"
)
[[ $# -gt 0 ]] && MODELS=("$@")

slug() { print -r -- "${1//\//__}" | sed 's/:/_/g'; }

# Block until Ollama reports nothing resident.
#
# `ollama stop` returns immediately and the model evicts in the background, so
# without this the next probe's first calls race the eviction and are timed
# against a busy GPU. Bounded so a wedged runner cannot hang the sweep.
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

run() {
  local name=$1 out=$2
  shift 2
  # Refuse rather than queue: a second sweep started by accident would corrupt
  # both, and a loud failure is cheaper than two unusable runs.
  if pgrep -f "model_probes/.*[.]dart" >/dev/null 2>&1; then
    echo ">>> ABORT $name - another probe is running; runs must be serial"
    exit 3
  fi
  if [[ -f "$out" ]]; then
    echo ">>> SKIP  $name (already recorded)"
    return
  fi
  echo ">>> START $name $(date +%T)"
  fvm dart run "$@" --json "$out" \
    >"$LOG/$(basename ${out%.json})-$(slug $M).log" 2>&1
  echo ">>> DONE  $name rc=$? $(date +%T)"
}

for M in $MODELS; do
  S=$(slug "$M")
  D="$RES/$S"
  mkdir -p "$D"
  echo "##### MODEL $M $(date +%T) #####"
  wait_for_idle
  run "$M json_format" "$D/json_format_probe.json" \
    tool/model_probes/json_format_probe.dart --model "$M" --samples 2
  run "$M tool_call" "$D/tool_call_probe.json" \
    tool/model_probes/tool_call_probe.dart --model "$M" --samples 2
  run "$M everyday" "$D/temperature_matrix.json" \
    tool/model_probes/temperature_matrix.dart --model "$M" --samples 1
  run "$M stress" "$D/temperature_stress.json" \
    tool/model_probes/temperature_stress.dart --model "$M" --samples 1
  run "$M shapes-seeded" "$D/shape_ab-seeded.json" \
    tool/model_probes/shape_ab.dart --model "$M" --samples 2 --timeout 120
  run "$M shapes-unaided" "$D/shape_ab-unaided.json" \
    tool/model_probes/shape_ab.dart --model "$M" --samples 2 --timeout 120 \
    --no-seed-card

  # Tool channel: only models whose tool_call_probe verdict is `supported`
  # can answer here at all, so skip the rest rather than record a run that
  # was never possible. Always unseeded — the seed is a prose-channel
  # artifact and cannot be sent down this channel.
  if grep -q '"verdict": "supported"' "$D/tool_call_probe.json" 2>/dev/null; then
    run "$M shapes-channel-tool" "$D/shape_ab-channel-tool.json" \
      tool/model_probes/shape_ab.dart --model "$M" --samples 2 --timeout 120 \
      --channel tool --no-seed-card
  fi
  run "$M cascade" "$D/cascade_ab.json" \
    tool/model_probes/cascade_ab.dart --model "$M" --samples 2 --timeout 120
  ollama stop "$M" >/dev/null 2>&1
  wait_for_idle
  echo "##### MODEL $M COMPLETE $(date +%T) #####"
done
echo "##### SWEEP COMPLETE $(date +%T) #####"
