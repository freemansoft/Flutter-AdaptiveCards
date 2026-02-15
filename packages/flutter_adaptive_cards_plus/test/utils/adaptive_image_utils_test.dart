import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/adaptive_image_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveImageUtils Tests', () {
    test('getImage returns Image.memory for base64 data', () {
      const String base64Url =
          'data:image/png;base64,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';

      final Widget widget = AdaptiveImageUtils.getImage(base64Url);

      expect(widget, isA<Image>());
      final Image image = widget as Image;
      expect(image.image, isA<MemoryImage>());
    });

    test('getImage returns SvgPicture for svg urls', () {
      const String svgUrl = 'https://example.com/image.svg';

      final Widget widget = AdaptiveImageUtils.getImage(svgUrl);

      expect(widget, isA<SvgPicture>());
    });

    test('getImage returns Image.network for regular urls', () {
      const String imageUrl = 'https://example.com/image.png';

      final Widget widget = AdaptiveImageUtils.getImage(imageUrl);

      expect(widget, isA<Image>());
      final Image image = widget as Image;
      expect(image.image, isA<NetworkImage>());
    });
  });
}
