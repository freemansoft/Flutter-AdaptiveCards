// JSON conversion can be a lot of things so it is dynamic
// ignore_for_file: strict_raw_type, unnecessary_parenthesis

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_adaptive_template_fs/src/ast.dart';
import 'package:flutter_adaptive_template_fs/src/expression_parser.dart';
import 'package:flutter_adaptive_template_fs/src/resolver.dart';
import 'package:intl/intl.dart';

/// template expression evaluator
class Evaluator {
  /// create a new evaluator
  Evaluator(this._rootData) {
    _dataStack.add(_rootData);
    _scopeStack.add({r'$root': _rootData});
  }
  final Map<String, dynamic> _rootData;

  // Stack of data contexts. The last one is the current '$data'.
  final List<dynamic> _dataStack = [];

  // Mapping of magic variables for current scope
  // $index, $root, etc.
  final List<Map<String, dynamic>> _scopeStack = [];

  /// expand the template
  String expand(Map<String, dynamic> template) {
    // 1. Traverse and expand
    final result = _expandValue(template);
    // 2. Serialize to JSON string
    return json.encode(result);
  }

  dynamic _expandValue(dynamic value) {
    if (value is String) {
      return _expandString(value);
    } else if (value is List) {
      return _expandList(value);
    } else if (value is Map) {
      return _expandMap(value);
    }
    return value;
  }

  dynamic _expandString(String value) {
    // Check for expression syntax ${...} and deprecated {...}
    final pattern = RegExp(r'\$?\{([^}]+)\}');
    final matches = pattern.allMatches(value);

    // If exact match "${expression}",
    //  return the evaluated value (can be object, list, etc)
    if (matches.length == 1) {
      final match = matches.first;
      if (match.start == 0 && match.end == value.length) {
        try {
          return _evaluateExpression(match.group(1)!);
        } on Object catch (_) {
          return value; // failed to parse, return original literal
        }
      }
    }

    // String interpolation "Hello ${name}"
    return value.replaceAllMapped(pattern, (match) {
      try {
        final val = _evaluateExpression(match.group(1)!);
        return val?.toString() ?? '';
      } on Object catch (_) {
        return match.group(0)!; // failed to parse, don't replace
      }
    });
  }

  dynamic _expandList(List value) {
    final expandedList = <dynamic>[];
    for (final item in value) {
      // Handle array iteration if needed here or in map expansion?
      // Actually, $data on an element repeats that element.
      // But if 'item' is just a string, expand it.
      // If 'item' is a map, it might have $data.

      if (item is Map) {
        // Check if this item is a template for iteration
        // But wait, in Adaptive Cards, the item ITSELF has $data.
        // If we are evaluating a list, we just evaluate distinct items.
        // The expanding of *one* request item into *multiple* result items
        // happens when that one item has $data pointing to an array.
        // So _expandMap should return a List if it expanded to multiple items?

        final expandedItemOrItems = _expandMap(item as Map<String, dynamic>);
        if (expandedItemOrItems is List) {
          expandedList.addAll(expandedItemOrItems);
        } else if (expandedItemOrItems != null) {
          expandedList.add(expandedItemOrItems);
        }
      } else {
        expandedList.add(_expandValue(item));
      }
    }
    return expandedList;
  }

  // Returns Map or List<Map> or null (if hidden)
  dynamic _expandMap(Map value) {
    // 1. Check $data
    var pushedScope = false;

    // We need to resolve $data before processing other properties
    if (value.containsKey(r'$data')) {
      final dataProp = value[r'$data'];
      dynamic newData;
      if (dataProp is String) {
        newData = _expandValue(dataProp);
      } else {
        newData = dataProp;
      }

      if (newData is List) {
        // Repeater!
        // I like types for readability
        // ignore: omit_local_variable_types
        final List<dynamic> resultList = [];
        final originalTemplateWithoutData = Map<String, dynamic>.from(value);
        // more readable
        // ignore: cascade_invocations
        originalTemplateWithoutData.remove(r'$data');

        var index = 0;
        for (final item in newData) {
          _dataStack.add(item);
          _scopeStack.add({r'$root': _rootData, r'$index': index});

          final expandedItem = _expandMapObject(originalTemplateWithoutData);
          if (expandedItem != null) {
            resultList.add(expandedItem);
          }

          _scopeStack.removeLast();
          _dataStack.removeLast();
          index++;
        }
        return resultList;
      } else {
        // Scope change
        _dataStack.add(newData);
        _scopeStack.add({r'$root': _rootData}); // index not available?
        pushedScope = true;
      }
    }

    final result = _expandMapObject(value);

    if (pushedScope) {
      _dataStack.removeLast();
      _scopeStack.removeLast();
    }

    return result;
  }

  // Expands a map object in the CURRENT scope
  dynamic _expandMapObject(Map value) {
    final newMap = <String, dynamic>{};

    // 2. Check $when
    if (value.containsKey(r'$when')) {
      final whenProp = value[r'$when'];
      // Evaluate as boolean
      // E.g. "${price > 30}"
      // If it's a string expression
      var condition = true;
      if (whenProp is String) {
        final evaluated = _expandValue(
          whenProp,
        ); // Should return bool if boolean expression
        if (evaluated is bool) {
          condition = evaluated;
        } else {
          // Try to parse 'true'/'false'? Or truthy?
          // AC spec says it evaluates to boolean.
          // strict check
          condition = evaluated == true;
        }
      }

      if (!condition) return null;
    }

    for (final entry in value.entries) {
      if (entry.key == r'$data' || entry.key == r'$when') continue;

      // Keys can be expr per Adaptive Cards Spec: "${dynamicKey}": "value"
      final keyStr = (entry.key is String)
          ? entry.key as String
          : entry.key.toString();
      final expandedKey = _expandValue(keyStr)?.toString() ?? keyStr;

      final expandedVal = _expandValue(entry.value);
      newMap[expandedKey] = expandedVal;
    }
    return newMap;
  }

  dynamic _evaluateExpression(String expression) {
    final ast = ExpressionParser.parse(expression);
    return _evaluateAst(ast);
  }

  dynamic _evaluateAst(AstNode node) {
    if (node is LiteralNode) return node.value;

    if (node is IdentifierNode) {
      if (node.name == r'$root') return _rootData;
      if (node.name == r'$data') {
        return _dataStack.isNotEmpty ? _dataStack.last : null;
      }
      if (node.name == r'$index') {
        for (var i = _scopeStack.length - 1; i >= 0; i--) {
          if (_scopeStack[i].containsKey(r'$index')) {
            return _scopeStack[i][r'$index'];
          }
        }
        return null;
      }
      return Resolver.resolve(_dataStack.last, node.name);
    }

    if (node is MemberAccessNode) {
      final obj = _evaluateAst(node.object);
      if (obj == null) return null;

      var propStr = '';
      if (node.isComputed) {
        propStr = _evaluateAst(node.property).toString();
      } else {
        propStr = (node.property as IdentifierNode).name;
      }

      if (obj is Map && obj.containsKey(propStr)) {
        return obj[propStr];
      }
      if (obj is List) {
        final idx = int.tryParse(propStr);
        if (idx != null && idx >= 0 && idx < obj.length) return obj[idx];
      }
      return null;
    }

    if (node is UnaryExpressionNode) {
      final arg = _evaluateAst(node.argument);
      if (node.operator == '!') return !(arg == true);
      if (node.operator == '-') return -(arg as num);
      if (node.operator == '+') return (arg as num);
    }

    if (node is BinaryExpressionNode) {
      final left = _evaluateAst(node.left);

      // Short circuit
      if (node.operator == '&&') {
        if (left != true) return false;
        return _evaluateAst(node.right) == true;
      }
      if (node.operator == '||') {
        if (left == true) return true;
        return _evaluateAst(node.right) == true;
      }

      final right = _evaluateAst(node.right);
      switch (node.operator) {
        case '==':
          return left == right;
        case '!=':
          return left != right;
        case '>':
          return (left as num) > (right as num);
        case '>=':
          return (left as num) >= (right as num);
        case '<':
          return (left as num) < (right as num);
        case '<=':
          return (left as num) <= (right as num);
        case '+':
          if (left is num && right is num) return left + right;
          return left.toString() + right.toString();
        case '-':
          return (left as num) - (right as num);
        case '*':
          return (left as num) * (right as num);
        case '/':
          return (left as num) / (right as num);
        case '%':
          return (left as num) % (right as num);
        case '^':
          return math.pow(left as num, right as num);
      }
    }

    if (node is FunctionCallNode) {
      final funcNameNode = node.function;
      var name = '';
      if (funcNameNode is IdentifierNode) name = funcNameNode.name;

      final args = node.arguments.map(_evaluateAst).toList();

      if (name == 'json') {
        if (args.isEmpty || args[0] == null) return null;
        try {
          return json.decode(args[0].toString());
        } on Object catch (_) {
          return null;
        }
      }
      if (name == 'if') {
        if (args.length == 3) {
          return (args[0] == true) ? args[1] : args[2];
        }
      }
      if (name == 'length') {
        if (args.isNotEmpty) {
          final dynamic arg0 = args[0];
          if (arg0 is String) return arg0.length;
          if (arg0 is List) return arg0.length;
          if (arg0 is Map) return arg0.length;
        }
        return 0;
      }
      if (name == 'concat') {
        // cause I want it to be obvious
        // ignore: avoid_redundant_argument_values
        return args.map((e) => e?.toString() ?? '').join('');
      }
      if (name == 'empty') {
        if (args.isEmpty || args[0] == null) return true;
        final dynamic arg0 = args[0];
        if (arg0 is String) return arg0.isEmpty;
        if (arg0 is List) return arg0.isEmpty;
        if (arg0 is Map) return arg0.isEmpty;
        return false;
      }
      // String functions
      if (name == 'toUpper') {
        return args.isNotEmpty ? args[0]?.toString().toUpperCase() : null;
      }
      if (name == 'toLower') {
        return args.isNotEmpty ? args[0]?.toString().toLowerCase() : null;
      }
      if (name == 'trim') {
        return args.isNotEmpty ? args[0]?.toString().trim() : null;
      }
      if (name == 'substring') {
        if (args.isEmpty) return null;
        final str = args[0]?.toString() ?? '';
        final start = args.length > 1 ? (args[1] as num?)?.toInt() ?? 0 : 0;
        final len = args.length > 2 ? (args[2] as num?)?.toInt() : null;
        if (start < 0 || start > str.length) return str;
        if (len != null) {
          final end = start + len;
          if (end < start || end > str.length) return str.substring(start);
          return str.substring(start, end);
        }
        return str.substring(start);
      }
      if (name == 'replace') {
        if (args.length < 3) return null;
        return args[0]?.toString().replaceAll(
          args[1]?.toString() ?? '',
          args[2]?.toString() ?? '',
        );
      }

      // Math functions
      if (name == 'min') {
        if (args.isEmpty) return null;
        var m = args[0] as num;
        for (var i = 1; i < args.length; i++) {
          m = math.min(m, args[i] as num);
        }
        return m;
      }
      if (name == 'max') {
        if (args.isEmpty) return null;
        var m = args[0] as num;
        for (var i = 1; i < args.length; i++) {
          m = math.max(m, args[i] as num);
        }
        return m;
      }
      if (name == 'round') {
        if (args.isEmpty || args[0] == null) return null;
        return (args[0] as num).round();
      }
      if (name == 'floor') {
        if (args.isEmpty || args[0] == null) return null;
        return (args[0] as num).floor();
      }
      if (name == 'ceil') {
        if (args.isEmpty || args[0] == null) return null;
        return (args[0] as num).ceil();
      }

      // Date and Time Functions
      if (name == 'utcNow') {
        return DateTime.now().toUtc().toIso8601String();
      }
      if (name == 'formatDateTime') {
        if (args.isEmpty || args[0] == null) return null;
        try {
          final date = DateTime.parse(args[0].toString()).toLocal();
          final format = args.length > 1
              ? args[1]?.toString()
              : "yyyy-MM-dd'T'HH:mm:ss";
          return DateFormat(format).format(date);
        } on Object catch (_) {
          return args[0];
        }
      }
      if (name == 'date') {
        if (args.isEmpty || args[0] == null) return null;
        try {
          final date = DateTime.parse(args[0].toString());
          return DateFormat('M/d/yyyy').format(date);
        } on Object catch (_) {
          return null;
        }
      }
      if (name == 'year' || name == 'month' || name == 'dayOfMonth') {
        if (args.isEmpty || args[0] == null) return null;
        try {
          final date = DateTime.parse(args[0].toString());
          if (name == 'year') return date.year;
          if (name == 'month') return date.month;
          if (name == 'dayOfMonth') return date.day;
        } on Object catch (_) {
          return null;
        }
      }
      if (name == 'addDays' ||
          name == 'addHours' ||
          name == 'addMinutes' ||
          name == 'addSeconds') {
        if (args.length < 2 || args[0] == null || args[1] == null) return null;
        try {
          final date = DateTime.parse(args[0].toString());
          final amount = (args[1] as num).toInt();
          if (name == 'addDays') {
            return date.add(Duration(days: amount)).toIso8601String();
          }
          if (name == 'addHours') {
            return date.add(Duration(hours: amount)).toIso8601String();
          }
          if (name == 'addMinutes') {
            return date.add(Duration(minutes: amount)).toIso8601String();
          }
          if (name == 'addSeconds') {
            return date.add(Duration(seconds: amount)).toIso8601String();
          }
        } on Object catch (_) {
          return null;
        }
      }

      // Unknown function
      return null;
    }
    return null;
  }
}
