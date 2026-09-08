/// Converts a blog draft in `blog/` to HTML that can be pasted into Google
/// Blogger's HTML view without losing tables, code, or paragraph structure.
///
/// Blogger is not a Markdown host and imposes three constraints that a plain
/// Markdown-to-HTML conversion does not satisfy:
///
/// 1. **It turns newlines in post HTML into `<br>`.** The drafts hard-wrap at
///    about 78 columns, so a naive conversion renders every paragraph as a
///    ragged column. Everything outside `<pre>` is therefore emitted
///    unwrapped, one line per top-level block. Newlines inside `<pre>` are
///    content, so those blocks are lifted out before unwrapping and put back
///    afterwards.
/// 2. **Its Compose view re-serializes the document**, which is the usual way
///    a pasted table gets flattened. Nothing here can prevent that; paste into
///    the HTML view and publish from the HTML view.
/// 3. **The post title is a separate field.** The `<h1>` is dropped so the
///    title does not appear twice. Pass `--keep-title` for other destinations.
///
/// No `style` attributes are emitted and no stylesheet is referenced: the
/// destination theme owns presentation. Fenced code keeps its
/// `class="language-*"`, which is inert without a highlighter and is what a
/// highlighter would look for if one is ever added.
///
/// Relative image paths do not resolve on Blogger. Each `src` becomes a
/// `{{IMAGE_URL:<original path>}}` token: upload the image through the
/// Blogger editor first, then substitute the URL it assigns.
///
/// Output goes to stdout so that a generated page never lands in the working
/// tree, since these are transient and are not checked in:
///
/// ```sh
/// fvm dart run tool/blog/to_blogger.dart blog/<draft>.md | pbcopy
/// fvm dart run tool/blog/to_blogger.dart blog/<draft>.md --out /tmp/a.html
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:markdown/markdown.dart' as md;

/// Block-level tags that may begin a line in the emitted HTML.
///
/// A newline is reinstated only between two of these, which keeps line breaks
/// out of table cells and list items where Blogger would render them as
/// `<br>`.
const _blockTags = 'h[1-6]|p|ul|ol|table|figure|blockquote|pre|hr';

/// Converts [source] Markdown to HTML for pasting into a themed CMS.
///
/// Set [keepTitle] to retain the leading `<h1>` for a destination that has no
/// separate title field. [imageTokens] controls whether image sources are
/// replaced with substitutable `{{IMAGE_URL:...}}` tokens; turn it off when
/// the images are already reachable at the paths the document names.
String convertToBloggerHtml(
  String source, {
  bool keepTitle = false,
  bool imageTokens = true,
}) {
  var html = md.markdownToHtml(
    source,
    extensionSet: md.ExtensionSet.gitHubWeb,
    inlineSyntaxes: [md.InlineHtmlSyntax()],
  );

  html = _rewriteGitHubAlerts(html);
  html = _buildFigures(html);
  if (imageTokens) html = _tokenizeImages(html);
  if (!keepTitle) {
    html = html.replaceAll(RegExp(r'<h1[^>]*>[\s\S]*?</h1>\s*'), '');
  }
  // Heading anchors are noise in a post body and collide with nothing there.
  html = html.replaceAllMapped(
    RegExp('<(h[1-6]) id="[^"]*">'),
    (m) => '<${m[1]}>',
  );

  return _unwrap(html);
}

/// Rewrites GitHub alert blockquotes as ordinary blockquotes.
///
/// `package:markdown` renders `> [!CAUTION]` as a `div` whose prominence comes
/// entirely from GitHub's own stylesheet, so it arrives unstyled anywhere else.
/// A blockquote is indented by every browser with no stylesheet at all, which
/// keeps the callout reading as set apart.
String _rewriteGitHubAlerts(String html) {
  // Alerts do not nest, so a non-greedy match reaches the right closing tag.
  final asQuotes = html.replaceAllMapped(
    RegExp(r'<div class="markdown-alert[^"]*">([\s\S]*?)</div>'),
    (m) => '<blockquote>${m[1]}</blockquote>',
  );
  return asQuotes.replaceAllMapped(
    RegExp('<p class="markdown-alert-title">([^<]*)</p>'),
    (m) => '<p><strong>${m[1]!.toUpperCase()}</strong></p>',
  );
}

/// Joins an image and the italic line beneath it into one captioned figure.
///
/// The drafts write a caption as an emphasised paragraph following the image,
/// which otherwise converts to two unrelated paragraphs.
String _buildFigures(String html) {
  return html.replaceAllMapped(
    RegExp(r'<p>(<img[^>]*>)</p>\s*<p><em>([\s\S]*?)</em></p>'),
    (m) => '<figure>${m[1]}<figcaption>${m[2]}</figcaption></figure>',
  );
}

/// Replaces each image source with a token naming the original path.
String _tokenizeImages(String html) {
  return html.replaceAllMapped(
    RegExp(r'<img src="([^"]*)" alt="([^"]*)"\s*/?>'),
    (m) => '<img src="{{IMAGE_URL:${m[1]}}}" alt="${m[2]}" />',
  );
}

/// Removes source line wrapping, preserving `<pre>` content verbatim.
String _unwrap(String html) {
  final pres = <String>[];
  var out = html.replaceAllMapped(RegExp(r'<pre>[\s\S]*?</pre>'), (m) {
    pres.add(m[0]!);
    return ' \u0000${pres.length - 1}\u0000 ';
  });

  out = out.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
  out = out.replaceAllMapped(
    RegExp('(</(?:$_blockTags)>) *(<(?:$_blockTags)[ >])'),
    (m) => '${m[1]}\n${m[2]}',
  );

  return out.replaceAllMapped(
    RegExp(
      '\u0000'
      r'(\d+)'
      '\u0000',
    ),
    (m) => pres[int.parse(m[1]!)],
  );
}

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('out', abbr: 'o', help: 'Write to this file instead of stdout.')
    ..addFlag(
      'keep-title',
      negatable: false,
      help: 'Keep the leading <h1>. Blogger supplies its own title field.',
    )
    ..addFlag(
      'no-image-tokens',
      negatable: false,
      help: 'Leave image paths as written instead of tokenizing them.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final opts = parser.parse(args);
  if (opts['help'] as bool || opts.rest.length != 1) {
    stdout
      ..writeln('Usage: dart run tool/blog/to_blogger.dart <draft.md> [flags]')
      ..writeln(parser.usage);
    exit(opts['help'] as bool ? 0 : 64);
  }

  final input = File(opts.rest.single);
  if (!input.existsSync()) {
    stderr.writeln('No such file: ${input.path}');
    exit(66);
  }

  final html = convertToBloggerHtml(
    input.readAsStringSync(),
    keepTitle: opts['keep-title'] as bool,
    imageTokens: !(opts['no-image-tokens'] as bool),
  );

  final out = opts['out'] as String?;
  if (out == null) {
    stdout.writeln(html);
  } else {
    File(out).writeAsStringSync('$html\n');
    stderr.writeln('wrote $out');
  }
}
