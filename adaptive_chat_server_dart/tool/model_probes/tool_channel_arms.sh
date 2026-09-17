#!/bin/zsh
# Measures the tool channel against prose with the system prompt held fixed,
# and re-derives the roster of models that can answer on the tool channel.
#
# The 2026-09-01 run could not attribute its result. It sent
# card_system_prompt.txt (223 lines) on the prose arm and a 70-line
# card_tool_prompt.txt on the tool arm, and that prompt dropped all 21 worked
# element examples along with the raw-JSON-emission mechanics a tool call makes
# false. Declines and wrong-shape calls, the two failure families it blamed on
# the channel, are both things those examples plausibly drive. The brief prompt
# had never been tuned against anything, so the comparison measured the gap
# between a tuned prompt and a guess.
#
# card_tool_prompt_matched.txt replaces it: card_system_prompt.txt with only
# the emission mechanics rewritten and a byte-identical element catalogue. The
# two arms, per model, unseeded at t=0 with --samples 2:
#
#   unaided               prose + card_system_prompt.txt
#   channel-tool-matched  tool  + card_tool_prompt_matched.txt
#
# so a delta between them is a property of the channel.
#
# A third arm restoring the raw-JSON-emission rules to the tool prompt was
# measured on 2026-09-16 and rejected. Its prompt and its results were deleted
# before being committed, so its figures are not re-derivable and are not
# quoted anywhere; git history before 2026-09-16 holds the prompt.
#
# The canary runs over the FULL roster, not just the models expected to pass
# it. Which models can use the tool channel is a measurement, and it moved when
# the canary's own prompt changed; hardcoding the eight that passed under the
# old prompt would assume the answer. Models that fail it get no shape arm,
# which is why they cost one model load each and nothing more.
#
# Same two rules as sweep.sh, for the same reasons: one model resident at a
# time, and `ollama stop` is asynchronous so eviction must be waited out.
# Resumable -- an arm whose JSON exists is skipped.
#
#   cd adaptive_chat_server_dart
#   export SWEEP_RESULTS=tool/model_probes/results-m1max-64gb-ollama0340
#   tool/model_probes/tool_channel_arms.sh
set -u

cd "$(dirname "$0")/../.." || exit 1
if [[ -z ${SWEEP_RESULTS:-} ]]; then
  echo "tool_channel_arms.sh: set SWEEP_RESULTS to this host's results directory, e.g."
  echo "  SWEEP_RESULTS=tool/model_probes/results-m1max-64gb-ollama0340 $0 $*"
  exit 2
fi
RES=$SWEEP_RESULTS
LOG=${SWEEP_LOG:-/tmp/tool-channel-arms-logs}
mkdir -p "$LOG"

# The full roster, ordered by stall risk as in sweep.sh.
MODELS=(
  "qwen3.8:27b-nvfp4" "granite4.1:8b" "qwen2.5-coder:7b" "qwen3.5:9b"
  "gpt-oss:20b" "qwen3-coder:30b" "qwen3.6:27b-coding-nvfp4"
  "nemotron-3-nano:30b" "hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest"
  "nemotron-3.5-lightning:30b" "llama3.2:latest" "llama3-chatqa:8b"
  "llama3-groq-tool-use:8b" "nemotron-3-nano:4b" "granite4.1:3b"
)
[[ $# -gt 0 ]] && MODELS=("$@")

slug() { print -r -- "${1//\//__}" | sed 's/:/_/g'; }

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

  run "$M tool_call" "$D/tool_call_probe.json" \
    tool/model_probes/tool_call_probe.dart --model "$M" --samples 2

  # Only a `supported` model can answer on the tool channel at all, so the rest
  # get no shape arm rather than a run that was never possible.
  if grep -q '"verdict": "supported"' "$D/tool_call_probe.json" 2>/dev/null; then
    run "$M shapes-unaided" "$D/shape_ab-unaided.json" \
      tool/model_probes/shape_ab.dart --model "$M" --samples 2 --timeout 120 \
      --no-seed-card
    run "$M shapes-channel-tool-matched" "$D/shape_ab-channel-tool-matched.json" \
      tool/model_probes/shape_ab.dart --model "$M" --samples 2 --timeout 120 \
      --channel tool --no-seed-card --baseline assets/card_tool_prompt_matched.txt
  else
    echo ">>> SKIP  $M shape arms - canary verdict is not 'supported'"
  fi

  ollama stop "$M" >/dev/null 2>&1
  wait_for_idle
  echo "##### MODEL $M COMPLETE $(date +%T) #####"
done
echo "##### ARMS COMPLETE $(date +%T) #####"
