#!/bin/zsh
# Runs context_fill_probe.dart with a filler sized to FIT each model's own
# window, as a control against the fixed-filler sweep in
# context_fill_sweep.sh.
#
# Why this exists. context_fill_probe sizes its filler in characters, at
# fillerCharsPerToken=4.0. That constant holds at 4.29 to 4.30 chars/token
# on llama3.2:latest, granite4.1:8b and gpt-oss:20b, and fails elsewhere:
# 2.99 on qwen3.8:27b-nvfp4 and qwen3.6:27b-coding-nvfp4, 2.74 on
# nemotron-3-nano:4b. The filler is digit-heavy and tokenizers split digits
# very differently. So a 28000-token target becomes 42426 to 46287 real
# tokens on those models, overflows the num_ctx sized from the estimate,
# and Ollama drops the history message whole. Six models were archived that
# way and read as discarding history they had room for. They had no room.
# This script is what showed that: give each model a filler that fits, and
# every one of them keeps it. See ModelBehavior.md's context-fill section.
#
#   cd adaptive_chat_server_dart
#   export FIT_CONTROL_RESULTS=tool/model_probes/context_fill_results/m1max-64gb-ollama0333-fitcontrol-calibrated
#   tool/model_probes/context_fill_fit_control.sh                    # every model below
#   tool/model_probes/context_fill_fit_control.sh qwen3.5:9b         # just one
#
# On a 16GB host pass only the models it can hold:
#   tool/model_probes/context_fill_fit_control.sh \
#     nemotron-3-nano:4b qwen3.5:9b qwen2.5-coder:7b
#
# FIT_CONTROL_RESULTS is required, not defaulted, for the reason
# SWEEP_RESULTS and CONTEXT_FILL_RESULTS are: a run aimed at the wrong
# directory files one host's numbers under another's name and nothing
# catches it. Name it after this host's RAM and `ollama --version`. The
# name deliberately does not use the -fillN form the fixed-filler
# directories use, because the parameters below differ per model rather
# than being one number a directory name can state.
#
# Resumable: a model whose JSON already exists is skipped.
set -u

if [[ -z ${FIT_CONTROL_CAFFEINATED:-} ]] && command -v caffeinate >/dev/null 2>&1; then
  export FIT_CONTROL_CAFFEINATED=1
  exec caffeinate -i "$0" "$@"
fi

cd "$(dirname "$0")/../.." || exit 1

if [[ -z ${FIT_CONTROL_RESULTS:-} ]]; then
  echo "context_fill_fit_control.sh: set FIT_CONTROL_RESULTS, e.g."
  echo "  FIT_CONTROL_RESULTS=tool/model_probes/context_fill_results/m1max-64gb-ollama0333-fitcontrol-calibrated $0 $*"
  exit 2
fi
RES=$FIT_CONTROL_RESULTS
LOG=${FIT_CONTROL_LOG:-/tmp/context-fill-fit-control-logs}
mkdir -p "$LOG"

# model -> "num_ctx fill_tokens".
#
# 65536 is above the trained window of every model here except
# qwen2.5-coder:7b, which is capped at 32768. Ollama allocates
# min(requested, trained window), so raising --num-ctx does nothing for
# that one and it gets a smaller filler instead: 12000 tokens is roughly
# 48000 characters, about 16k tokens even at the 2.99 chars/token the Qwen
# tokenizers showed, which leaves room inside 32768 under any reading.
typeset -A PARAMS=(
  "nemotron-3-nano:4b"          "65536 42000"
  "qwen3.5:9b"                  "65536 42000"
  # Capped at a 32768 trained window, so it cannot take the 42000 the
  # others do. 20000 tokens plus the card system prompt fills roughly
  # three quarters of what it is allocated, which is as full as this
  # model can be driven.
  "qwen2.5-coder:7b"            "32768 20000"
  "qwen3-coder:30b"             "65536 42000"
  "nemotron-3-nano:30b"         "65536 42000"
  "nemotron-3.5-lightning:30b"  "65536 42000"
  # The two nvfp4 builds did not drop the filler, they overflowed: both
  # evaluated about 6,700 tokens more than the 35851 they were allocated,
  # so their fixed-filler scores measure overflow rather than capacity.
  # Same treatment as the droppers, for the same reason.
  "qwen3.8:27b-nvfp4"           "65536 42000"
  "qwen3.6:27b-coding-nvfp4"    "65536 42000"
)
# Smallest first, so a partial run still says something.
MODELS=(
  "nemotron-3-nano:4b" "qwen3.5:9b" "qwen2.5-coder:7b"
  "qwen3.8:27b-nvfp4" "qwen3.6:27b-coding-nvfp4"
  "qwen3-coder:30b" "nemotron-3-nano:30b" "nemotron-3.5-lightning:30b"
)
[[ $# -gt 0 ]] && MODELS=("$@")

slug() { print -r -- "${1//\//__}" | sed 's/:/_/g'; }

# Borrowed from sweep.sh: `ollama stop` returns before the model actually
# evicts, and eviction competes for the GPU.
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
  if [[ -z ${PARAMS[$M]:-} ]]; then
    echo ">>> SKIP  $M (no fitted parameters recorded; add it to PARAMS)"
    continue
  fi
  CTX=${PARAMS[$M]%% *}
  FILL=${PARAMS[$M]##* }
  S=$(slug "$M")
  OUT="$RES/$S/context_fill_probe.json"
  if [[ -f "$OUT" ]]; then
    echo ">>> SKIP  $M (already recorded)"
    continue
  fi
  mkdir -p "$RES/$S"
  echo "##### MODEL $M num_ctx=$CTX fill-tokens=$FILL $(date +%T) #####"
  wait_for_idle
  # Calibrated, so --fill-tokens means what it says on every tokenizer.
  # The first version of this control ran before calibration existed: it
  # asked for 28000 tokens and delivered 42426 to 46287 on the denser
  # tokenizers, which is why the targets below state the level actually
  # wanted rather than a number that happened to land there.
  fvm dart run tool/model_probes/context_fill_probe.dart \
    --model "$M" --fill-tokens "$FILL" --num-ctx "$CTX" --json "$OUT" \
    >"$LOG/$(slug $M).log" 2>&1
  echo ">>> DONE  $M rc=$? $(date +%T)"
  ollama stop "$M" >/dev/null 2>&1
  wait_for_idle
  echo "##### MODEL $M COMPLETE $(date +%T) #####"
done
echo "##### FIT CONTROL COMPLETE $(date +%T) #####"
