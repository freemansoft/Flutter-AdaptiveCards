# Closed archive

These runs were measured on the Apple M1 Max (64 GB) under **Ollama 0.34.0**.
That host moved to 0.35.1 on 2026-10-03 — see
[`../results-m1max-64gb-ollama0351/`](../results-m1max-64gb-ollama0351/) — so
nothing here can be re-run in place: a re-measurement belongs in that
directory.

`check_results.dart` reads this file's presence — not its text — and reports
stale prompt digests in this directory as notes rather than failing CI. The
figures remain valid for the prompt and runtime they name.

## What this directory holds

- **The tool channel against prose, with the system prompt held fixed.** Each
  supported model has a `shape_ab-channel-tool-matched.json` (tool channel,
  `card_tool_prompt_matched.txt`) beside a `shape_ab-unaided.json` (prose,
  `card_system_prompt.txt`), produced by `../tool_channel_arms.sh`. This is
  the comparison `results-m1max-64gb-ollama0332/` could not make, because its
  tool arm used a 70-line prompt that has since been deleted.
- **`tool_call_probe.json` for all 15 models**, re-measured against the
  matched prompt rather than carried over, and `retry_probe.json` for most of
  them.
- **The nine-phase `prefill_cache_probe` runs**, at 100 to 450 history
  entries and in a card-prompt variant, with an `ollama serve` log slice beside
  each, including the two MLX
  builds (`nemotron-3-nano-mlx:4b-bf16` and
  `mvincig11/semif-qwen3.5-4b-mlx-4bit`) that separate runner from
  architecture and quantization.
- **One full `sweep.sh` run, `granite4.1:3b` on 2026-09-18**
  (`json_format_probe`, `temperature_matrix`, `temperature_stress`,
  `shape_ab-seeded`, `shape_ab-unaided`, `cascade_ab`), which re-measured the
  model whose 0.33.2 figures were cascade-damaged and recorded no stall.
- **`json_format_probe.json` for the three `format`-canary models**
  (`gpt-oss:20b`, `qwen3.8:27b-nvfp4`, `qwen3.6:27b-coding-nvfp4`), re-run
  2026-09-24, all three verdicts holding.

Every `shape_ab` file here predates the per-call `timings` field that
`shape_ab.dart` records from 0.18.0 onward, so no phase split can be derived
from this directory. The matched 0.35.1 sweeps in
[`../results-m1max-64gb-ollama0351/`](../results-m1max-64gb-ollama0351/) and
[`../results-m5-16gb-ollama0351/`](../results-m5-16gb-ollama0351/) carry it.

`README.md` beside this file describes the two arms and how to read a tool
arm's pass rate.
