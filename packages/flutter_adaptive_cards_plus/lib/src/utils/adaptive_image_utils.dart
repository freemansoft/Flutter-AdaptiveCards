import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdaptiveImageUtils {
  static Widget getImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
    String? semanticsLabel,
  }) {
    final resolvedSemanticsLabel = semanticsLabel ?? 'alt text not set';
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
      );
    } else {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        color: color,
        semanticLabel: resolvedSemanticsLabel,
      );
    }
  }

  static ImageProvider getImageProvider(String url) {
    if (url.startsWith('data:image/') && url.contains('base64,')) {
      final String base64String = url.split('base64,')[1];
      return MemoryImage(base64Decode(base64String));
    }
    return NetworkImage(url);
  }
}
