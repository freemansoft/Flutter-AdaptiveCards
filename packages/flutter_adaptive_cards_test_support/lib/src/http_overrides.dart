import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Test `HttpOverrides` that stubs image HTTP with transparent PNG / minimal SVG
/// — install via `adaptiveCardsTestExecutable` or `HttpOverrides.global`.
class MyTestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestImageHttpClient();
  }
}

class _TestImageHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _TestImageHttpClientRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _TestImageHttpClientRequest(url);

  @override
  void close({bool force = false}) {}
}

class _TestImageHttpClientRequest extends Fake implements HttpClientRequest {
  _TestImageHttpClientRequest(this.uri);

  @override
  final Uri uri;

  @override
  HttpHeaders get headers => _TestImageHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  int contentLength = 0;

  @override
  void add(List<int> data) {}

  @override
  void write(Object? object) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async =>
      _TestImageHttpClientResponse(uri: uri);
}

class _TestImageHttpClientResponse extends Fake implements HttpClientResponse {
  _TestImageHttpClientResponse({required this.uri});

  final Uri uri;

  List<int> get _bytes {
    final path = uri.path.toLowerCase();
    if (path.endsWith('.svg')) {
      return utf8.encode(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1">'
        ' <rect width="1" height="1"/>'
        ' </svg>',
      );
    }
    return TransparentImage.bytes;
  }

  String get _contentType {
    final path = uri.path.toLowerCase();
    if (path.endsWith('.svg')) {
      return 'image/svg+xml';
    }
    return 'image/png';
  }

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  HttpHeaders get headers => _TestImageHttpHeaders({
    'content-type': [_contentType],
  });

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  int get contentLength => _bytes.length;

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
    return Stream<List<int>>.fromIterable(<List<int>>[_bytes]).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError ?? false,
    );
  }
}

class _TestImageHttpHeaders extends Fake implements HttpHeaders {
  _TestImageHttpHeaders([this._headers = const {}]);

  final Map<String, List<String>> _headers;

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _headers[name];

  @override
  String? value(String name) => _headers[name]?.first;
}

/// 1×1 transparent PNG bytes for stubbed network images in widget/golden tests.
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

/// Small opaque blue PNG fixture ([bytes] / base64) for tests needing
/// non-transparent images.
class Blue8x8Image {
  // 1. Base64 encoded string of a simple 1x1 blue pixel (non-transparent)
  static String blue8x8ImageBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAFElEQVR4nGNkYPjPgA0wYRUdtBIAy0MBD1YkjLoAAAAASUVORK5CYII=';
  static Uint8List bytes = base64Decode(blue8x8ImageBase64);
}
