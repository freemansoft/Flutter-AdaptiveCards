/// Parsed **`TextRun`** inline from a **`RichTextBlock`** `inlines` array.
///
/// See [TextRun](https://adaptivecards.io/explorer/TextRun.html).
class TextRunModel {
  /// Creates a text run with display [text] and optional inline styling.
  const TextRunModel({
    required this.text,
    this.color,
    this.fontType,
    this.highlight = false,
    this.isSubtle = false,
    this.italic = false,
    this.selectAction,
    this.size,
    this.strikethrough = false,
    this.underline = false,
    this.weight,
  });

  /// Parses a `TextRun` object from card JSON.
  factory TextRunModel.fromJson(Map<String, dynamic> json) {
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

  /// Run display text.
  final String text;

  /// Semantic foreground color token.
  final String? color;

  /// Monospace vs default font token.
  final String? fontType;

  /// When true, apply highlight background on this run.
  final bool highlight;

  /// When true, use subtle foreground color.
  final bool isSubtle;

  /// When true, render italic.
  final bool italic;

  /// Optional per-run tap action.
  final Map<String, dynamic>? selectAction;

  /// Size token (`Small`, `Medium`, `Large`, …).
  final String? size;

  /// When true, strikethrough decoration.
  final bool strikethrough;

  /// When true, underline decoration.
  final bool underline;

  /// Weight token (`Lighter`, `Default`, `Bolder`, …).
  final String? weight;
}
