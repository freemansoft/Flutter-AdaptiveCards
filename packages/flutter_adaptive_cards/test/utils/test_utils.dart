import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/actions/action_handler.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/host_config.dart';
import 'package:mockito/mockito.dart';

class MyTestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockImageHttpClient(context);
  }
}

HttpClient _createMockImageHttpClient(SecurityContext? context) {
  return _MockHttpClient();
}

class _MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => TransparentImage.bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[
      TransparentImage.bytes,
      //Blue8x8Image.bytes,
    ]).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError ?? false,
    );
  }
}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

class TransparentImage {
  static final List<int> bytes = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];
}

class Blue8x8Image {
  // 1. Base64 encoded string of a simple 1x1 blue pixel (non-transparent)
  static String blue8x8ImageBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAFElEQVR4nGNkYPjPgA0wYRUdtBIAy0MBD1YkjLoAAAAASUVORK5CYII=';
  static Uint8List bytes = base64Decode(blue8x8ImageBase64);
}

///
/// Helper function to get a widget from a path prefixed with test/samples/
///
/// Optionally provide a key to wrap the returned widget in a RepaintBoundary with that key
/// primarily used for golden tests regions
Widget getTestWidgetFromPath({required String path, Key? key}) {
  final File file = File('test/samples/$path');
  final Map<String, dynamic> map =
      json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return getTestWidgetFromMap(map: map, key: key, title: path);
}

/// This lets us inject action handlers for testing
Widget getTestWidgetFromMap({
  required Map<String, dynamic> map,
  required String title,
  Key? key,
  Function(String)? onOpenUrl,
  Function(Map<dynamic, dynamic>)? onSubmit,
}) {
  final Widget adaptiveCard = RawAdaptiveCard.fromMap(
    map: map,
    // debug "show json" panes don't show in prod
    // so dislable them in the golden images
    showDebugJson: false,
    hostConfigs: HostConfigs(),
  );

  // this should generate an action handler set instead but the LLM
  // saw that we could rely on InheritedAdaptiveCardHandlers here
  if (onOpenUrl != null || onSubmit != null) {
    // wrap in handlers
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          // tests look for this value key as the root for golden
          key: key,
          child: InheritedAdaptiveCardHandlers(
            onOpenUrl: onOpenUrl ?? (_) {},
            // this a test so we can look at this later
            // ignore: inference_failure_on_collection_literal
            onSubmit: onSubmit ?? (Map _) => {},
            onExecute: (_) {},
            onChange: null,
            child: adaptiveCard,
          ),
        ),
      ),
    );
  } else {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          // tests look for this value key as the root for golden
          key: key,
          child: adaptiveCard,
        ),
      ),
    );
  }
}
