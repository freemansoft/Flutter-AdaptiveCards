import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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

///
/// Helper function to get a widget from a path prefixed with test/samples/
///
Widget getWidget(String path) {
  final File file = File('test/samples/$path');
  final Map<String, dynamic> map =
      json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  final Widget adaptiveCard = RawAdaptiveCard.fromMap(
    map: map,
    //onChange: (_) {},
    onSubmit: (_) {},
    onExecute: (_) {},
    onOpenUrl: (_) {},
    // debug "show json" panes don't show in prod
    // so dislable them in the golden images
    showDebugJson: false,
    hostConfig: HostConfig(),
  );

  return MaterialApp(
    home: adaptiveCard,
  );
}
