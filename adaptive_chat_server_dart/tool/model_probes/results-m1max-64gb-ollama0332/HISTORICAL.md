# Closed archive

These runs were measured on the Apple M1 Max (64 GB) under **Ollama 0.32.14**
and **0.33.2**. That host has since moved to 0.33.3 — see
`results-m1max-64gb-ollama0333/` — so nothing here can be re-run in place.

`check_results.dart` reads this file's presence — not its text — and reports
stale prompt digests in this directory as notes rather than failing CI. The
figures remain valid for the prompt and runtime they name.

Superseded by the `Input.Rating` palette addition on 2026-09-07, which moved
`card_system_prompt.txt` from `4bfa327067f8` to `8cbfde243266`.

The tool-channel runs and the tool-call canaries were deleted on 2026-09-16.
Both were measured against a 70-line `card_tool_prompt.txt` that has since
been deleted: it was never tuned, and pairing it with the tuned
`card_system_prompt.txt` measured the gap between a tuned prompt and a guess
rather than the channel. `card_tool_prompt_matched.txt` replaces it, and
`results-m1max-64gb-ollama0340/` holds the re-measurement. Git history before
2026-09-16 holds the deleted runs.
