# Results: Apple M1 Max / 64 GB, Ollama 0.34.0

Measurements taken on this host under Ollama 0.34.0, distinct from
[`../results-m1max-64gb-ollama0333/`](../results-m1max-64gb-ollama0333/) and
[`../results-m1max-64gb-ollama0332/`](../results-m1max-64gb-ollama0332/) (same
host, Ollama 0.33.3 and 0.33.2) and
[`../results-m5-16gb-ollama0331/`](../results-m5-16gb-ollama0331/) (Apple M5 /
16 GB, Ollama 0.33.1).

## The two arms

This directory exists to measure the tool channel against prose with the
system prompt held fixed, which the 2026-09-01 run in
`results-m1max-64gb-ollama0332/` did not. That run sent
`card_system_prompt.txt` on the prose arm and a 70-line `card_tool_prompt.txt`
on the tool arm. The brief prompt dropped all 21 worked element examples along
with the raw-JSON-emission mechanics a tool call makes false, and it had never
been tuned against anything, so the comparison measured a tuned prompt against
a guess rather than a channel. It has since been deleted; git history before
2026-09-16 holds it.

Produced by [`../tool_channel_arms.sh`](../tool_channel_arms.sh), one model
resident at a time, `--samples 2`, `t=0`, unseeded, cold-start and
with-history:

| File                                 | Channel | System prompt                  |
| ------------------------------------ | ------- | ------------------------------ |
| `shape_ab-unaided.json`              | prose   | `card_system_prompt.txt`       |
| `shape_ab-channel-tool-matched.json` | tool    | `card_tool_prompt_matched.txt` |

`card_tool_prompt_matched.txt` is `card_system_prompt.txt` with only the
emission mechanics rewritten; its element catalogue is byte-identical. A delta
between the two arms is therefore a property of the channel.

A third arm, `shape_ab-channel-tool-both.json`, was measured on 2026-09-16 and
deleted with its prompt. It restored the raw-JSON-emission rules to the tool
prompt to guard the message-body fallback; it repaired 7 malformed calls and
introduced 2, and cost `nemotron-3.5-lightning:30b` 8 tool calls per 100. The
rules guard the fallback and also advertise it.

`tool_call_probe.json` is here for all 15 models, not only the ones that pass
it. The canary now sends the matched prompt too, so which models can answer on
the tool channel is re-measured rather than carried over from the deleted
prompt. Only a `supported` model gets shape arms.

## Reading a tool arm's pass rate

Every call in a tool arm records `toolUsed`. Offering a tool does not oblige a
model to use one, and `shape_ab.dart` judges a reply that arrives in
`message.content` by the prose rules, so such a call can score a pass. A tool
arm's `n/25` is therefore a statement about the tool channel only for the
calls where `toolUsed` is true; the rest measure the message body under a
tool-channel system prompt. Read the two apart before quoting a figure.

This also bounds what the `malformed` bucket means. A tool call cannot carry
malformed JSON, because Ollama returns its arguments decoded. Malformed calls
in a tool arm are fallbacks: the model ignored the tool, wrote card JSON as
text, and got it wrong. `card_tool_prompt_matched.txt` drops the emission
mechanics that protect that path, since a tool call makes them false, so a
fallback under it malforms where the prose arm's would not.

Neither arm is seeded. The seed card is a synthetic assistant turn holding raw
card JSON, which is a prose-channel artifact, so the tool arms cannot carry it
and `shape_ab.dart` refuses the combination.
