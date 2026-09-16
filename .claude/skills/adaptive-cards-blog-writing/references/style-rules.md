# Style rules for the blog series

The full rules behind the checklist in `SKILL.md`. Each rule carries its reason,
because most rules have edge cases and the reason decides them. Examples come
from real drafts. Figures and series-wide names are governed by the Figures and
Terms and units sections of `adaptive_chat_server_dart/blog/README.md`, not by
this file.

## Contents

1. Verifying claims
2. Terminology
3. Describing mechanisms
4. Openings
5. Headings and titles
6. Terms tables and definitions
7. Register
8. Diagrams and images
9. Cross-article references
10. Attribution
11. Presentation

## 1. Verifying claims

A reader cannot check a sentence against the repo, so every sentence about a
mechanism, a default, a flag, or a model is a claim the article vouches for.

- **Check mechanisms and constraints in the source before writing them.** Read
  the function, the argument parser, or the request builder. Article 4 said
  the tool channel "cannot be seeded". `shape_ab.dart` refuses `--channel tool`
  unless `--no-seed-card` is passed, and its error message gives the reason.
  Citing what the code enforces is stronger than asserting it, and reading the
  parser showed that the seed flag defaults to on, which the first rewrite got
  wrong.
- **Model properties come from the notebook or a model card, not from memory.**
  The notebook describes `qwen3-coder:30b` and `nemotron-3-nano:30b` as the same
  architecture class, 30B total and 3B active. A clarifying edit turned that
  into "same LLM architecture", which the evidence does not support. Say what
  was measured, here the size class, and leave the rest untested.
- **Clarifying a claim must not strengthen it.** A rewrite for plainness states
  the same claim. "The chat template is the better predictor" became a heading
  saying it "predicts win or loss", while the evidence was one pair of builds
  scored by a different probe. When cutting or rewording a sentence, check
  whether it was the paragraph's only hedge: removing a caveat can silently
  promote an inferred mechanism to an established one.
- **A definition must fit every row of the table it labels.** Test each row.
  The notebook says a model is a win "only if" the tool channel never made it
  worse. Restating that as "a win if it never made it worse" made `qwen3.6`
  (+1, 0) a win in a table that labels it unaffected. A necessary condition is
  not a sufficient one.
- **Keep measured and inferred apart, in the text and when answering questions
  about it.** Asked why the tool channel lost on half the models, the answer
  separates the per-call accounting (measured), the mechanism (an inference
  from labels), and what was never run (thinking-on). The article's wording
  carries the same split: "appears to favor", "on the evidence of one pair".
- **Report a confirmed narrow hypothesis as confirmed, and the net result
  separately.** Malformed JSON going to zero was the expected effect and it
  held. Four losses were a separate result. Neither makes the channel "a bust"
  or "a success", and a title or summary that implies either misreports both.

## 2. Terminology

Most of the rewriting these drafts needed was a term doing two jobs at once, or
two terms doing one job.

- **One name per concept, taken from the code or API.** Article 4 used "arm" and
  "channel" for the same thing. Ollama's API has no name for it: the reply is in
  `message.content` or in `message.tool_calls`. The probe's flag is `--channel`,
  so the article uses "channel" and never mentions the dropped synonym, which
  the reader does not need.
- **Qualify a vendor-specific mechanism by vendor.** Write "the Ollama tool
  channel" when the mechanism is Ollama's; a general mechanism stays
  unqualified. Use the qualified form in the title and at the first mention in
  each `##` section, then the short form. Prefixing every occurrence repeats the
  vendor name twenty times in one article. Leave link text that quotes another
  document's heading as it is, because it has to match that heading.
- **Name the actor precisely.** "Which the chat server parses", not "which the
  server parses", in a series that also has a probe, a runtime, and a Flutter
  client.
- **Say what kind of thing a term is.** "LLM architecture" rather than
  "architecture". "A chat template ships with the model build, in the same
  download as the weights, but it is neither the weights nor the architecture."
  A reader who cannot tell whether something lives in the weights, the build,
  the runtime, or the probe cannot follow a claim about it.
- **Restate with the defined vocabulary.** A bucket defined as `wrong-shape` is
  not called "shape regressions" two paragraphs later.
- **Make referents explicit.** "The measured value of the tool channel", not
  "the measured value".

## 3. Describing mechanisms

- **Give direction and data.** Say what the request body carries, what the
  response carries, which field holds the result, and in what form. "Declare a
  function and the model answers by calling it" let a reader picture the
  harness routing the model's output into `tool_calls`. The fix said that the
  request body declares the function and its schema as data, that nothing ever
  runs the function, and that the response carries the card in
  `message.tool_calls[0].function.arguments`, normally already decoded.
- **Say that a declared thing is data when it is.** A function declaration in a
  request body is not a callback, and "the request declares" left that open
  until it became "the request body declares".
- **Say why a baseline or comparison was chosen, and what rules out the
  alternative.** The tool channel is scored against unseeded prose because the
  seed is a prose-channel artifact, and the probe refuses to combine it with the
  tool channel.
- **Say whether alternatives are exclusive, and where each one applies.** "The
  probe uses one channel for a whole run, and the server uses only the prose
  channel" stops a reader inferring a runtime fallback from a diagram with two
  branches.

## 4. Openings

**Every article is standalone.** A reader arrives from a search result or a
single link, not from article 1, and the articles are read in no fixed order.
Nothing may depend on another article having been read: each one names the
project, what the model is asked for, and what renders the reply, and expands a
term the first time that article uses it. The ownership map in the README
governs which article carries a topic in full. It does not license leaving a
reader without the setup needed to read the article they opened.

**Open with a framing paragraph, then the finding.** The first paragraph says
what the thing is, meaning what the project does, what the model is asked for
and what happens to the answer, before any figure or verdict appears. A lead
that opens on the finding asks the reader to weigh a claim about a system nobody
has described to them yet. Article 4 once opened on "moving the card out of the
message body and into the arguments of a function call drove malformed JSON to
zero", which names a mechanism, two channels, and a failure family to a reader
who has not yet been told that the server asks a model for card JSON at all.

The framing paragraph carries the setup itself rather than announcing it (see
Register on "the frame, briefly"), and two or three sentences is enough.
Framing first is an ordering rule, not a reason to open slowly: the finding
follows immediately, in the paragraph after the setup lands.

**At least one intro paragraph sits between the `#` title and the first `##`
heading.** It is the background: what the project is, what the model is asked
for, what renders the reply, and the question the article answers. A reader who
arrived from a search result needs all four before the first heading makes a
claim. Filing that paragraph under the first `##` puts general background
beneath a specific heading and leaves the title standing alone above nothing.
Pose the question as a question, or let the finding answer it; do not announce
it with "This article asks" (see Register).

**The setup the finding depends on belongs in the intro, even ahead of a terms
table.** Article 4's explanation of the tool channel first sat under its first
`##`, which left the intro describing only one of the two routes the article
compares. A terms table defined later is not a reason to hold the setup back.

## 5. Headings and titles

- **A heading states a finding, not a verdict, and gets re-derived when the
  section beneath it changes.** "None of this was needed to ship the demo"
  outlived the paragraphs that made that claim by one revision, and a heading
  promising three test sets sat over forty lines about something else.
- **One finding per heading.** Two findings joined by "and" become two sections,
  or the second clause moves into the section's first sentence.
- **No clause that reads as an extra entity.** "The same code scores both
  channels, against the unseeded prose run" read as a three-way comparison,
  because the unseeded prose run is one of the two channels. "Both channels are
  judged by the same code, against unseeded prose only" does not.
- **Concrete words, not constructions that read as machine-written.** Two
  patterns do: a gerund subject acting on an abstract noun ("Bucketing the
  failures resolves the contradiction"), and a personified abstraction ("The
  channel hides what it does not remove"). Name the thing instead: "Every
  failed call, bucketed by its label"; "The Ollama tool channel converts
  detected failures into silent ones". The same test applies to sentences.
- **A heading does not repeat its section's bold first sentence.** When a
  heading is rewritten to state the finding, rewrite the first sentence so it
  adds information.
- **Titles get a paraphrase test.** Write down how a hurried reader would
  restate the title, then fix whatever the title lets them believe that the
  article does not support. "Drove malformed JSON to zero" invited "always
  generated valid JSON", which the decline counts contradict. "Lost half the
  models" reads as models lost, where "lost on half the models" does not.
  Dramatic verbs such as "crushed" fail the register as well.
- **A title change updates the README.** The status table quotes each title;
  grep the repo for the old one.

## 6. Terms tables and definitions

- **A dense article can carry a "Terms used in this article" table** after the
  opening, as articles 3 and 4 do. Table rows do not count against the length
  cap, so the table is also cheap.
- **Define each term once.** A term defined in the terms table is not defined
  again in the body. A term defined beside its own table, such as a bucket list
  or a derived column, stays there and is left out of the terms table.
- **Series-wide naming** (conditions versus test sets, one unit per quantity,
  `n/m` only for fractions, glossing probe identifiers) is in the README under
  Terms and units.
- **After moving or deleting a section, check every "next section", "above", and
  "below".** Article 4's terms table said "see the next section" after a
  reordering had put the explanation two sections away.

## 7. Register

The repo's documentation-tone rules, as in CLAUDE.md: state results plainly,
replace superlatives with the figure they stand for, reserve bold for a
section's load-bearing claim and for figures, hedge inferred mechanisms, and end
on the last factual sentence.

Counts are measured; the explanation for them usually is not. Report negative
results as plainly as wins. Articles 2 and 4 are substantially negative results
and they must not read as apologies.

**Write a technical blog post, not a research paper.** Active voice, sentences
of about 12 to 20 words, and one idea per sentence. The published posts on the
target blog are the register to match. A paper hides the actor behind a passive
("eight models were measured", "the filler is sized in characters", "that group
was written up as unexplained"); a post names it. Do not name it as a person.

**No first-person singular.** No "I", "me", or "my" anywhere in an article, even
though the blog's older, hand-written posts use them. An article drafted with an
agent's help cannot say "I measured" without the reader wondering whether the
author or the model is speaking, so the articles drop the question entirely.
"We" and "our" are allowed, because they read as the project speaking; article
2's published title is "We tried 14 levers". Prefer the thing that acted over
either pronoun: the probe sizes the filler, the sweep omitted the unload step,
the server log shows the generation kept running, the notebook records the run
as cascade-damaged. Where nobody in particular acted, "is still open" or "has no
explanation yet" replaces "I cannot say". Imperatives are fine ("check
`ollama ps`", "dump the bytes"), and "you" is fine where the reader is the one
acting.

**No em dashes as punctuation.** A dash setting off a clause reads to many
readers as a machine-authored tell, so the published articles carry none.
Restructure the sentence rather than dropping a comma into the same slot, which
leaves a dash-shaped sentence behind: a paired aside becomes commas or a
sentence of its own, and a trailing dash becomes a period or a colon depending
on whether what follows restates or expands. "The obvious repair — tell the
model harder not to write anything after the card — did not work" becomes two
sentences: "The obvious repair was to tell the model harder not to write
anything after the card. That did not work." A definition wedged between a
subject and its verb moves out to its own sentence. Editing passes reintroduce
dashes easily, so count them after every pass.

The exception is a table cell, where an em dash may stand in for a value that
does not exist. Prefer `n/a` wherever it reads correctly, and reserve the dash
for cells `n/a` would misdescribe.

**No amplifiers and no closing flourish.** Cut "exactly", "just", "even",
"specifically", "materially", "without exception". Cut a sentence built for
effect rather than information, such as "Zero malformed JSON was never zero
broken cards", and end the section on its last factual sentence. Do not repeat
a sentence verbatim in two sections.

Three paper habits to convert on sight:

- **The agentless passive.** Rewrite with the probe, sweep, server, runtime, or
  notebook as the subject.
- **Announcing the article's question.** "This article asks what changes when
  the window is full" becomes the question itself, or the finding.
- **The defensive pair.** "checked rather than assumed", "measured rather than
  inferred", "not a finding either way". Keep the hedge, drop the contrast: say
  what was checked. A pair that carries real information, such as "a
  correctness requirement, not a performance tip", may stay.

Habits to cut on sight, all of which survived into first drafts:

- **Rebutting an objection no reader raised.** "not a framing choice", "stated
  as a requirement, not as advice", "three parts, not two". Assert the thing;
  the contrast is imaginary.
- **Narrating the article's own rhetoric.** "The obvious doubt that raises is
  worth answering here", "The pairing rule carries weight, so it is worth
  stating". Answer the doubt or state the rule; do not announce that you are
  about to.
- **Announcing the setup instead of giving it.** "The frame, briefly". Never
  write _the frame_ in an article. Open the paragraph with the setup itself:
  what the project is, what the model is asked for, what renders the reply.
- **An ordinal implying an enumeration the text never made.** "a fourth set",
  "splits the roster a fourth way". The reader stops to count and finds no
  list. Name the thing instead.

## 8. Diagrams and images

- **A diagram says what the prose says, in the prose's names.** Label a probe's
  alternatives with the names the article uses ("prose channel", "tool
  channel"), not with command-line flags, and do not label a server path with a
  probe flag.
- **Draw exclusive alternatives as a branch.** Use a decision node with one
  labelled edge per alternative, and say in the node or the lead-in that only
  one is taken. A box with two arrows out reads as a pipeline or a fallback.
- **Mermaid is for the draft; Blogger needs an image.** Render the fence to a
  PNG before publishing (see the Publish mode in `SKILL.md`). Articles 1 and 2
  use screenshots from the demo client, saved as `blog-N-<name>.png` beside the
  drafts.
- **Image and chart placeholders are HTML comments** describing what the visual
  should show, including any data it needs. Article 3 no longer has one: its
  chart is a mermaid block carrying the eight ratio pairs, which
  `to_blogger.dart` emits as preformatted source, so it has to be rendered to
  an image before publishing.

## 9. Cross-article references

The ownership map in the README decides _what_ defers. How a deferral is written
is a separate matter, and the drafts got it wrong the same way repeatedly.

- **A deferral is a sentence with a verb, not an equation.** "which seven, and
  what the smaller machine costs, is the two-host article" equates a question
  with a document. Write "A later article names those seven and measures what
  the smaller machine costs."
- **Verify a claim about a sibling article against that article.** A draft
  called `prompt_ab.dart` "the tuning article's instrument"; article 2 uses it
  once, and its evidence is mostly `shape_ab.dart`. A pointer is a factual
  claim.
- **Do not close a section or an article with a bare deferral paragraph.**
  Listing what the next article covers duplicates the README and ends the piece
  on someone else's material. End on the last factual sentence.

## 10. Attribution

Three placements per article, because a reader who stops early should still be
able to reach the source:

1. **First screen.** Name and link the repo.
2. **Beside the artifact under discussion.** A reproduced table needs its source
   anchor next to it, not in the closing paragraph.
3. **Close.** The repo and the notebook, both URLs spelled out.

**All links are absolute GitHub URLs.** Repo-relative paths break the moment an
article leaves the repository. This applies to inline artifact names too:
`assets/card_system_prompt.txt` and `lib/src/card_detect.dart` are links, not
bare filenames.

**Two link targets, and the distinction is deliberate, but only after
publication.** While the articles are drafts, references to `ModelBehavior.md`
track `/blob/main/` so the drafts follow the notebook as it changes. At
publication, re-point them, every article to the same commit, the one the
figures were read at, including the link in the closing paragraph, so a quoted
figure still resolves after the notebook moves on. Links to code and assets
track `/blob/main/` in drafts and published articles alike, because a reader
following them wants the current file, not an archived one.

## 11. Presentation

- **Target length: about 2,000 words of prose per article, hard cap 3,000.**
  Prose excludes fenced code and diagram blocks, table rows, and link URLs;
  measure with the command in `SKILL.md`, not `wc -w` on the raw file, which
  runs 5 to 10% higher. An article that outgrows the cap gets trimmed or split,
  with the README ownership map updated if split.
- **Prefer a table to a prose list** anywhere a section compares more than two
  things.
- **A table section runs intro, table, then commentary.** The intro is one or
  two sentences saying what the table holds and what to look for in it; a
  section that opens on a table makes the reader infer that. After the table,
  the rows that carry a finding get a paragraph each, two sentences or more,
  because a single sentence restates the row rather than explaining it. Not
  every row earns one: a fifteen-row roster is discussed by group, and rows
  that only supply the denominator need no commentary at all. What the
  paragraphs must not do is leave a row that the reader will stop on, an outlier
  or a reversed sign or a figure that contradicts a neighbouring row, standing
  without an account.
- **Keep every table, including one the notebook also carries.** A table is
  easier to read than the equivalent prose, so duplication between an article
  and `ModelBehavior.md` is accepted rather than avoided. Do not sort tables
  into "main" and "supporting" and cut the second kind: that line is not
  reliably drawable, and drawing it is how a useful table gets dropped. The
  primary table for a claim belongs in the article, beside the paragraph it
  supports. What defers to the notebook is hard prose detail, meaning per-run
  readings, provenance caveats and mechanism discussion, not the tables that
  carry the finding. A figure that appears in both places has to be updated in
  both.
- **Converting prose into a table costs nothing against the cap,** because the
  word count excludes table rows. A passage that enumerates readings, such as
  rules paired with the measurement behind each, per-run figures, or a list of
  conditions, reads better as a table and buys headroom at the same time. It is
  the cheapest way to make room in an article sitting at the cap without
  dropping content.
- **A wide source table needs fitting to blog width.** Either split it into
  per-category mini-tables placed with the prose that discusses them, or shorten
  the widest column and move its content into prose. Do not trim an Evidence
  column; that is where the figures live.
- **Quote one real question per test set.** A denominator describes a set's
  size; a prompt describes its difficulty, and the gap between "What size shirt
  should I order?" and a nine-field expense form is the argument the prose was
  making anyway.
