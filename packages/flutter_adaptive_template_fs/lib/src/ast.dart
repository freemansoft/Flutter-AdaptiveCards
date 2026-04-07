/// Base class for all Abstract Syntax Tree nodes.
abstract class AstNode {
  /// Default constructor for the AST node.
  const AstNode();
}

/// Represents a literal value like a string, number, or boolean.
class LiteralNode extends AstNode {
  /// Creates a literal node with the given [value].
  const LiteralNode(this.value);

  /// The literal value.
  final dynamic value;

  @override
  String toString() => 'Literal($value)';
}

/// Represents an identifier or variable name.
class IdentifierNode extends AstNode {
  /// Creates an identifier node with the given [name].
  const IdentifierNode(this.name);

  /// The name of the identifier.
  final String name;

  @override
  String toString() => 'Identifier($name)';
}

/// Represents accessing a property on an object.
class MemberAccessNode extends AstNode {
  /// Creates a member access node.
  const MemberAccessNode(this.object, this.property, {this.isComputed = false});

  /// The object being accessed.
  final AstNode object;

  /// The property being accessed on the object.
  /// If [isComputed] is true, this is evaluated. Otherwise, it is an
  /// [IdentifierNode].
  final AstNode property;

  /// Whether the property access is computed (using bracket notation).
  final bool isComputed;

  @override
  String toString() => isComputed
      ? 'MemberAccess($object[$property])'
      : 'MemberAccess($object.$property)';
}

/// Represents a function call.
class FunctionCallNode extends AstNode {
  /// Creates a function call node.
  const FunctionCallNode(this.function, this.arguments);

  /// The function being called (usually an [IdentifierNode]).
  final AstNode function;

  /// The list of arguments passed to the function.
  final List<AstNode> arguments;

  @override
  String toString() => 'FunctionCall($function, $arguments)';
}

/// Represents a binary expression with a left and right operand.
class BinaryExpressionNode extends AstNode {
  /// Creates a binary expression node.
  const BinaryExpressionNode(this.operator, this.left, this.right);

  /// The operator string (e.g., '+', '>', '&&').
  final String operator;

  /// The left operand.
  final AstNode left;

  /// The right operand.
  final AstNode right;

  @override
  String toString() => 'Binary($left $operator $right)';
}

/// Represents a unary expression with a single argument.
class UnaryExpressionNode extends AstNode {
  /// Creates a unary expression node.
  const UnaryExpressionNode(this.operator, this.argument);

  /// The operator string (e.g., '!', '-').
  final String operator;

  /// The argument of the expression.
  final AstNode argument;

  @override
  String toString() => 'Unary($operator$argument)';
}
