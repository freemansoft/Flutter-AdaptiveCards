import 'package:flutter_adaptive_template_fs/src/ast.dart';

/// The type of a lexical token.
enum TokenType {
  /// An identifier (e.g., variable or function name).
  identifier,
  /// A numeric literal.
  number,
  /// A string literal.
  string,
  /// An operator (e.g., '+', '>', '&&').
  operator,
  /// A dot for property access.
  dot,
  /// A comma separating arguments.
  comma,
  /// A left parenthesis '('.
  leftParen,
  /// A right parenthesis ')'.
  rightParen,
  /// A left bracket '[' or '{'.
  leftBracket,
  /// A right bracket ']' or '}'.
  rightBracket,
  /// End of file/input.
  eof,
}

/// A lexical token produced by the [Lexer].
class Token {
  /// Creates a new token.
  const Token(this.type, this.value);

  /// The type of the token.
  final TokenType type;

  /// The string value of the token.
  final String value;

  @override
  String toString() => 'Token($type, $value)';
}

/// A simple lexical analyzer for Adaptive Expressions.
class Lexer {
  /// Creates a lexer for the given [input].
  Lexer(this.input);

  /// The input string to lex.
  final String input;

  /// The current position in the input string.
  int pos = 0;

  /// The list of supported operators.
  static const operators = [
    '==', '!=', '<=', '>=', '&&', '||',
    '<', '>', '+', '-', '*', '/', '%', '^', '!',
  ];

  /// Returns the next token in the input stream.
  Token nextToken() {
    _skipWhitespace();
    if (pos >= input.length) {
      return const Token(TokenType.eof, '');
    }

    final c = input[pos];

    if (c == '(') {
      pos++;
      return const Token(TokenType.leftParen, '(');
    }
    if (c == ')') {
      pos++;
      return const Token(TokenType.rightParen, ')');
    }
    if (c == '[') {
      pos++;
      return const Token(TokenType.leftBracket, '[');
    }
    if (c == ']') {
      pos++;
      return const Token(TokenType.rightBracket, ']');
    }
    if (c == '{') {
      pos++;
      return const Token(TokenType.leftBracket, '{'); // mapped for now
    }
    if (c == '}') {
      pos++;
      return const Token(TokenType.rightBracket, '}'); 
    }
    if (c == '.') {
      pos++;
      return const Token(TokenType.dot, '.');
    }
    if (c == ',') {
      pos++;
      return const Token(TokenType.comma, ',');
    }

    // strings
    if (c == "'" || c == '"') {
      return _readString(c);
    }

    // numbers
    if (_isDigit(c)) {
      return _readNumber();
    }

    // operators
    for (final op in operators) {
      if (input.startsWith(op, pos)) {
        pos += op.length;
        return Token(TokenType.operator, op);
      }
    }

    // identifiers
    if (_isAlpha(c) || c == r'$' || c == '_') {
      return _readIdentifier();
    }

    pos++;
    return Token(TokenType.identifier, c); // fallback
  }

  Token _readString(String quote) {
    pos++; // skip quote
    final start = pos;
    while (pos < input.length && input[pos] != quote) {
      // no escape char logic for simplicty though spec might want it
      pos++;
    }
    final value = input.substring(start, pos);
    if (pos < input.length) pos++; // skip closing quote
    return Token(TokenType.string, value);
  }

  Token _readNumber() {
    final start = pos;
    while (pos < input.length && (_isDigit(input[pos]) || input[pos] == '.')) {
      pos++;
    }
    return Token(TokenType.number, input.substring(start, pos));
  }

  Token _readIdentifier() {
    final start = pos;
    while (pos < input.length &&
        (_isAlphaNum(input[pos]) || input[pos] == r'$' || input[pos] == '_')) {
      pos++;
    }
    return Token(TokenType.identifier, input.substring(start, pos));
  }

  void _skipWhitespace() {
    while (pos < input.length && input[pos].trim().isEmpty) {
      pos++;
    }
  }

  bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isAlphaNum(String c) => _isAlpha(c) || _isDigit(c);
}

/// A recursive-descent parser for Adaptive Expressions.
class ExpressionParser {
  /// Creates a parser for the given [input].
  ExpressionParser(String input) : _lexer = Lexer(input) {
    _advance(); // read first token
  }

  final Lexer _lexer;
  late Token _current;

  /// Parses the given [input] string into an [AstNode].
  static AstNode parse(String input) {
    if (input.trim().isEmpty) return const LiteralNode('');
    final parser = ExpressionParser(input);
    return parser._parseExpression();
  }

  void _advance() {
    _current = _lexer.nextToken();
  }

  bool _matchType(TokenType type) {
    return _current.type == type;
  }

  void _expect(TokenType type) {
    if (_matchType(type)) {
      _advance();
    } else {
      throw FormatException('Expected $type but got ${_current.type}');
    }
  }

  AstNode _parseExpression() {
    return _parseLogicalOr();
  }

  AstNode _parseLogicalOr() {
    var node = _parseLogicalAnd();
    while (_current.type == TokenType.operator && _current.value == '||') {
      final op = _current.value;
      _advance();
      node = BinaryExpressionNode(op, node, _parseLogicalAnd());
    }
    return node;
  }

  AstNode _parseLogicalAnd() {
    var node = _parseEquality();
    while (_current.type == TokenType.operator && _current.value == '&&') {
      final op = _current.value;
      _advance();
      node = BinaryExpressionNode(op, node, _parseEquality());
    }
    return node;
  }

  AstNode _parseEquality() {
    var node = _parseRelational();
    while (_current.type == TokenType.operator &&
        (_current.value == '==' || _current.value == '!=')) {
      final op = _current.value;
      _advance();
      node = BinaryExpressionNode(op, node, _parseRelational());
    }
    return node;
  }

  AstNode _parseRelational() {
    var node = _parseAdditive();
    while (_current.type == TokenType.operator &&
        (_current.value == '<' ||
         _current.value == '>' ||
         _current.value == '<=' ||
         _current.value == '>=')) {
      final op = _current.value;
      _advance();
      node = BinaryExpressionNode(op, node, _parseAdditive());
    }
    return node;
  }

  AstNode _parseAdditive() {
    var node = _parseMultiplicative();
    while (_current.type == TokenType.operator &&
        (_current.value == '+' || _current.value == '-')) {
      final op = _current.value;
      _advance();
      node = BinaryExpressionNode(op, node, _parseMultiplicative());
    }
    return node;
  }

  AstNode _parseMultiplicative() {
    var node = _parseExponential();
    while (_current.type == TokenType.operator &&
        (_current.value == '*' || _current.value == '/' || _current.value == '%')) {
      final op = _current.value;
      _advance();
      node = BinaryExpressionNode(op, node, _parseExponential());
    }
    return node;
  }

  AstNode _parseExponential() {
    var node = _parseUnary();
    while (_current.type == TokenType.operator && _current.value == '^') {
      final op = _current.value;
      _advance();
      node = BinaryExpressionNode(op, node, _parseUnary());
    }
    return node;
  }

  AstNode _parseUnary() {
    if (_current.type == TokenType.operator &&
        (_current.value == '!' ||
         _current.value == '-' ||
         _current.value == '+')) {
      final op = _current.value;
      _advance();
      return UnaryExpressionNode(op, _parseUnary());
    }
    return _parsePrimary();
  }

  AstNode _parsePrimary() {
    if (_matchType(TokenType.leftParen)) {
      _advance();
      final node = _parseExpression();
      _expect(TokenType.rightParen);
      return _parseAccessors(node);
    }
    
    if (_matchType(TokenType.string)) {
      final val = _current.value;
      _advance();
      return _parseAccessors(LiteralNode(val));
    }
    
    if (_matchType(TokenType.number)) {
      final numVal = num.tryParse(_current.value);
      _advance();
      return _parseAccessors(LiteralNode(numVal));
    }
    
    if (_matchType(TokenType.identifier)) {
      final text = _current.value;
      _advance(); // consume identifier

      if (text == 'true') return _parseAccessors(const LiteralNode(true));
      if (text == 'false') return _parseAccessors(const LiteralNode(false));
      if (text == 'null') return _parseAccessors(const LiteralNode(null));

      var node = IdentifierNode(text) as AstNode;

      // is it a function call?
      if (_matchType(TokenType.leftParen)) {
        _advance();
        final args = <AstNode>[];
        if (!_matchType(TokenType.rightParen)) {
          args.add(_parseExpression());
          while (_matchType(TokenType.comma)) {
            _advance();
            args.add(_parseExpression());
          }
        }
        _expect(TokenType.rightParen);
        node = FunctionCallNode(node, args);
      }

      return _parseAccessors(node);
    }

    throw FormatException('Unexpected token ${_current.value}');
  }

  AstNode _parseAccessors(AstNode base) {
    var node = base;
    while (true) {
      if (_matchType(TokenType.dot)) {
        _advance();
        if (!_matchType(TokenType.identifier)) {
           throw const FormatException('Expected identifier after dot');
        }
        final propName = _current.value;
        _advance();
        node = MemberAccessNode(node, IdentifierNode(propName));
      } else if (_matchType(TokenType.leftBracket)) {
        _advance();
        final indexNode = _parseExpression();
        _expect(TokenType.rightBracket);
        node = MemberAccessNode(node, indexNode, isComputed: true);
      } else {
        break;
      }
    }
    return node;
  }
}
