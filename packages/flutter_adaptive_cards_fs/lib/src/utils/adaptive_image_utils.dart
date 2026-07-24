import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/adaptive_error_placeholder.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 1×1 transparent PNG used as the fallback provider for a denied image URL.
final Uint8List _transparentPixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9'
  'awAAAABJRU5ErkJggg==',
);

/// Helpers for loading Adaptive Cards image URLs (network, SVG, data URI).
class AdaptiveImageUtils {
  /// Returns a widget that loads [url] as raster, SVG, or base64 image.
  ///
  /// When [uriPolicy] is non-null, network [url]s (non-`data:`) are validated
  /// first; a denied URL renders a broken-image placeholder instead of issuing
  /// a request, so untrusted cards cannot point images at private hosts.
  static Widget getImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
    String? semanticsLabel,
    AdaptiveUriPolicy? uriPolicy,
  }) {
    // Pass the label through as-is. A null label (decorative / no altText)
    // must stay null so Flutter excludes the image from the semantics tree,
    // rather than announcing a placeholder string to screen readers.
    final resolvedSemanticsLabel = semanticsLabel;
    final isDataUri = url.startsWith('data:image/') && url.contains('base64,');
    if (uriPolicy != null &&
        !isDataUri &&
        uriPolicy.validate(url) is AdaptiveUriDenied) {
      return Icon(
        Icons.broken_image,
        size: width ?? height,
        color: color,
        semanticLabel: resolvedSemanticsLabel,
      );
    }
    if (url.startsWith('data:image/') && url.contains('base64,')) {
      final String base64String = url.split('base64,')[1];
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit,
        color: color,
        semanticLabel: resolvedSemanticsLabel,
      );
    }

    if (url.toLowerCase().contains('.svg')) {
      return SvgPicture.network(
        url,
        width: width,
        height: height,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
        semanticsLabel: resolvedSemanticsLabel,
        errorBuilder: (context, error, stackTrace) => AdaptiveErrorPlaceholder(
          message: 'Failed to load image: $url',
          width: width,
          height: height,
          semanticsLabel: resolvedSemanticsLabel,
        ),
      );
    } else {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        color: color,
        semanticLabel: resolvedSemanticsLabel,
        errorBuilder: (context, error, stackTrace) => AdaptiveErrorPlaceholder(
          message: 'Failed to load image: $url',
          width: width,
          height: height,
          semanticsLabel: resolvedSemanticsLabel,
        ),
      );
    }
  }

  /// Returns an [ImageProvider] for [url] (memory or network).
  ///
  /// When [uriPolicy] is non-null, a denied network [url] yields a transparent
  /// 1×1 provider instead of a [NetworkImage], so untrusted background images
  /// cannot trigger requests to disallowed hosts.
  static ImageProvider getImageProvider(
    String url, {
    AdaptiveUriPolicy? uriPolicy,
  }) {
    if (url.startsWith('data:image/') && url.contains('base64,')) {
      final String base64String = url.split('base64,')[1];
      return MemoryImage(base64Decode(base64String));
    }
    if (uriPolicy != null && uriPolicy.validate(url) is AdaptiveUriDenied) {
      return MemoryImage(_transparentPixelPng);
    }
    return NetworkImage(url);
  }
}
