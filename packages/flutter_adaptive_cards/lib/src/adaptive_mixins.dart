import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:format/format.dart';

// Mixin for widgets that are adaptive elements- widget and not state

mixin AdaptiveElementWidgetMixin on StatefulWidget {
  // this is an abstract method that everyone needs to implmenet

  /// implementers will need to provide the adaptive map
  Map<String, dynamic> get adaptiveMap;

  /// implementers will need to provide the widget state
  RawAdaptiveCardState get widgetState;

  /// implementers will need to provide the id
  String get id;
}

mixin AdaptiveElementMixin<T extends AdaptiveElementWidgetMixin> on State<T> {
  String get id => widget.id;

  RawAdaptiveCardState get widgetState => widget.widgetState;

  Map<String, dynamic> get adaptiveMap => widget.adaptiveMap;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // only register cards with IDs so we can target them
    if (idIsNatural(adaptiveMap)) {
      // register cards with IDs so we can target them
      // At one time this was only used for showCard
      // TODO(username): We don't have a good way to unregister cards see dispose()
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(adaptiveCardElementStateProvider).registerCardWidget(id, widget);
    } else {
      // a lot of them don't have ids
      //debugPrint('No ID found for ${widget.runtimeType}');
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
    final myFillMode = fillMode?.toLowerCase();
    switch (myFillMode) {
      case 'repeatvertically':
      case 'repeathorizontally':
      case 'repeat':
        return BoxFit.none;
      default:
        return BoxFit.cover;
    }
  }

  ImageRepeat calculateBackgroundImageRepeat(String? fillMode) {
    final myFillMode = fillMode?.toLowerCase();
    switch (myFillMode) {
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

  /// Reliable image loader that handles when image not found
  /// Cards that support background images include
  /// AdaptiveCard, Column, Container, TableCell, Authentication
  Widget getBackgroundImage(
    String url, {
    ImageRepeat repeat = ImageRepeat.noRepeat,
    BoxFit fit = BoxFit.cover,
  }) {
    return AdaptiveImageUtils.getImage(
      url,
      fit: fit,
    );
  }

  /// Reliable image provider loader that handles base64 and network images
  ImageProvider getBackgroundImageProvider(String url) {
    return AdaptiveImageUtils.getImageProvider(url);
  }

  /// internal helper to resolve the background image properties from either a string or a map
  ({String url, BoxFit fit, ImageRepeat repeat})? resolveBackgroundImage(
    dynamic backgroundImage,
  ) {
    if (backgroundImage == null) return null;

    if (backgroundImage is String) {
      return (
        url: backgroundImage,
        fit: BoxFit.cover,
        repeat: ImageRepeat.noRepeat,
      );
    }

    if (backgroundImage is Map && backgroundImage['url'] != null) {
      final url = backgroundImage['url'];
      final fillMode = backgroundImage['fillMode']?.toString().toLowerCase();

      return (
        url: url,
        fit: calculateBackgroundImageFit(fillMode),
        repeat: calculateBackgroundImageRepeat(fillMode),
      );
    }

    return null;
  }

  /// JSON schema aware version of getBackgroundImage
  Widget? getBackgroundImageFromMap(Map element) {
    final props = resolveBackgroundImage(element['backgroundImage']);
    if (props == null) return null;

    return getBackgroundImage(props.url, repeat: props.repeat, fit: props.fit);
  }

  /// JSON schema aware BoxDecoration wrapper of getDecorationImageFromMap
  BoxDecoration getDecorationFromMap(Map element, {Color? backgroundColor}) {
    final decorationImage = getDecorationImageFromMap(element);
    return BoxDecoration(image: decorationImage, color: backgroundColor);
  }

  /// JSON schema aware DecorationImage wrapper of DecorationImage
  /// Cards that support background images include
  /// AdaptiveCard, Column, Container, TableCell, Authentication
  DecorationImage? getDecorationImageFromMap(Map element) {
    final props = resolveBackgroundImage(element['backgroundImage']);
    if (props == null) return null;

    return DecorationImage(
      image: getBackgroundImageProvider(props.url),
      repeat: props.repeat,
      fit: props.fit,
    );
  }
}

mixin AdaptiveActionMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  String get title => adaptiveMap['title'] as String? ?? '';

  void onTapped();
}

mixin AdaptiveInputMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late String value;
  late String placeholder;
  late String? errorMessage;

  @override
  void initState() {
    super.initState();
    value = adaptiveMap['value'].toString() == 'null'
        ? ''
        : adaptiveMap['value'].toString();

    placeholder = adaptiveMap['placeholder'] as String? ?? '';
    errorMessage = adaptiveMap['errorMessage'] as String?;
  }

  /// Input cards implement this to copy their state **to** the map
  void appendInput(Map map);

  /// Input cards implement this as a way of loading state from a Map, `inputData`
  void initInput(Map map);

  /// Input card types implement this as a way of changing their state, currently only choice_set
  void loadInput(Map map) {}

  /// this is a prototype that is overridden by the input fields
  /// to check if they are required and there is a value
  bool checkRequired();

  void resetInput() {
    // Default implementation: reset to initial value to the map value
    if (adaptiveMap.containsKey('value')) {
      assert(() {
        developer.log(
          format(
            'resetting value to {} string for {}',
            adaptiveMap['value'],
            id,
          ),
          name: runtimeType.toString(),
        );
        return true;
      }());
      value = adaptiveMap['value'].toString();
    } else {
      assert(() {
        developer.log(
          format('resetting value to empty string for {}', id),
          name: runtimeType.toString(),
        );
        return true;
      }());
      value = ''; // default value for inputs that don't have one
    }
    // Subclasses should override update their text controllers etc.
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

mixin AdaptiveVisibilityMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late bool isVisible;

  @override
  void initState() {
    super.initState();
    // Parse isVisible from adaptiveMap
    // Handle: 'true'/'false' strings, boolean, null/absent (default true)
    final isVisibleValue = adaptiveMap['isVisible'];
    if (isVisibleValue == null) {
      isVisible = true;
    } else if (isVisibleValue is bool) {
      isVisible = isVisibleValue;
    } else if (isVisibleValue is String) {
      isVisible = isVisibleValue.toLowerCase() == 'true';
    } else {
      isVisible = true; // default
    }
  }

  /// Update visibility and trigger rebuild
  void setIsVisible({required bool visible}) {
    if (isVisible != visible) {
      setState(() {
        isVisible = visible;
      });
    }
  }
}
