# Article 7 MLX runner controls

**Goal.** Test whether two article 7 claims that it attributes to the MLX
runner hold on MLX builds that are not `nvfp4`. Article 7 measured MLX only
through `qwen3.8:27b-nvfp4` and `qwen3.6:27b-coding-nvfp4`, so runner and
quantization are confounded in both claims:

1. **"The setting does not reach the MLX runner."** Evidence today: the two
   `nvfp4` builds report the same `size_vram` under f16 and q8_0. The notebook
   heading scopes it to "the two `nvfp4` builds".
2. **First full-window call by runner** (MLX 637 to 711 s, `llama-server` 101
   to 324 s). The MLX row is also the only dense 27B row, so model size is a
   third confound.

**Existing evidence (2026-10-22, no new run).** The two non-`nvfp4` MLX
controls ran a 28000-token `--no-calibrate` filler at a 35851 request under
the q8_0 service, `--samples 1`, 180 s ceiling:

| Model                                        | Quantization | Prompt tokens | First call | `size_vram` |
| -------------------------------------------- | ------------ | ------------- | ---------- | ----------- |
| `nemotron-3-nano-mlx:4b-bf16`                | `bfloat16`   | 42616         | 80 s       | 9.25 GB     |
| `mvincig11/semif-qwen3.5-4b-mlx-4bit:latest` | `int4`       | 42554         | 91 s       | 4.13 GB     |

The first-call figures already argue against the runner as the cause of the
637 s, but they are not matched to the article 7 matrix (window, token count,
calibration, samples) and no f16 arm exists for the memory claim.

**Method.** Add the two controls to the 2026-10-24 matrix, all four cells,
with the matrix's own driver
(`tool/model_probes/raw-captures/m1max_ollama0351_fa1_kv_matrix_2026_10_24.sh`)
restricted to these two models and writing into the same four directories,
so every input matches the eight models already there: `--num-ctx 65536`,
`--fill-tokens 42000` calibrated (full) or `0 --no-calibrate` (empty),
`--samples 2 --timeout 1800`, flash attention on, q8_0 on the Homebrew
service and f16 on a hand-started `ollama serve`. One model resident at a
time. The driver restarts the Homebrew service at the end.

`nemotron-3-nano-mlx:4b-bf16` carries the same weights as
`nemotron-3-nano:4b` (GGUF, `llama-server`), already in the matrix. That pair
isolates the runner; the tokenizer still differs, which calibration absorbs.

**Readings.**

- Claim 1: `runnerSizeVram` per control, f16 cell against q8_0 cell. Equal
  means the setting does not reach MLX regardless of quantization. Confirm
  from the server log that each control ran on the MLX runner
  (`"mlx runner is ready"`).
- Claim 2: first-call ms, full window, f16, for the Nemotron 4B pair, and the
  two controls against the two `nvfp4` builds.
- Side readings: per-sample pass counts and sample-1/sample-2 disagreement,
  empty against full.

**Writes.**

1. Driver copy for this run in `raw-captures/`, plus a server-log excerpt.
2. The four matrix directory READMEs: add the two rows and the measurement
   date.
3. `ModelBehavior.md`: a paragraph under the matched-matrix section, and
   rescope the KV-ignore and first-call statements to what the controls show.
4. Article 7: rescope the KV sentence, the terms-table runner row and the
   first-call table to what was measured. The controls stay out of the
   eight-model ranking. Blog edits are shown as prose before any commit.

**Verification.** `npm run check:md` and `npm run check:md:chat`; the article
figure-token diff against `main`, every decrease intended; no commit until the
user has read the changed prose.
