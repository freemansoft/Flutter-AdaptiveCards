# Fit control: a filler sized to fit each model's own window

Apple M1 Max / 64 GB, Ollama 0.33.3, `--samples 1`, measured 2026-09-11.

The sibling `m1max-64gb-ollama0333-fill28000/` directories hold a **fixed**
filler: the same text, sized at 28000 tokens by
`fillerCharsPerToken = 4.0`, sent to every model. That constant holds for
llama, granite and gpt-oss tokenizers at roughly 4.30 chars/token and for
nothing else measured, so for models whose tokenizers are denser the
prompt overflowed the window the probe had sized for it, and Ollama
dropped the history message whole. Six models recorded that way look like
they discarded a message they had room for.

This directory is the control that shows they did not. Each model here got
a filler that fits inside the window it is actually allocated, and every
one ingested it. The name deliberately does not use the `-fillN` form the
sibling directories use, because the parameters differ per model rather
than being one number the directory can state. Each run's own
`summary.fillTokensTarget` and `summary.numCtx` are the record:

| Model                        | `--fill-tokens` | `--num-ctx` | Allocated | Prompt tokens |
| ---------------------------- | --------------- | ----------- | --------- | ------------- |
| `nemotron-3-nano:4b`         | 28000           | 65536       | 65536     | 46287         |
| `nemotron-3-nano:30b`        | 28000           | 65536       | 65536     | 42602         |
| `nemotron-3.5-lightning:30b` | 28000           | 65536       | 65536     | 42603         |
| `qwen3-coder:30b`            | 28000           | 65536       | 65536     | 42426         |
| `qwen3.5:9b`                 | 28000           | 65536       | 65536     | 42540         |
| `qwen2.5-coder:7b`           | 12000           | 32768       | 32768     | 19974         |

`qwen2.5-coder:7b` is the one that could not be fixed by raising the
ceiling. Its trained window is 32768 and Ollama allocates
`min(requested, trained window)`, so a larger `--num-ctx` changes nothing
for it. It got a smaller filler instead.

Not one of the seven sweep probes, and not swept by `check_results.dart`.
See `ModelBehavior.md`'s context-fill section for what these runs
establish.
