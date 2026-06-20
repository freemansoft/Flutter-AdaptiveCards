import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getImage returns a broken-image placeholder for a denied URL', () {
    final widget = AdaptiveImageUtils.getImage(
      'http://192.168.1.1/secret.png',
      uriPolicy: AdaptiveUriPolicy.standard,
    );
    expect(widget, isA<Icon>());
    expect((widget as Icon).icon, Icons.broken_image);
  });

  test('getImage allows an in-policy network URL', () {
    final widget = AdaptiveImageUtils.getImage(
      'https://example.com/ok.png',
      uriPolicy: AdaptiveUriPolicy.standard,
    );
    expect(widget, isA<Image>());
  });

  test('getImageProvider returns a memory fallback for a denied URL', () {
    final provider = AdaptiveImageUtils.getImageProvider(
      'http://127.0.0.1/secret.png',
      uriPolicy: AdaptiveUriPolicy.standard,
    );
    expect(provider, isA<MemoryImage>());
  });

  test('getImage without a policy preserves legacy network behavior', () {
    final widget = AdaptiveImageUtils.getImage('http://192.168.1.1/x.png');
    expect(widget, isA<Image>());
  });
}
