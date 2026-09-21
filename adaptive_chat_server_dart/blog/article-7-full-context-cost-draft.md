# A full context costs three of eight local models 5 to 7 of 25 card test cases

In [`freemansoft/Flutter-AdaptiveCards`](https://github.com/freemansoft/Flutter-AdaptiveCards) a demonstration Dart chat server hands a question to a local Ollama
model. It asks for the answer as Adaptive Card JSON, a strict,
closed-vocabulary schema that a Flutter client renders as interactive UI
rather than as text. Probes in that repository put the same questions to
different local models.
[`context_fill_probe.dart`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/tool/model_probes/context_fill_probe.dart)
is the probe that produced every figure in this article. It runs 25 test cases,
one question each. A test case passes only if the reply used an element type
that would answer the question. Every other probe in that set had been asking
into a nearly empty window. That window holds a system prompt, one question,
and at most a short canned exchange showing the model the shape of a card.

The probe stands in for a long conversation by filling three quarters of the
window with generated text. It measured eight models twice, once with no
history at all and once carrying roughly 48,500 tokens of prompt for seven of
the eight. The host was an Apple M1 Max with 64 GB, under Ollama 0.33.3, with
two empty-window cells from a later 0.34.0 run. Five models move by three cases
or fewer out of 25, in both directions. Three lose 5, 5 and 7 cases. Each of
those three fails a different way, so no single validation check catches them.
The losses also reorder the models: one that outscores another on an empty
window trails it on a full one.

Every figure is transcribed from
[`ModelBehavior.md`](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md),
the lab notebook in that repository.

## Terms used in this article

| Term                    | What it means here                                                                                                                                                                                                                                                                                                                                                                                               |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Window**              | The context window: the number of tokens Ollama allocates to one request, which holds the system prompt, the history and the question.                                                                                                                                                                                                                                                                           |
| **Shape score**, `n/25` | 25 test cases, one question each, paired with the Adaptive Card element types that would answer it. Scored on one thing: did the reply use one of them? What it measures is **shape coverage**, not accuracy, and the article reports a change in it as cases gained or lost out of 25. A model can be entirely correct in prose and score low. One of the 25 is a negative control where a card is the failure. |
| **The judge**           | `judgeShape`, the function that assigns each reply one verdict. It is the same judge the repository's other shape probes use, so the verdicts below are comparable with theirs.                                                                                                                                                                                                                                  |
| **`--samples 1`**       | Each case runs once and is scored on that one reply. Most figures in the notebook are `--samples 2`, where a case passes only if both runs pass, so the noise floor here is looser than the series' usual ±1.                                                                                                                                                                                                    |
| **Filler**              | A block of deterministic nonsense the probe prepends as conversation history, sized to a token target, so a run can ask what a model does with a window that is mostly used.                                                                                                                                                                                                                                     |
| **`prompt_eval_count`** | The token count Ollama reports for the prompt it actually evaluated. It is how each run below proves it delivered the history it meant to.                                                                                                                                                                                                                                                                       |
| **Empty window**        | The same 25 cases with no history: the card system prompt and the question, about 4,000 tokens depending on the tokenizer. It is the comparison column throughout, and it is the condition nearly every local-model score published elsewhere appears to be measured under.                                                                                                                                      |
| **Full window**         | The same 25 cases with a filler history sized so the prompt fills about three quarters of the window Ollama allocates: roughly 48,500 of 65,536 tokens, or 24,721 of 32,768 for `qwen2.5-coder:7b`.                                                                                                                                                                                                              |

**Every run below verified its fill size**, and reports the token count it
actually delivered in the **Prompt tokens, full** column. Tokenizers differ
enough that a filler sized in characters can overflow a window and be discarded
whole, with no error. The companion article "Ollama silently drops a history
message larger than its context window" covers that defect and its fix.

## Three of eight models lose 5 to 7 of 25 cases on a full context window

The probe gave each model a filler calibrated to its own tokenizer, sized to
fit the window Ollama actually allocates it. **Empty window** and **Full
window** hold the shape score under each condition. Compare them row by row.

| Model                        | Empty window | Full window | Prompt tokens, full | Window, full |
| ---------------------------- | ------------ | ----------- | ------------------- | ------------ |
| `qwen3-coder:30b`            | 18/25        | 20/25       | 48459               | 65536        |
| `qwen3.6:27b-coding-nvfp4`   | 23/25\*      | 20/25       | 48535               | 65536        |
| `qwen2.5-coder:7b`           | 22/25        | 19/25       | 24721               | 32768        |
| `qwen3.5:9b`                 | 18/25        | 16/25       | 48537               | 65536        |
| `qwen3.8:27b-nvfp4`          | 21/25\*      | **16/25**   | 48539               | 65536        |
| `nemotron-3.5-lightning:30b` | 20/25        | **13/25**   | 48600               | 65536        |
| `nemotron-3-nano:30b`        | 17/25        | **12/25**   | 48611               | 65536        |
| `nemotron-3-nano:4b`         | 8/25         | 6/25        | 48559               | 65536        |

\* These two builds were measured on an empty window for the first time on a
later run, under Ollama 0.34.0. Their filled and empty figures therefore come
from different runtimes. The pairing holds because the filled run itself
repeats on 0.34.0. It returns 16/25 for `qwen3.8:27b-nvfp4` and 20/25 for
`qwen3.6:27b-coding-nvfp4`, matching all 25 verdicts case for case. Until that
run this column held a reading for both builds taken under an already-full
window, and both were read as unaffected.

The other six rows read the empty-window figure from the pre-calibration sweep,
under Ollama 0.33.3. A filler was sent there, overflowed the allocation, and
Ollama discarded it whole, so those runs still reached the model with no
history. Every empty-window run asked for a 35,851-token window, against 65,536
for the filled runs, so the two arms differ in window size as well as in
history. The exception is `qwen2.5-coder:7b`, whose trained window caps both
arms at 32,768.

```mermaid
xychart-beta horizontal
    title "Shape cases gained or lost when the window is filled, out of 25 (qwen2.5-coder:7b on half the tokens)"
        x-axis ["nemotron-3.5-lightning:30b", "nemotron-3-nano:30b", "qwen3.8:27b-nvfp4", "qwen2.5-coder:7b", "qwen3.6:27b-coding-nvfp4", "qwen3.5:9b", "nemotron-3-nano:4b", "qwen3-coder:30b"]
        y-axis "Cases, filled window minus empty" -8 --> 3
    bar [-7, -5, -5, -3, -3, -2, -2, 2]
```

The three bars at minus five and beyond are the finding. The other five are
single-sample runs moving by two or three cases in both directions, which is
noise.

`nemotron-3.5-lightning:30b` loses 8 of the 20 cases it passed on an empty
window and wins 1 back, for a net of 7. `nemotron-3-nano:30b` loses 8 of its 17
and wins 3 back, for 5. `qwen3.8:27b-nvfp4` loses 7 of its 21 and wins 2 back,
for 5. The table and the chart carry the net figures. The model, the 25
questions and the judge are the same in both arms. `qwen3-coder:30b` gains two
cases under the same load.

`qwen2.5-coder:7b`'s minus three does not belong beside the others. Its trained
window caps it at 32768, so its filler is smaller too. It runs three quarters
full like every other model, but on 24,721 tokens rather than about 48,500. Its
bar comes from half the token load.

Both Nemotron losses reproduced at a second prompt size. An earlier run of the
same control, before the filler was calibrated per tokenizer, carried about
42,600 tokens for the two of them and returned 13/25 and 12/25. The run above
carries 48,500 and returns 13/25 and 12/25 again. `qwen3.8:27b-nvfp4`
reproduces the same way from a different archive, the fixed-filler sweep: 17/25
at 42,542 tokens and 16/25 at 48,539, against 21/25 empty. Two prompt sizes
landing on the same counts is a stronger reading than either alone. None of the
Qwen movements reproduce that way.

A later run repeated three of these rows on a second machine, a 16 GB Apple M5,
on the same Ollama 0.33.3. Those three are every model in the eight-row table
that a 16 GB host can hold.

| Model                | Prompt tokens, full | M1 Max, full window | M5, full window |
| -------------------- | ------------------- | ------------------- | --------------- |
| `nemotron-3-nano:4b` | 48559               | 6/25                | 6/25            |
| `qwen3.5:9b`         | 48537               | 16/25               | 16/25           |
| `qwen2.5-coder:7b`   | 24721               | 19/25               | 20/25           |

The prompt counts are identical to the digit and two of the three scores are
unchanged. One case across three models is the noise floor. Identical prompt
counts are expected, since a tokenizer is a property of the model and not of the
machine. The scores come from generated replies, and they held.

## The three models that lose 5 to 7 cases fail in three different ways

A lost case is not one thing. Sorting each run's 25 verdicts by what the judge
said turns the losses of 7, 5 and 5 cases into three different problems. The
judge assigns one of five failure verdicts:

- `prose`, a reply with no card in it.
- `no-input`, a valid card that shows something where the case asked it to
  collect something.
- `wrong-shape`, a card using the wrong element.
- `broken`, a reply the probe could not score as a card at all, either because
  it did not parse or because it never finished.
- `unwanted-card`, a card returned for the one case that asks for prose. It
  appears once in the table below.

Each cell below reads empty window first, then full.

| Model                        | Shape score | `prose`     | `no-input` | `wrong-shape` | `broken`   |
| ---------------------------- | ----------- | ----------- | ---------- | ------------- | ---------- |
| `nemotron-3.5-lightning:30b` | 20 to 13    | **1 to 10** | 1 to 0     | 0 to 0        | 3 to 2     |
| `nemotron-3-nano:30b`        | 17 to 12    | 0 to 0      | **4 to 8** | 2 to 3        | 2 to 2     |
| `qwen3.8:27b-nvfp4`          | 21 to 16    | 2 to 2      | 0 to 0     | 1 to 0        | **0 to 7** |
| `qwen2.5-coder:7b`           | 22 to 19    | 0 to 3      | 2 to 1     | 1 to 2        | 0 to 0     |
| `nemotron-3-nano:4b`         | 8 to 6      | 14 to 14    | 0 to 0     | 2 to 3        | 1 to 2     |

Each row sums to 25 in both arms, except `qwen3.8:27b-nvfp4`'s empty-window
figures, which sum to 24 because its twenty-fifth verdict is that
`unwanted-card`.

`nemotron-3-nano:4b`'s `prose` count does not move, 14 to 14, because it was
already answering 14 of 25 cases in prose on an empty window. Its two lost
cases are ordinary single-sample movement, not an effect of the full window.

`qwen2.5-coder:7b` is the one hint that the loss starts below 48,500 tokens. It
reverts to prose on three cases while carrying 24721 tokens, three quarters of
its own smaller window.

`nemotron-3.5-lightning:30b` **stops producing cards**. All eight cases it
loses come back as prose. A ninth comes from the case it had answered with a
static `TextBlock`, which is why its `prose` column reads 1 to 10. On an empty
window it answered in prose once in twenty-five.

`nemotron-3-nano:30b` keeps producing cards and **replaces inputs with static
text**. It substitutes on eight cases with the window full, against four when
empty, and every one is valid card JSON. Seven of the eight put a static
`TextBlock` where the question asked for an interactive input:

- `got {TextBlock} want {Input.Time}`, where the question asked for a time.
- `got {TextBlock} want {Input.ChoiceSet}`, where it asked the reader to pick
  from a set.
- `got {TextBlock} want {Input.ChoiceSet, Input.Toggle}`, where it asked for a
  yes or no.

Each case asks the model to collect something, and it displays something
instead. Its other verdicts do not all parse. Two replies in each arm are
`broken`, so the substitution is what changed rather than the only thing
failing.

`qwen3.8:27b-nvfp4` picks the right elements and **stops finishing its
replies**. Its `broken` count goes 0 on an empty window to 7 on a full one, and
those seven are not one failure. Four ran past the probe's 180-second ceiling
and were scored as stalls; three returned a body that does not parse as JSON.
`qwen3.6:27b-coding-nvfp4` goes 2 to 5 on the same verdict. It gains stalls and
no malformed bodies, on three of the four cases that stalled on
`qwen3.8:27b-nvfp4`.

```mermaid
flowchart TD
  R["Reply to a card question,\nwindow full"] --> T{"did the reply\narrive at all?"}
  T -- "no: ran past 180 s\nqwen3.8:27b-nvfp4, 4 cases" --> STALL["caught only by a timeout,\na retry runs the same risk"]
  T -- yes --> D{"does the reply parse\nas a card?"}
  D -- "no: answered in prose\nnemotron-3.5-lightning:30b, 1 to 10" --> CAUGHT["caught by a parse check"]
  D -- "no: body does not parse\nqwen3.8:27b-nvfp4, 3 cases" --> RETRY["caught by a parse check,\nand a retry is a fresh sample"]
  D -- yes --> E{"is the element the one\nthe question asked for?"}
  E -- yes --> OK["card rendered as asked"]
  E -- "no: TextBlock where an Input.* belongs\nnemotron-3-nano:30b, 4 to 8" --> BLANK["passes every structural check,\nno retry fires,\nreaches the user as a screen\nthat cannot be filled in"]
  style OK fill:#6c6,stroke:#060,color:#000
  style CAUGHT fill:#fc6,stroke:#960,color:#000
  style RETRY fill:#fc6,stroke:#960,color:#000
  style STALL fill:#f66,stroke:#900,color:#000
  style BLANK fill:#f66,stroke:#900,color:#000
```

The differences decide which defense works. The three models produce four kinds
of failure, because `qwen3.8:27b-nvfp4`'s splits in two. A check that asks
whether the reply parsed as a card catches two of the four. It sees the model
that reverts to prose and the bodies that do not parse, and an application that
renders cards has to run that check anyway. That check does not see a stall,
which needs a timeout of its own. Nor does a retry help there, since the
request already ran 180 seconds under a full window. A well-formed card with
the wrong element type passes the parse check and triggers no retry at all. It
reaches the user as a screen that renders correctly and cannot be filled in.
Catching that one means validating the reply against what was asked for, not
just against the schema.

The `nemotron-3.5-lightning:30b` and `nemotron-3-nano:30b` patterns look like
weakening instruction adherence over a long context. Each is specifically a
failure to follow the system prompt. One ignored the instruction to answer as a
card, the other the list of element types the prompt allows. Ordinary question
answering is intact in both, since a prose reply and a `TextBlock` card both
answer what was asked. `qwen3.8:27b-nvfp4` does not fit that account. A reply
that stalls or stops parsing is a generation failure rather than an instruction
ignored, and it is the pattern both `nvfp4` builds show. These runs do not test
either mechanism. Establishing one would mean moving the card instruction to a
different position in the prompt. The alternative is sweeping the fill across
sizes to see whether the loss scales, which the M5 run below does for three
other models. Neither run covers these two.

## Two models swap places between an empty window and a full one

Score on an empty window does not predict the score on a full one. On an empty
window `nemotron-3.5-lightning:30b` scores 20/25 and `qwen3.5:9b` scores 18/25.
On a full one the order reverses, 13/25 against 16/25.

A leaderboard, or a local benchmark that asks short questions, ranks models on
the empty-window column. For a chat application that is the wrong column, and a
published score does not say which way a model moves when the window fills.

## Four checks for a chat application that fills its window

Each check below follows from one of the findings above.

| Check                                                       | Why                                                                                                                           |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Measure at the context length you will run at               | Three of eight models here lose 5 to 7 of 25 cases on a full window, and the empty-window score does not predict which three. |
| Validate the reply against the request, not just the schema | A well-formed card with a `TextBlock` where an input belongs passes every structural check and fails the user.                |
| Give a card request a timeout of its own                    | Four of the seven cases `qwen3.8:27b-nvfp4` loses never returned inside 180 seconds.                                          |
| Re-measure after a model swap, not just after a prompt edit | The three models that lose here sit beside five that hold, on the same prompt and a fill sized to each model's own window.    |

## Two caveats on all of it

Every figure is a single-sample run. A movement of two or three cases is noise,
and only the two five-case losses and the seven-case one are large enough to
read.

The shape of the loss is only partly measured. A later run on that same M5 took
the three models it can hold to a third fill level. It held the window constant
for the two filled levels, and found no threshold. The three models' shape
scores, added together, run 47/75 near-empty, 42/75 half and 42/75 full. So the
cost is neither proportional to how full the window is nor a cliff at some
particular depth. One qualifier applies to the first step. The near-empty
reading comes from an earlier uncalibrated archive, at a smaller allocated
window for two of the three models, rather than from a matched control. The
five-case fall between it and half fill is therefore not established, and
settling it needs `--samples 2` and more models. No 30-billion-parameter
Nemotron build fits a 16 GB host, so how the loss scales with fill is untested
on the two models that lose the most.

The repository is
[https://github.com/freemansoft/Flutter-AdaptiveCards](https://github.com/freemansoft/Flutter-AdaptiveCards),
and the lab notebook these figures are read from is
[https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md](https://github.com/freemansoft/Flutter-AdaptiveCards/blob/main/adaptive_chat_server_dart/ModelBehavior.md).
