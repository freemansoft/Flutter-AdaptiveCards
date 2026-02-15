import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards_plus/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('Action.OpenUrlDialog opens dialog and fetches card', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> cardMap = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Main Card',
        },
      ],
      'actions': [
        {
          'type': 'Action.OpenUrlDialog',
          'title': 'Open Dialog',
          'url': 'https://example.com/card.json',
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RawAdaptiveCard.fromMap(
            map: cardMap,
            hostConfigs: HostConfigs(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap 'Open Dialog'
    await tester.tap(find.text('Open Dialog'));
    await tester.pump(); // Start dialog animation

    // Wait for future to complete
    await tester.pumpAndSettle();

    // Verify dialog content (the fetched card)
    expect(find.text('Fetched Card Content'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Fetched Card Content'), findsNothing);
  });

  testWidgets('Action.OpenUrlDialog auto-launches browser for non-JSON content', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> cardMap = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {'type': 'TextBlock', 'text': 'Main Card'},
      ],
      'actions': [
        {
          'type': 'Action.OpenUrlDialog',
          'title': 'Open Web Page',
          'url': 'https://example.com/page.html',
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RawAdaptiveCard.fromMap(
            map: cardMap,
            hostConfigs: HostConfigs(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap 'Open Web Page'
    await tester.tap(find.text('Open Web Page'));

    // Pump to start the action (show dialog)
    await tester.pump();

    // Pump to let FutureBuilder resolve and show "Opening in browser..."
    // We expect the widget to be in tree before postFrameCallback pops it.
    await tester.pump(const Duration(milliseconds: 100));

    // Verify "Opening in browser..." is shown
    expect(find.text('Opening in browser...'), findsOneWidget);

    // Pump again to allow addPostFrameCallback to execute (which pops the dialog)
    await tester.pumpAndSettle();

    // Verify dialog is closed
    expect(find.text('Opening in browser...'), findsNothing);
    // Main card should be visible
    expect(find.text('Main Card'), findsOneWidget);
  });
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _handleUrl(url);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _handleUrl(url);
  }

  Future<HttpClientRequest> _handleUrl(Uri url) async {
    debugPrint('MockHttpClient.request called with $url');
    if (url.toString() == 'https://example.com/card.json') {
      return MockHttpClientRequest();
    } else if (url.toString() == 'https://example.com/page.html') {
      return MockHttpClientRequest(isJson: false);
    }
    throw Exception('Unexpected URL: $url');
  }

  @override
  void close({bool force = false}) {
    // No-op
  }
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  MockHttpClientRequest({this.isJson = true});
  final bool isJson;

  @override
  HttpHeaders get headers => MockHttpHeaders();

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
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<void> flush() async {}

  @override
  Future<HttpClientResponse> get done async =>
      MockHttpClientResponse(isJson: isJson);

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(isJson: isJson);
  }
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  MockHttpClientResponse({this.isJson = true});
  final bool isJson;

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => -1;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  HttpHeaders get headers => MockHttpHeaders({
    'content-type': [
      if (isJson)
        'application/json; charset=utf-8'
      else
        'text/html; charset=utf-8',
    ],
  });

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final Map<String, dynamic> responseCard = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Fetched Card Content',
        },
      ],
    };
    final String jsonString = json.encode(responseCard);
    final List<int> bytes = utf8.encode(jsonString);

    if (isJson) {
      return Stream.value(bytes).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    } else {
      const html = '<html><body><h1>Hello</h1></body></html>';
      final htmlBytes = utf8.encode(html);
      return Stream.value(htmlBytes).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    }
  }
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  MockHttpHeaders([this._headers = const {}]);
  final Map<String, List<String>> _headers;

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  List<String>? operator [](String name) {
    return _headers[name];
  }

  @override
  String? value(String name) {
    return _headers[name]?.first;
  }
}
