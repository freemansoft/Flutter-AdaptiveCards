/// Parsed **`TextRun`** inline from a **`RichTextBlock`** `inlines` array.
///
/// See [TextRun](https://adaptivecards.io/explorer/TextRun.html).
/// See [TextRun](https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/text-run).
class const TextRunModel({
  /// Run display text.
  required final String text,

  /// Semantic foreground color token.
  final String? color,

  /// Monospace vs default font token.
  final String? fontType,

  /// When true, apply highlight background on this run.
  final bool highlight = false,

  /// When true, use subtle foreground color.
  final bool isSubtle = false,

  /// When true, render italic.
  final bool italic = false,

  /// Optional per-run tap action.
  final Map<String, dynamic>? selectAction,

  /// Size token (`Small`, `Medium`, `Large`, …).
  final String? size,

  /// When true, strikethrough decoration.
  final bool strikethrough = false,

  /// When true, underline decoration.
  final bool underline = false,

  /// Weight token (`Lighter`, `Default`, `Bolder`, …).
  final String? weight,
}) {
  /// Creates a text run with display [text] and optional inline styling.
  this;

  /// Parses a `TextRun` object from card JSON.
  factory fromJson(Map<String, dynamic> json) {
    return TextRunModel(
      text: json['text']?.toString() ?? '',
      color: json['color']?.toString(),
      fontType: json['fontType']?.toString(),
      highlight: json['highlight'] as bool? ?? false,
      isSubtle: json['isSubtle'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      selectAction: json['selectAction'] is Map
          ? Map<String, dynamic>.from(json['selectAction'] as Map)
          : null,
      size: json['size']?.toString(),
      strikethrough: json['strikethrough'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      weight: json['weight']?.toString(),
    );
  }
}

/// Parses a card JSON `inlines` array; returns empty when invalid.
List<Map<String, dynamic>> inlinesFromJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

/// Serializes inlines for overlay merge boundaries.
List<Map<String, dynamic>> inlinesToJsonList(
  List<Map<String, dynamic>> inlines,
) => inlines.map(Map<String, dynamic>.from).toList();
