import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdaptiveImageUtils {
  static Widget getImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    if (url.toLowerCase().contains('.svg')) {
      return SvgPicture.network(
        url,
        width: width,
        height: height,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color, BlendMode.srcIn)
            : null,
      );
    } else {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        color: color,
      );
    }
  }
}
