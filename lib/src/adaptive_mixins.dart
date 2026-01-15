import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin AdaptiveElementWidgetMixin on StatefulWidget {
  // this is an abstract method that everyone needs to implmenet
  Map<String, dynamic> get adaptiveMap;
}

mixin AdaptiveElementMixin<T extends AdaptiveElementWidgetMixin> on State<T> {
  late String id;

  late RawAdaptiveCardState widgetState;

  Map<String, dynamic> get adaptiveMap => widget.adaptiveMap;

  @override
  void initState() {
    super.initState();

    widgetState = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(rawAdaptiveCardStateProvider);
    if (widget.adaptiveMap.containsKey('id')) {
      id = widget.adaptiveMap['id'];
    } else {
      id = UUIDGenerator().getId();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveElementMixin &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  BoxFit calculateBackgroundImageFit(String? fillMode) {
    switch (fillMode) {
      case 'repeatvertically':
      case 'repeathorizontally':
      case 'repeat':
        return BoxFit.none;
      default:
        return BoxFit.cover;
    }
  }

  ImageRepeat calculateBackgroundImageRepeat(String? fillMode) {
    switch (fillMode) {
      case 'repeatvertically':
        return ImageRepeat.repeatY;
      case 'repeathorizontally':
        return ImageRepeat.repeatX;
      case 'repeat':
        return ImageRepeat.repeat;
      default:
        return ImageRepeat.noRepeat;
    }
  }

  /// Reliable image loader that handles image not found
  Widget getBackgroundImage(
    String url, {
    ImageRepeat repeat = ImageRepeat.noRepeat,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      url,
      repeat: repeat,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.error);
      },
      loadingBuilder: (context, child, loadingProgress) {
        // Optional: display a loading indicator while the image is fetching
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  /// Always returns a widget, even if the image is not specified
  Widget? getBackgroundImageFromMap(Map element) {
    // could be string or map
    if (element['backgroundImage'] is String) {
      return getBackgroundImage(
        element['backgroundImage'] as String,
      );
    }

    var backgroundImage = element['backgroundImage'];
    // JSON Schema definition for BackgroundImage
    // has properties "url" and "fillMode"
    if (backgroundImage != null && backgroundImage['url'] != null) {
      var backgroundImageUrl = backgroundImage['url'];
      // JSON Schema definition "ImageFillMode"
      // has values 'cover', 'repeatHorizontally', 'repeatVertically', 'repeat'
      var fillMode = backgroundImage['fillMode'] != null
          ? backgroundImage['fillMode'].toString().toLowerCase()
          : 'cover';

      BoxFit fit = calculateBackgroundImageFit(fillMode);
      ImageRepeat repeat = calculateBackgroundImageRepeat(fillMode);

      return getBackgroundImage(
        backgroundImageUrl,
        repeat: repeat,
        fit: fit,
      );
    } else {
      return null;
      // return const SizedBox(width: 0, height: 0);
    }
  }
}

mixin AdaptiveActionMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  String get title => widget.adaptiveMap['title'] ?? '';

  void onTapped();
}

mixin AdaptiveInputMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late String value;
  late String placeholder;

  @override
  void initState() {
    super.initState();
    value = adaptiveMap['value'].toString() == 'null'
        ? ''
        : adaptiveMap['value'].toString();

    placeholder = widget.adaptiveMap['placeholder'] ?? '';
  }

  /// Input cards implement this to copy their state **to** the map
  void appendInput(Map map);

  /// Input cards implement this as a way of loading state from a Map, `inputData`
  void initInput(Map map);

  /// Input card types implement this as a way of changing their state, currently only choice_set
  void loadInput(Map map) {}

  bool checkRequired();

  void resetInput() {
    // Default implementation: reset to initial value
    value = adaptiveMap['value'].toString() == 'null'
        ? ''
        : adaptiveMap['value'].toString();
    // Subclasses should override update their text controllers etc.
  }

  BoxFit calculateBackgroundImageFit(String? fillMode) {
    switch (fillMode) {
      case 'repeatvertically':
      case 'repeathorizontally':
      case 'repeat':
        return BoxFit.none;
      default:
        return BoxFit.cover;
    }
  }

  ImageRepeat calculateBackgroundImageRepeat(String? fillMode) {
    switch (fillMode) {
      case 'repeatvertically':
        return ImageRepeat.repeatY;
      case 'repeathorizontally':
        return ImageRepeat.repeatX;
      case 'repeat':
        return ImageRepeat.repeat;
      default:
        return ImageRepeat.noRepeat;
    }
  }
}

mixin AdaptiveTextualInputMixin<T extends AdaptiveElementWidgetMixin>
    on State<T>
    implements AdaptiveInputMixin<T> {
  @override
  void initState() {
    super.initState();
  }
}
