# Changelog

## [0.14.0]

### Changed 0.14.0

- **Internal cleanup (no behavior change)** — applied `dart format` to `evaluator.dart` (formatting drift), and removed the stray git-tracked `analysis_options copy.yaml` backup file (the analyzer only reads `analysis_options.yaml`).

## [0.13.0]

### Changed 0.13.0

- **Docs:** README **Status** section now includes the detailed per-feature coverage table (with legend) and a templating **Known gaps** note, moved here from the central `docs/Implementation-Status.md` so it is visible on pub.dev.

## [0.12.0]

### Security 0.12.0

- **`json()` builtin input cap:** the template `json()` function now returns `null` for inputs over 256 KiB instead of decoding an unbounded string, bounding memory/CPU on untrusted template data.

### Added 0.12.0

- **Collection functions** `join`, `first`, `last`, `sum`, `average` and **date functions** `formatEpoch`, `getPastTime`, `getFutureTime` added to the expression evaluator. (`select`/`where` remain unimplemented — they require lazy lambda evaluation.)

## [0.11.0]

- no changes yet

## [0.10.0]

- Microsoft template fixture tests deduplicated via shared **`test/ms_template_fixture_test_helper.dart`** (`registerMicrosoftTemplateFixtureTests`); **`ms_template_sample_test.dart`** and **`ms_template_examples_test.dart`** are thin callers.

## [0.9.0]

- Version alignment with `flutter_adaptive_cards_fs` 0.9.0.

## [0.8.0]

- Updated to Dart SDK 3.12 and Flutter 3.44
- Added Unit tests for `Resolver` path resolution (`test/unit/resolver_test.dart`).
- Added Unit tests for `Lexer`, `ExpressionParser`, and AST node shapes (`test/unit/expression_parser_test.dart`).
- Added Expression evaluation matrix tests for operators, builtins, member access, and parse-failure behavior (`test/unit/evaluator_expressions_test.dart`).

## [0.7.0]

- Version alignment and dependency updates for 0.7.0 release.

## [0.6.0]

- Bumped versions to 0.6.0 for next development cycle
- Updated to Dart SDK 3.11 and Flutter 3.41

## [0.5.0] - 2026-04-19

- version numbers were sync'd to 0.5.0

## [0.4.0] - 2026-04-14

- version numbers were sync'd to the flutter_adaptive_charts_fs 0.4.0

## [0.3.0] - 2026-04-12

- Initial release of the independent `flutter_adaptive_template_fs` package.
- Fixed flaky date formatting tests in `template_test.dart` by making expectations timezone-aware.
- Replaced regex-based expression evaluator with a robust AST-based recursive-descent parser.
- Added support for full Adaptive Expressions Language (AEL) operators (math, logical, comparison).
- Enabled dynamic key expansion for objects (e.g., `{"${dynamicKey}": "value"}`).
- Implemented standard AEL functions: `length`, `concat`, `empty`, `json`, and `if`.
- Added support for legacy `{}` syntax for broader compatibility.
- Improved stability and error handling for complex nested expressions.
- Added support for math operations (modulo `%` and power `^`).
- Added support for core math functions: `min`, `max`, `round`, `floor`, and `ceil`.
- Added support for core string functions: `toUpper`, `toLower`, `trim`, `replace`, and `substring`.
- Added Adaptive Expressions Language (AEL) Date/Time function support (`utcNow`, `formatDateTime`, `year`, `month`, `dayOfMonth`, `date`).
- Added Date manipulation functions (`addDays`, `addHours`, `addMinutes`, `addSeconds`).
- Added `intl` package dependency for date parsing functionality.
