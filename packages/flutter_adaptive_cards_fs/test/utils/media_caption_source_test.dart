import 'package:flutter_adaptive_cards_fs/src/utils/media_caption_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('captionSourcesFromJsonList', () {
    test('parses a list of caption descriptors', () {
      final result = captionSourcesFromJsonList(<Map<String, dynamic>>[
        {'mimeType': 'vtt', 'label': 'English', 'url': 'https://x/en.vtt'},
        {'mimeType': 'vtt', 'label': 'French', 'url': 'https://x/fr.vtt'},
      ]);
      expect(result, hasLength(2));
      expect(result[0].label, 'English');
      expect(result[0].url, 'https://x/en.vtt');
      expect(result[0].mimeType, 'vtt');
    });

    test('returns empty list for null or non-list input', () {
      expect(captionSourcesFromJsonList(null), isEmpty);
      expect(captionSourcesFromJsonList('nope'), isEmpty);
    });

    test('skips entries without a url', () {
      final result = captionSourcesFromJsonList(<Map<String, dynamic>>[
        {'mimeType': 'vtt', 'label': 'NoUrl'},
        {'mimeType': 'vtt', 'label': 'Ok', 'url': 'https://x/a.vtt'},
      ]);
      expect(result, hasLength(1));
      expect(result[0].label, 'Ok');
    });
  });
}
