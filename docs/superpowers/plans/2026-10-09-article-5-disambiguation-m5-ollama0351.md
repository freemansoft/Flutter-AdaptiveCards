# Removing the open questions from article 5, on the M5 under Ollama 0.35.1

Article 5, "Eight measurement rules from a local-model benchmark on Ollama",
states its eight rules on figures measured under Ollama 0.32.14, 0.33.1, 0.33.2,
0.33.3 and 0.34.0. None of those runtimes is installed on either host, and
three of the archives behind them are closed or deleted. The article carries
eight statements that say outright that something is not established.

This plan closes what can be closed. Every run lands in
[`tool/model_probes/results-m5-16gb-ollama0351/`](../../../adaptive_chat_server_dart/tool/model_probes/results-m5-16gb-ollama0351),
the live archive for this host and runtime: **Apple M5 / 16 GB (`Mac17,3`),
Ollama 0.35.1**, which is the machine this work runs on.

Two things found while scoping changed the plan and are recorded first.

## Finding 1: the server log for the M5 0.35.1 sweep still exists

Article 5's central irrecoverable loss is stated at its line 194: "Those logs
have since rotated." That is true of the 0.33.2 sweep. It is **not** true of the
0.35.1 M5 sweep.

The live server is Homebrew-managed (`/opt/homebrew/opt/ollama/bin/ollama serve`),
not the macOS app, so it writes to `/opt/homebrew/var/log/ollama.log` rather
than `~/.ollama/logs/server.log`. That file covers **2026-10-03T21:37 through
now**, which spans the entire 2026-10-03/04 sweep, with 2,367 `/api/chat`
requests logged.

Attributing each request to its model's sweep window (model windows taken from
the log's own `template selection` lines):

| Sweep window                    | `/api/chat` requests | 500s at the ceiling | held > 10 min |  longest held | probe-recorded stalls |
| ------------------------------- | -------------------: | ------------------: | ------------: | ------------: | --------------------: |
| `granite4.1:8b` 21:53           |                  356 |                   0 |             0 |             — |                     0 |
| `qwen2.5-coder:7b` 22:40        |                  256 |                   0 |             0 |             — |                     0 |
| `qwen3.5:9b` 23:21              |                  256 |                   0 |             0 |             — |                     0 |
| `llama3-groq-tool-use:8b` 00:07 |                  256 |                   0 |             0 |             — |                     0 |
| `llama3.2:latest` 00:31         |                  256 |              **32** |        **13** | **103.8 min** |                 **4** |
| `llama3-chatqa:8b` 02:36        |                  256 |                   0 |             0 |             — |                     0 |
| `nemotron-3-nano:4b` 02:51      |                  256 |                   2 |             0 |             — |                     3 |
| `granite4.1:3b` 03:24           |                  256 |              **18** |        **37** | **115.8 min** |                **56** |
| `granite4.1:3b` 08:59, re-run   |                  109 |              **32** |        **22** | **111.7 min** |                     — |

Two readings follow, and both bear on rules 3 and 6.

**Abandoned generations complete long after the client gives up, on 0.35.1.**
Thirteen requests in `granite4.1:3b`'s window returned 200 between 02:17:01 and
02:18:18 with durations descending in a staircase: 1h31m59s, 1h29m39s, 1h26m50s,
1h17m53s, 1h8m58s, 1h2m59s, 59m2s, 57m5s, 55m6s, 27m9s, 23m11s, 15m13s, 1m14s,
after which normal 1 to 3 s calls resume. That is a queue draining. The article
describes this behavior as a 0.33.2 property that 0.34.0 removed; it is present
on 0.35.1.

**The probe-side stall count is not a measure of the server-side queue.**
`llama3.2:latest` recorded **4** stalls, all `temperature_matrix` calls at the
180 s default, and its archive holds no call over 100 s outside those four. Its
server-side window holds **32** requests terminating at a ceiling with a 500 and
**13** held for 15 to 104 minutes. The client-side count understates the queue
by roughly an order of magnitude, and nothing in the archive reveals it. This is
a rule-grade finding that article 5 does not have, and it is the sharper version
of its rule 3.

## Finding 2: the probes' own cancellation path is not the cause

`ModelBehavior.md` open question 11 records that the unload and disconnect tests
used `curl` against `/api/generate`, while the probes use Dart's
`HttpClient.abort()` against `/api/chat`, "which was not tested this way". That
test has now been run on 0.35.1, replicating `probeOnce`'s exact sequence, with
the two actions separated in time so the server log can attribute a termination
to one of them. `granite4.1:3b`, `num_predict` 1150, `num_ctx` 16384, `t=0`,
`seed` 7. Total elapsed 55 s.

| Phase                                       | Long call                                            | Slot probe after | Server log                                         |
| ------------------------------------------- | ---------------------------------------------------- | ---------------- | -------------------------------------------------- |
| A baseline, undisturbed                     | 16,687 ms, 858 tokens, `stop`                        | —                | 200 at 16.67 s                                     |
| B `abort()` at 3 s, slot probe fresh client | threw at 3,007 ms                                    | **59 ms**        | 500 at 3.005 s                                     |
| C `abort()` at 3 s, slot probe same client  | threw at 3,003 ms                                    | **68 ms**        | 500 at 3.002 s                                     |
| D unload at 3 s, connection left open       | **ran to completion**, 16,506 ms, 858 tokens, `stop` | —                | 200 at 16.50 s; unload answered 200 in **2.19 ms** |
| E `abort()` at 3 s, unload at 13 s          | threw at 3,004 ms                                    | **113 ms**       | 500 at 3.003 s                                     |

Three conclusions, all on one runtime and one host:

1. **The disconnect ends the generation and frees the slot.** Phase E separates
   the two actions by 10 s, so article 5's row four, where the probe dropped its
   connection and sent the unload in the same second and "either could have
   ended those two calls", is resolved: the disconnect is the cause.
2. **The unload does not cancel a running generation.** Phase D acknowledges the
   unload with `done_reason=unload` in 2.19 ms and the generation still emits all
   858 tokens. This reproduces the 0.33.2 and 0.34.0 results on a third runtime.
3. **Connection pooling is not the mechanism.** The slot frees in under 70 ms
   whether the next call reuses the probe's client or a fresh one, so the
   pooled-socket explanation for the sweep's behavior is excluded.

So the sweep's behavior is not explained by the runtime, by the unload, or by the
client. The notebook's "an isolated reproduction cancels correctly and the
sweep's did not" is now confirmed on 0.35.1 with both halves measured on the same
host and model. What differs between the two is narrowed to the sweep condition:
the abort fires at 120 s rather than 3 s, against a generation that is running
away rather than finishing, on a request carrying a system prompt and history.
Task 1 below tests that.

## Tasks

### Task 1: reproduce the runaway and abort it at the ceiling

The one condition Finding 2 did not cover. `granite4.1:3b` unaided runs away on
`facts`; the 0.35.1 M5 cascade begins at `facts`, cold, sample 1, call index 39.

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/shape_ab.dart \
  --model granite4.1:3b --no-seed-card --samples 2 --timeout 120 \
  --only facts,columnset \
  --json tool/model_probes/results-m5-16gb-ollama0351/granite4.1_3b/shape_ab-unaided-trigger-only.json
```

Then, from the server log, record for each stalled call: whether the request
ended with a 500 at 2m0s, or returned 200 minutes later; and whether the call
after it queued. If the runaway is aborted cleanly at 120 s the way phase B
aborted at 3 s, the cascade needs another explanation. If it is not, the
difference between a 3 s abort and a 120 s abort is the mechanism.

Repeat once with `--timeout 7200` to recover the runaway's true duration. That
restates rule 2's evidence on 0.35.1 and replaces its `gpt-oss:20b` anchor, which
names a model no longer installed. Budget up to 2 h unattended for that arm.

### Task 2: archive a server-log slice with every run

Finding 1 is luck, not method: the log happened not to have rotated. Add a step
to `sweep.sh` that records the log slice for each model's window into the model's
results directory, so a stall count always has its server side. Without this,
Task 1's server-side readings are unreproducible.

### Task 3: the position control, the one real measurement gap

Neither 0.35.1 sweep took a same-host re-run, so the reproducibility floor under
0.35.1 is unmeasured on either host, and article 5's "the size of the effect is
not settled" stands. Three of the four existing figures live only in plan
documents.

Measure `qwen3.5:9b`, `granite4.1:8b` and `qwen2.5-coder:7b` cold at position 0
after 600 s idle, and hot immediately after a sweep, two replicates each. This
also closes article 3's stated limit 3.

### Task 4: rule 7 restated on one runtime

Run `granite4.1:3b` through both shape probes with the pre-`Input.Rating` prompt
(digest `4bfa327067f8`, extractable at `9fcba7af^`) and with the shipped prompt
(`8cbfde243266`), on this host and this runtime, so the prompt is isolated with
host and runtime held constant. Rule 7 then needs no 0.33.2-versus-0.34.0
comparison.

**Blocked on a harness fix.** `shape_ab.dart` records the digest of the prompt
_in the tree_, not of the `--baseline` file it sent, so an old-prompt run placed
under `results-*/` reads as a second run against the current prompt and
`check_results.dart` will treat it that way. Either fix the recording or keep the
run in `raw-captures/`, which is where the 0.34.0 control sits for this reason.

### Task 5: the n/25 noise floor

The "±1 case" floor is asserted, not measured, and it is load-bearing for the
article's reading of a 15/25. Repeat one seeded shape probe three to five times
on this host and report the observed spread.

## Carried into the article without new measurement

- **Rule 5 is already re-evidenced.** Measured on this host under 0.35.1 on
  2026-10-09: a 13,349-token prompt against `num_ctx` 4096, 8192, 16384 and 32768
  reports `prompt_eval_count` of 2,050, 4,098, 8,194 and 16,386, each exactly
  `num_ctx / 2 + 2`, every call HTTP 200 with no error, `prompt_eval_cached_count`
  0 throughout. The same prompt under a window it fits reports its true 13,349.
  The article's "half the window plus the template header" is a formula across
  four windows rather than an inference from one, its 4,098 figure reproduces,
  and rule 5 no longer depends on 0.33.3. Add the caveat the notebook records and
  the article omits: the chat server's overflow warning estimates tokens as
  characters ÷ 4, compares against the requested rather than the allocated
  window, and would not have fired on the three history drops it was built for.
- **Rule 8's figure is stale and the tree holds a counterexample.** The article's
  "250 replies parsed as cards, and none used an unknown type" is correct for its
  own figures. The 0.35.1 archives hold 2,278 card-parsed calls, of which 12
  invented an element type: `Input.Paragraph` and `Chart.ProgressRing` on
  `nemotron-3-nano:4b`, identical on both hosts, neither in `card_schema.json`.
  All 12 scored `pass: false`, but as `wrong-shape` rather than by the
  vocabulary check, so the blind spot is sharper than the article states: **a
  model inventing a type that is in the accepted set would still pass.** The
  notebook asked for this comparison at its line 1057 and it has not been made.
- **Rule 4's cross-host band is superseded.** `ModelBehavior.md` line 377 says so
  outright. The article's "1.15x to 1.44x on seven of eight, the eighth reads
  2.32x" is the closed-archive version; 0.35.1 reads 1.14x to 1.78x, and
  `llama3-chatqa:8b` is 1.78x, not 2.32x.
- **Two figures name uninstalled models, and both have better substitutes.**
  `gpt-oss:20b`'s 7.2 s median, rule 2's calibration anchor, becomes
  `qwen3.5:9b` at 4.68 s on the M1 Max under 0.35.1, which strengthens the
  argument. `qwen3-coder:30b`'s 10.2 min contrast becomes `granite4.1:3b`'s
  121 min against `granite4.1:8b`'s 21 min at 2.5x the weight, same host, same
  runtime, same sweep.

## One claim to correct regardless of what is run

Article 5 line 304: "The runtime change stopped one runaway from becoming a
cascade, and the prompt edit removed the runaway."

Both halves are contradicted by data already in the tree. Under 0.35.1 on this
M5, with the shipped prompt, `granite4.1:3b` recorded a 56-stall cascade: one
unbroken block, calls 39 through 94, every stall between 119,991 and 120,051 ms,
112.0 minutes of queueing against 2.6 minutes of real work, onset at `facts`
cold, drain visible at call 95 (67.3 s) then 649 ms and 507 ms. The same model on
the M1 Max the same day, same runtime, same prompt: 0 stalls, 9 minutes.
`ModelBehavior.md` line 474 states the conclusion the article lacks, that across
four runs reading 52, 1, 0 and 56 stalls "the behaviour follows neither the host
nor the runtime".

This is also how the article stops needing old runtimes. Rules 3, 6 and 7
currently require a cross-runtime comparison, which is what drags 0.32.14,
0.33.2 and 0.34.0 along. The 0.35.1 data offers a better axis: a host split with
runtime and prompt held constant. That is stronger evidence than the original,
two variables fixed instead of none, and it needs no uninstallable runtime.

## What will not come back

Rule 1's 0.32.14 incident is unrecoverable four ways: the archive was removed
2026-09-03, the server logs are gone, the runtime is uninstallable, and the
0.32.14 attribution itself rests on one surviving log line that does not cover
the 2026-08-20 runs. No measurement helps. Either replace it with the notebook's
second instance of the same rule (`llama3.2:latest` on the M5, 89 min and 40
stalls, re-run 15 min and 2 stalls, also unarchived), or state rule 1 as a design
property, since `sweep.sh`'s `wait_for_idle()` and `SWEEP_COOLDOWN=600`
engineered the condition out and it cannot recur.

"Which change inside 0.34.0 lets a disconnect end the generation is not
identified" is not a measurement question. Finding 2 characterizes 0.35.1
directly, so the sentence can go rather than be answered.

## Repo fixes found while scoping

- `shape_ab.dart` records the in-tree prompt digest rather than the `--baseline`
  file's, which is what forced the 0.34.0 control out of the archive. Blocks
  Task 4.
- **Not a defect, checked 2026-10-09.** `check_results.dart:81`'s
  `shapeTableDir = 'results-m1max-64gb-ollama0332'` reads as stale and is not:
  `ModelBehavior.md` line 318 records that the shape-coverage table derives
  from that 0.33.2 directory, so the constant names its actual source and
  repointing it at a 0.35.1 directory would make the drift check compare the
  table against runs it was not built from. Leave it.
- `tool_channel.dart`'s timeout handler calls `abort()` without `evictModel`,
  unlike `probe_support.dart`. A stalled tool-channel call leaves the runner
  loaded.
- `results-m5-16gb-ollama0351/README.md` line 10 drops the word "stalls", so it
  reads "recorded 56 of its 100 calls".

## Verification

Each task's run is complete when `fvm dart run tool/model_probes/check_results.dart`
reports no fatal finding against `results-m5-16gb-ollama0351/`, and the figure it
produced is written into `ModelBehavior.md` beside the host and runtime that
measured it. Article 5 is edited only after that, per the notebook-is-the-source
rule in `adaptive_chat_server_dart/blog/README.md`.
