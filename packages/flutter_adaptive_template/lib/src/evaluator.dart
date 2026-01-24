// JSON conversion can be a lot of things so it is dynamic
// ignore_for_file: strict_raw_type

import 'dart:convert';
import 'package:flutter_adaptive_template/src/resolver.dart';

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
    // Check for expression syntax ${...}
    // Is a simplified regex, might need a proper parser for nested braces etc.
    // For now, let's assume simple cases or match the full string.

    final pattern = RegExp(r'\$\{(.*?)\}');
    final matches = pattern.allMatches(value);

    // If exact match "${expression}",
    //  return the evaluated value (can be object, list, etc)
    if (matches.length == 1) {
      final match = matches.first;
      if (match.start == 0 && match.end == value.length) {
        return _evaluateExpression(match.group(1)!);
      }
    }

    // String interpolation "Hello ${name}"
    return value.replaceAllMapped(pattern, (match) {
      final val = _evaluateExpression(match.group(1)!);
      return val?.toString() ?? '';
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

      final key =
          entry.key; // Keys can also be templated? "Implicitly binds..."
      // Spec says: "${<property>}": "Implicitly binds..."

      // TODO(username): Key expansion? For now assuming static keys.

      final expandedVal = _expandValue(entry.value);
      newMap[key as String] = expandedVal;
    }
    return newMap;
  }

  dynamic _evaluateExpression(String expression) {
    final expr = expression.trim();

    // 1. Literal Strings
    if ((expr.startsWith("'") && expr.endsWith("'")) ||
        (expr.startsWith('"') && expr.endsWith('"'))) {
      if (expr.length < 2) return '';
      return expr.substring(1, expr.length - 1);
    }

    // 2. Numeric Literals
    if (num.tryParse(expr) != null) {
      return num.parse(expr);
    }

    // 3. Comparisons (Naive)
    // >, <, <=, >=, ==, !=
    // Use regex to split safely? For now, manual check.
    if (expr.contains(' > ')) {
      final parts = expr.split(' > ');
      if (parts.length == 2) {
        final left = _evaluateExpression(parts[0]);
        final right = _evaluateExpression(parts[1]);
        if (left is num && right is num) return left > right;
      }
    }
    if (expr.contains(' <= ')) {
      final parts = expr.split(' <= ');
      if (parts.length == 2) {
        final left = _evaluateExpression(parts[0]);
        final right = _evaluateExpression(parts[1]);
        if (left is num && right is num) return left <= right;
      }
    }

    // 4. Reserved Keywords (simple)
    if (expr == r'$root') return _rootData;
    if (expr == r'$data') return _dataStack.last;
    if (expr == r'$index') {
      for (var i = _scopeStack.length - 1; i >= 0; i--) {
        if (_scopeStack[i].containsKey(r'$index')) {
          return _scopeStack[i][r'$index'];
        }
      }
      return null;
    }

    // 5. Function Calls (balanced parens) & Property Chains
    if (expr.contains('(')) {
      final openParen = expr.indexOf('(');
      // Check if it looks like a function call at the start
      final funcName = expr.substring(0, openParen).trim();

      // Known functions
      if (funcName == 'json' || funcName == 'if') {
        var balance = 0;
        var closeParen = -1;
        for (var i = openParen; i < expr.length; i++) {
          if (expr[i] == '(') balance++;
          if (expr[i] == ')') balance--;
          if (balance == 0) {
            closeParen = i;
            break;
          }
        }

        if (closeParen != -1) {
          final argsStr = expr.substring(openParen + 1, closeParen);
          final after = expr.substring(closeParen + 1).trim();

          dynamic result;

          if (funcName == 'json') {
            final evaluatedArg = _evaluateExpression(argsStr);
            if (evaluatedArg is String) {
              try {
                result = json.decode(evaluatedArg);
              } catch (_) {
                result = null;
              }
            } else {
              result = null;
            }
          } else if (funcName == 'if') {
            final args = _splitArgs(argsStr);
            if (args.length == 3) {
              final cond = _evaluateExpression(args[0]);
              result = (cond == true)
                  ? _evaluateExpression(args[1])
                  : _evaluateExpression(args[2]);
            }
          }

          // Resolve remaining path if any
          if (after.isNotEmpty) {
            String? p;
            if (after.startsWith('.')) {
              p = after.substring(1);
            } else if (after.startsWith('[')) {
              p = after;
            }

            if (p != null) {
              return Resolver.resolve(result, p);
            }
          }

          return result;
        }
      }
    }

    // 6. Property access on keywords
    if (expr.startsWith(r'$root.')) {
      return Resolver.resolve(_rootData, expr.substring(6));
    }
    if (expr.startsWith(r'$data.')) {
      return Resolver.resolve(_dataStack.last, expr.substring(6));
    }

    // 7. Fallback property access
    return Resolver.resolve(_dataStack.last, expr);
  }

  List<String> _splitArgs(String args) {
    // Extremely naive split by comma, respecting quotes would be needed
    // For now verification tasks likely simple
    return args.split(',').map((e) => e.trim()).toList();
  }
}
