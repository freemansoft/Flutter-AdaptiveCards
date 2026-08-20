/// The two-turn cases `cascade_ab.dart` runs.
///
/// Each is a pick-one question followed by a request to widen it to a
/// multi-select. Kept beside the probe, and separate from it, for the same
/// reason `shape_cases.dart` is: the case list is edited far more often than
/// the scoring, and a diff that touches only prompts is easy to review.
library;

/// One cascade: a first turn that should produce a single-select list, and a
/// follow-up that should widen the *same* list to multi-select.
class CascadeCase {
  /// Creates a case.
  const CascadeCase({
    required this.id,
    required this.first,
    required this.second,
  });

  /// Short identifier used in output.
  final String id;

  /// Turn 1 — asks for a list to pick one item from.
  final String first;

  /// Turn 2 — asks to widen turn 1's list, without restating its contents.
  ///
  /// Deliberately refers back ("those", "that list") instead of naming the
  /// items again: a model that can only answer by re-deriving the list has
  /// not used the history, which is the thing being measured.
  final String second;
}

/// The cases. Three is enough to separate a model that cascades from one that
/// got lucky, without paying for a fourth cold model load on every run.
const cascadeCases = <CascadeCase>[
  CascadeCase(
    id: 'states',
    first: 'What are the top 5 US states by population? I want to pick one.',
    second: 'Actually, I want to be able to pick more than one of those.',
  ),
  CascadeCase(
    id: 'loglevel',
    first: 'Which log level should I use? Let me choose one.',
    second: 'Change that so I can select several of them instead.',
  ),
  CascadeCase(
    id: 'deploy',
    first: 'What environments can I deploy to? I want to pick one.',
    second: 'I need to pick more than one environment from that list.',
  ),
];
