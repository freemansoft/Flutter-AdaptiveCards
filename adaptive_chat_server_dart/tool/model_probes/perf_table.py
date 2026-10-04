#!/usr/bin/env python3
"""Derives ModelBehavior.md's performance table from recorded probe runs.

Every other figure in that file is generated (`sync_shape_table.dart`) or
checked (`check_results.dart`); the performance table was the one still typed
by hand, and it had drifted -- `qwen3.8:27b-nvfp4` read 4.4 s against a
recorded 4339 ms.

The three rules below are the ones that reproduce the published Apple M1 Max
rows, and two of them are easy to get wrong:

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

    python3 tool/model_probes/perf_table.py tool/model_probes/results-m1max-64gb-ollama0332
    python3 tool/model_probes/perf_table.py tool/model_probes/results-m5-16gb-ollama0331 \
        --compare tool/model_probes/results-m1max-64gb-ollama0332
    python3 tool/model_probes/perf_table.py tool/model_probes/results-m5-16gb-ollama0331 \
        --compare tool/model_probes/results-m1max-64gb-ollama0332 --by-probe

`--by-probe` splits the wall clock per probe instead of summing it. It exists
because the summed columns can disagree in a way that looks like an error and is
not: `llama3-chatqa:8b` matches the M1 Max median at 1.0x while its full sweep
goes 3 min to 5, because the median is one greedy probe and the sweep is seven.
Stalls are excluded here -- they measure the ceiling rather than throughput, and
one stalled call at 120 s would swamp a probe that otherwise runs in seconds.

Do not read a probe-class pattern off this without checking it across models. The
greedy/sampled split looks large on `llama3-chatqa:8b` (1.30x against 2.16x) and
nearly vanishes over all eight (mean 1.25x against 1.33x), with two models
running the other way.

`--phases` splits the median call into Ollama's own prompt and generation
timings (`timings` on each `shape_ab-seeded.json` call, recorded from
2026-10), with the prompt median reported separately for the first and
repeat time a case's prompt is seen within a condition: `shape_ab` runs each
case twice per condition (`sample` 0 and 1), and the first run of a prompt
costs Ollama a cache miss while the second is a cache hit. Splitting by
`condition` (cold/warm) instead, as an earlier version of this report did,
does not separate these -- cold and warm are within noise of each other, and
the apparent condition split was an artifact of population size (49 cold
calls versus 50 warm, so the integer-divide median index lands on opposite
sides of the same sample-0/sample-1 gap). Checking `promptEvalCount` against
`promptEvalNs` on a sample of calls suggests the first-sample figure is, for
most models, the uncached tail of the case prompt behind a cached system
prompt; for `nemotron-3-nano:4b` and `qwen3.5:9b` it runs 1.5-4 s, consistent
with the whole prompt being processed rather than only the tail (inferred
from that check, not measured directly -- the mechanism is not established).
The repeat-sample figure is a prompt-cache hit, a lookup cost rather than a
processing one (tens of thousands of tokens/s is a lookup speed, not a
processing speed). Never divide `promptEvalCount` by `promptEvalNs` to get a
rate for this reason. Generation stays pooled across samples: first- and
repeat-sample generation medians are within 6% of each other. Runs recorded
before `timings` existed print `n/a`.
"""

import argparse
import json
import pathlib
import sys

MEDIAN_PROBE = "shape_ab-seeded.json"

# Recognized probe stems (file name without ".json"): the seven standard
# probes plus "shape_ab-channel-tool", the optional eighth. Mirrors
# `expectedProbes` in check_results.dart:37-45 (the eighth is that file's
# `conditionalProbes`, gated on tool support). Keep the two lists in sync by
# hand: Python cannot import the Dart constant.
#
# This decides which files are *known* -- sweep probes or the channel probe
# -- versus a one-off diagnostic to skip and report (prefill_cache_probe,
# gguf_defaults_probe, shape_ab-seeded-* variants, ...). It is an allowlist,
# not a denylist, because a denylist would silently admit every future
# one-off; only an allowlist stays correct as new diagnostics are added.
# Recognizing the channel probe here does not mean it is summed -- see
# CHANNEL_PROBE below, which both read functions still exclude, exactly as
# before this filter existed.
STANDARD_PROBES = {
    "shape_ab-seeded",
    "shape_ab-unaided",
    "cascade_ab",
    "temperature_stress",
    "temperature_matrix",
    "json_format_probe",
    "tool_call_probe",
    "shape_ab-channel-tool",
}

CHANNEL_PROBE = "shape_ab-channel-tool.json"


def is_stall(call):
    """Matches anywhere, not at the start: the shape judge wraps a stalled
    call as `broken: timeout (120s)`."""
    return "timeout (" in call["label"]


def standard_probe_files(model_dir):
    """Known probe files in `model_dir`, plus the one-off diagnostic files
    skipped.

    "Known" includes the channel probe -- callers that must not sum it (both
    `read_model` and `read_model_probes`) filter it out separately, the same
    exclusion this script always applied. Skips are reported by the caller,
    not here, so each can label them with the model directory they came from.
    """
    kept, skipped = [], []
    for path in sorted(model_dir.glob("*.json")):
        (kept if path.stem in STANDARD_PROBES else skipped).append(path)
    return kept, skipped


def report_skipped(model_dir, skipped):
    if skipped:
        names = ", ".join(p.name for p in skipped)
        print(f"{model_dir.name}: skipping non-sweep files: {names}", file=sys.stderr)


def read_model(model_dir):
    total_ms = 0
    stalls = 0
    median_s = None
    model = None
    machines, dates, versions = set(), set(), set()
    paths, skipped = standard_probe_files(model_dir)
    report_skipped(model_dir, skipped)
    for path in paths:
        if path.name == CHANNEL_PROBE:
            continue
        run = json.loads(path.read_text())
        model = run["model"]
        # Sets, not last-wins: a model's probes can straddle two days or two
        # runtimes, and a table that silently reported one of them would hide
        # exactly the provenance this script exists to surface.
        machines.add(run.get("machine"))
        dates.add(run.get("measuredAt"))
        versions.add(run.get("ollama"))
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
        "machine": machines,
        "measuredAt": dates,
        "ollama": versions,
        "median_s": median_s,
        "sweep_min": round(total_ms / 60000),
        "stalls": stalls,
    }


PROBE_ORDER = [
    "json_format_probe",
    "tool_call_probe",
    "temperature_matrix",
    "temperature_stress",
    "shape_ab-seeded",
    "shape_ab-unaided",
    "cascade_ab",
]


def read_model_probes(model_dir):
    """Wall clock per probe, stalls excluded, keyed by probe file stem."""
    out = {}
    model = None
    paths, skipped = standard_probe_files(model_dir)
    report_skipped(model_dir, skipped)
    for path in paths:
        if path.name == CHANNEL_PROBE:
            continue
        run = json.loads(path.read_text())
        model = run["model"]
        out[path.stem] = sum(
            c["ms"]
            for c in run["calls"]
            if c.get("ms") is not None and not is_stall(c)
        )
    return model, out


def read_phases(model_dir):
    """Median prompt and generation time from `shape_ab-seeded.json`, prompt
    split into the first and repeat time each case's prompt is seen.

    `shape_ab` runs each case twice per condition, recording `sample: 0` for
    the first run and `sample: 1` for the second. The first time Ollama sees
    a case's prompt it is a cache miss; the second time it is a cache hit,
    which is why the prompt-ms population is bimodal. Splitting by `sample`
    separates the two clusters cleanly; splitting by `condition` (cold/warm,
    an earlier version of this function) does not, because both conditions
    mix sample 0 and sample 1 roughly evenly (see the module docstring's
    `--phases` paragraph). A call with no `sample` field counts toward
    neither. Generation stays pooled across samples. Never divide
    `promptEvalCount` by `promptEvalNs` to get a rate: a cache hit reports
    tens of thousands of tokens/s, a lookup speed rather than a processing
    one.

    Same population as the median s/call column otherwise: the first call
    (which carries the model load) and stalls are dropped. Ollama reports
    nanoseconds; the report prints milliseconds. Calls recorded before
    `timings` existed are skipped and counted, never read as zero. An
    `unexpected-response` call has `ms` but no `timings`, so Timed calls can
    be below the ms population by that count. A one-token reply has no
    generation interval and Ollama stamps it as a microsecond, so such calls
    stay in the generation-ms median and in Timed calls but are counted in
    One-token calls and excluded from tokens per second.

    Fixture that catches a 1e3-for-1e6 slip in the ns-to-ms conversion (the
    ratio columns would not: a uniform unit error cancels in a ratio and
    only shows up in the absolute ms figures). A `shape_ab-seeded.json` with
    a load call plus three timed calls --
    `sample: 0, promptEvalNs: [400e6, 500e6, 600e6], evalNs: [1e9, 2e9,
    3e9], evalCount: 100` each -- plus a fourth, one-token call --
    `sample: 0, promptEvalNs: 500e6, evalNs: 1000, evalCount: 1` --
    and a trailing stall, read against a `--compare` dir holding the same
    three timed calls at half those prompt/eval values and no fourth call,
    prints exactly:

        | `m` | 500 | n/a | 2000 | 50.0 | 1 | 4 | 2.00x | n/a | 2.00x |

    Prompt-first median 500 ms from [400, 500, 500, 600]; no repeat-sample
    calls, so n/a; gen median 2000 ms from [0.001, 1000, 2000, 3000]; the
    one-token call is excluded from the tok/s median, which stays 50.0 from
    the three 100-token calls; one one-token call; four timed calls; ratios
    against the halved compare dir are 2.00x / n/a / 2.00x.
    """
    path = model_dir / MEDIAN_PROBE
    if not path.exists():
        return None
    run = json.loads(path.read_text())
    prompt_first, prompt_repeat, gen, rate = [], [], [], []
    one_token = 0
    for c in run["calls"][1:]:
        t = c.get("timings")
        if is_stall(c) or not t:
            continue
        pns = t.get("promptEvalNs")
        if pns is not None:
            sample = c.get("sample")
            if sample == 0:
                prompt_first.append(pns / 1e6)
            elif isinstance(sample, int) and sample >= 1:
                prompt_repeat.append(pns / 1e6)
        if t.get("evalNs"):
            gen.append(t["evalNs"] / 1e6)
            if (t.get("evalCount") or 0) >= 2:
                rate.append(t["evalCount"] / (t["evalNs"] / 1e9))
            else:
                one_token += 1

    def med(v):
        return sorted(v)[len(v) // 2] if v else None

    return {
        "model": run["model"],
        "prompt_first_ms": med(prompt_first),
        "prompt_repeat_ms": med(prompt_repeat),
        "gen_ms": med(gen),
        "gen_tps": med(rate),
        "one_token": one_token,
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
    head = (
        "| Model | Prompt first ms | Prompt repeat ms | Gen ms | Gen tok/s "
        "| One-token calls | Timed calls |"
    )
    rule = (
        "| ----- | ---------------- | ----------------- | ------ | --------- "
        "| ---------------- | ----------- |"
    )
    if base:
        head += " Prompt first ratio | Prompt repeat ratio | Gen ratio |"
        rule += " -------------------- | -------------------- | --------- |"
    print(head)
    print(rule)

    def fmt_ms(v):
        # Below 0.5 ms rounds to "0", which reads as an instantaneous call
        # rather than as a sub-millisecond one -- see llama3-chatqa:8b, whose
        # one-token replies land here.
        if v is None:
            return "n/a"
        return "<1" if v < 0.5 else format(v, ".0f")

    def fmt(v, spec):
        return "n/a" if v is None else format(v, spec)

    def ratio(a, b):
        """`a / b`, or `n/a` when either side is None or below 0.5 ms -- a
        sub-millisecond median has no usable ratio, since both sides already
        round to the same "<1" display value regardless of their true
        difference."""
        if a is None or b is None or a < 0.5 or b < 0.5:
            return "n/a"
        return f"{a / b:.2f}x"

    for model, r in sorted(here.items()):
        line = (
            f"| `{model}` | {fmt_ms(r['prompt_first_ms'])} "
            f"| {fmt_ms(r['prompt_repeat_ms'])} | {fmt_ms(r['gen_ms'])} "
            f"| {fmt(r['gen_tps'], '.1f')} | {r['one_token']} | {r['timed']} |"
        )
        if base:
            b = base.get(model, {})
            line += (
                f" {ratio(r['prompt_first_ms'], b.get('prompt_first_ms'))} "
                f"| {ratio(r['prompt_repeat_ms'], b.get('prompt_repeat_ms'))} "
                f"| {ratio(r['gen_ms'], b.get('gen_ms'))} |"
            )
        print(line)


def print_by_probe(results_dir, compare_dir):
    rows = []
    for model_dir in sorted(pathlib.Path(results_dir).iterdir()):
        if not model_dir.is_dir():
            continue
        model, probes = read_model_probes(model_dir)
        if not model:
            continue
        base = {}
        if compare_dir:
            bd = pathlib.Path(compare_dir) / model_dir.name
            if bd.is_dir():
                _, base = read_model_probes(bd)
        rows.append((model, probes, base))
    if not rows:
        sys.exit(f"no recorded runs under {results_dir}")

    seen = [p for p in PROBE_ORDER if any(p in r[1] for r in rows)]
    seen += sorted({p for r in rows for p in r[1]} - set(seen))

    for model, probes, base in sorted(rows, key=lambda r: r[0]):
        print(f"\n{model}")
        for p in seen:
            cur = probes.get(p)
            if cur is None:
                continue
            line = f"  {p:22s} {cur / 1000:8.1f}s"
            b = base.get(p)
            if b:
                line += f"  vs {b / 1000:8.1f}s   {cur / b:.2f}x"
            elif base:
                # A zero baseline is real: tool_call_probe records no per-call
                # ms on either host, so a ratio there would be invented.
                line += f"  vs {(b or 0) / 1000:8.1f}s        n/a"
            print(line)


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
    ap.add_argument(
        "--by-probe",
        action="store_true",
        help="split wall clock per probe instead of summing it",
    )
    ap.add_argument(
        "--phases",
        action="store_true",
        help="split the median call into prompt processing and generation",
    )
    args = ap.parse_args()

    if args.by_probe:
        print_by_probe(args.results_dir, args.compare)
        return

    if args.phases:
        print_phases(args.results_dir, args.compare)
        return

    rows = read_dir(args.results_dir)
    if not rows:
        sys.exit(f"no recorded runs under {args.results_dir}")
    baseline = (
        {r["model"]: r for r in read_dir(args.compare)} if args.compare else {}
    )

    def joined(key):
        seen = {v for r in rows for v in r[key] if v}
        return ", ".join(sorted(seen)) or "unstamped"

    print(f"host(s): {joined('machine')}")
    print(f"measured: {joined('measuredAt')}")
    print(f"ollama: {joined('ollama')}")
    print(f"models: {len(rows)}\n")

    head = "| Model | Median s/call | Full sweep | Stalls |"
    rule = "| ----- | ------------- | ---------- | ------ |"
    if baseline:
        # Append a column, keeping the trailing pipe: stripping it merges the
        # new header into the previous cell and the table stops parsing.
        head += " vs baseline |"
        rule += " ------------ |"
    print(head)
    print(rule)
    for r in sorted(
        rows, key=lambda r: (r["median_s"] is None, r["median_s"] or 0)
    ):
        # Two decimals under a second: at 253 ms vs 248 ms -- a 2% difference --
        # one-decimal rounding straddles 0.25 and prints "0.3 s" against "0.2 s",
        # which reads as 33% and contradicts the ratio column beside it.
        if r["median_s"] is None:
            med = "n/a"
        elif r["median_s"] < 1:
            med = f"{r['median_s']:.2f} s"
        else:
            med = f"{r['median_s']:.1f} s"
        line = f"| `{r['model']}` | {med} | {r['sweep_min']} min | {r['stalls']} |"
        if baseline:
            b = baseline.get(r["model"])
            if b and b["median_s"] and r["median_s"]:
                line += f" {r['median_s'] / b['median_s']:.1f}x |"
            else:
                line += " n/a |"
        print(line)


if __name__ == "__main__":
    main()
