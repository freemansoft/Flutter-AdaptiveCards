# Matched M1 Max / M5 Re-sweep with Per-Phase Timings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-measure the eight 16 GB candidates on both Apple hosts under one
identical Ollama version, the current harness and the current card system
prompt, recording Ollama's per-call prompt-processing and token-generation
timings, so that article 3 can drop most of its caveats and test whether the
M5's newer GPU recovers time on the compute-bound prompt phase.

**Architecture:** Three small code changes come first, all on Windows or a Mac:
`shape_ab.dart` records Ollama's `prompt_eval_*`, `eval_*` and `load_duration`
fields per call; `perf_table.py` gains a `--phases` report that splits the
median call into its two phases; `sweep.sh` gains an optional idle cooldown
between models. Then both Macs run the same eight-model sweep into new,
host-and-version-named results directories, with `powermetrics` logging the
M5's GPU frequency and thermal pressure. The notebook records the new
configuration as a new subsection beside the closed 0.33.x archives, and
article 3's tables are rederived from it.

**Tech Stack:** Dart 3.x via FVM (`fvm dart`), zsh (`sweep.sh`), Python 3
(`perf_table.py` only), Ollama (same patch version on both hosts), macOS
`powermetrics`, Prettier (`npm run check:md:chat`).

**Spec:** No separate spec. This plan implements steps 2-4 of the order of
work agreed on 2026-10-03, after article 3's five-agent review (PR #116,
commits `27c77283` and earlier on `docs/article-3-hardware-table`). The
"Facts established before writing this plan" section is the spec; every row
was read from a file on 2026-10-03.

## Global Constraints

- **Same Ollama server version on both hosts, to the patch digit.** Read it
  from `curl -s http://127.0.0.1:11434/api/version`, never from a client
  warning line. The directory names carry it (`ollama0340` = 0.34.0).
- **Prefix every `dart` command with `fvm`.** `sweep.sh` already does.
- **One model resident at a time.** Never bypass `sweep.sh`'s `wait_for_idle`
  or its `pgrep` abort. Close other GPU-heavy apps on the host during a sweep.
- **Same model order on both hosts:** `granite4.1:8b qwen2.5-coder:7b
qwen3.5:9b llama3-groq-tool-use:8b llama3.2:latest llama3-chatqa:8b
nemotron-3-nano:4b granite4.1:3b`, passed explicitly as `sweep.sh`
  arguments. This keeps each model at the same sweep position on both hosts.
- **Same cooldown on both hosts:** `SWEEP_COOLDOWN=600` (10 minutes idle
  before each model).
- **Do not write into a closed archive:** `results-m1max-64gb-ollama0332/`,
  `results-m1max-64gb-ollama0333/`, `results-m5-16gb-ollama0331/` are closed.
  `results-m1max-64gb-ollama0340/` already holds tool-channel and
  prompt-cache runs, including untimed `shape_ab-unaided.json` files for
  three of the eight models, which `sweep.sh` would silently skip. Task 4
  decides the new directory names.
- **Sibling naming rule (CLAUDE.md).** If a new directory needs a dimension
  the existing sibling's name lacks, rename the existing sibling to state it
  too, and fix every reference in the same change.
- **Do not regenerate the fifteen-model shape-coverage table.** It derives
  from `results-m1max-64gb-ollama0332/` via `shapeTableDir` in
  `check_results.dart`. This plan adds a configuration beside it.
- **Hand-written serialization.** `fromJson`/`toJson` by hand, camelCase keys,
  null-safe; no code generation.
- **Primary constructors.** `class const X({required final int a, ...})` with
  an in-body `this;` carrying `/// Creates ...`; never `this.a`.
- **Logging:** `dart:developer` `log` in library code; the probes already use
  `stdout` for their reports, keep that.
- **Documentation tone (CLAUDE.md)** for `ModelBehavior.md`, the results
  READMEs and article 3: flat analytical register, figures instead of
  superlatives, hedge inferred mechanisms.
- **Blog prose gate.** Article 3 changes are shown as prose to the user and
  confirmed before commit (`adaptive-cards-blog-writing` skill). The
  subagent commit exception does not cover `blog/`.
- **Never push, merge, or touch `main` without the user's confirmation.**

## Review Focus

1. **An Ollama reply without timing fields** (timeout, HTTP error, tool
   channel, an older runtime): the call must record `timings: null`, never
   crash or record zeros. Pinned in Task 1 (`OllamaTimings.fromBody` tests).
2. **Nanoseconds read as milliseconds.** Ollama durations are nanoseconds; a
   report that divides by 1e3 instead of 1e6 is off by 1000x and still looks
   plausible. Pinned in Task 2 (fixture with known ns values and expected ms).
3. **A sweep that silently reuses an untimed file.** `sweep.sh` skips any
   existing JSON. Task 7 checks that every seeded call in the new
   directories carries `timings`.
4. **Client and server version disagree.** `detectOllamaVersion()` runs
   `ollama --version`; if the client binary lags the server, the stamp is
   wrong. Task 4 checks the stamp against `/api/version` after the first
   model.
5. **The first call's model load leaking into the prompt phase.** Ollama
   reports `load_duration` separately; the median drops the first call
   anyway. Pinned in Task 2 (fixture's first call carries a large
   `loadNs` and must not move the medians).

---

## Facts established before writing this plan

| Fact                                                   | Value                                                                                                                                                                                                            |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Current article state                                  | `docs/article-3-hardware-table`, commit `27c77283` (PR #116, open)                                                                                                                                               |
| Hosts                                                  | Apple M1 Max / 64 GB, `MacBookPro18,4`, 32 GPU cores; Apple M5 / 16 GB, `Mac17,3` (MacBook Air, fanless), 8 GPU cores                                                                                            |
| Runtimes behind article 3 today                        | M1 Max 0.33.2, M5 0.33.1 (`ModelBehavior.md` "Performance, by host and runtime")                                                                                                                                 |
| M1 Max runtime now                                     | 0.34.0 (`ModelBehavior.md`: "which is what it runs now")                                                                                                                                                         |
| M5 runtime now                                         | Not recorded since 2026-09-07 (0.33.3). Task 4 reads it.                                                                                                                                                         |
| Prompt digest behind article 3's scores                | `4bfa327067f8`; shipped prompt is `8cbfde243266` (`Input.Rating` added, commit `9fcba7af`)                                                                                                                       |
| Only full 0.34.0 sweep on record                       | `granite4.1:3b`, `results-m1max-64gb-ollama0340/granite4.1_3b/`: 0 stalls, 8 min                                                                                                                                 |
| Per-call record today                                  | `ProbeCall` in `tool/model_probes/probe_results.dart:27-112`: `case`, `sample`, `pass`, `label`, `condition`, `setting`, `ms`, `toolUsed`, `unknownTypes`. No phase timings.                                     |
| Where replies are parsed                               | `probeOnce` in `tool/model_probes/probe_support.dart:421-561`; `_promptEvalCountOrNull` at `:585`; `judgeReply` at `:602`                                                                                        |
| Request mode                                           | `'stream': false`, so the single reply body carries Ollama's final timing fields                                                                                                                                 |
| Ceilings                                               | 120 s on shape and cascade (`sweep.sh` passes `--timeout 120`), 180 s default elsewhere (`probe_support.dart:36`)                                                                                                |
| Median rule                                            | `perf_table.py`: `shape_ab-seeded.json` only, drop first call, drop stalls, `v[len//2]`                                                                                                                          |
| Existing references to `results-m1max-64gb-ollama0340` | 15 lines in 6 files: `CHANGELOG.md` (2), `ModelBehavior.md` (6), `blog/article-8-prompt-cache-draft.md` (2), `results-m1max-64gb-ollama0332/HISTORICAL.md` (1), `retry_sweep.sh` (2), `tool_channel_arms.sh` (2) |

## File Structure

| File                                                                      | Change      | Responsibility                                                           |
| ------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------ |
| `adaptive_chat_server_dart/tool/model_probes/probe_results.dart`          | Modify      | New `OllamaTimings` value type; `ProbeCall.timings` with JSON round trip |
| `adaptive_chat_server_dart/tool/model_probes/probe_support.dart`          | Modify      | `ProbeOutcome.timings`; `probeOnce` and `judgeReply` pass it through     |
| `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart`               | Modify      | Copy `outcome.timings` into each `ProbeCall`                             |
| `adaptive_chat_server_dart/test/probe_results_test.dart`                  | Modify      | `OllamaTimings` parsing and `ProbeCall` round-trip tests                 |
| `adaptive_chat_server_dart/test/probe_support_test.dart`                  | Modify      | `judgeReply` timings pass-through test                                   |
| `adaptive_chat_server_dart/tool/model_probes/perf_table.py`               | Modify      | `--phases` report                                                        |
| `adaptive_chat_server_dart/tool/model_probes/sweep.sh`                    | Modify      | `SWEEP_COOLDOWN`                                                         |
| `adaptive_chat_server_dart/tool/model_probes/results-<host>-ollama<ver>/` | Create (x2) | New runs plus `README.md` and `MODELS.md` provenance                     |
| `adaptive_chat_server_dart/ModelBehavior.md`                              | Modify      | New subsection with the matched figures                                  |
| `adaptive_chat_server_dart/blog/article-3-m1max-vs-m5-draft.md`           | Modify      | Tables rederived; caveats the new data removes are cut                   |
| `adaptive_chat_server_dart/CHANGELOG.md`                                  | Modify      | One bullet per code task under `## [Unreleased]`                         |

---

### Task 0: Set up the branch on the Mac

**Files:** none

- [x] **Step 1: Get the code**

```bash
cd ~/Documents/GitHub/freemansoft/Flutter-AdaptiveCards
git fetch origin
git status   # must be clean
```

If PR #116 has merged, branch from `main`; otherwise branch from the PR
branch so the article revision is underneath:

```bash
# PR #116 merged:
git switch main && git pull && git switch -c measure/matched-resweep-phase-timings
# PR #116 still open:
git switch docs/article-3-hardware-table && git pull && git switch -c measure/matched-resweep-phase-timings
```

- [x] **Step 2: Confirm the toolchain**

```bash
fvm install            # installs the pinned SDK from .fvmrc
cd adaptive_chat_server_dart
fvm dart pub get
fvm dart test test/probe_results_test.dart test/probe_support_test.dart
```

Expected: all tests pass. If they do not, stop and report; do not start
Task 1 on a red baseline.

---

### Task 1: Record Ollama's per-call phase timings in `shape_ab.dart`

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/probe_results.dart` (add `OllamaTimings` above `ProbeCall`; extend `ProbeCall` at `:27-112`)
- Modify: `adaptive_chat_server_dart/tool/model_probes/probe_support.dart:226-282` (`ProbeOutcome`), `:543-560` (`probeOnce` tail), `:602-614` (`judgeReply`)
- Modify: `adaptive_chat_server_dart/tool/model_probes/shape_ab.dart:126-140`
- Test: `adaptive_chat_server_dart/test/probe_results_test.dart`, `adaptive_chat_server_dart/test/probe_support_test.dart`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Produces: `class OllamaTimings` with nullable `int` fields `promptEvalCount`,
  `promptEvalNs`, `evalCount`, `evalNs`, `loadNs`;
  `static OllamaTimings? fromBody(String body)`;
  `factory fromJson(Map<String, dynamic>)`; `Map<String, dynamic> toJson()`.
  JSON keys: `promptEvalCount`, `promptEvalNs`, `evalCount`, `evalNs`, `loadNs`.
- Produces: `ProbeOutcome.timings` (`OllamaTimings?`), `ProbeCall.timings`
  (`OllamaTimings?`, JSON key `timings`, omitted when null).
- Produces: `judgeReply(String content, int ms, {int? promptEvalCount, OllamaTimings? timings})`.
- Consumed by Task 2: each call object in `shape_ab-seeded.json` may carry
  `"timings": {"promptEvalNs": <int>, "evalNs": <int>, "evalCount": <int>, ...}`.

- [x] **Step 1: Write the failing `OllamaTimings` and `ProbeCall` tests**

Append to `test/probe_results_test.dart`, inside `main()`:

```dart
  group('OllamaTimings', () {
    test('reads every phase field from an /api/chat body', () {
      final t = OllamaTimings.fromBody(
        '{"message":{"content":"x"},"prompt_eval_count":3178,'
        '"prompt_eval_duration":412000000,"eval_count":96,'
        '"eval_duration":1850000000,"load_duration":5000000}',
      );
      expect(t, isNotNull);
      expect(t!.promptEvalCount, 3178);
      expect(t.promptEvalNs, 412000000);
      expect(t.evalCount, 96);
      expect(t.evalNs, 1850000000);
      expect(t.loadNs, 5000000);
    });

    test('is null when the body carries no timing field', () {
      expect(OllamaTimings.fromBody('{"message":{"content":"x"}}'), isNull);
    });

    test('is null rather than throwing on a body that is not JSON', () {
      expect(OllamaTimings.fromBody('upstream timeout'), isNull);
    });

    test('ignores a field of the wrong type instead of casting it', () {
      final t = OllamaTimings.fromBody(
        '{"eval_count":96,"eval_duration":"1.85s"}',
      );
      expect(t!.evalCount, 96);
      expect(t.evalNs, isNull);
    });

    test('round-trips through JSON, omitting absent fields', () {
      const t = OllamaTimings(evalCount: 96, evalNs: 1850000000);
      expect(t.toJson(), {'evalCount': 96, 'evalNs': 1850000000});
      final back = OllamaTimings.fromJson(t.toJson());
      expect(back.evalCount, 96);
      expect(back.evalNs, 1850000000);
      expect(back.promptEvalNs, isNull);
    });
  });

  group('ProbeCall timings', () {
    test('serializes timings when present', () {
      const call = ProbeCall(
        caseId: 'table',
        sample: 0,
        pass: true,
        label: 'card[1]',
        ms: 2300,
        timings: OllamaTimings(promptEvalNs: 400000000, evalNs: 1800000000),
      );
      final json = call.toJson();
      expect(json['timings'], {
        'promptEvalNs': 400000000,
        'evalNs': 1800000000,
      });
      final back = ProbeCall.fromJson(json);
      expect(back.timings!.evalNs, 1800000000);
    });

    test('omits the key when timings are absent, so older files still read', () {
      const call = ProbeCall(
        caseId: 'table',
        sample: 0,
        pass: false,
        label: 'broken: timeout (120s)',
      );
      expect(call.toJson().containsKey('timings'), isFalse);
      expect(ProbeCall.fromJson(call.toJson()).timings, isNull);
    });
  });
```

- [x] **Step 2: Run the tests to verify they fail**

```bash
cd adaptive_chat_server_dart
fvm dart test test/probe_results_test.dart
```

Expected: compile failure, `OllamaTimings` is undefined and `ProbeCall` has
no `timings` parameter.

- [x] **Step 3: Add `OllamaTimings` to `probe_results.dart`**

Insert above `class const ProbeCall(`:

```dart
/// Ollama's own per-request phase timings, read from an `/api/chat` reply.
///
/// A call's wall clock mixes two phases that different hardware limits:
/// processing the prompt is compute-bound, and generating the reply streams
/// the weights out of memory for every token, so it is bandwidth-bound.
/// Recording both is what lets a cross-host ratio say which phase moved,
/// rather than only that the call got slower. Durations are nanoseconds,
/// verbatim from Ollama; every field is null when the reply did not carry it.
class const OllamaTimings({
  /// `prompt_eval_count`: prompt tokens Ollama reports evaluating.
  final int? promptEvalCount,

  /// `prompt_eval_duration`, nanoseconds.
  final int? promptEvalNs,

  /// `eval_count`: tokens generated.
  final int? evalCount,

  /// `eval_duration`, nanoseconds.
  final int? evalNs,

  /// `load_duration`, nanoseconds: time spent loading the model for this call.
  final int? loadNs,
}) {
  /// Creates a timing record.
  this;

  /// Rebuilds a record from its JSON form.
  factory fromJson(Map<String, dynamic> json) => OllamaTimings(
    promptEvalCount: json['promptEvalCount'] as int?,
    promptEvalNs: json['promptEvalNs'] as int?,
    evalCount: json['evalCount'] as int?,
    evalNs: json['evalNs'] as int?,
    loadNs: json['loadNs'] as int?,
  );

  /// Reads the timing fields from an `/api/chat` [body].
  ///
  /// Null when the body is not a JSON object or carries none of the fields:
  /// a timed-out or failed call has no timings, and recording zeros would
  /// read as an infinitely fast call.
  static OllamaTimings? fromBody(String body) {
    final Object? data;
    try {
      data = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (data is! Map<String, dynamic>) return null;
    final map = data;
    int? read(String key) {
      final v = map[key];
      return v is int ? v : null;
    }

    final t = OllamaTimings(
      promptEvalCount: read('prompt_eval_count'),
      promptEvalNs: read('prompt_eval_duration'),
      evalCount: read('eval_count'),
      evalNs: read('eval_duration'),
      loadNs: read('load_duration'),
    );
    return t.toJson().isEmpty ? null : t;
  }

  /// JSON form, omitting absent fields.
  Map<String, dynamic> toJson() => {
    if (promptEvalCount != null) 'promptEvalCount': promptEvalCount,
    if (promptEvalNs != null) 'promptEvalNs': promptEvalNs,
    if (evalCount != null) 'evalCount': evalCount,
    if (evalNs != null) 'evalNs': evalNs,
    if (loadNs != null) 'loadNs': loadNs,
  };
}
```

`probe_results.dart` already imports `dart:convert`.

- [x] **Step 4: Add `timings` to `ProbeCall`**

In `class const ProbeCall(`, after the `unknownTypes` field:

```dart
  /// Ollama's phase timings for this call, where the probe recorded them.
  ///
  /// Null on runs recorded before 2026-10 and on any call that did not
  /// return a reply body (a stall, an HTTP error).
  final OllamaTimings? timings,
```

In `factory fromJson`, add:

```dart
    timings: json['timings'] == null
        ? null
        : OllamaTimings.fromJson(json['timings'] as Map<String, dynamic>),
```

In `toJson()`, add as the last entry:

```dart
    if (timings != null) 'timings': timings!.toJson(),
```

- [x] **Step 5: Run the tests to verify they pass**

```bash
fvm dart test test/probe_results_test.dart
```

Expected: PASS, including the existing tests.

- [x] **Step 6: Write the failing `judgeReply` pass-through test**

Append to the `judgeReply promptEvalCount` group in
`test/probe_support_test.dart`:

```dart
    test('carries Ollama phase timings into the outcome', () {
      final outcome = judgeReply(
        'why is the sky blue',
        12,
        timings: const OllamaTimings(evalCount: 9, evalNs: 90000000),
      );
      expect(outcome.timings!.evalNs, 90000000);
    });

    test('leaves timings null when the caller has none', () {
      expect(judgeReply('why is the sky blue', 12).timings, isNull);
    });
```

Add the import at the top of the test file, after the `probe_support.dart`
import:

```dart
import '../tool/model_probes/probe_results.dart';
```

- [x] **Step 7: Run it to verify it fails**

```bash
fvm dart test test/probe_support_test.dart
```

Expected: compile failure, `judgeReply` has no `timings` parameter.

- [x] **Step 8: Thread `timings` through `probe_support.dart`**

Add the import beside the other relative-free imports at the top of
`probe_support.dart` (after the `package:` imports):

```dart
import 'probe_results.dart';
```

In `class const ProbeOutcome(`, after `toolUsed`:

```dart
  /// Ollama's phase timings for the request, when the reply carried them.
  /// Null on a timeout, an HTTP error, or a body with no timing fields.
  final OllamaTimings? timings,
```

Change `judgeReply`'s signature and its inner `outcome` builder:

```dart
ProbeOutcome judgeReply(
  String content,
  int ms, {
  int? promptEvalCount,
  OllamaTimings? timings,
}) {
  final hash = md5.convert(utf8.encode(content)).toString().substring(0, 8);
  ProbeOutcome outcome({required bool ok, required String label}) =>
      ProbeOutcome(
        ok: ok,
        label: label,
        chars: content.length,
        ms: ms,
        hash: hash,
        reply: content,
        promptEvalCount: promptEvalCount,
        timings: timings,
      );
```

Change the last line of `probeOnce` (currently
`return judgeReply(content, ms, promptEvalCount: _promptEvalCountOrNull(body));`):

```dart
  return judgeReply(
    content,
    ms,
    promptEvalCount: _promptEvalCountOrNull(body),
    timings: OllamaTimings.fromBody(body),
  );
```

- [x] **Step 9: Record the timings in `shape_ab.dart`**

In the `ProbeCall(` built inside the case loop (`shape_ab.dart:126-140`), add
after `unknownTypes:`:

```dart
          timings: outcome.timings,
```

- [x] **Step 10: Run the full probe test set and the analyzer**

```bash
fvm dart test
fvm dart analyze
fvm dart format --output=none --set-exit-if-changed tool/ test/
```

Expected: all tests pass, `No issues found!`, format exit 0. Fix any
`public_member_api_docs` or `use_declaring_parameters` finding before
moving on.

- [x] **Step 11: Smoke-test against a live model (Mac with Ollama running)**

```bash
fvm dart run tool/model_probes/shape_ab.dart --model llama3.2:latest \
  --samples 1 --timeout 120 --json /tmp/timings-smoke.json
python3 -c "import json;c=json.load(open('/tmp/timings-smoke.json'))['calls'];print(sum('timings' in x for x in c),'of',len(c),'calls timed');print(c[1].get('timings'))"
```

Expected: every non-stalled call carries `timings` with nonzero
`promptEvalNs`, `evalNs`, `evalCount`. Delete `/tmp/timings-smoke.json`.

- [x] **Step 12: Changelog and commit**

Add under `## [Unreleased]` in `adaptive_chat_server_dart/CHANGELOG.md`:

```markdown
- `shape_ab.dart` records Ollama's per-call `prompt_eval_*`, `eval_*` and
  `load_duration` fields as `timings`, so a latency comparison can separate
  prompt processing from token generation.
```

```bash
git add tool/model_probes/probe_results.dart tool/model_probes/probe_support.dart \
  tool/model_probes/shape_ab.dart test/probe_results_test.dart \
  test/probe_support_test.dart CHANGELOG.md
git commit -m "feat(probes): record Ollama per-call phase timings in shape_ab"
```

---

### Task 2: Add a `--phases` report to `perf_table.py`

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/perf_table.py`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Consumes: Task 1's `timings` object per call in `shape_ab-seeded.json`.
- Produces: `perf_table.py <dir> [--compare <dir>] --phases`, printing one
  Markdown row per model: `| Model | Prompt ms | Gen ms | Gen tok/s | Timed calls |`,
  plus `| Prompt ratio | Gen ratio |` columns with `--compare`. Ratios are
  `results_dir ÷ compare_dir`, matching the existing ratio column.

- [x] **Step 1: Write the fixture and the expected output (the failing check)**

```bash
mkdir -p /tmp/phases-fixture/a/m /tmp/phases-fixture/b/m
python3 - <<'EOF'
import json
def run(prompt_ns, eval_ns):
    calls = [{"case":"load","sample":0,"pass":True,"label":"card[1]","ms":9000,
              "timings":{"promptEvalNs":9_000_000_000,"evalNs":1,"evalCount":1,"loadNs":8_000_000_000}}]
    for i, (p, e) in enumerate(zip(prompt_ns, eval_ns)):
        calls.append({"case":f"c{i}","sample":0,"pass":True,"label":"card[1]","ms":(p+e)//1_000_000,
                      "timings":{"promptEvalNs":p,"evalNs":e,"evalCount":100}})
    calls.append({"case":"stall","sample":0,"pass":False,"label":"broken: timeout (120s)","ms":120000})
    return {"probe":"shape_ab","model":"m","measuredAt":"2026-10-03","samples":1,"assets":{},"calls":calls}
json.dump(run([400_000_000, 500_000_000, 600_000_000], [1_000_000_000, 2_000_000_000, 3_000_000_000]),
          open("/tmp/phases-fixture/a/m/shape_ab-seeded.json","w"))
json.dump(run([200_000_000, 250_000_000, 300_000_000], [500_000_000, 1_000_000_000, 1_500_000_000]),
          open("/tmp/phases-fixture/b/m/shape_ab-seeded.json","w"))
EOF
cd adaptive_chat_server_dart
python3 tool/model_probes/perf_table.py /tmp/phases-fixture/a --compare /tmp/phases-fixture/b --phases
```

Expected now: `error: unrecognized arguments: --phases`.

Expected after Step 2, exactly this row (the load call and the stall are
excluded; medians are 500 ms and 2000 ms against 250 ms and 1000 ms; 100
tokens in 2.0 s is 50.0 tok/s):

```
| `m` | 500 | 2000 | 50.0 | 3 | 2.00x | 2.00x |
```

- [x] **Step 2: Implement `--phases`**

Add after `read_model_probes` in `perf_table.py`:

```python
def read_phases(model_dir):
    """Median prompt and generation time from `shape_ab-seeded.json`.

    Same population as the median s/call column: the first call (which carries
    the model load) and stalls are dropped. Ollama reports nanoseconds; the
    report prints milliseconds. Calls recorded before `timings` existed are
    skipped and counted, never read as zero.
    """
    path = model_dir / MEDIAN_PROBE
    if not path.exists():
        return None
    run = json.loads(path.read_text())
    prompt, gen, rate = [], [], []
    for c in run["calls"][1:]:
        t = c.get("timings")
        if is_stall(c) or not t:
            continue
        if t.get("promptEvalNs") is not None:
            prompt.append(t["promptEvalNs"] / 1e6)
        if t.get("evalNs"):
            gen.append(t["evalNs"] / 1e6)
            if t.get("evalCount"):
                rate.append(t["evalCount"] / (t["evalNs"] / 1e9))

    def med(v):
        return sorted(v)[len(v) // 2] if v else None

    return {
        "model": run["model"],
        "prompt_ms": med(prompt),
        "gen_ms": med(gen),
        "gen_tps": med(rate),
        "timed": len(gen),
    }


def print_phases(results_dir, compare_dir):
    def rows(d):
        out = {}
        for model_dir in sorted(pathlib.Path(d).iterdir()):
            if model_dir.is_dir():
                r = read_phases(model_dir)
                if r:
                    out[r["model"]] = r
        return out

    here = rows(results_dir)
    base = rows(compare_dir) if compare_dir else {}
    head = "| Model | Prompt ms | Gen ms | Gen tok/s | Timed calls |"
    rule = "| ----- | --------- | ------ | --------- | ----------- |"
    if base:
        head += " Prompt ratio | Gen ratio |"
        rule += " ------------ | --------- |"
    print(head)
    print(rule)

    def fmt(v, spec):
        return "n/a" if v is None else format(v, spec)

    def ratio(a, b):
        return "n/a" if not a or not b else f"{a / b:.2f}x"

    for model, r in sorted(here.items()):
        line = (
            f"| `{model}` | {fmt(r['prompt_ms'], '.0f')} | {fmt(r['gen_ms'], '.0f')} "
            f"| {fmt(r['gen_tps'], '.1f')} | {r['timed']} |"
        )
        if base:
            b = base.get(model, {})
            line += (
                f" {ratio(r['prompt_ms'], b.get('prompt_ms'))} "
                f"| {ratio(r['gen_ms'], b.get('gen_ms'))} |"
            )
        print(line)
```

In `main()`, add the flag beside `--by-probe`:

```python
    ap.add_argument(
        "--phases",
        action="store_true",
        help="split the median call into prompt processing and generation",
    )
```

and dispatch it right after the `--by-probe` dispatch:

```python
    if args.phases:
        print_phases(args.results_dir, args.compare)
        return
```

Add one paragraph to the module docstring, after the `--by-probe` paragraph:

```
`--phases` splits the median call into Ollama's own prompt-processing and
generation timings (`timings` on each `shape_ab-seeded.json` call, recorded
from 2026-10). Prompt processing is compute-bound and generation is
bandwidth-bound, so a host comparison that moves one and not the other names
the resource. Runs recorded before `timings` existed print `n/a`.
```

- [x] **Step 3: Run the fixture check**

```bash
python3 tool/model_probes/perf_table.py /tmp/phases-fixture/a --compare /tmp/phases-fixture/b --phases
python3 tool/model_probes/perf_table.py tool/model_probes/results-m5-16gb-ollama0331 --phases | head -4
```

Expected: the first prints the header, rule, and exactly
``| `m` | 500 | 2000 | 50.0 | 3 | 2.00x | 2.00x |``. The second prints `n/a`
cells and `0` timed calls for every model (old runs have no timings), with no
traceback. Then `rm -rf /tmp/phases-fixture`.

- [x] **Step 4: Confirm the existing report is unchanged**

```bash
python3 tool/model_probes/perf_table.py tool/model_probes/results-m5-16gb-ollama0331 \
  --compare tool/model_probes/results-m1max-64gb-ollama0332 | tail -8
```

Expected: eight rows whose `vs baseline` column reads 1.1x to 1.4x for seven
models and 2.3x for `llama3-chatqa:8b`, the one-decimal form of the
notebook's cross-host ratios. Any difference means Step 2 touched the
default report.

- [x] **Step 5: Changelog and commit**

```markdown
- `perf_table.py --phases` reports median prompt-processing and generation
  time per model from the new per-call `timings`, with host-to-host ratios
  under `--compare`.
```

```bash
git add tool/model_probes/perf_table.py CHANGELOG.md
git commit -m "feat(probes): perf_table --phases splits the median call by phase"
```

---

### Task 3: Add an idle cooldown between models to `sweep.sh`

**Files:**

- Modify: `adaptive_chat_server_dart/tool/model_probes/sweep.sh`
- Modify: `adaptive_chat_server_dart/CHANGELOG.md`

**Interfaces:**

- Produces: `SWEEP_COOLDOWN=<seconds>` environment variable, default `0`
  (current behavior). Applied after `wait_for_idle` and before each model's
  first probe, including the first model, so every model starts from the
  same idle interval.

- [x] **Step 1: Add the variable and the comment**

After `mkdir -p "$LOG"`:

```zsh
# Seconds of idle before each model, default none. The 2026-08-28 M5 sweep
# ran eight models back to back and only the first started on an idle host;
# re-runs then moved single-model medians 1.03x to 1.54x by sweep position
# alone. A fixed cooldown gives every model the same starting state, so
# position stops being a variable rather than a bias to estimate afterwards.
COOLDOWN=${SWEEP_COOLDOWN:-0}
```

- [x] **Step 2: Apply it in the model loop**

Replace the first `wait_for_idle` inside `for M in $MODELS; do` with:

```zsh
  wait_for_idle
  if (( COOLDOWN > 0 )); then
    echo ">>> COOLDOWN ${COOLDOWN}s $(date +%T)"
    sleep "$COOLDOWN"
  fi
```

Add one usage line to the header comment, after the `just one` example:

```zsh
#   SWEEP_COOLDOWN=600 tool/model_probes/sweep.sh m1 m2   # 10 min idle before each
```

- [x] **Step 3: Verify syntax and behavior**

```bash
zsh -n tool/model_probes/sweep.sh && echo syntax-ok
grep -n 'COOLDOWN' tool/model_probes/sweep.sh
```

Expected: `syntax-ok`; three code lines plus the header example. A live
check happens in Task 5 Step 3, where the log must show `>>> COOLDOWN 600s`
before each model.

- [x] **Step 4: Changelog and commit**

```markdown
- `sweep.sh` honors `SWEEP_COOLDOWN` (seconds of idle before each model) so
  a multi-model sweep can start every model from the same host state.
```

```bash
git add tool/model_probes/sweep.sh CHANGELOG.md
git commit -m "feat(probes): sweep.sh SWEEP_COOLDOWN idles before each model"
```

---

### Task 4: Align the Ollama version and name the result directories

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama<VER>/README.md`, `.../MODELS.md`
- Create: `adaptive_chat_server_dart/tool/model_probes/results-m5-16gb-ollama<VER>/README.md`, `.../MODELS.md`
- Possibly rename: `results-m1max-64gb-ollama0340/` (Step 3, branch B only)

`<VER>` is the server version with the dots removed: 0.34.0 is `0340`,
0.34.1 is `0341`.

- [x] **Step 1: Read both servers' versions**

On each Mac:

```bash
curl -s http://127.0.0.1:11434/api/version
ollama --version
sw_vers -productVersion
sysctl -n hw.model
```

Record all four on each host. If client and server differ, fix the
client (`ollama --version` is what `detectOllamaVersion()` stamps into the
files).

- [x] **Step 2: Pick one version for both hosts**

Install the same release on both, the newest one both can run. Do not
proceed with different patch versions. Then pull the current weights on the
M5 and compare digests:

```bash
for m in granite4.1:8b qwen2.5-coder:7b qwen3.5:9b llama3-groq-tool-use:8b \
         llama3.2:latest llama3-chatqa:8b nemotron-3-nano:4b granite4.1:3b; do
  ollama pull "$m" >/dev/null && ollama list | grep -F "$m"
done
```

Expected: the digests match `results-m5-16gb-ollama0331/MODELS.md` (for
example `granite4.1:8b 444af1c4b2fe`). A changed digest is a different
measurement; record it in `MODELS.md` and tell the user before sweeping.

- [x] **Step 3: Name the directories**

- **Branch A, `<VER>` is not `0340`:** use `results-m1max-64gb-ollama<VER>/`
  and `results-m5-16gb-ollama<VER>/`. Neither name collides with an existing
  directory; no rename is needed.
- **Branch B, `<VER>` is `0340`:** the M1 Max name collides with the existing
  `results-m1max-64gb-ollama0340/`, which holds untimed `shape_ab-unaided.json`
  files `sweep.sh` would skip. Per the sibling naming rule, rename the
  existing directory to state what it holds and give the new one the same
  dimension:

```bash
cd adaptive_chat_server_dart/tool/model_probes
git mv results-m1max-64gb-ollama0340 results-m1max-64gb-ollama0340-diagnostics
git grep -n 'results-m1max-64gb-ollama0340' -- ':!**/CHANGELOG.md'
```

Fix every hit except dated `CHANGELOG.md` entries and completed plans
(the 15 references listed in Facts, minus the 2 changelog lines): point
them at `results-m1max-64gb-ollama0340-diagnostics`. Then name the new
directories `results-m1max-64gb-ollama0340-sweep/` and
`results-m5-16gb-ollama0340-sweep/` so both hosts' names carry the same
dimension. Run `fvm dart run tool/model_probes/check_results.dart` and
`fvm dart test` after the rename; both must pass before any sweep.

- [x] **Step 4: Write the provenance files**

Each new directory gets a `MODELS.md` in the format of
`results-m5-16gb-ollama0331/MODELS.md`: host line (chip / memory, Ollama
version from `/api/version`, macOS version, model identifier), the pulled
`ollama list` block for the eight models, and one sentence saying the prompt
is `card_system_prompt.txt` at the digest the run files record. Each gets a
`README.md`:

```markdown
# Results: <Apple M1 Max / 64 GB | Apple M5 / 16 GB>, Ollama <VER dotted>

The eight 16 GB candidates, swept 2026-10-DD by `sweep.sh` with
`SWEEP_COOLDOWN=600`, in the fixed order
`granite4.1:8b qwen2.5-coder:7b qwen3.5:9b llama3-groq-tool-use:8b
llama3.2:latest llama3-chatqa:8b nemotron-3-nano:4b granite4.1:3b`, matched
with the <other host> directory `<sibling dir name>`. `shape_ab` calls carry
Ollama's per-call `timings`. <M5 only: `powermetrics.txt` holds GPU frequency
and thermal-pressure samples taken during the sweep.>
```

- [x] **Step 5: Commit**

```bash
git add tool/model_probes/results-*-ollama<VER>*/
git commit -m "measure(probes): provenance for the matched <VER> re-sweep directories"
```

(Branch B also stages the rename and the reference fixes in this commit.)

---

### Task 5: Sweep the M5

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results-m5-16gb-ollama<VER>[-sweep]/<model>/*.json`
- Create: `.../powermetrics.txt`

- [x] **Step 1: Prepare the host**

Plug in power, close other apps, leave the lid open, disable sleep for the
run (`caffeinate` below). Note the room temperature if known.

- [x] **Step 2: Start `powermetrics` in a second terminal**

```bash
sudo powermetrics --samplers gpu_power,thermal -i 10000 \
  -o /tmp/powermetrics-m5.txt
```

`gpu_power` gives GPU active frequency and residency; `thermal` gives the
thermal pressure level. Apple Silicon `powermetrics` does not report die
temperature; record that absence rather than substituting another tool's
reading.

- [x] **Step 3: Run the sweep**

```bash
cd adaptive_chat_server_dart
export SWEEP_RESULTS=tool/model_probes/results-m5-16gb-ollama<VER>[-sweep]
export SWEEP_COOLDOWN=600
caffeinate -i tool/model_probes/sweep.sh granite4.1:8b qwen2.5-coder:7b \
  qwen3.5:9b llama3-groq-tool-use:8b llama3.2:latest llama3-chatqa:8b \
  nemotron-3-nano:4b granite4.1:3b 2>&1 | tee /tmp/sweep-m5.log
```

Expected: about 2.5-3 hours of probes plus 80 minutes of cooldown. The log
shows `>>> COOLDOWN 600s` before each `##### MODEL`, and ends with
`##### SWEEP COMPLETE`.

- [x] **Step 4: Stop `powermetrics` and file it**

Ctrl-C the `powermetrics` terminal, then:

```bash
cp /tmp/powermetrics-m5.txt "$SWEEP_RESULTS/powermetrics.txt"
grep -c 'GPU HW active frequency' "$SWEEP_RESULTS/powermetrics.txt"
```

Expected: a sample count near the sweep length in seconds divided by 10.

- [x] **Step 5: Check the run**

```bash
fvm dart run tool/model_probes/check_results.dart
python3 tool/model_probes/perf_table.py "$SWEEP_RESULTS"
python3 tool/model_probes/perf_table.py "$SWEEP_RESULTS" --phases
```

Expected: `check_results` OK; eight rows; every model's `Timed calls` is
the seeded call count minus one minus its stalls. Any model with more than a
handful of stalls: stop and report before Task 6, with the stalled cases
from its `shape_ab-seeded.json`.

- [x] **Step 6: Commit**

```bash
git add "$SWEEP_RESULTS"
git commit -m "measure(probes): M5 / 16 GB matched re-sweep of the eight candidates"
```

---

### Task 6: Sweep the M1 Max

**Files:**

- Create: `adaptive_chat_server_dart/tool/model_probes/results-m1max-64gb-ollama<VER>[-sweep]/<model>/*.json`

- [x] **Step 1: Same host preparation as Task 5 Step 1.** `powermetrics` is
      optional on this host; if run, file it the same way.

- [x] **Step 2: Run the sweep with the same order and cooldown**

```bash
cd adaptive_chat_server_dart
export SWEEP_RESULTS=tool/model_probes/results-m1max-64gb-ollama<VER>[-sweep]
export SWEEP_COOLDOWN=600
caffeinate -i tool/model_probes/sweep.sh granite4.1:8b qwen2.5-coder:7b \
  qwen3.5:9b llama3-groq-tool-use:8b llama3.2:latest llama3-chatqa:8b \
  nemotron-3-nano:4b granite4.1:3b 2>&1 | tee /tmp/sweep-m1max.log
```

- [x] **Step 3: Check, then commit**

Same checks as Task 5 Step 5, then:

```bash
git add "$SWEEP_RESULTS"
git commit -m "measure(probes): M1 Max / 64 GB matched re-sweep of the eight candidates"
```

---

### Task 7: Derive the figures and record them in a ledger

**Files:**

- Create: `.superpowers/sdd/2026-10-03-matched-resweep/FIGURES.md` (working
  ledger, the pattern the 2026-09-01 plan used; not published)

- [x] **Step 1: Confirm every seeded call is timed**

```bash
cd adaptive_chat_server_dart
for d in tool/model_probes/results-m5-16gb-ollama<VER>* tool/model_probes/results-m1max-64gb-ollama<VER>*; do
  python3 - "$d" <<'EOF'
import json, pathlib, sys
for f in sorted(pathlib.Path(sys.argv[1]).glob("*/shape_ab-seeded.json")):
    calls = json.loads(f.read_text())["calls"]
    untimed = [c["case"] for c in calls if "timings" not in c and "timeout (" not in c["label"]]
    print(f.parent.name, "untimed non-stall calls:", len(untimed))
EOF
done
```

Expected: `0` for every model on both hosts. A nonzero count means an old
file was reused; delete that model's file and re-run that model alone.

- [x] **Step 2: Produce every table the notebook and article will quote**

```bash
M5=tool/model_probes/results-m5-16gb-ollama<VER>[-sweep]
M1=tool/model_probes/results-m1max-64gb-ollama<VER>[-sweep]
python3 tool/model_probes/perf_table.py $M5 --compare $M1
python3 tool/model_probes/perf_table.py $M5 --compare $M1 --phases
python3 tool/model_probes/perf_table.py $M1
python3 tool/model_probes/perf_table.py $M5
```

Paste each output verbatim into `FIGURES.md` with the command above it. Add
each model's seeded and unaided with-history shape scores per host, read
from `shape_ab-seeded.json` / `shape_ab-unaided.json` (the probe prints
`shapes N/25` per condition in its log, and `sync_shape_table.dart`'s
scoring is the reference).

- [x] **Step 3: Write down what the phase split shows, and what it does not**

In `FIGURES.md`, one short paragraph per finding, each naming its figures:

- Prompt ratio and generation ratio per model, M5 ÷ M1 Max.
- Whether generation ratios sit near the 2.61x rated-bandwidth gap, and
  whether prompt ratios sit below 1.0x (the M5 faster on the compute phase).
- The M5's GPU frequency and thermal-pressure range from `powermetrics.txt`,
  and whether either moved between the first and last model.
- Which article 3 caveats this data removes (list them) and which remain
  (same-host reproducibility, the GGUF runner's accelerator use).

Hedge mechanisms; state measured figures plainly.

No commit: `.superpowers/` is a working area.

---

### Task 8: Update `ModelBehavior.md`

**Files:**

- Modify: `adaptive_chat_server_dart/ModelBehavior.md` (new `####` subsection
  at the end of "Performance, by host and runtime", before the next `###`)

- [x] **Step 1: Add the subsection**

Heading states the finding in the notebook's style, for example
`#### Matched Ollama <VER> re-sweep: <prompt/generation finding in one clause>`.
Contents, in this order:

1. Configuration: both hosts, Ollama version, prompt digest, cooldown, model
   order, `--samples 2`, links to both new directories.
2. The cross-host median table (from `perf_table.py --compare`).
3. The phase table (from `--phases`), with one paragraph reading it.
4. Shape scores per host, seeded and unaided, with-history, and how they
   compare with the 0.33.x figures and the `Input.Rating` A/B.
5. Thermal: what `powermetrics` recorded on the M5, and that it does not
   report die temperature.
6. What stays open: same-host reproducibility (one sweep per host), and
   whether the GGUF runner uses the M5's Neural Accelerators.

Do not edit the fifteen-model shape-coverage table or the closed 0.33.x
cross-host table; add a one-line pointer under the 0.33.x cross-host table
to the new subsection.

- [x] **Step 2: Verify and commit**

```bash
cd ..
npm run check:md:chat
cd adaptive_chat_server_dart && fvm dart run tool/model_probes/check_results.dart
git add ModelBehavior.md
git commit -m "docs(chat-server): record the matched <VER> host re-sweep with phase timings"
```

---

### Task 9: Rewrite article 3's figures from the new runs

**Files:**

- Modify: `adaptive_chat_server_dart/blog/article-3-m1max-vs-m5-draft.md`
- Modify: `adaptive_chat_server_dart/blog/README.md` (status row only)

This task is prose. Invoke the **`adaptive-cards-blog-writing`** skill and
follow its Revise mode. The subagent commit exception does not apply:
show the changed prose to the user and wait for confirmation before
committing.

- [x] **Step 1: Replace the tables with the new figures**

- Host table: the Ollama row becomes `<VER>` on both hosts.
- Latency table: the eight rows from Task 7 Step 2, same columns.
- Add the phase table after the latency table (prompt ms, gen ms, both
  ratios), with a one-sentence intro and one sentence of commentary.
- Shape-score table: the new seeded and unaided with-history scores.
- Re-run table: keep it as the historical control, with one sentence saying
  it comes from the 0.33.x runs, or cut it if the user prefers.

- [x] **Step 2: Cut the caveats the new data removes**

Expected removals, each to be confirmed against `FIGURES.md` before cutting:
the two-version note, the eviction limit, the `granite4.1:3b` cascade limit
and footnote, the `qwen3.5:9b` position-0 paragraph, the `llama3.2:latest`
artifact bullet, and the `Input.Rating` "predates" paragraph. Rewrite the
bandwidth subsection from the phase table: it can now state which phase
carries the gap instead of "may".

- [x] **Step 3: Run the blog skill's verification block and show the prose**

Run every command in the skill's Verification section against the article
(length, figure-token diff against the branch point, em dashes, first
person, sentence length, `npm run check:md:chat`). Print the changed
sections to the user. Commit only after the user says to proceed:

```bash
git add blog/article-3-m1max-vs-m5-draft.md blog/README.md
git commit -m "docs(chat-server): article 3 figures from the matched <VER> re-sweep"
```

---

### Final Task: Full verification

- [x] **Step 1: Run the suites and gates**

```bash
cd adaptive_chat_server_dart
fvm dart analyze
fvm dart test
fvm dart run tool/model_probes/check_results.dart
fvm dart format --output=none --set-exit-if-changed tool/ test/ lib/
cd ..
npm run check:md:chat
git status --short
```

Expected: `No issues found!`; all tests pass; `check_results` OK with the
two new directories counted; format exit 0; Prettier clean; a clean tree.

- [x] **Step 2: Report** the commands' output (exit codes, pass counts) per
      `superpowers:verification-before-completion`, then ask the user whether to
      push the branch and open a PR. Do not push without that confirmation.

## Risks

| Risk                                                       | What to do                                                                                                                      |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| One host cannot run the other's Ollama version             | Stop at Task 4 Step 2 and ask; a mixed-version sweep reintroduces the caveat this plan exists to remove                         |
| A pulled tag's digest changed since 2026-08-28             | Record it in `MODELS.md`, tell the user; the comparison is still matched across hosts but not with the 0.33.x archives          |
| `powermetrics` sampler names differ on the installed macOS | Run `powermetrics -h`, pick the samplers that report GPU frequency and thermal pressure, record the command used in the README  |
| A model stalls repeatedly on the new runtime               | Stop and report with the stalled case ids; do not raise the 120 s ceiling (`ModelBehavior.md`: anchor the ceiling to usability) |
| The phase split shows nothing different from the medians   | Record it as measured; the article's bandwidth subsection then says the prompt phase did not offset the gap                     |

## Deliberately out of scope

- Re-sweeping the seven models that do not fit 16 GB.
- Testing whether the GGUF runner uses the M5's Neural Accelerators (needs a
  source read of Ollama's runner or an MLX-vs-GGUF build of one model).
- Repeated sweeps per host for a reproducibility distribution.
- Regenerating the fifteen-model shape-coverage table.

## Execution notes (2026-10-03 to 2026-10-04)

Every task above ran; the checkboxes are ticked where the step was done as
written or with one of the deviations below. Branch
`measure/matched-resweep-phase-timings`, stacked on
`docs/article-3-hardware-table` (PR #116, still open at the time).

- **Version.** Both hosts ran Ollama **0.35.1**, not 0.34.0, so Task 4 took
  branch A: `results-m1max-64gb-ollama0351/` and `results-m5-16gb-ollama0351/`,
  no rename. `results-m1max-64gb-ollama0340/` gained a `HISTORICAL.md` in
  Task 8 because the M1 Max no longer has 0.34.0 installed.
- **Task 5** ran on the M5 by hand, in parallel with Task 6, from the pushed
  branch; its results were pushed to this branch and the M1 Max commits were
  rebased on top. `granite4.1:3b` stalled on 56 of 100 unaided shape calls on
  the M5 (one contiguous block; seeded and cascade arms clean). The run was
  kept and the stall is recorded as a finding rather than re-run.
- **Task 2 was amended twice after the sweeps.** One-token replies (an
  `eval_duration` of 1 µs) are excluded from tokens per second. The prompt
  median is split by **sample index** (`Prompt first ms` / `Prompt repeat ms`),
  not by condition: in 16 of 16 model-host pairs the first time a case's prompt
  is seen is slow and the repeat is a prompt-cache hit, and cold and warm are
  within noise of each other. The plan's "split the median call into its two
  phases" was underspecified on this point.
- **Task 7's ledger** lives at
  `.superpowers/sdd/2026-10-03-matched-host-resweep-phase-timings/figures/`,
  not the path named above.
- **Task 9 went further than the plan.** At the user's direction the article
  now quotes only 0.35.1 figures, and its "Re-running a model on the same
  host" section was cut (the reproducibility caveat became one limit with a
  notebook link; the throttling paragraph moved to the bandwidth subsection
  with the M5 GPU-clock reading). The 16 GB pick stays `granite4.1:8b`, with
  `qwen3.5:9b`'s figures beside it.
- **Prompt phase finding.** Generation ratios are 1.12x to 1.65x against the
  2.61x rated-bandwidth gap; the prompt phase is a cache hit on repeats and is
  material only on `nemotron-3-nano:4b` and `qwen3.5:9b`, which are consistent
  with reprocessing the whole prompt (mechanism not established).
