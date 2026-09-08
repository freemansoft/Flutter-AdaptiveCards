import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/blog/to_blogger.dart';

// to_blogger.dart converts a draft in blog/ into HTML for Blogger's HTML view.
// The cases below cover the three things that break a naive conversion there:
// Blogger turning source line wrapping into <br>, its themes supplying no CSS
// for what the drafts rely on, and relative image paths that do not resolve.
void main() {
  group('convertToBloggerHtml', () {
    test('emits no styling of its own', () {
      final html = convertToBloggerHtml('''
# Title

A paragraph with `code` in it.

| a   | b   |
| --- | --- |
| 1   | 2   |
''');

      expect(html, isNot(contains('style=')));
      expect(html, isNot(contains('<style')));
      expect(html, contains('<table>'));
      expect(html, contains('<code>'));
    });

    test('drops the h1, because Blogger has its own title field', () {
      final html = convertToBloggerHtml('# Title\n\nBody.\n');

      expect(html, isNot(contains('<h1')));
      expect(html, contains('<p>Body.</p>'));
    });

    test('keeps the h1 when asked', () {
      final html = convertToBloggerHtml('# Title\n\nBody.\n', keepTitle: true);

      expect(html, contains('<h1>Title</h1>'));
    });

    test('unwraps hard-wrapped prose onto one line per block', () {
      // Blogger renders a newline inside post HTML as a <br>, so a paragraph
      // wrapped at 78 columns would arrive as a ragged column.
      final html = convertToBloggerHtml('''
One sentence that the author
wrapped across three
source lines.

A second paragraph.
''');

      final lines = html.trim().split('\n');
      expect(lines, hasLength(2));
      expect(lines.first, contains('wrapped across three source lines.'));
    });

    test('preserves newlines inside fenced code', () {
      final html = convertToBloggerHtml('''
Intro.

```bash
one
two
```
''');

      expect(html, contains('one\ntwo'));
      expect(html, contains('<pre>'));
    });

    test('tokenizes image sources, which do not resolve on Blogger', () {
      final html = convertToBloggerHtml('![Alt text](shot.png)\n');

      expect(html, contains('{{IMAGE_URL:shot.png}}'));
      expect(html, contains('alt="Alt text"'));
    });

    test('leaves image sources alone when tokens are turned off', () {
      final html = convertToBloggerHtml(
        '![Alt text](shot.png)\n',
        imageTokens: false,
      );

      expect(html, contains('src="shot.png"'));
      expect(html, isNot(contains('IMAGE_URL')));
    });

    test('joins an image and its italic caption into one figure', () {
      final html = convertToBloggerHtml('''
![Alt text](shot.png)

_The caption._
''');

      expect(html, contains('<figure>'));
      expect(html, contains('<figcaption>The caption.</figcaption>'));
    });

    test('renders a GitHub alert as a blockquote, not an unstyled div', () {
      // package:markdown emits a div whose prominence comes from GitHub's own
      // stylesheet; a blockquote is indented with no stylesheet at all.
      final html = convertToBloggerHtml('''
> [!CAUTION]
>
> Do not do this.
''');

      expect(html, contains('<blockquote>'));
      expect(html, contains('<strong>CAUTION</strong>'));
      expect(html, isNot(contains('markdown-alert')));
    });

    test('does not break a line inside a table row', () {
      final html = convertToBloggerHtml('''
| Model | Score |
| ----- | ----- |
| a     | 1     |
''');

      final tableLine = html
          .split('\n')
          .firstWhere((l) => l.contains('<table>'));
      expect(tableLine, contains('</table>'));
    });
  });
}
