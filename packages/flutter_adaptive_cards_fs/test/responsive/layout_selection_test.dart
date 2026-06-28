import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectLayout', () {
    test('null/empty layouts → null (stack default)', () {
      expect(selectLayout(null, WidthBucket.wide), isNull);
      expect(selectLayout(const [], WidthBucket.wide), isNull);
    });

    test('returns the layout whose targetWidth matches', () {
      final layouts = [
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
      ];
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
      expect(selectLayout(layouts, WidthBucket.narrow), isNull);
    });

    test('exact-bucket layout wins over relational', () {
      final layouts = [
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:narrow'},
        {'type': 'Layout.Stack', 'targetWidth': 'standard'},
      ];
      expect(selectLayout(layouts, WidthBucket.standard)?['type'], 'Layout.Stack');
    });

    test('relational match preferred over no-targetWidth default', () {
      final layouts = [
        {'type': 'Layout.Stack'},
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
      ];
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
    });

    test('falls back to no-targetWidth default when nothing else matches', () {
      final layouts = [
        {'type': 'Layout.Flow'},
        {'type': 'Layout.Stack', 'targetWidth': 'wide'},
      ];
      expect(selectLayout(layouts, WidthBucket.narrow)?['type'], 'Layout.Flow');
    });

    test('ignores non-map entries', () {
      final layouts = ['nonsense', {'type': 'Layout.Flow', 'targetWidth': 'wide'}];
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
    });

    test('nearest relational match wins (atLeast) at wide', () {
      final layouts = [
        {'type': 'Layout.Stack', 'targetWidth': 'atLeast:narrow'},
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
      ];
      // At wide, atLeast:standard covers 2 buckets and atLeast:narrow covers 3,
      // so atLeast:standard is more specific and wins.
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
    });

    test('nearest relational match wins regardless of array order', () {
      final layouts = [
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:standard'},
        {'type': 'Layout.Stack', 'targetWidth': 'atLeast:narrow'},
      ];
      expect(selectLayout(layouts, WidthBucket.wide)?['type'], 'Layout.Flow');
    });

    test('nearest relational match wins (atMost) at veryNarrow', () {
      final layouts = [
        {'type': 'Layout.Stack', 'targetWidth': 'atMost:wide'},
        {'type': 'Layout.Flow', 'targetWidth': 'atMost:narrow'},
      ];
      // At veryNarrow, atMost:narrow covers 2 buckets and atMost:wide covers 4,
      // so atMost:narrow is more specific and wins.
      expect(
        selectLayout(layouts, WidthBucket.veryNarrow)?['type'],
        'Layout.Flow',
      );
    });

    test('equal-specificity relational matches keep array order', () {
      final layouts = [
        {'type': 'Layout.Flow', 'targetWidth': 'atLeast:narrow'},
        {'type': 'Layout.Stack', 'targetWidth': 'atMost:standard'},
      ];
      // At standard both cover 3 buckets (equal specificity); first wins.
      expect(selectLayout(layouts, WidthBucket.standard)?['type'], 'Layout.Flow');
    });
  });
}
