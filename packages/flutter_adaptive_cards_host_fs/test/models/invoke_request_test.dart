import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromExecute maps verb actionId and data', () {
    const invoke = ExecuteActionInvoke(
      data: {'x': 1},
      verb: 'save',
      actionId: 'act1',
    );
    final req = AdaptiveCardInvokeRequest.fromExecute(invoke);
    expect(req.kind, AdaptiveCardInvokeKind.execute);
    expect(req.verb, 'save');
    expect(req.actionId, 'act1');
    expect(req.data, {'x': 1});
  });

  test('fromSubmit maps actionId and data', () {
    const invoke = SubmitActionInvoke(
      data: {'email': 'a@b.com'},
      actionId: 'submit1',
    );
    final req = AdaptiveCardInvokeRequest.fromSubmit(invoke);
    expect(req.kind, AdaptiveCardInvokeKind.submit);
    expect(req.actionId, 'submit1');
    expect(req.data, {'email': 'a@b.com'});
  });

  test('fromInputChange maps inputId value and dataQuery', () {
    final invoke = InputChangeInvoke(
      inputId: 'city',
      value: 'nyc',
      dataQuery: DataQuery(
        dataset: 'cities',
        parameters: {'country': 'usa'},
      ),
      cardState: _ThrowingCardState(),
    );
    final req = AdaptiveCardInvokeRequest.fromInputChange(invoke);
    expect(req.kind, AdaptiveCardInvokeKind.inputChange);
    expect(req.inputId, 'city');
    expect(req.value, 'nyc');
    expect(req.dataQuery?.dataset, 'cities');
    expect(req.data, {'country': 'usa'});
  });
}

class _ThrowingCardState extends RawAdaptiveCardState {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
