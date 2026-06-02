import 'package:flutter_adaptive_template_fs/src/ast.dart';
import 'package:flutter_adaptive_template_fs/src/expression_parser.dart';
import 'package:flutter_test/flutter_test.dart';

List<Token> _lexAll(String input) {
  final lexer = Lexer(input);
  final tokens = <Token>[];
  while (true) {
    final token = lexer.nextToken();
    tokens.add(token);
    if (token.type == TokenType.eof) {
      break;
    }
  }
  return tokens;
}

void _expectIdentifier(AstNode node, String name) {
  expect(node, isA<IdentifierNode>());
  expect((node as IdentifierNode).name, name);
}

void _expectLiteral(AstNode node, Object? value) {
  expect(node, isA<LiteralNode>());
  expect((node as LiteralNode).value, value);
}

BinaryExpressionNode _expectBinary(AstNode node, String operator) {
  expect(node, isA<BinaryExpressionNode>());
  final binary = node as BinaryExpressionNode;
  expect(binary.operator, operator);
  return binary;
}

void main() {
  group('Lexer', () {
    test('tokenizes empty input as eof', () {
      final tokens = _lexAll('');
      expect(tokens, [const Token(TokenType.eof, '')]);
    });

    test('skips whitespace between tokens', () {
      final tokens = _lexAll('  a  +  b  ');
      expect(
        tokens.map((t) => t.type).toList(),
        [
          TokenType.identifier,
          TokenType.operator,
          TokenType.identifier,
          TokenType.eof,
        ],
      );
      expect(tokens[0].value, 'a');
      expect(tokens[1].value, '+');
      expect(tokens[2].value, 'b');
    });

    test('tokenizes multi-character operators before single-character', () {
      final tokens = _lexAll('== != <= >= && ||');
      expect(
        tokens.map((t) => t.value).toList(),
        ['==', '!=', '<=', '>=', '&&', '||', ''],
      );
    });

    test('tokenizes numbers and strings', () {
      final tokens = _lexAll("42 3.14 'hi' \"there\"");
      expect(tokens[0].type, TokenType.number);
      expect(tokens[0].value, '42');
      expect(tokens[1].type, TokenType.number);
      expect(tokens[1].value, '3.14');
      expect(tokens[2].type, TokenType.string);
      expect(tokens[2].value, 'hi');
      expect(tokens[3].type, TokenType.string);
      expect(tokens[3].value, 'there');
    });

    test('tokenizes identifiers including magic variables', () {
      final tokens = _lexAll(r'name $root $index _private');
      expect(
        tokens.map((t) => t.value).toList(),
        ['name', r'$root', r'$index', '_private', ''],
      );
    });

    test('tokenizes punctuation', () {
      final tokens = _lexAll('().[],{}');
      expect(
        tokens.map((t) => t.type).toList(),
        [
          TokenType.leftParen,
          TokenType.rightParen,
          TokenType.dot,
          TokenType.leftBracket,
          TokenType.rightBracket,
          TokenType.comma,
          TokenType.leftBracket,
          TokenType.rightBracket,
          TokenType.eof,
        ],
      );
    });
  });

  group('ExpressionParser.parse', () {
    test('empty or whitespace input becomes empty literal', () {
      _expectLiteral(ExpressionParser.parse(''), '');
      _expectLiteral(ExpressionParser.parse('   '), '');
    });

    test('parses boolean and null literals', () {
      _expectLiteral(ExpressionParser.parse('true'), true);
      _expectLiteral(ExpressionParser.parse('false'), false);
      _expectLiteral(ExpressionParser.parse('null'), null);
    });

    test('parses numeric and string literals', () {
      _expectLiteral(ExpressionParser.parse('42'), 42);
      _expectLiteral(ExpressionParser.parse('3.14'), 3.14);
      _expectLiteral(ExpressionParser.parse("'x'"), 'x');
    });

    test('parses additive lower precedence than multiplicative', () {
      final ast = ExpressionParser.parse('a + b * c');
      final root = _expectBinary(ast, '+');
      _expectIdentifier(root.left, 'a');
      final mul = _expectBinary(root.right, '*');
      _expectIdentifier(mul.left, 'b');
      _expectIdentifier(mul.right, 'c');
    });

    test('parses logical OR lower precedence than AND', () {
      final ast = ExpressionParser.parse('a || b && c');
      final root = _expectBinary(ast, '||');
      _expectIdentifier(root.left, 'a');
      final and = _expectBinary(root.right, '&&');
      _expectIdentifier(and.left, 'b');
      _expectIdentifier(and.right, 'c');
    });

    test('parses unary operators', () {
      final notAst = ExpressionParser.parse('!flag');
      expect(notAst, isA<UnaryExpressionNode>());
      expect((notAst as UnaryExpressionNode).operator, '!');
      _expectIdentifier(notAst.argument, 'flag');

      final negAst = ExpressionParser.parse('-x');
      expect((negAst as UnaryExpressionNode).operator, '-');
      _expectIdentifier(negAst.argument, 'x');

      final posAst = ExpressionParser.parse('+x');
      expect((posAst as UnaryExpressionNode).operator, '+');
      _expectIdentifier(posAst.argument, 'x');
    });

    test('parses parenthesized grouping', () {
      final ast = ExpressionParser.parse('(a + b)');
      final root = _expectBinary(ast, '+');
      _expectIdentifier(root.left, 'a');
      _expectIdentifier(root.right, 'b');
    });

    test('parses dot member access', () {
      final ast = ExpressionParser.parse('foo.bar');
      expect(ast, isA<MemberAccessNode>());
      final access = ast as MemberAccessNode;
      expect(access.isComputed, isFalse);
      _expectIdentifier(access.object, 'foo');
      _expectIdentifier(access.property, 'bar');
    });

    test('parses bracket member access as computed', () {
      final ast = ExpressionParser.parse('items[0]');
      expect(ast, isA<MemberAccessNode>());
      final access = ast as MemberAccessNode;
      expect(access.isComputed, isTrue);
      _expectIdentifier(access.object, 'items');
      _expectLiteral(access.property, 0);
    });

    test('parses chained accessors', () {
      final ast = ExpressionParser.parse('items[0].name');
      expect(ast, isA<MemberAccessNode>());
      final nameAccess = ast as MemberAccessNode;
      expect(nameAccess.isComputed, isFalse);
      _expectIdentifier(nameAccess.property, 'name');

      final indexAccess = nameAccess.object as MemberAccessNode;
      expect(indexAccess.isComputed, isTrue);
      _expectIdentifier(indexAccess.object, 'items');
      _expectLiteral(indexAccess.property, 0);
    });

    test('parses function calls with multiple arguments', () {
      final ast = ExpressionParser.parse('min(1, 2)');
      expect(ast, isA<FunctionCallNode>());
      final call = ast as FunctionCallNode;
      _expectIdentifier(call.function, 'min');
      expect(call.arguments, hasLength(2));
      _expectLiteral(call.arguments[0], 1);
      _expectLiteral(call.arguments[1], 2);
    });

    test('parses if() with three arguments', () {
      final ast = ExpressionParser.parse('if(a, b, c)');
      expect(ast, isA<FunctionCallNode>());
      final call = ast as FunctionCallNode;
      _expectIdentifier(call.function, 'if');
      expect(call.arguments, hasLength(3));
      _expectIdentifier(call.arguments[0], 'a');
      _expectIdentifier(call.arguments[1], 'b');
      _expectIdentifier(call.arguments[2], 'c');
    });

    test('parses empty function call argument list', () {
      final ast = ExpressionParser.parse('utcNow()');
      expect(ast, isA<FunctionCallNode>());
      final call = ast as FunctionCallNode;
      _expectIdentifier(call.function, 'utcNow');
      expect(call.arguments, isEmpty);
    });

    group('parse failures', () {
      test('unclosed parenthesis throws FormatException', () {
        expect(
          () => ExpressionParser.parse('(a + b'),
          throwsA(isA<FormatException>()),
        );
      });

      test('dot without identifier throws FormatException', () {
        expect(
          () => ExpressionParser.parse('foo.'),
          throwsA(isA<FormatException>()),
        );
      });

      test('unexpected token throws FormatException', () {
        expect(
          () => ExpressionParser.parse(')'),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });

  group('AstNode toString', () {
    test('formats nodes for debugging', () {
      expect(const LiteralNode(1).toString(), 'Literal(1)');
      expect(const IdentifierNode('x').toString(), 'Identifier(x)');
      expect(
        const MemberAccessNode(
          IdentifierNode('a'),
          IdentifierNode('b'),
        ).toString(),
        'MemberAccess(Identifier(a).Identifier(b))',
      );
      expect(
        const BinaryExpressionNode(
          '+',
          LiteralNode(1),
          LiteralNode(2),
        ).toString(),
        'Binary(Literal(1) + Literal(2))',
      );
    });
  });
}
