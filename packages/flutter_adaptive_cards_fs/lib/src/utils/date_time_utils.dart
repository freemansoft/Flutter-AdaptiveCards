import 'package:intl/intl.dart';

class DateTimeUtils {
  static final RegExp _dateRegex = RegExp(r'\{\{DATE\((.*?)\)\}\}');
  static final RegExp _timeRegex = RegExp(r'\{\{TIME\((.*?)\)\}\}');

  /// Parses an Adaptive Cards text string and replaces {{DATE}} and {{TIME}} macros.
  static String formatText(String input) {
    var result = input;
    
    // Replace {{DATE(timestamp, FORMAT)}}
    result = result.replaceAllMapped(_dateRegex, (match) {
      final argsStr = match.group(1);
      if (argsStr == null || argsStr.isEmpty) return match.group(0)!;
      
      final args = argsStr.split(',').map((e) => e.trim()).toList();
      final timestamp = args[0];
      final formatHint = args.length > 1 ? args[1].toUpperCase() : 'COMPACT';
      
      try {
        final date = DateTime.parse(timestamp).toLocal();
        if (formatHint == 'COMPACT') {
          return DateFormat.yMd().format(date);
        } else if (formatHint == 'SHORT') {
          return DateFormat('E, MMM d, yyyy').format(date);
        } else if (formatHint == 'LONG') {
          return DateFormat('EEEE, MMMM d, yyyy').format(date);
        } else {
          return DateFormat.yMd().format(date);
        }
      } catch (e) {
        return match.group(0)!;
      }
    });

    // Replace {{TIME(timestamp)}}
    result = result.replaceAllMapped(_timeRegex, (match) {
      final argsStr = match.group(1);
      if (argsStr == null || argsStr.isEmpty) return match.group(0)!;
      
      final args = argsStr.split(',').map((e) => e.trim()).toList();
      final timestamp = args[0];
      
      try {
        final date = DateTime.parse(timestamp).toLocal();
        return DateFormat.jm().format(date);
      } catch (e) {
        return match.group(0)!;
      }
    });

    return result;
  }
}
