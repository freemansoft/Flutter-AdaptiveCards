/// The synthetic card-shaped exchange `OllamaResponder` prepends to every
/// request.
///
/// A conversation answered once in Markdown tends to stay in Markdown: once
/// prose is the established format, models keep replying in prose even for a
/// question a card would answer better ("warm-start prose drift", measured in
/// `ModelBehavior.md` under "Multi-turn set — history replay"). Prepending
/// this exchange ahead of the real history — regardless of whether the real
/// history exists — makes a card the conversation's format *before* any
/// prose can accumulate, so there is nothing for a model to drift back
/// toward.
///
/// This was screened as candidate N2 (`--seed-card`) against four other
/// mechanisms — none of which moved the deciding model — and confirmed
/// across six models on the full 25-case set: cold-start shape coverage rose
/// on 6/6, with-history coverage rose on 5/6. It is unconditional (not a
/// flag) because that is what was measured: every candidate that shipped a
/// configuration knob shipped one because the underlying behavior was
/// model-specific (see `reinforceReminder`'s delivery caveat in
/// `tool/model_probes/shape_cases.dart`), and N2 carried no such caveat —
/// prepending two fixed turns needs no per-model gating. The cost is real
/// and unconditional too: every request now spends the tokens for two extra
/// turns, and a `table` reply newly erodes with history present on 4 of the
/// 6 measured models — a nested-shape trade-off the net numbers absorb on
/// most models but do not erase. Full numbers, the erosion pattern, and the
/// thin latency evidence are in `ModelBehavior.md`.
library;

/// The synthetic user turn that opens every conversation sent to Ollama,
/// ahead of any real history.
///
/// Deliberately unrelated to anything a real case or user prompt asks about,
/// so a model cannot pass a measurement by echoing this exchange's subject
/// matter — only its *format* (a bare Adaptive Card element array) is meant
/// to transfer to later turns.
const seedCardUser = 'what timezone should I use for the nightly build?';

/// The card-shaped assistant half of [seedCardUser]'s exchange.
///
/// A bare element array — the shape the card system prompt asks the model to
/// prefer — so the seed models good output, not just "a card happened".
const seedCardAssistant =
    '[{"type":"TextBlock","text":"Pick a timezone for the nightly '
    'build:","wrap":true},{"type":"Input.ChoiceSet","id":"tz","'
    'style":"compact","choices":[{"title":"UTC","value":"+0000"},{'
    '"title":"CET","value":"+0100"}]}]';
