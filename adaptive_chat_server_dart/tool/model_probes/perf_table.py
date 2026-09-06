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
    args = ap.parse_args()

    if args.by_probe:
        print_by_probe(args.results_dir, args.compare)
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
