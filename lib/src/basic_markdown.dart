import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class BasicMarkdown extends MarkdownWidget {
  /// Creates a non-scrolling widget that parses and displays Markdown.
  const BasicMarkdown(
      {super.key,
      required super.data,
      required MarkdownStyleSheet super.styleSheet,
      required SyntaxHighlighter super.syntaxHighlighter,
      required MarkdownTapLinkCallback super.onTapLink,
      required String super.imageDirectory,
      required this.maxLines});

  final int maxLines;

  @override
  Widget build(BuildContext context, List<Widget>? children) {
    if (children?.length == 1) return children!.single;

    //if(maxLines != null && )
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children ?? [],
    );
  }
}
