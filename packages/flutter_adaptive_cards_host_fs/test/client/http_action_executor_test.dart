import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('GET issues a GET with substituted url and headers', () async {
    late http.Request seen;
    final executor = HttpAdaptiveHttpExecutor(
      client: MockClient((request) async {
        seen = request;
        return http.Response('ok', 200);
      }),
    );

    final result = await executor.execute(
      const HttpActionInvoke(
        method: 'GET',
        url: 'https://contoso.com/hi?name=David',
        headers: [HttpActionHeader(name: 'X-Test', value: 'v')],
        inputValues: {},
      ),
    );

    expect(seen.method, 'GET');
    expect(seen.url.toString(), 'https://contoso.com/hi?name=David');
    expect(seen.headers['X-Test'], 'v');
    expect(result.statusCode, 200);
    expect(result.isSuccess, isTrue);
    expect(result.body, 'ok');
  });

  test('POST sends the body', () async {
    late http.Request seen;
    final executor = HttpAdaptiveHttpExecutor(
      client: MockClient((request) async {
        seen = request;
        return http.Response('', 200);
      }),
    );

    await executor.execute(
      const HttpActionInvoke(
        method: 'POST',
        url: 'https://contoso.com/api',
        body: '{"name":"David"}',
        headers: [],
        inputValues: {},
      ),
    );

    expect(seen.method, 'POST');
    expect(seen.body, '{"name":"David"}');
  });

  test('result exposes lower-cased response headers and failure status', () async {
    final executor = HttpAdaptiveHttpExecutor(
      client: MockClient(
        (request) async => http.Response(
          'bad',
          400,
          headers: {'CARD-ACTION-STATUS': 'Nope'},
        ),
      ),
    );

    final result = await executor.execute(
      const HttpActionInvoke(
        method: 'GET',
        url: 'https://contoso.com',
        headers: [],
        inputValues: {},
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.headers['card-action-status'], 'Nope');
  });
}
