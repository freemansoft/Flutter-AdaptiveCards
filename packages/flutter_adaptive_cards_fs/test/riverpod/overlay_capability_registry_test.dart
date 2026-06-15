/// Unit tests for [OverlayCapabilityRegistry] — the shared map of supported
/// runtime overlay fields per Adaptive Card JSON `type`.
///
/// The registry is exposed on [CardTypeRegistry.overlayCapabilities] and mirrors
/// [`docs/overlay-properties-by-type.md`](../../../../docs/overlay-properties-by-type.md).
/// These tests guard:
///
/// - Standard input, display, and action field sets
/// - [OverlayCapabilityRegistry.validateElementUpdate] / [validateActionUpdate]
/// - Optional [ElementOverlayExtension] registration (`extensionPayload`, [ElementOverlayExtension.overlayPatchKeys])
///
/// Widget-level overlay behavior remains in `*_overlay_test.dart` files; merge
/// semantics stay in `adaptive_card_document_notifier_test.dart`.
library;

import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverlayCapabilityRegistry', () {
    const registry = OverlayCapabilityRegistry();

    test('Input.Text supports standard input overlay fields', () {
      expect(
        registry.elementFieldsFor('Input.Text'),
        containsAll([
          ElementOverlayField.value,
          ElementOverlayField.label,
          ElementOverlayField.isRequired,
        ]),
      );
      expect(
        registry.elementFieldsFor('Input.Text'),
        isNot(contains(ElementOverlayField.text)),
      );
    });

    test('Input.ChoiceSet adds choices and query session fields', () {
      expect(
        registry.elementFieldsFor('Input.ChoiceSet'),
        containsAll([
          ElementOverlayField.choices,
          ElementOverlayField.queryCount,
          ElementOverlayField.querySearchText,
        ]),
      );
    });

    test('TextBlock supports text and visibility only', () {
      expect(
        registry.elementFieldsFor('TextBlock'),
        equals({
          ElementOverlayField.isVisible,
          ElementOverlayField.text,
        }),
      );
    });

    test('Action.Submit supports action overlay fields', () {
      expect(
        registry.actionFieldsFor('Action.Submit'),
        containsAll([
          ActionOverlayField.isEnabled,
          ActionOverlayField.title,
          ActionOverlayField.tooltip,
        ]),
      );
    });

    test('validateElementUpdate rejects text patch on Input.Text', () {
      final issues = registry.validateElementUpdate(
        'Input.Text',
        const AdaptiveElementUpdate(id: 'x', text: 'nope'),
      );
      expect(issues, isNotEmpty);
      expect(issues.first, contains('text'));
    });

    test('validateElementUpdate accepts value patch on Input.Text', () {
      final issues = registry.validateElementUpdate(
        'Input.Text',
        const AdaptiveElementUpdate(id: 'x', value: 'ok'),
      );
      expect(issues, isEmpty);
    });

    test('extensionPayload requires registered extension for Chart types', () {
      const coreOnly = OverlayCapabilityRegistry();
      final issues = coreOnly.validateElementUpdate(
        'Chart.VerticalBar',
        const AdaptiveElementUpdate(
          id: 'c',
          extensionPatches: {
            'charts': {'chartData': <dynamic>[]},
          },
        ),
      );
      expect(issues, isNotEmpty);
    });

    test('Chart extension enables extensionPayload when registered', () {
      final chartRegistry = OverlayCapabilityRegistry(
        overlayExtensions: CardOverlayExtensionRegistry(
          extensions: [_TestChartExtension()],
        ),
      );
      expect(
        chartRegistry.elementFieldsFor('Chart.Line'),
        contains(ElementOverlayField.extensionPayload),
      );
      final issues = chartRegistry.validateElementUpdate(
        'Chart.Line',
        const AdaptiveElementUpdate(
          id: 'c',
          extensionPatches: {
            'charts': {
              'chartData': [1, 2],
            },
          },
        ),
      );
      expect(issues, isEmpty);
    });

    test('Chart extension rejects unknown patch keys', () {
      final chartRegistry = OverlayCapabilityRegistry(
        overlayExtensions: CardOverlayExtensionRegistry(
          extensions: [_TestChartExtension()],
        ),
      );
      final issues = chartRegistry.validateElementUpdate(
        'Chart.Line',
        const AdaptiveElementUpdate(
          id: 'c',
          extensionPatches: {
            'charts': {'unknownKey': true},
          },
        ),
      );
      expect(issues, isNotEmpty);
      expect(issues.first, contains('unknownKey'));
    });
  });
}

class _TestChartExtension extends ElementOverlayExtension {
  @override
  String get id => 'charts';

  @override
  Set<String> get overlayPatchKeys => const {'chartData', 'chartProperties'};

  @override
  bool appliesTo(String elementType) => elementType.startsWith('Chart.');

  @override
  void mergeResolved(
    Map<String, dynamic> merged,
    Map<String, dynamic> payload,
  ) {}

  @override
  Map<String, dynamic> mergePayload({
    required Map<String, dynamic> current,
    required Map<String, dynamic> patch,
  }) => patch;

  @override
  Map<String, dynamic>? patchFromHostMap(Map<String, dynamic> hostPatch) =>
      null;
}
