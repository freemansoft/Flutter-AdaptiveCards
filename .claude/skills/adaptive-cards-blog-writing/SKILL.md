---
name: adaptive-cards-blog-writing
description: >
  Draft, review, revise, retitle, and publish the blog articles in
  adaptive_chat_server_dart/blog/, which explain findings from the
  ModelBehavior.md lab notebook to readers outside the repo. Covers the series
  register (flat analytical tone, no em dashes, no first-person singular),
  headings and titles that state one finding, terminology grounded in the code,
  claims verified against the notebook and source, terms tables, diagrams,
  length and figure checks, and the Blogger publishing step. Use this skill
  whenever the user asks to review an article for style, substance, complexity,
  or wording; to tighten a title, heading, or sentence; asks what a passage in
  a draft means or whether a reader would understand it; wants a diagram made
  clearer; asks how long an article is; carries notebook figures into the blog;
  starts a new article; or prepares one for Blogger. Use it even when the user
  only quotes one sentence from a draft and asks a question about it.
---

# Writing and reviewing the blog series

The articles in `adaptive_chat_server_dart/blog/` explain what
`adaptive_chat_server_dart/ModelBehavior.md` records about local Ollama models
producing Adaptive Card JSON. The reader is a developer outside this repo who
arrived from a search result. Two consequences drive most of what follows:
every article has to stand alone, and every sentence is a claim the reader will
take at face value because they cannot check it against the code.

Three sources govern the work, and they do not overlap:

| Source                                     | Owns                                                                                                                             |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `adaptive_chat_server_dart/ModelBehavior.md` | Every figure. When the notebook and a draft disagree, the notebook wins.                                                          |
| `adaptive_chat_server_dart/blog/README.md` | The series plan: status table, what each article owns and defers, the **Figures** rules, and **Terms and units**.                |
| This skill                                 | How to write, review, verify, and publish. The full rules, with reasons and examples, are in `references/style-rules.md`.        |

The CLAUDE.md "Documentation tone" rules also apply. `references/style-rules.md`
carries their blog-specific form.

## Setup for any pass

1. **Branch first.** Create `docs/article-N-<pass>` (for example
   `docs/article-4-cut-pass`) from `main` before the first edit. Never commit
   or push until the user has seen the diff and said to proceed; this is the
   CLAUDE.md commit gate, and it holds even when the request sounds like it
   covers the whole job.
2. **Read the whole article**, its entry under "What each article owns" in the
   README, and the README's Figures and Terms and units sections.
3. **Calibrate on the most recently reworked drafts.** The README status column
   and `git log -- adaptive_chat_server_dart/blog/` show which articles have had
   a register or cut pass. Match those rather than an older draft.
4. **Read `references/style-rules.md`.** It is the rulebook. The checklist at
   the end of this file is only an index into it.
5. **Record the starting prose word count** with the command under
   Verification, so any length claim has a before and an after.

## Modes

### Review

Triggered by requests like "examine this article for style, substance,
complexity and wording". Produce findings; edit only if asked.

**Read the draft twice.** The first pass hunts defects against the checklist.
The second reads it straight through as a reader who arrived from a search
result, and that pass is where the problems no checklist item names turn up: an
incident told three times before its cause arrives, a term doing two jobs, five
runtime versions that no table attributes. A review assembled only from the
checklist finds violations and misses shape.

- **Open with three or four lines of orientation.** What the article does well,
  and the few things keeping it from reading like the most recently reworked
  drafts. Then the ranked findings.
- **Rank by harm.** Claims the notebook or code does not support come first,
  then contradictions (a definition that does not fit its table, a
  cross-reference that no longer resolves), then register violations, then
  structure and wording.
- **Make each finding actionable.** Cite the line, quote the text, say how it
  misleads a reader, and propose the fix.
- **On an article that compares two configurations, diff the arms before
  reading the prose.** Open the probe that produced the figures and list every
  input that differs between the two, not just the one the article is about. A
  difference nobody mentioned is invisible to a sentence-by-sentence check, and
  this is how article 4's two system prompts went unnoticed through a revision
  and a review. See "When an article compares two configurations" in the style
  rules.
- **Propose the shape, not only the faults.** Where the order is wrong, give the
  section order you would use, one line per section saying what it holds and
  what moves into it. "This section holds two findings" is half a finding; the
  other half is where the second one goes. See Section order and article shape
  in the style rules.
- **Count a recurring habit instead of fixing one instance of it.** When a tic
  appears more than twice, say how many times and list the lines. "Five
  reversals, at these lines" tells the author it is a habit; one flagged
  sentence reads as a one-off.
- **Rewrite the worst two or three passages in full.** The densest paragraph and
  any headings you would change earn finished prose, because a described fix for
  a tangled paragraph is not checkable. Everything else stays a described fix: a
  review that rewrites the whole article is a revision nobody asked for.
- **Forecast the length** when the article is over the 2,000-word target. Say
  what the proposed changes would leave it at, and which cost nothing because
  they move prose into table rows.
- **When reviewing edits made earlier in the session, separate the errors those
  edits introduced from pre-existing ones**, and say which are which.
- **Show what was checked.** Paste the output of the Verification commands.
- **End by asking which findings to apply.** Flag any fix that depends on a
  source outside the repo, such as a model card, before applying it.

### Clarify a passage

Triggered by "what does this mean?", "is it clear to the reader that...", or a
quoted sentence with a question.

Answer from the source, not from the draft: read the function, the flag
definition, or the notebook section. Then check whether the article gives an
outside reader the same answer. A user who had to ask is evidence that it does
not, so say what is missing and offer the edit.

When the user's message stops mid-sentence, ask for the rest instead of
answering a guessed completion.

### Revise

- **Treat each request as an instance of a rule.** "Say the chat server, not
  the server" is the rule "name the actor precisely"; apply it everywhere it
  holds **in the files the request named**.
- **An edit that reaches a file the request did not name gets confirmed
  first.** Say what you found and what you would change, and leave the file
  alone until the user answers. This holds in every mode, including a clarify
  request that turns into an edit, and it covers the notebook, the README, and
  any sibling article. A test run of this skill was asked to clarify one term
  in article 7 and rewrote the identical row in article 6 as well, which nobody
  had asked for; the run without the skill reported that row instead, which is
  the behavior to copy. Two exceptions, because omitting them breaks the change
  that was asked for: the README status row quoting a title you just changed,
  and a cross-reference your own edit invalidated.
- **When a rule would repeat a word many times,** confirm the scope before
  applying it, such as every occurrence against the first mention in each
  section.
- **Wording edits never change a figure, and clarifying a claim never
  strengthens it.** Keep every hedge the paragraph had.
- **A title change updates the article's row in the README status table.**
  Grep the repo for the old title.
- **After moving or deleting a section,** re-derive its heading and re-check
  every "next section", "above", and "below".
- **Run the full Verification before reporting done**, and report the numbers.

### Carry notebook changes into the blog

The drafts drift silently when the notebook moves. When a notebook figure,
section heading, or anchor changes, grep the drafts for it
(`grep -n '<figure or anchor>' adaptive_chat_server_dart/blog/*.md`) and update
them in the same change. Update attributions and qualifiers to what was
measured, not to what a plan predicted. An addition to an article near the
cap is paid for with a trim in the same edit.

### Draft a new article

Check the ownership map first. If another article already owns the topic, the
new one links to it rather than re-explaining it.

Draft from an outline, then delete the outline once the draft is verified; a
second description of an existing article is drift waiting to happen. The
outline carries:

- A section list with a word budget each, summing to the target length.
- The figures each section quotes, with the arithmetic behind any denominator
  spelled out so the drafter cannot guess it.
- The tables the article needs, with their rows named.
- The traps: for each figure that is easy to misread, a sentence saying what
  not to write. These caught more errors than any other part of the outlines.
- Where the three attributions go, and which visuals are needed.

Then draft in this order, because each step constrains the next:

1. **Name the finding in one sentence.** Everything in the article supports it.
   If it takes two sentences, that is either two articles or one article and a
   deferral.
2. **Collect the figures and copy the notebook's tables in verbatim.** Every
   figure carries its test set and its condition and names the probe that
   produced it. Table rows do not count against the length cap, so a table is
   cheaper than the prose that would replace it.
3. **Lay out the sections, one finding each.** Section order is part of the
   argument, so read Section order and article shape in the style rules before
   fixing the order.
4. **Draft the body before the opening.** Tables first, then the commentary
   each table needs, then the intro, and the title last, because the title has
   to survive the paraphrase test against what the draft actually says.
5. **Add a terms table** if the article uses more than a few terms a reader
   outside the repo would not know, and define each of them only there.
6. **Review the draft against the checklist below** and run the verification
   commands, before showing it to anyone.
7. **Register it:** add the row to the README status table and an entry to the
   ownership map saying what the article owns and what it defers. Update any
   sibling article whose deferral now points at it.

### Publish to Blogger

The conversion command is in the README under "Publishing to Blogger". Before
running it:

- **Render each mermaid fence to a PNG** saved as
  `adaptive_chat_server_dart/blog/blog-N-<name>.png`, and replace the fence
  with an `<img>` pointing at it. Blogger does not run mermaid, and
  `tool/blog/to_blogger.dart` passes a fence through as text. The script turns
  each image `src` into an `{{IMAGE_URL:<path>}}` token to fill in after
  uploading the image.
- **Re-point the notebook links** to the commit the figures were read at (see
  Attribution in the style rules).

## Using subagents

Most of this work parallelizes, because articles are independent files and the
analyses of one article are independent of each other. Fan out when the work
splits cleanly, and keep the judgment in one place.

**Worth delegating:**

- **One article per agent** when a notebook change touches several drafts, or
  when several articles need the same sweep, such as a term renamed across the
  series.
- **One analysis per agent** on a single long article: claims and figures
  against the notebook and the code, structure and section order, register and
  wording. These read the same file and produce separate findings, so they do
  not collide.
- **A second opinion on a high-stakes article.** Running one reviewer with this
  skill and one without it found different things on article 5: four unsourced
  figures against five, and only the run with the skill resolved a sentence
  that described a rounding defect backwards. A review costs roughly 120k to
  210k tokens and 3 to 10 minutes, so a second pass is cheap against publishing
  a wrong figure.

**Keep with the coordinator:**

- Deciding which findings to apply, and asking the user.
- Every edit to a file in the repo. A subagent that writes to a shared draft
  races the next one; give each agent a scratch copy, or have it report rather
  than edit.
- The verification block, run once over the finished state.
- Commits, which need the user anyway.

**Briefing an agent:** name the exact files, say the repo is read-only and
where to write output, and say which analysis it owns so two agents do not
produce the same list. A subagent's report is a claim, not a result: check what
it says against the notebook or the code before repeating it to the user or
acting on it. One review in this repo asserted that two models share an
architecture, which the notebook does not say.

## Verification

Run from the repo root. Set `A` to the article and `BASE` to the branch point.
Paste the output when reporting; a summary without numbers is not a check.

```bash
A=adaptive_chat_server_dart/blog/article-4-tool-channel-draft.md; BASE=main

# Prose words, using the cap convention: fenced blocks, table rows, and URLs
# excluded. Target about 2,000, hard cap 3,000. The raw file reads 5-10% higher.
python3 - "$A" <<'EOF'
import re, sys
t = open(sys.argv[1]).read()
t = re.sub(r'```.*?```', '', t, flags=re.S)
t = re.sub(r'^\|.*$', '', t, flags=re.M)
t = re.sub(r'\(https?://[^)]*\)', '', t)
t = re.sub(r'https?://\S+', '', t)
print('prose words:', len(t.split()))
EOF

# Figures: compare numeric token counts, not presence. A trim once dropped a
# figure that a presence check missed because the number appeared elsewhere.
# Every decrease must be one you meant.
python3 - "$A" "$BASE" <<'EOF'
import re, subprocess, sys
from collections import Counter
path, base = sys.argv[1], sys.argv[2]
old = subprocess.run(['git', 'show', f'{base}:{path}'],
                     capture_output=True, text=True).stdout
new = open(path).read()
tok = lambda s: Counter(re.findall(r'\d+(?:[./:x]\d+)*', s))
print('decreased:', dict(tok(old) - tok(new)))
print('increased:', dict(tok(new) - tok(old)))
EOF

# Em dashes outside table rows. Edits reintroduce them, so count after every pass.
grep -v '^|' "$A" | grep -o '—' | wc -l

# First-person singular. Review each hit: a quoted reader question may use "I".
grep -nwE 'I|me|my' "$A"

# Comparison articles: inputs the probe picks by the variable under comparison.
# Each hit is a difference between the arms that the article either names or
# carries as an unmeasured confound. Point it at the probe behind the figures.
grep -nE "== '(tool|prose)'|\? *'[A-Za-z0-9_]+\.(txt|json)'" \
  adaptive_chat_server_dart/tool/model_probes/shape_ab.dart

# Sentences past 25 words, against the 12 to 20 word target. A hint, not a rule:
# a long sentence carrying one idea is fine, one carrying three is not.
python3 - "$A" <<'EOF'
import re, sys
t = open(sys.argv[1]).read()
t = re.sub(r'```.*?```', '', t, flags=re.S)
t = re.sub(r'^\|.*$', '', t, flags=re.M)
t = re.sub(r'^#.*$', '', t, flags=re.M)
for sent in re.split(r'(?<=[.!?])\s+', t):
    n = len(sent.split())
    if n > 25:
        print(n, sent.strip()[:90])
EOF

# The reversal tic ("It was not.", "They are not."). Count before fixing one.
grep -nE '\b(It|They|That|This|The [a-z]+) (is|are|was|were) not\.' "$A"

# Markdown format gate. adaptive_chat_server_dart/** is covered by check:md:chat,
# not by check:md. Fix with npm run format:md:chat.
npm run check:md:chat
```

## Checklist

One line per rule. The section named in parentheses in
`references/style-rules.md` holds the rule, its reason, and examples.

**Claims** (Verifying claims)

- [ ] Mechanisms, flag defaults, and enforced constraints checked in the source.
- [ ] Model properties taken from the notebook or a model card, not memory.
- [ ] Every definition fits every row of the table it labels.
- [ ] Measured and inferred kept apart; no hedge lost in an edit.

**Names** (Terminology; Describing mechanisms)

- [ ] One name per concept, taken from the code or API.
- [ ] Vendor-specific mechanisms qualified in the title and at the first mention
      in each `##` section.
- [ ] Actors named precisely; each term says what kind of thing it is.
- [ ] Mechanisms described by direction and data; exclusive alternatives stated.

**Structure** (Openings; Headings and titles; Terms tables and definitions;
Section order and article shape)

- [ ] Framing paragraph first, with the setup the finding depends on.
- [ ] Each heading states one finding in concrete words and matches its section.
- [ ] Section order carries the argument: one thread per section, mechanism
      before verdict, no incident told twice.
- [ ] Title survives the paraphrase test; README status row matches it.
- [ ] Each term defined once; every cross-reference resolves.

**Register** (Register)

- [ ] No em dashes, first-person singular, amplifiers, or closing flourish.

**Visuals, tables, sources** (Diagrams and images; Presentation; Attribution;
Cross-article references)

- [ ] Diagrams use the prose's names and draw exclusive branches as branches.
- [ ] Table sections run intro, table, commentary; no table cut.
- [ ] Repo on the first screen, source beside each table, both URLs at the close.
