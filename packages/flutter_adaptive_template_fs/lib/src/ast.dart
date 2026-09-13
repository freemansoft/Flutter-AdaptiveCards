/// Base class for all Abstract Syntax Tree nodes.
abstract class const AstNode() {
  /// Default constructor for the AST node.
  this;
}

/// Represents a literal value like a string, number, or boolean.
class const LiteralNode(
  /// The literal value.
  final dynamic value,
) extends AstNode {
  /// Creates a literal node with the given [value].
  this;

  @override
  String toString() => 'Literal($value)';
}

/// Represents an identifier or variable name.
class const IdentifierNode(
  /// The name of the identifier.
  final String name,
) extends AstNode {
  /// Creates an identifier node with the given [name].
  this;

  @override
  String toString() => 'Identifier($name)';
}

/// Represents accessing a property on an object.
class const MemberAccessNode(
  /// The object being accessed.
  final AstNode object,

  /// The property being accessed on the object.
  /// If [isComputed] is true, this is evaluated. Otherwise, it is an
  /// [IdentifierNode].
  final AstNode property, {

  /// Whether the property access is computed (using bracket notation).
  final bool isComputed = false,
}) extends AstNode {
  /// Creates a member access node.
  this;

  @override
  String toString() => isComputed
      ? 'MemberAccess($object[$property])'
      : 'MemberAccess($object.$property)';
}

/// Represents a function call.
class const FunctionCallNode(
  /// The function being called (usually an [IdentifierNode]).
  final AstNode function,

  /// The list of arguments passed to the function.
  final List<AstNode> arguments,
) extends AstNode {
  /// Creates a function call node.
  this;

  @override
  String toString() => 'FunctionCall($function, $arguments)';
}

/// Represents a binary expression with a left and right operand.
class const BinaryExpressionNode(
  /// The operator string (e.g., '+', '>', '&&').
  final String operator,

  /// The left operand.
  final AstNode left,

  /// The right operand.
  final AstNode right,
) extends AstNode {
  /// Creates a binary expression node.
  this;

  @override
  String toString() => 'Binary($left $operator $right)';
}

/// Represents a unary expression with a single argument.
class const UnaryExpressionNode(
  /// The operator string (e.g., '!', '-').
  final String operator,

  /// The argument of the expression.
  final AstNode argument,
) extends AstNode {
  /// Creates a unary expression node.
  this;

  @override
  String toString() => 'Unary($operator$argument)';
}
