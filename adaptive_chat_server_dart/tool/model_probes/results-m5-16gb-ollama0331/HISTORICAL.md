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
