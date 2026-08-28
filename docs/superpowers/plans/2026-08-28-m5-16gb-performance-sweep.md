# M5 / 16 GB Performance Sweep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Measure probe latency for the eight 16 GB-capable models on this Apple M5 / 16 GB MacBook Air and add the results to `adaptive_chat_server_dart/ModelBehavior.md`, alongside the existing Apple M1 Max / 64 GB figures rather than replacing them.

**Architecture:** `tool/model_probes/sweep.sh` already implements the correct methodology (one model resident at a time, `ollama stop` plus an idle wait between models, per-call timeout, JSON result per run). It hardcodes its output directory and skips any `(model, probe)` whose JSON already exists — so pointed at the default directory on this host it would skip all 113 recorded M1 Max runs and produce nothing. The change is one line: make the results directory an environment variable, write the M5 runs to a sibling directory, and leave `results/` as the M1 Max archive that `check_results.dart` and CI already police. The table figures are then re-derived from the JSON by a script rather than transcribed by hand.

**Tech Stack:** zsh, Ollama 0.33.1 (local, `http://127.0.0.1:11434`), Dart 3.12.0 via FVM, Python 3 (derivation script only), Prettier (Markdown format gate).

## Global Constraints

- **Host is fixed and must be recorded verbatim.** `detectMachine()` on this box returns `Apple M5 / 16 GB`. Every result file stamps it automatically; do not hand-edit the field.
- **Prefix every `flutter` and `dart` command with `fvm`.** `sweep.sh` already does. Bare `dart` may not be the pinned SDK.
- **One model resident at a time.** Never run two probes concurrently, and never start a probe while `ollama ps` still lists a model. A concurrent run does not merely add noise — the 2026-08-20 sweep recorded 52 stalled calls and a wrong 12/25 score for `granite4.1:3b` purely from a missing unload.
- **Do not write into `tool/model_probes/results/`.** That directory is the M1 Max archive; `check_results.dart` reads it recursively and CI (`.github/workflows/chat-apps.yml:119`) fails on any disagreement with `ModelBehavior.md`'s shape-coverage table.
- **Do not edit the shape-coverage table, and change only one cell of the M1 Max performance table.** Those figures are verified; this plan adds, with the single exception recorded in Task 2 Step 3.
- **Documentation tone (CLAUDE.md).** `ModelBehavior.md` is named explicitly: flat analytical register, no amplifying adverbs, replace superlatives with the figure, bold reserved for a section's load-bearing claim and for figures, hedge inferred mechanisms, end on the last factual sentence.
- **Markdown format gate.** `adaptive_chat_server_dart/**` is covered by `npm run check:md:chat`, **not** by `npm run check:md`. Run the `:chat` one.
- **Never commit or push without explicit user confirmation** (CLAUDE.md git gate). Show the diff, summarize, wait.

## Facts established before writing this plan

Recorded here so no task has to re-derive them.

| Fact                         | Value                                                                                                                                         |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Host                         | `Apple M5 / 16 GB`, `Mac17,3` (MacBook Air, **fanless**), macOS 26.6.2, 17179869184 bytes RAM                                                 |
| Ollama                       | **0.33.1** (updated from 0.32.15 while this plan was being written), reachable at `http://127.0.0.1:11434`                                    |
| Models already pulled        | `qwen2.5-coder:7b`, `qwen3.5:9b`, `llama3.2:latest` (all Q4_K_M)                                                                              |
| Free disk                    | 204 GB — the ~17 GB of additional pulls is not a constraint                                                                                   |
| Baseline check               | `fvm dart run tool/model_probes/check_results.dart` → `OK`, 113 recorded runs, asset digests current                                          |
| `Median s/call` derives from | `shape_ab-seeded.json` only: sort call `ms`, **skip the first call**, **exclude any call whose label contains `timeout (`**, take `v[len~/2]` |
| `Full sweep` derives from    | Sum of every call's `ms` across the **seven standard probes**, excluding `shape_ab-channel-tool.json`                                         |
| `Stalls` derives from        | Count of calls whose label contains `timeout (`, same seven probes                                                                            |

Those three derivation rules were validated against all fifteen recorded M1 Max
models and reproduce every published figure exactly. The `Full sweep` rule is
the one the file currently states imprecisely — it says "every probe for that
model", but including `shape_ab-channel-tool` puts eight of the fifteen rows out
by 3–21 minutes. Task 5 corrects that sentence.

**The Ollama runtime is an uncontrolled variable, and it moved.** This host is
now on 0.33.1; the archive's runs record `machine`, `measuredAt`, and asset
digests, but **not** the Ollama version they ran against, so the version behind
the Apple M1 Max / 64 GB figures is not recoverable from the results. A
cross-host latency difference therefore cannot be cleanly attributed to the box
rather than to the runtime. Task 1b closes the gap going forward — it cannot
close it backwards, so Task 5's write-up has to state the limitation rather than
explain it away.

## The eight models

Every model the roster marks ✅ or ⚠️ in its **16 GB** column. `gpt-oss:20b` at
12.8 GB is deliberately excluded: the roster marks it ❌, and 12.8 GB of weights
plus KV cache sits above the default Metal wired limit on a 16 GB unified-memory
host, so it is not a model this machine can measure honestly.

| Model                     | Weights | Pull needed | M1 Max median | M1 Max sweep | M1 Max stalls |
| ------------------------- | ------- | ----------- | ------------- | ------------ | ------------- |
| `llama3.2:latest`         | 1.9 GB  | no          | 1.4 s         | 12 min       | 2             |
| `granite4.1:3b`           | 2.0 GB  | **yes**     | 1.1 s         | 34 min       | 13            |
| `nemotron-3-nano:4b`      | 2.6 GB  | **yes**     | 2.6 s         | 18 min       | 1             |
| `llama3-chatqa:8b`        | 4.3 GB  | **yes**     | 0.3 s         | 3 min        | 0             |
| `llama3-groq-tool-use:8b` | 4.3 GB  | **yes**     | 1.8 s         | 9 min        | 0             |
| `qwen2.5-coder:7b`        | 4.4 GB  | no          | 2.3 s         | 18 min       | 0             |
| `granite4.1:8b`           | 5.0 GB  | **yes**     | 2.7 s         | 14 min       | 0             |
| `qwen3.5:9b`              | 6.1 GB  | no          | 6.9 s         | 34 min       | 0             |

M1 Max total: **142 minutes** of measured call time. Memory-bandwidth-bound
decode on a base-M5 (~150 GB/s) against an M1 Max (~400 GB/s) suggests the M5
run takes longer despite the newer core; budget **4–7 hours** wall clock and
treat that as an estimate, not a prediction. `granite4.1:3b` is the stall risk —
13 of the M1 Max sweep's 19 stalls are its.

## File Structure

- `adaptive_chat_server_dart/tool/model_probes/sweep.sh` — **modify**, one line: make the results directory overridable so a second host does not collide with the archive.
- `adaptive_chat_server_dart/tool/model_probes/probe_results.dart` + `test/probe_results_test.dart` — **modify** (Task 1b), add a nullable `ollama` version field so the next cross-host comparison records its runtime.
- `adaptive_chat_server_dart/tool/model_probes/perf_table.py` — **create**, the derivation script. Python rather than Dart because it reads recorded JSON and prints a Markdown table; it is a reporting aid, not part of the probe pipeline, and `check_results.dart` remains the Dart-side authority.
- `adaptive_chat_server_dart/tool/model_probes/results-m5-16gb/<model-slug>/*.json` — **create** (written by the sweep), 8 directories, 58 files.
- `adaptive_chat_server_dart/ModelBehavior.md` — **modify**, the performance section plus three host claims elsewhere in the file.
- `adaptive_chat_server_dart/tool/model_probes/README.md:157-161` — **modify**, one paragraph that says the development machine has 64 GB.
- `adaptive_chat_server_dart/CHANGELOG.md` — **modify**, one `## [Unreleased]` bullet.

---

### Task 1: Make the sweep's results directory overridable

Without this the sweep is a no-op on this host: `run()` skips any `(model,
probe)` whose output file already exists, and all 58 target files already exist
from the M1 Max run.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/sweep.sh:33`

**Interfaces:**

- Produces: environment variable `SWEEP_RESULTS`, defaulting to `tool/model_probes/results`. Tasks 3 and 4 set it to `tool/model_probes/results-m5-16gb`.

- [ ] **Step 1: Confirm the current no-op behavior before changing anything**

```bash
cd adaptive_chat_server_dart
grep -n 'RES=' tool/model_probes/sweep.sh
ls tool/model_probes/results/qwen2.5-coder_7b/
```

Expected: `RES=tool/model_probes/results` on line 33, and seven JSON files
listed. Those seven are exactly what `run()` would skip.

- [ ] **Step 2: Make the directory overridable**

Replace line 33:

```sh
RES=tool/model_probes/results
```

with:

```sh
# Overridable so a second host records beside the archive rather than into it.
# `tool/model_probes/results/` holds the Apple M1 Max / 64 GB runs that
# check_results.dart re-derives ModelBehavior.md's shape table from, and run()
# skips any (model, probe) whose JSON already exists -- so a sweep on another
# machine pointed here would silently skip every model and record nothing.
RES=${SWEEP_RESULTS:-tool/model_probes/results}
```

- [ ] **Step 3: Verify the default is unchanged and the override takes effect**

```bash
cd adaptive_chat_server_dart
zsh -n tool/model_probes/sweep.sh && echo "syntax OK"
SWEEP_RESULTS=/tmp/sweep-probe-dryrun zsh -c '
  source /dev/stdin <<< "$(sed -n "30,40p" tool/model_probes/sweep.sh)"
  echo "RES=$RES"'
```

Expected: `syntax OK`, then `RES=/tmp/sweep-probe-dryrun`. Re-run the second
command without the variable set and expect `RES=tool/model_probes/results`.

- [ ] **Step 4: Verify the archive is still intact and CI-clean**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/check_results.dart
```

Expected: `check_results: 113 recorded run(s), 4 model(s) in launch.json`
followed by the `OK —` line. A `FAIL` here means something other than this
step's edit is wrong; stop and investigate before sweeping.

- [ ] **Step 5: Commit** (show the diff and get confirmation first — CLAUDE.md git gate)

```bash
git add adaptive_chat_server_dart/tool/model_probes/sweep.sh
git commit -m "chore(chat-server): let sweep.sh record to a per-host results dir"
```

---

### Task 1b: Stamp the Ollama version into every result file

Ollama updated from 0.32.15 to 0.33.1 while this plan was being written, which
turns a latent gap into an active one: the M5 runs and the archive will differ in
runtime as well as in host, and nothing recorded says so. `ModelBehavior.md`
already argues that "a figure that cannot name its machine does not belong here";
the same argument covers the runtime that produced it.

This cannot repair the archive — those runs are finished and their version is not
recoverable — so it is worth doing only because it makes the _next_ comparison
interpretable. Cut this task if you would rather keep the sweep's blast radius to
the sweep.

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/probe_results.dart`
- Modify: `adaptive_chat_server_dart/test/probe_results_test.dart`

**Interfaces:**

- Produces: `String? detectOllamaVersion()` — returns e.g. `0.33.1`, or `null` when the daemon is unreachable. `ProbeRun` gains a nullable `ollama` field, serialized after `machine` and omitted when null, so existing result files still parse.

- [ ] **Step 1: Write the failing tests**

Add to `test/probe_results_test.dart`, inside the existing `round trip` group,
replacing that group's single test with these two:

```dart
    test('survives JSON without losing a field', () {
      final run = ProbeRun(
        probe: 'shape_ab',
        model: 'qwen3.8:27b-nvfp4',
        variant: 'unaided',
        measuredAt: '2026-08-20',
        machine: 'Apple M1 Max / 64 GB',
        ollama: '0.33.1',
        samples: 2,
        temperature: 0,
        assets: const {'card_system_prompt.txt': 'abc123def456'},
        summary: const {'coldStart': 23, 'withHistory': 24},
        notes: 'backfilled',
        calls: [call('date', ms: 1200, cond: 'cold')],
      );
      final back = ProbeRun.fromJson(run.toJson());
      expect(back.toJson(), run.toJson());
      expect(back.variant, 'unaided');
      expect(back.machine, 'Apple M1 Max / 64 GB');
      expect(back.ollama, '0.33.1');
      expect(back.calls.single.condition, 'cold');
    });

    test('reads a run recorded before the version was stamped', () {
      // The archive has 113 of these. A new field must not make them
      // unreadable, or check_results.dart stops being able to police them.
      final legacy = {
        'probe': 'shape_ab',
        'model': 'qwen2.5-coder:7b',
        'measuredAt': '2026-08-20',
        'machine': 'Apple M1 Max / 64 GB',
        'samples': 2,
        'assets': {'card_system_prompt.txt': 'abc123def456'},
        'summary': <String, dynamic>{},
        'calls': [
          {'case': 'date', 'sample': 0, 'pass': true, 'label': 'card[2]'},
        ],
      };
      final run = ProbeRun.fromJson(legacy);
      expect(run.ollama, isNull);
      expect(run.toJson().containsKey('ollama'), isFalse);
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd adaptive_chat_server_dart
fvm dart test test/probe_results_test.dart
```

Expected: a compile error — `No named parameter with the name 'ollama'`. That is
the failure; it proves the field does not exist yet.

- [ ] **Step 3: Add the field and the detector**

In `probe_results.dart`, add to the `ProbeRun` constructor parameter list beside
`this.machine`:

```dart
    this.ollama,
```

to `fromJson`, beside the `machine` line:

```dart
    ollama: json['ollama'] as String?,
```

the field itself, after `machine`:

```dart
  /// The Ollama version that served the calls, where it could be read.
  ///
  /// Recorded for the same reason [machine] is: a latency figure is a joint
  /// property of the model, the box, and the runtime, and the first cross-host
  /// comparison in this directory was taken across an Ollama upgrade with no
  /// record of which version produced which half. Null on runs recorded before
  /// this field existed, and on any run where the daemon did not answer.
  final String? ollama;
```

and to `toJson`, immediately after the `machine` entry:

```dart
    if (ollama != null) 'ollama': ollama,
```

Then the detector, beside `detectMachine()`:

```dart
/// Reads the running Ollama version, or null if the daemon does not answer.
///
/// Null rather than a throw or a placeholder: a probe that can reach Ollama
/// well enough to run is the normal case, and one that cannot is already
/// failing louder elsewhere. An absent field reads as "not recorded", which is
/// true, where `unknown` would read as a measured value.
String? detectOllamaVersion() {
  try {
    final r = Process.runSync('ollama', ['--version']);
    final m = RegExp(
      r'(\d+\.\d+\.\d+)',
    ).firstMatch((r.stdout as String).trim());
    return m?.group(1);
  } on ProcessException {
    return null;
  }
}
```

and wire it into `writeProbeRun`, beside `machine: detectMachine(),`:

```dart
    ollama: detectOllamaVersion(),
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd adaptive_chat_server_dart
fvm dart test test/probe_results_test.dart
fvm dart analyze
fvm dart format --output=none --set-exit-if-changed .
```

Expected: all tests pass, analyze clean, format clean.

- [ ] **Step 5: Verify the archive still reads and CI is still green**

```bash
cd adaptive_chat_server_dart
fvm dart run tool/model_probes/check_results.dart
git status --short tool/model_probes/results/
```

Expected: `113 recorded run(s)` and `OK`, and no modification to any archived
file. The field is additive and write-side only; nothing rewrites the archive.

- [ ] **Step 6: Confirm the detector reads this host**

```bash
cd adaptive_chat_server_dart
fvm dart run -e "import 'tool/model_probes/probe_results.dart'; void main() => print(detectOllamaVersion());" 2>/dev/null   || ollama --version
```

Expected: `0.33.1`. If `dart run -e` is unavailable in this SDK, the fallback
prints the same version from the CLI, which is the string the regex parses.

- [ ] **Step 7: Commit** (diff + confirmation first)

```bash
git add adaptive_chat_server_dart/tool/model_probes/probe_results.dart adaptive_chat_server_dart/test/probe_results_test.dart
git commit -m "feat(chat-server): stamp the Ollama version into probe results"
```

---

### Task 2: Write and validate the perf-table derivation script

The three derivation rules are non-obvious — particularly that `Full sweep`
excludes the tool-channel run — and the file's whole provenance argument is that
figures get derived rather than typed. Validating the script against the M1 Max
data first is what makes its M5 output trustworthy.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/perf_table.py`

**Interfaces:**

- Consumes: result JSON written by `writeProbeRun` (`probe_results.dart:333`) — fields `model`, `machine`, `measuredAt`, and `calls[].{ms,label}`.
- Produces: CLI `python3 tool/model_probes/perf_table.py <results-dir> [--compare <results-dir>]`, printing a Markdown table sorted ascending by median s/call. Task 5 pastes its output.

- [ ] **Step 1: Write the script**

```python
#!/usr/bin/env python3
"""Derives ModelBehavior.md's performance table from recorded probe runs.

Every other figure in that file is generated (`sync_shape_table.dart`) or
checked (`check_results.dart`); the performance table was the one still typed
by hand. The three rules below are the ones that reproduce all fifteen
published Apple M1 Max rows exactly, and two of them are easy to get wrong:

  Median s/call  `shape_ab-seeded.json` only, so the 25-case mix is identical
                 across models. Drop the first call -- a cold call costs ~6-7x
                 a warm one -- and drop stalls, which measure the ceiling
                 rather than the model.
  Full sweep     Sum of every call's wall clock across the SEVEN standard
                 probes. `shape_ab-channel-tool.json` is excluded: only
                 tool-capable models have one, so including it would make the
                 column mean different things on different rows (it moves
                 eight of the fifteen M1 Max rows by 3-21 minutes).
  Stalls         Calls that hit the per-call ceiling, same seven probes.
                 Reported beside the latency, never folded into it.

    python3 tool/model_probes/perf_table.py tool/model_probes/results
    python3 tool/model_probes/perf_table.py tool/model_probes/results-m5-16gb \
        --compare tool/model_probes/results
"""

import argparse
import json
import pathlib
import sys

CHANNEL_PROBE = "shape_ab-channel-tool.json"
MEDIAN_PROBE = "shape_ab-seeded.json"


def is_stall(call):
    """Matches anywhere, not at the start: the shape judge wraps a stalled
    call as `broken: timeout (120s)`."""
    return "timeout (" in call["label"]


def read_model(model_dir):
    total_ms = 0
    stalls = 0
    median_s = None
    model = machine = measured = None
    for path in sorted(model_dir.glob("*.json")):
        if path.name == CHANNEL_PROBE:
            continue
        run = json.loads(path.read_text())
        model = run["model"]
        machine = run.get("machine")
        measured = run.get("measuredAt")
        calls = run["calls"]
        total_ms += sum(c["ms"] for c in calls if c.get("ms") is not None)
        stalls += sum(1 for c in calls if is_stall(c))
        if path.name == MEDIAN_PROBE:
            warm = sorted(
                c["ms"]
                for c in calls[1:]
                if c.get("ms") is not None and not is_stall(c)
            )
            if warm:
                median_s = warm[len(warm) // 2] / 1000
    if model is None:
        return None
    return {
        "model": model,
        "machine": machine,
        "measuredAt": measured,
        "median_s": median_s,
        "sweep_min": round(total_ms / 60000),
        "stalls": stalls,
    }


def read_dir(results_dir):
    rows = []
    for model_dir in sorted(pathlib.Path(results_dir).iterdir()):
        if not model_dir.is_dir():
            continue
        row = read_model(model_dir)
        if row:
            rows.append(row)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("results_dir")
    ap.add_argument("--compare", help="second results dir, adds a ratio column")
    args = ap.parse_args()

    rows = read_dir(args.results_dir)
    if not rows:
        sys.exit(f"no recorded runs under {args.results_dir}")
    baseline = {r["model"]: r for r in read_dir(args.compare)} if args.compare else {}

    machines = sorted({r["machine"] for r in rows if r["machine"]})
    dates = sorted({r["measuredAt"] for r in rows if r["measuredAt"]})
    print(f"host(s): {', '.join(machines) or 'unstamped'}")
    print(f"measured: {', '.join(dates) or 'unstamped'}")
    print(f"models: {len(rows)}\n")

    head = "| Model | Median s/call | Full sweep | Stalls |"
    rule = "| ----- | ------------- | ---------- | ------ |"
    if baseline:
        head = head[:-1] + " vs M1 Max |"
        rule = rule[:-1] + " ---------- |"
    print(head)
    print(rule)
    for r in sorted(rows, key=lambda r: (r["median_s"] is None, r["median_s"] or 0)):
        med = "n/a" if r["median_s"] is None else f"{r['median_s']:.1f} s"
        line = (
            f"| `{r['model']}` | {med} | {r['sweep_min']} min | {r['stalls']} |"
        )
        if baseline:
            b = baseline.get(r["model"])
            if b and b["median_s"] and r["median_s"]:
                line += f" {r['median_s'] / b['median_s']:.1f}x |"
            else:
                line += " n/a |"
        print(line)


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Validate against the M1 Max archive — this is the test**

```bash
cd adaptive_chat_server_dart
python3 tool/model_probes/perf_table.py tool/model_probes/results
```

Expected: `host(s): Apple M1 Max / 64 GB`, `models: 15`, and fifteen rows that
match `ModelBehavior.md`'s current table **exactly**, in the same order:

```
llama3-chatqa:8b 0.3 s / 3 min / 0
granite4.1:3b 1.1 s / 34 min / 13
llama3.2:latest 1.4 s / 12 min / 2
qwen3-coder:30b 1.6 s / 10 min / 0
llama3-groq-tool-use:8b 1.8 s / 9 min / 0
nemotron-3.5-lightning:30b 2.0 s / 12 min / 0
nemotron-3-nano:30b 2.2 s / 11 min / 0
qwen2.5-coder:7b 2.3 s / 18 min / 0
hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest 2.3 s / 15 min / 2
nemotron-3-nano:4b 2.6 s / 18 min / 1
granite4.1:8b 2.7 s / 14 min / 0
qwen3.8:27b-nvfp4 4.3 s / 39 min / 0     <-- table currently says 4.4 s; see Step 3
qwen3.6:27b-coding-nvfp4 6.2 s / 37 min / 0
qwen3.5:9b 6.9 s / 34 min / 0
gpt-oss:20b 7.3 s / 48 min / 1
```

Fourteen of the fifteen rows must match cell for cell. If any of those fourteen
disagrees, the script is wrong — fix the script, not the table. The published
figures are the fixture here.

- [ ] **Step 3: Correct the one row that does not match**

`qwen3.8:27b-nvfp4`'s recorded run gives a median of **4339 ms**, which is
**4.3 s**; the published table says 4.4 s. This was confirmed against the run
before this plan was written — the 99 warm calls sort to `[… 4295, 4339, 4404 …]`
around the midpoint, so 4.3 s is the figure and 4.4 s is a transcription slip.
It is the drift `check_results.dart` was built to catch and could not, because
the performance table is the one table it does not re-derive.

Correct that single cell in `ModelBehavior.md`'s M1 Max table from `4.4 s` to
`4.3 s`. Change nothing else in that table, and flag the correction to the user
when presenting the diff — CLAUDE.md forbids altering a published figure while
editing prose, and this is an exception justified by the recorded run, not a
judgment call.

Verify the correction is the only difference:

```bash
cd adaptive_chat_server_dart
python3 tool/model_probes/perf_table.py tool/model_probes/results
```

Expected after the edit: all fifteen rows match the file.

- [ ] **Step 4: Commit** (diff + confirmation first)

```bash
git add adaptive_chat_server_dart/tool/model_probes/perf_table.py adaptive_chat_server_dart/ModelBehavior.md
git commit -m "fix(chat-server): derive the performance table, correcting one median"
```

---

### Task 3: Pull the five missing models and record their identity

Weights are re-published under the same tag over time. Recording each tag's
digest is what lets a future reader tell "the M5 is slower" from "a different
build was measured".

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results-m5-16gb/MODELS.md`

- [ ] **Step 1: Confirm what is already local**

```bash
curl -s http://127.0.0.1:11434/api/tags |
  python3 -c "import sys,json;[print(m['name'], m['digest'][:12], m['details']['quantization_level'], round(m['size']/2**30,1),'GiB') for m in sorted(json.load(sys.stdin)['models'], key=lambda m: m['name'])]"
```

Expected before pulling: `qwen2.5-coder:7b`, `qwen3.5:9b`, `llama3.2:latest`,
all `Q4_K_M`.

- [ ] **Step 2: Pull the five missing models**

Roughly 17 GB of download; 204 GB free, so disk is not a constraint. Serial on
purpose — a parallel pull saturates the link and tells you nothing sooner.

```bash
for m in granite4.1:3b granite4.1:8b llama3-chatqa:8b \
         llama3-groq-tool-use:8b nemotron-3-nano:4b; do
  echo "=== $m ==="
  ollama pull "$m" || echo ">>> FAILED $m"
done
```

If a tag 404s, it has been withdrawn from the Ollama library. Do not substitute
a near-neighbor tag — record the model as unavailable in Step 4 and let Task 5's
table carry seven rows instead of eight. A silently different model is worse
than a missing row.

- [ ] **Step 3: Verify all eight are present and none is a surprise quantization**

```bash
curl -s http://127.0.0.1:11434/api/tags |
  python3 -c "
import sys,json
want={'granite4.1:3b','granite4.1:8b','llama3-chatqa:8b','llama3-groq-tool-use:8b','llama3.2:latest','nemotron-3-nano:4b','qwen2.5-coder:7b','qwen3.5:9b'}
have={m['name']:m for m in json.load(sys.stdin)['models']}
for n in sorted(want):
    m=have.get(n)
    print(('OK   ' if m else 'MISS '), n, (m['digest'][:12]+' '+m['details']['quantization_level']+' '+str(round(m['size']/2**30,1))+' GiB') if m else '')
"
```

Expected: eight `OK` lines. Compare each `GiB` figure against the Weights column
in this plan's model table — a size differing by more than ~0.3 GiB means the
tag was re-published since the M1 Max sweep, which is a real finding for the
write-up, not an error.

- [ ] **Step 4: Record the roster**

Write `adaptive_chat_server_dart/tool/model_probes/results-m5-16gb/MODELS.md`
with the exact output of Step 3, plus:

```markdown
# Models measured on Apple M5 / 16 GB

Ollama 0.33.1, macOS 26.6.2, Mac17,3. Pulled <DATE>.

Digests are recorded because a tag can be re-published: a latency difference
against the Apple M1 Max / 64 GB figures means something different if the
weights also changed.

<paste the Step 3 output here as a fenced block>
```

- [ ] **Step 5: Commit** (diff + confirmation first)

```bash
git add adaptive_chat_server_dart/tool/model_probes/results-m5-16gb/MODELS.md
git commit -m "docs(chat-server): record the model roster measured on the M5 host"
```

---

### Task 4: Run the sweep

Four to seven hours of sustained GPU load. This is the only task that cannot be
retried cheaply, so its preconditions matter more than its steps.

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results-m5-16gb/<slug>/*.json` — 7 files per model, plus `shape_ab-channel-tool.json` for whichever models report `"verdict": "supported"` (on the M1 Max run that was `nemotron-3-nano:4b` and `qwen3.5:9b`).

**Interfaces:**

- Consumes: `SWEEP_RESULTS` from Task 1.
- Produces: the result JSON Task 5's `perf_table.py` reads.

- [ ] **Step 1: Quiesce the machine**

The sweep measures the box as much as the model, and this box is a **fanless
MacBook Air**. Before starting:

```bash
ollama ps                     # must list nothing
pgrep -fl "model_probes/.*[.]dart"   # must print nothing
uptime                        # load average should be near idle
```

Quit other applications, put the machine on AC power, and open Activity Monitor
long enough to confirm nothing is holding memory. On a 16 GB unified-memory host
a background application competing for the Metal budget looks exactly like a
slow model — that is the failure mode `granite4.1:3b`'s first measurement fell
into.

- [ ] **Step 2: Start the sweep, ordered by stall risk**

`sweep.sh`'s built-in `MODELS` list is the full fifteen, so pass the eight
explicitly. The order below is the script's own ordering — reliable models
first, `granite4.1:3b` last — so a stalling tail cannot delay the rest.

```bash
cd adaptive_chat_server_dart
export SWEEP_RESULTS=tool/model_probes/results-m5-16gb
export SWEEP_LOG=/tmp/sweep-logs-m5
caffeinate -is tool/model_probes/sweep.sh \
  granite4.1:8b qwen2.5-coder:7b qwen3.5:9b llama3.2:latest \
  llama3-chatqa:8b llama3-groq-tool-use:8b nemotron-3-nano:4b granite4.1:3b \
  2>&1 | tee /tmp/sweep-m5.log
```

`caffeinate -is` keeps the machine awake for the duration; a sleep mid-sweep
leaves a partial result file that the resume logic will then skip. The sweep is
resumable — an interrupted run re-invoked with the identical command continues
where it stopped, because `run()` skips `(model, probe)` pairs whose JSON
already exists.

- [ ] **Step 3: Watch the first model to completion before walking away**

From a second terminal:

```bash
tail -f /tmp/sweep-m5.log
```

Expected inside the first few minutes: `##### MODEL granite4.1:8b`, then
`>>> START granite4.1:8b json_format`, then `>>> DONE ... rc=0`. Two things mean
stop immediately:

- `>>> ABORT ... another probe is running` — a stale probe process is alive. Find it with `pgrep -fl "model_probes/.*[.]dart"`, kill it, restart.
- `>>> SKIP` on any line — `SWEEP_RESULTS` did not take effect and the sweep is reading the M1 Max archive. Stop, re-check Task 1.

- [ ] **Step 4: Verify the run is complete and well-formed**

```bash
cd adaptive_chat_server_dart
tail -1 /tmp/sweep-m5.log        # expect: ##### SWEEP COMPLETE
ls tool/model_probes/results-m5-16gb/          # expect 8 dirs + MODELS.md
find tool/model_probes/results-m5-16gb -name '*.json' | wc -l   # expect 56-58
python3 -c "
import json,glob
for f in sorted(glob.glob('tool/model_probes/results-m5-16gb/*/*.json')):
    j=json.load(open(f))
    assert j['machine']=='Apple M5 / 16 GB', (f, j['machine'])
    assert j.get('ollama')=='0.33.1', (f, j.get('ollama'))   # drop if Task 1b was cut
print('all runs stamped Apple M5 / 16 GB on Ollama 0.33.1')
"
```

A `rc=` other than 0 in the log for some `(model, probe)` leaves that file
missing. Re-run the same command from Step 2 — completed pairs are skipped and
only the gap is retried.

- [ ] **Step 5: Cross-check shape coverage against the M1 Max archive**

This is the sanity gate. Both hosts ran the same assets at `t=0`, so shape
coverage is a property of the model and should reproduce within ±1 (the file
already documents that `--samples 2` moves ten of twelve steady models by ±1
between identical runs). A larger gap means the measurement is wrong — memory
pressure, a re-published tag, or an Ollama behavior change — not that the M5 is
worse at shapes.

```bash
cd adaptive_chat_server_dart
python3 -c "
import json
models=['granite4.1_8b','qwen2.5-coder_7b','qwen3.5_9b','llama3.2_latest',
        'llama3-chatqa_8b','llama3-groq-tool-use_8b','nemotron-3-nano_4b','granite4.1_3b']
for m in models:
    try:
        a=json.load(open(f'tool/model_probes/results/{m}/shape_ab-seeded.json'))['summary']
        b=json.load(open(f'tool/model_probes/results-m5-16gb/{m}/shape_ab-seeded.json'))['summary']
    except FileNotFoundError as e:
        print('MISSING', m); continue
    d=b['withHistory']-a['withHistory']
    print(f\"{m:26s} M1Max {a['coldStart']}/{a['withHistory']}  M5 {b['coldStart']}/{b['withHistory']}  delta {d:+d}\" + ('   <-- INVESTIGATE' if abs(d)>1 else ''))
"
```

Expected: every delta in `-1..+1`. Record any `INVESTIGATE` row and resolve it
before Task 5 — do not publish latency figures from a run whose coverage says
the measurement was disturbed.

- [ ] **Step 6: Confirm the archive and CI are untouched**

```bash
cd adaptive_chat_server_dart
git status --short tool/model_probes/results/    # expect no output
fvm dart run tool/model_probes/check_results.dart
```

Expected: no changes under `results/`, and `check_results` still reports 113
runs and `OK`. The M5 directory is a sibling, so the checker does not see it.

- [ ] **Step 7: Commit the results** (diff + confirmation first — `git diff --stat`, this is ~58 files)

```bash
git add adaptive_chat_server_dart/tool/model_probes/results-m5-16gb/
git commit -m "test(chat-server): record the eight 16 GB-capable models on Apple M5 / 16 GB"
```

---

### Task 5: Update `ModelBehavior.md`

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md` — the performance section (lines 266–286 as of this plan), plus the three host claims at lines 123, 151, 259, and the anchor reference at line 622.
- Modify: `adaptive_chat_server_dart/tool/model_probes/README.md:157-161`

**Interfaces:**

- Consumes: `python3 tool/model_probes/perf_table.py tool/model_probes/results-m5-16gb --compare tool/model_probes/results` from Task 2.

- [ ] **Step 1: Generate the figures**

```bash
cd adaptive_chat_server_dart
python3 tool/model_probes/perf_table.py tool/model_probes/results-m5-16gb \
  --compare tool/model_probes/results
```

Keep this output open — every figure in the following steps comes from it, and
nothing else. Do not round differently, reorder, or "tidy" a value.

- [ ] **Step 2: Restructure the performance section**

The heading `#### Performance on this machine` and its opening sentence ("All
timings are one host — **Apple M1 Max / 64 GB**, the machine every measurement
in this file was taken on") both stop being true once a second host is recorded.
Replace the heading and the first paragraph, keep the two methodology paragraphs
that follow, and put the existing fifteen-row table under a host sub-heading
with the M5 table beside it.

Replace lines 266–270 (heading through the "A second full run" paragraph's
predecessor) with:

```markdown
#### Performance, by host

Latency is a property of the model _and_ the box, so each recorded run stamps
the host into its result file; a figure that cannot name its machine does not
belong here. Two hosts are recorded, and their figures are not interchangeable.

**Median s/call** is over the fixed 25-case shape sweep, so the case mix cancels
and models are comparable. It excludes the first call after a model load, which
costs roughly **6-7x** a warm one, and it excludes stalled calls, which measure
the ceiling rather than the model. **Full sweep** is the seven standard probes
for that model, stalls included — that is wall clock someone waited. The
tool-channel run is excluded from it, because only tool-capable models have one
and a column that means different things on different rows is not a column.

A second full run is deliberately _not_ taken. Min-of-two is the usual noise
filter, but the dominant noise here is the known load event rather than jitter,
and on a laptop the second run is measured on a hotter, throttling machine, so
min-of-two would trade one uncontrolled bias for another.

All three figures are derived from the recorded runs by
[`perf_table.py`](tool/model_probes/perf_table.py) rather than transcribed, so a
re-run diffs against the table rather than against somebody's typing.

##### Apple M1 Max / 64 GB

The host every shape, cascade, everyday, and stress figure elsewhere in this
file was measured on. All fifteen models, 2026-08-20.
```

Then the existing fifteen-row table, **unchanged**, followed by its existing two
paragraphs ("**Weight does not predict speed.**" and "**Stalls, not token rate,
decide how long a sweep takes.**"), also unchanged.

- [ ] **Step 3: Add the M5 sub-section after those two paragraphs**

```markdown
##### Apple M5 / 16 GB

A fanless MacBook Air (`Mac17,3`), 16 GB unified memory, macOS 26.6.2, Ollama
0.33.1, measured <DATE>. Only the eight models the [roster](#candidate-models)
marks 16 GB-capable were run: `gpt-oss:20b` at 12.8 GB is the roster's flagged
exception on coverage, but its weights plus KV cache sit above the default Metal
budget on a 16 GB host, so it is not a model this box can measure honestly.

The **vs M1 Max** column is the median ratio, and is the reason this table
exists — the shape, cascade, and stress figures elsewhere in the file are
host-independent at `t=0`, and latency is not.

**The two hosts also differ in Ollama version, and the ratio cannot separate the
two causes.** The 2026-08-20 runs did not record their runtime, so the version
behind them is not recoverable; these were taken on 0.33.1. Read the ratio as
"this host, this runtime, against that one", not as a property of the silicon.
Runs recorded from now on stamp the version.

<paste the perf_table.py table here verbatim>

<Findings paragraphs — write these from the generated figures. Each must be a
claim the numbers support, in the file's register: state the figure, hedge the
mechanism. The three the data will bear on are:>

- Whether the ratio is roughly uniform across the eight models or scales with weights. A uniform ratio points at memory bandwidth; a ratio that grows with model size points at the Metal budget. Say which the numbers show, and hedge the mechanism.
- Whether `granite4.1:3b`'s stall count moved. On the M1 Max it stalled 13 times under the 120 s ceiling, and the ceiling is fixed, so a higher count on a slower host is expected rather than a new property of the model — say so explicitly, because that row is the one most likely to be misread.
- Whether the M1 Max ordering survives. If two models swap places, name them; if the order holds, say that a single ordering describes both hosts.

**Sustained load on a fanless host is a caveat these figures carry and the M1
Max figures do not.** The sweep runs the GPU for hours in a chassis with no fan,
so later models are measured on a hotter machine than earlier ones. The
methodology note above rejects min-of-two for exactly this reason; here the bias
is inside a single run, ordered by the sweep's stall-risk sequence rather than
by weight. Read a small difference between two adjacent rows as noise.
```

- [ ] **Step 4: Fix the two anchor references the renamed heading breaks**

`ModelBehavior.md:259`:

```markdown
- **Weight class does not predict coverage — or speed.** `granite4.1:8b` at 5.0 GB scores 21/25, matching two models four times its size. Weight predicts runtime even less: `qwen3-coder:30b` at 17.3 GB runs a full sweep in 10 minutes while `gpt-oss:20b` at 12.8 GB takes 48 — see [Performance, by host](#performance-by-host).
```

`ModelBehavior.md:622` — change `[the performance table](#performance-on-this-machine)`
to `[the performance table](#performance-by-host)`.

- [ ] **Step 5: Correct the two "the development machine has 64 GB" claims**

`ModelBehavior.md:123`, replace the sentence "The current development machine is
a **64 GB M1**, where every model in this table runs comfortably on its own —
including the ❌ rows." with:

```markdown
Two hosts have been measured: a **64 GB M1 Max**, where every model in this table runs comfortably on its own — including the ❌ rows — and a **16 GB M5**, where only the ✅ and ⚠️ rows do. A ❌ means "do not make this the recommended default", not "cannot be probed".
```

`ModelBehavior.md:151`, replace "Probing a ❌ model on the 64 GB development
machine is expected and useful; it is how this matrix gets filled in." with:

```markdown
Probing a ❌ model on the 64 GB host is expected and useful; it is how this matrix gets filled in, and the 16 GB host is where the column gets checked rather than asserted.
```

- [ ] **Step 6: Update `tool/model_probes/README.md:157-161`**

Replace "On the 64 GB development machine every model probed so far fits
**individually** …" with a sentence naming both hosts:

```markdown
This holds regardless of how much memory the host has. On the 64 GB host every
model probed so far fits **individually**, but the two largest together (≈24 GB
each) would sit near the usable Metal budget, and Ollama would still evict and
reload when the tag changes. On the 16 GB host only the roster's 16 GB-capable
models fit at all. The rule is about reload cost and measurement noise, not only
about a hard ceiling.
```

- [ ] **Step 7: Verify no figure moved and the doc still checks out**

The tone rule forbids changing a figure while adjusting register, so prove it:

```bash
cd adaptive_chat_server_dart
git show HEAD:ModelBehavior.md | grep -oE '[0-9]+(\.[0-9]+)?' | sort | uniq -c > /tmp/nums-before.txt
grep -oE '[0-9]+(\.[0-9]+)?' ModelBehavior.md | sort | uniq -c > /tmp/nums-after.txt
diff /tmp/nums-before.txt /tmp/nums-after.txt
```

Expected: differences **only** where the M5 table and its findings added
figures. Any count that decreased means an existing figure was altered — revert
that edit.

```bash
fvm dart run tool/model_probes/check_results.dart
```

Expected: still `OK`. The shape-coverage table was not touched, so this must not
have changed.

- [ ] **Step 8: Run the Markdown format gate**

`adaptive_chat_server_dart/**` is covered by `check:md:chat`, not `check:md` —
the trap CLAUDE.md calls out.

```bash
cd /Users/joefreemanjoe/Documents/Flutter-AdaptiveCards
npm run check:md:chat
```

If it fails, `npm run format:md:chat`, then re-run Step 7's numeric diff —
Prettier reflows tables and normalizes emphasis, and the numeric check is what
proves the reflow changed nothing that matters.

- [ ] **Step 9: Commit** (diff + confirmation first)

```bash
git add adaptive_chat_server_dart/ModelBehavior.md adaptive_chat_server_dart/tool/model_probes/README.md
git commit -m "docs(chat-server): record M5 / 16 GB performance beside the M1 Max figures"
```

---

### Task 6: Changelog and final verification

`ModelBehavior.md`'s Sources section points at `CHANGELOG.md` for "dated entries
with the measurement that justified each change", and every prior sweep has one.

**Files:**

- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

If Task 1b was cut, drop its changelog bullet below and the `ollama` assertion in
Task 4 Step 4.

- [ ] **Step 1: Add the `## [Unreleased]` bullets**

Match the surrounding entries' style — a bolded claim, then what was measured.
Fill the bracketed figures from Task 5's generated table.

```markdown
- Added: **latency measured on a second host.** The eight models the roster marks
  16 GB-capable were swept end to end on an **Apple M5 / 16 GB** MacBook Air, and
  `ModelBehavior.md`'s performance section now carries both hosts rather than
  asserting one. Median s/call runs <RATIO RANGE> the Apple M1 Max / 64 GB
  figures. Results in `tool/model_probes/results-m5-16gb/`; shape coverage
  reproduced the M1 Max figures within ±1 on all eight, which is what says the
  latency difference is the box.
- Added: **`tool/model_probes/perf_table.py`** derives the performance table from
  recorded runs. It was the last table in `ModelBehavior.md` still typed by hand,
  and the `Full sweep` column had been described as "every probe for that model"
  when the figures actually exclude the tool-channel run — a discrepancy of 3-21
  minutes on eight of the fifteen rows. The description is now corrected and the
  figures are generated.
- Fixed: **`qwen3.8:27b-nvfp4`'s median latency read 4.4 s against a recorded
  4339 ms.** A transcription slip, found by deriving the table from the runs
  rather than reading it. Corrected to 4.3 s; no other cell moved.
- Added: **probe results record the Ollama version.** They already stamped the
  host, the date, and the prompt digests, but not the runtime — so the first
  cross-host comparison in this directory spans an Ollama upgrade with no record
  of which version produced which half. Stamped going forward; the 113 archived
  runs stay unstamped, because their version is not recoverable.
- Changed: **`sweep.sh` takes `SWEEP_RESULTS`.** It previously hardcoded
  `tool/model_probes/results/`, where its resume logic would have skipped every
  already-recorded model rather than measuring a new host.
```

- [ ] **Step 2: Full verification**

```bash
cd /Users/joefreemanjoe/Documents/Flutter-AdaptiveCards
npm run check:md:chat
cd adaptive_chat_server_dart
fvm dart format --output=none --set-exit-if-changed .
fvm dart analyze
fvm dart test
fvm dart run tool/model_probes/check_results.dart
```

Expected: all pass, and `check_results` reports 113 runs and `OK` — unchanged
from the Task 1 baseline, because nothing in this plan touches the archive or
the shape table.

- [ ] **Step 3: Invoke `superpowers:verification-before-completion`** and paste the command output — exit codes and pass/fail counts — before claiming the work is done. CLAUDE.md's plan completion gate requires evidence, not a summary.

- [ ] **Step 4: Commit** (diff + confirmation first)

```bash
git add adaptive_chat_server_dart/CHANGELOG.md
git commit -m "docs(chat-server): changelog for the M5 / 16 GB performance sweep"
```

---

## Risks and what to do about them

| Risk                                                                     | Signal                                                                | Response                                                                                                                          |
| ------------------------------------------------------------------------ | --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Sweep writes into the M1 Max archive                                     | `>>> SKIP` lines in the log; `git status` shows changes in `results/` | Stop. `SWEEP_RESULTS` did not take effect. `git checkout -- tool/model_probes/results/` and re-check Task 1.                      |
| Ollama 0.33.1 changed scheduling or defaults since the archive's runtime | Ratios cluster far from what bandwidth alone predicts                 | Not resolvable — the archive did not record its version. State it in the write-up; do not attribute the gap to the box.           |
| A model tag was re-published since 2026-08-20                            | Size differs >0.3 GiB from this plan's table; shape delta >±1         | Not a blocker — record the digest and say so in the write-up. A latency comparison across different weights is a different claim. |
| Thermal throttling on the fanless Air biases later models                | Cannot be detected from one run                                       | Do not attempt to correct it. It is stated as a caveat in Task 5 Step 3, and the ordering is recorded in the log.                 |
| `granite4.1:3b` stalls far more than 13 times                            | Its `Full sweep` figure balloons                                      | Expected under a fixed 120 s ceiling on a slower host. Report it, and say the ceiling — not the model — moved.                    |
| A model OOMs or Ollama evicts mid-run                                    | `rc=` non-zero, or a shape delta well below −1                        | Confirm nothing else was resident (`ollama ps`), delete that model's directory, re-run it alone.                                  |
| Sweep interrupted                                                        | Log ends without `SWEEP COMPLETE`                                     | Re-run the identical Task 4 Step 2 command. Completed pairs are skipped; the sweep resumes.                                       |

## Deliberately out of scope

- **Making `check_results.dart` host-aware.** The right long-term shape is for the checker to partition recorded runs by their `machine` field so a second host can be CI-checked too. That is a real change to the checker's model of its own data and deserves its own plan; this one keeps the M5 runs in a sibling directory the checker does not read.
- **Re-deriving the shape-coverage table from the M5 runs.** Task 4 Step 5 uses M5 shape coverage as a sanity gate on the measurement, not as a published figure. `ModelBehavior.md`'s shape table stays the M1 Max measurement, which is what `sync_shape_table.dart` and CI expect.
- **Probing `gpt-oss:20b` on the M5.** 12.8 GB of weights plus KV cache exceeds the default Metal wired limit on a 16 GB host. Raising `iogpu.wired_limit_mb` to force it would measure a machine nobody is running.
- **Re-running the M1 Max host.** Nothing here invalidates those figures; the assets are unchanged and `check_results` is clean.
