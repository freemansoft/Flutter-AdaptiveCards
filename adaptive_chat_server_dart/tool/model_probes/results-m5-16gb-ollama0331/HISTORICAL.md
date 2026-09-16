# Closed archive

These runs were measured on the Apple M5 (16 GB) under **Ollama 0.33.1**. That
host now runs 0.33.3, so nothing here can be re-run in place: a re-measurement
belongs in `results-m5-16gb-ollama0333/`, and these files keep the asset
digests they were taken with permanently.

`check_results.dart` reads this file's presence — not its text — and reports
stale prompt digests in this directory as notes rather than failing CI. The
figures remain valid for the prompt they name; they are not valid for the
prompt the tree ships today.

Superseded by the `Input.Rating` palette addition on 2026-09-07, which moved
`card_system_prompt.txt` from `4bfa327067f8` to `8cbfde243266`.

The tool-channel runs and the tool-call canaries were deleted on 2026-09-16,
for the reason given in
[`../results-m1max-64gb-ollama0332/HISTORICAL.md`](../results-m1max-64gb-ollama0332/HISTORICAL.md).
This host has no re-measurement: it is not available, so the cross-host canary
comparison is gone rather than superseded. Git history before 2026-09-16 holds
the deleted runs.
