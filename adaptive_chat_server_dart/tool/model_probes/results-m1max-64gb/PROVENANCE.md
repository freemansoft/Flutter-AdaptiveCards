# Provenance of the Apple M1 Max / 64 GB runs

These 113 runs were recorded 2026-08-20 and 2026-08-21, before probe results
stamped the Ollama version. The `ollama` key is absent from every file here,
and `check_results.dart` leaves a wholly unstamped directory alone for that
reason.

The version is partly recoverable anyway, from the Ollama server logs rather
than from the results. Ollama rotates `server-N.log` on every restart and
keeps a bounded number of them; as of 2026-09-01 the rotated files
`server-1.log` through `server-5.log` retain only one restart that falls
inside the 2026-08-20/21 measurement window — the two earlier restarts of
that window have already been rotated out. `server-5.log` covers
2026-08-21T13:34:28 through 2026-08-22T21:56:20 and reports:

```
time=2026-08-21T13:34:28.331-04:00 level=INFO source=routes.go:1990 msg="Listening on [::]:11434 (version 0.32.14)"
```

This is one of the three restarts the archive's `measuredAt` dates should
bracket, not all three — the other two (expected near 2026-08-20T06:55 and
2026-08-21T07:57) are gone from every log file present on disk. A single
corroborating line is what remains; it is not contradicted by anything else on
disk, since no other server log covers 2026-08-20 or the first half of
2026-08-21.

The same restart shows that server ran on the GPU:

```
time=2026-08-21T13:34:28.727-04:00 level=INFO source=types.go:32 msg="inference compute" id=0 filter_id=0 library=Metal compute=0.0 name=MTL0 description="Apple M1 Max" libdirs="" driver=0.0 pci_id="" type=iGPU total="51.8 GiB" available="51.8 GiB"
```

This rules out a CPU fallback for the one restart the log covers
(2026-08-21T13:34:28 onward), not for the whole archive — the two earlier
restarts are exactly as unrecoverable here as their version, and GPU/CPU
selection is not guaranteed stable across restarts on this host: a later
0.33.2 server on this same machine failed GPU discovery and fell back to CPU
(`library=cpu`, `total_vram="0 B"` in `server-3.log`, restart of
2026-09-01T07:27:29). Nothing on disk says the earlier two archive-era
restarts ran on CPU either — there is simply no log evidence either way for
them.

Recorded here rather than backfilled into the JSON. A result file states what
the probe stamped at the time; this is external evidence about those runs, and
merging the two would make a reconstruction indistinguishable from a
measurement. `results-m1max-64gb-ollama033/` holds the same host re-measured on
a stamped runtime, which is the comparison the version question actually needs.
