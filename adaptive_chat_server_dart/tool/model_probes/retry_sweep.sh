#!/bin/zsh
# Runs retry_probe.dart over every model in the roster, one model resident at
# a time.
#
# The tool-channel comparison left one route open. Malformed JSON is the prose
# channel's largest failure, and a tool call structurally cannot carry one,
# but the channel did not ship because models decline to call the tool on 16 to
# 30 calls per 100 and history makes that worse. A retry fires only on a reply
# that already failed to parse, so it cannot depress adoption on the calls that
# worked. Whether it rescues the broken ones is what this measures.
#
# The roster is the full fifteen, not the models a retry is expected to help.
# An earlier version ran the nine that happened to have a prose arm on this
# runtime, which is data availability rather than a designed sample, and it
# would have missed the one model whose answer decides anything:
# `qwen2.5-coder:7b` is the server's compiled-in default and is `unsupported`
# on the tool canary, so a tool-channel retry should be unable to help it at
# all. It runs first for that reason.
#
# The canary verdict does not gate the roster either. `overCalls` is only a
# defect on prose questions, and a retry fires solely where a card was wanted
# and the reply broke, so an over-caller may be a good retry candidate rather
# than a bad one. Whether the verdict predicts the rescue rate is a result, not
# an input.
#
# retry_probe.dart runs its own prose phase, so a model needs no pre-existing
# shape arm to be measured here.
#
# Same two rules as sweep.sh: one model resident at a time, and `ollama stop`
# is asynchronous so eviction must be waited out. Resumable.
#
#   cd adaptive_chat_server_dart
#   export SWEEP_RESULTS=tool/model_probes/results-m1max-64gb-ollama0340
#   tool/model_probes/retry_sweep.sh
set -u

cd "$(dirname "$0")/../.." || exit 1
if [[ -z ${SWEEP_RESULTS:-} ]]; then
  echo "retry_sweep.sh: set SWEEP_RESULTS to this host's results directory, e.g."
  echo "  SWEEP_RESULTS=tool/model_probes/results-m1max-64gb-ollama0340 $0 $*"
  exit 2
fi
RES=$SWEEP_RESULTS
LOG=${SWEEP_LOG:-/tmp/retry-sweep-logs}
mkdir -p "$LOG"

# Ordered by stall risk, as in sweep.sh.
# The server default leads, so the answer that decides whether this ships
# lands first. The rest follow sweep.sh's stall-risk order.
MODELS=(
  "qwen2.5-coder:7b"
  "qwen3.8:27b-nvfp4" "granite4.1:8b" "qwen3.5:9b" "gpt-oss:20b"
  "qwen3-coder:30b" "qwen3.6:27b-coding-nvfp4" "nemotron-3-nano:30b"
  "hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest"
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
  run "$M retry" "$D/retry_probe.json" \
    tool/model_probes/retry_probe.dart --model "$M" --samples 2 --timeout 120
  ollama stop "$M" >/dev/null 2>&1
  wait_for_idle
  echo "##### MODEL $M COMPLETE $(date +%T) #####"
done
echo "##### RETRY SWEEP COMPLETE $(date +%T) #####"
