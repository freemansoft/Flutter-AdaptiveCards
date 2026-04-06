import 'package:flutter_adaptive_cards_plus/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards_plus/src/action/default_actions.dart';
import 'package:flutter_adaptive_cards_plus/src/action/generic_action.dart';

/// Finds the action processor for a given action type
/// This is the way "Action" handlers are registered and discovered.
///
/// Applications can inject their own custom action registry when constructing [AdaptiveCardsRoot]
abstract class ActionTypeRegistry {
  const ActionTypeRegistry();

  /// Gets a [GenericAction] for the provided action map.
  /// The map is expected to contain a `type` string like 'Action.Submit'.
  GenericAction? getActionForType({
    required Map<String, dynamic> map,
  });
}

/// The default action registry if none is passed into [AdaptiveCardsRoot] constructors
class DefaultActionTypeRegistry extends ActionTypeRegistry {
  const DefaultActionTypeRegistry();

  /// Gets a [GenericAction] for the provided action map.
  /// The map is expected to contain a `type` string like 'Action.Submit'.
  @override
  GenericAction? getActionForType({
    required Map<String, dynamic> map,
  }) {
    final String stringType = map['type'] as String;

    switch (stringType) {
      case 'Action.ShowCard':
        assert(
          false,
          'Action.ShowCard can only be used directly by the root card',
        );
        return null;
      case 'Action.OpenUrl':
        return const DefaultOpenUrlAction();
      case 'Action.OpenUrlDialog':
        return const DefaultOpenUrlDialogAction();
      case 'Action.Submit':
        return const DefaultSubmitAction();
      case 'Action.Execute':
        return const DefaultExecuteAction();
      case 'Action.ResetInputs':
        return const DefaultResetInputsAction();
      case 'Action.ToggleVisibility':
        return const DefaultToggleVisibilityAction();
      case 'Action.InsertImage':
        assert(false, 'Action.InsertImage is not supported');
        return null;
      case 'Action.Popup':
        assert(false, 'Action.Popup is not supported');
        return null;
      default:
        assert(false, 'No action found with type $stringType');
        return null;
    }
  }
}
