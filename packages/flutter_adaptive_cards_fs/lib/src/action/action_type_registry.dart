import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/action/default_actions.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';

/// Finds the action processor for a given action type
/// This is the way "Action" card type handelers are registered and discovered.
///
/// Applications can inject their own custom action registry when constructing [AdaptiveCardsCanvas]
abstract class ActionTypeRegistry {
  /// Creates a registry that maps action JSON `type` strings to [GenericAction]s.
  const ActionTypeRegistry();

  /// Gets a [GenericAction] for the provided action map.
  /// The map is expected to contain a `type` string like 'Action.Submit'.
  GenericAction? getActionForType({
    required Map<String, dynamic> map,
  });
}

/// The default action registry if none is passed into [AdaptiveCardsCanvas] constructors
class DefaultActionTypeRegistry extends ActionTypeRegistry {
  /// Built-in registry used when [AdaptiveCardsCanvas] does not override actions.
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
      case 'Action.Popover':
        return const DefaultPopoverAction();
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
