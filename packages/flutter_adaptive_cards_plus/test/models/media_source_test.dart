import 'package:flutter_adaptive_cards_plus/src/models/media_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaSource', () {
    test('fromJson creates MediaSource with all properties', () {
      final json = {
        'url': 'https://example.com/video.mp4',
        'mimeType': 'video/mp4',
      };

      final mediaSource = MediaSource.fromJson(json);

      expect(mediaSource.url, 'https://example.com/video.mp4');
      expect(mediaSource.mimeType, 'video/mp4');
    });

    test('fromJson creates MediaSource with only url', () {
      final json = {
        'url': 'https://example.com/video.mp4',
      };

      final mediaSource = MediaSource.fromJson(json);

      expect(mediaSource.url, 'https://example.com/video.mp4');
      expect(mediaSource.mimeType, isNull);
    });

    test('fromJson handles missing url', () {
      final json = <String, dynamic>{};

      final mediaSource = MediaSource.fromJson(json);

      expect(mediaSource.url, '');
      expect(mediaSource.mimeType, isNull);
    });

    test('toJson includes all properties', () {
      const mediaSource = MediaSource(
        url: 'https://example.com/video.mp4',
        mimeType: 'video/mp4',
      );

      final json = mediaSource.toJson();

      expect(json['url'], 'https://example.com/video.mp4');
      expect(json['mimeType'], 'video/mp4');
    });

    test('toJson excludes null mimeType', () {
      const mediaSource = MediaSource(
        url: 'https://example.com/video.mp4',
      );

      final json = mediaSource.toJson();

      expect(json['url'], 'https://example.com/video.mp4');
      expect(json.containsKey('mimeType'), isFalse);
    });

    test('round-trip serialization works', () {
      const original = MediaSource(
        url: 'https://example.com/video.mp4',
        mimeType: 'video/mp4',
      );

      final json = original.toJson();
      final restored = MediaSource.fromJson(json);

      expect(restored.url, original.url);
      expect(restored.mimeType, original.mimeType);
    });

    test('equality works correctly', () {
      const source1 = MediaSource(
        url: 'https://example.com/video.mp4',
        mimeType: 'video/mp4',
      );
      const source2 = MediaSource(
        url: 'https://example.com/video.mp4',
        mimeType: 'video/mp4',
      );
      const source3 = MediaSource(
        url: 'https://example.com/different.mp4',
        mimeType: 'video/mp4',
      );

      expect(source1, equals(source2));
      expect(source1, isNot(equals(source3)));
    });

    test('hashCode works correctly', () {
      const source1 = MediaSource(
        url: 'https://example.com/video.mp4',
        mimeType: 'video/mp4',
      );
      const source2 = MediaSource(
        url: 'https://example.com/video.mp4',
        mimeType: 'video/mp4',
      );

      expect(source1.hashCode, equals(source2.hashCode));
    });
  });
}
