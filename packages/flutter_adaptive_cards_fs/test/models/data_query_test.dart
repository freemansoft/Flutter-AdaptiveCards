import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataQuery', () {
    test('fromJson parses associatedInputs none', () {
      final query = DataQuery.fromJson({
        'dataset': 'cities',
        'associatedInputs': 'none',
      });

      expect(query.associatedInputs, 'none');
    });

    test(
      'withMergedSiblingInputs merges when auto '
      '(country in parameters, city excluded)',
      () {
        final query = DataQuery(
          dataset: 'cities',
          associatedInputs: 'auto',
          parameters: const {'country': 'US'},
        );

        final merged = query.withMergedSiblingInputs(
          {'country': 'CA', 'city': 'Toronto'},
          excludeInputId: 'city',
        );

        expect(merged.parameters, {'country': 'CA'});
      },
    );

    test('withMergedSiblingInputs no-op when none (parameters unchanged)', () {
      final query = DataQuery(
        dataset: 'cities',
        associatedInputs: 'none',
        parameters: const {'country': 'US'},
      );

      final merged = query.withMergedSiblingInputs(
        {'country': 'CA', 'city': 'Toronto'},
        excludeInputId: 'city',
      );

      expect(identical(merged, query), isTrue);
      expect(merged.parameters, {'country': 'US'});
    });
  });
}
