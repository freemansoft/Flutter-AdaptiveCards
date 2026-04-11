## 0.3.0

- Initial release of the independent `flutter_adaptive_template_fs` package.
- Replaced regex-based expression evaluator with a robust AST-based recursive-descent parser.
- Added support for full Adaptive Expressions Language (AEL) operators (math, logical, comparison).
- Enabled dynamic key expansion for objects (e.g., `{"${dynamicKey}": "value"}`).
- Implemented standard AEL functions: `length`, `concat`, `empty`, `json`, and `if`.
- Added support for legacy `{}` syntax for broader compatibility.
- Improved stability and error handling for complex nested expressions.
- Added support for math operations (modulo `%` and power `^`).
- Added support for core math functions: `min`, `max`, `round`, `floor`, and `ceil`.
- Added support for core string functions: `toUpper`, `toLower`, `trim`, `replace`, and `substring`.
