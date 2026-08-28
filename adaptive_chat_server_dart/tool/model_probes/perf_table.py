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

    python3 tool/model_probes/perf_table.py tool/model_probes/results-m1max-64gb
    python3 tool/model_probes/perf_table.py tool/model_probes/results-m5-16gb \
        --compare tool/model_probes/results-m1max-64gb
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
    model = None
    machines, dates, versions = set(), set(), set()
    for path in sorted(model_dir.glob("*.json")):
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
        head = head[:-1] + " vs baseline |"
        rule = rule[:-1] + " ------------ |"
    print(head)
    print(rule)
    for r in sorted(
        rows, key=lambda r: (r["median_s"] is None, r["median_s"] or 0)
    ):
        med = "n/a" if r["median_s"] is None else f"{r['median_s']:.1f} s"
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
