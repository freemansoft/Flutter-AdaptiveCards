/// The cases `shape_ab.dart` measures, and the rules for judging a reply
/// against one.
///
/// Kept separate from the runner so the table and the classifier can be unit
/// tested without constructing an `HttpClient`.
library;

import 'package:adaptive_chat_server_dart/src/card_detect.dart';

// Relative: probe_support lives outside lib/, beside this file.
import 'probe_support.dart';

/// One prompt, the element types that would answer it acceptably, and whether
/// it asks the user for a value.
///
/// [accepted] is a set because several shapes are often equally correct —
/// "summarize these specs" is defensibly a `FactSet` or a `Table`. An empty
/// [accepted] means the case is the negative control: the correct reply is
/// prose, and a card is the failure.
///
/// [requiresInput] separates "sent the wrong input widget" from "sent no
/// input at all", which are different bugs with different fixes.
class ShapeCase {
  /// Creates a case.
  const ShapeCase({
    required this.id,
    required this.prompt,
    required this.accepted,
    this.requiresInput = false,
  });

  /// Short stable identifier, used by `--only` and in output.
  final String id;

  /// The user turn sent to the model.
  final String prompt;

  /// Element types that count as a correct shape; empty means "expect prose".
  final Set<String> accepted;

  /// Whether the reply must contain some `Input.*` element.
  final bool requiresInput;
}

/// The two prose turns that establish Markdown as the conversation's format.
///
/// Copied verbatim from `choiceset_ab.dart` so the with-history condition is
/// identical across both probes and their numbers stay comparable.
const shapeHistoryUser = 'what is CI/CD?';

/// The assistant half of [shapeHistoryUser]'s exchange.
const shapeHistoryAssistant =
    'CI/CD is a practice where code changes are automatically built, tested, '
    'and deployed.\n\n- **CI** builds and tests every commit.\n'
    '- **CD** ships passing builds to production.';

/// Every case, covering 21 of the 24 element types the card system prompt
/// advertises.
///
/// `TextBlock` is exercised constantly but never asserted — it is the
/// ubiquitous fallback, so asserting it would pass trivially. `Icon` is
/// decorative, so its absence is not a failure. `Image` cannot be elicited
/// honestly because the prompt forbids inventing URLs.
const shapeCases = <ShapeCase>[
  // Inputs — each asks the user for a value.
  ShapeCase(
    id: 'date',
    prompt: 'Book me a meeting. Ask me for a date.',
    accepted: {'Input.Date'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'time',
    prompt: 'Ask me what time I want the standup.',
    accepted: {'Input.Time'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'toggle',
    prompt: 'Ask me whether to enable email notifications.',
    accepted: {'Input.Toggle', 'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'text',
    prompt: 'Ask me to describe the bug in a few sentences.',
    accepted: {'Input.Text'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'number',
    prompt: 'Ask me how many seats I need to license.',
    accepted: {'Input.Number', 'Input.Text'},
    requiresInput: true,
  ),

  // Pick-from-a-set — verbatim from choiceset_ab.dart.
  ShapeCase(
    id: 'choice1',
    prompt: 'what are my options for deployment targets',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice2',
    prompt: 'which log level should I use?',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice3',
    prompt: 'what environments can I deploy to?',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice4',
    prompt: 'what are my options for notification frequency',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice5',
    prompt: 'help me pick a database engine',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),
  ShapeCase(
    id: 'choice6',
    prompt: 'what build modes can I choose from?',
    accepted: {'Input.ChoiceSet'},
    requiresInput: true,
  ),

  // Charts.
  ShapeCase(
    id: 'pie',
    prompt:
        'Show the market share of the top 5 phone vendors as parts of a whole.',
    accepted: {'Chart.Pie', 'Chart.Donut'},
  ),
  ShapeCase(
    id: 'bar',
    prompt: 'Compare signups for Mon-Fri as a bar chart.',
    accepted: {'Chart.VerticalBar', 'Chart.HorizontalBar'},
  ),
  ShapeCase(
    id: 'line',
    prompt: 'Show response time trending across the last 6 releases.',
    accepted: {'Chart.Line'},
  ),
  ShapeCase(
    id: 'gauge',
    prompt: 'Show disk usage at 72% against a 0-100 range.',
    accepted: {'Chart.Gauge'},
  ),

  // Rating — read-only display vs collecting a value from the user.
  ShapeCase(
    id: 'rating_show',
    prompt:
        "What's the average customer rating for the iPhone 15 Pro? "
        'Show it as stars.',
    accepted: {'Rating'},
  ),
  ShapeCase(
    id: 'rating_ask',
    prompt: 'Ask me to rate my support experience from 1 to 5.',
    accepted: {'Input.ChoiceSet', 'Input.Number'},
    requiresInput: true,
  ),

  // Display.
  ShapeCase(
    id: 'carousel',
    prompt: 'Walk me through setting up CI/CD in 3 steps, one step per page.',
    accepted: {'Carousel'},
  ),
  ShapeCase(
    id: 'table',
    prompt: 'Table of the 4 largest planets with diameter and moons.',
    accepted: {'Table'},
  ),
  ShapeCase(
    id: 'facts',
    prompt: 'Summarize the iPhone 15 Pro specs as labelled facts.',
    accepted: {'FactSet', 'Table'},
  ),
  ShapeCase(
    id: 'columnset',
    prompt: 'Compare SQLite and Postgres side by side.',
    accepted: {'ColumnSet', 'Table'},
  ),
  ShapeCase(
    id: 'codeblock',
    prompt:
        'Dart snippet that reads a JSON file and prints the "name" field, '
        'with a short explanation.',
    accepted: {'CodeBlock'},
  ),
  ShapeCase(
    id: 'progress',
    prompt: 'Show me the deployment is 72% complete.',
    accepted: {'ProgressBar', 'ProgressRing'},
  ),
  ShapeCase(
    id: 'badge',
    prompt: 'Show the current build status as a small status pill.',
    accepted: {'Badge'},
  ),

  // Negative control: the right answer is prose, and a card is the failure.
  ShapeCase(
    id: 'prose',
    prompt: 'In two sentences, why is the sky blue?',
    accepted: {},
  ),
];

/// How one reply scored against one [ShapeCase].
class ShapeResult {
  /// Creates a result.
  const ShapeResult({
    required this.caseId,
    required this.pass,
    required this.label,
    required this.found,
    required this.wanted,
  });

  /// The case this judged.
  final String caseId;

  /// Whether the reply was the right shape.
  final bool pass;

  /// One of `ok`, `prose-ok`, `prose`, `no-input`, `wrong-shape`,
  /// `unwanted-card`, or `broken: <reason>`.
  final String label;

  /// Every element type the reply actually contained, empty when it was not
  /// a card.
  final Set<String> found;

  /// The case's accepted types, carried so a failure line can show both sides
  /// of the mismatch without the caller re-looking-up the case.
  final Set<String> wanted;

  /// A one-line explanation, naming both sides when the shape was wrong.
  ///
  /// "carousel failed" and "carousel failed, it emitted three TextBlocks"
  /// call for different fixes, so a wrong-shape line prints what came back
  /// next to what was acceptable.
  String describe() {
    if (pass) return label == 'ok' ? _sorted(found).join(', ') : label;
    if (label == 'wrong-shape' || label == 'no-input') {
      return '$label: got {${_sorted(found).join(', ')}} '
          'want {${_sorted(wanted).join(', ')}}';
    }
    if (label == 'unwanted-card') {
      return '$label: got {${_sorted(found).join(', ')}} want prose';
    }
    return label;
  }

  static List<String> _sorted(Set<String> types) => types.toList()..sort();
}

/// Judges [outcome] against [c], layering shape checks over the server's own
/// card/prose verdict.
///
/// `no-input` is decided before `wrong-shape` deliberately: "asked for a date
/// and got a bare TextBlock" and "asked for a date and got an Input.Text" are
/// different failures, and collapsing them loses the distinction that says
/// whether the model understood it needed to collect something at all.
ShapeResult judgeShape(ShapeCase c, ProbeOutcome outcome) {
  final body = tryParseCardBody(outcome.reply);

  // Negative control: prose is correct here and a card is the failure.
  if (c.accepted.isEmpty) {
    // Checked first, mirroring the general branch below: a reply the server
    // itself calls broken (invalid JSON, duplicate keys, prose wrapping a
    // card) must never score prose-ok just because it didn't parse as a
    // card. Data integrity takes precedence over the control's own verdict.
    if (!outcome.ok) {
      return ShapeResult(
        caseId: c.id,
        pass: false,
        label: 'broken: ${outcome.label}',
        found: body == null ? const {} : collectElementTypes(body),
        wanted: c.accepted,
      );
    }
    if (body == null) {
      return ShapeResult(
        caseId: c.id,
        pass: true,
        label: 'prose-ok',
        found: const {},
        wanted: c.accepted,
      );
    }
    return ShapeResult(
      caseId: c.id,
      pass: false,
      label: 'unwanted-card',
      found: collectElementTypes(body),
      wanted: c.accepted,
    );
  }

  // Short-circuit on duplicate-key and other hard errors: tryParseCardBody
  // succeeds even with duplicate keys (jsonDecode keeps the last value),
  // but the server's own checkNoDuplicateJsonKeys has already failed.
  // Report the server's verdict rather than silently accepting data loss.
  if (body != null && !outcome.ok) {
    return ShapeResult(
      caseId: c.id,
      pass: false,
      label: 'broken: ${outcome.label}',
      found: collectElementTypes(body),
      wanted: c.accepted,
    );
  }

  if (body == null) {
    // outcome.ok is true only for clean prose here, since a card would have
    // parsed; anything else is broken and carries the server's own reason.
    return ShapeResult(
      caseId: c.id,
      pass: false,
      label: outcome.ok ? 'prose' : 'broken: ${outcome.label}',
      found: const {},
      wanted: c.accepted,
    );
  }

  final found = collectElementTypes(body);
  if (c.requiresInput && !found.any((t) => t.startsWith('Input.'))) {
    return ShapeResult(
      caseId: c.id,
      pass: false,
      label: 'no-input',
      found: found,
      wanted: c.accepted,
    );
  }
  if (found.intersection(c.accepted).isEmpty) {
    return ShapeResult(
      caseId: c.id,
      pass: false,
      label: 'wrong-shape',
      found: found,
      wanted: c.accepted,
    );
  }
  return ShapeResult(
    caseId: c.id,
    pass: true,
    label: 'ok',
    found: found,
    wanted: c.accepted,
  );
}
