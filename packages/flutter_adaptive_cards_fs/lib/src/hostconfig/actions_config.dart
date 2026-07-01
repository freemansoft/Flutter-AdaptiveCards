/// HostConfig `actions.showCard` settings controlling ShowCard action
/// rendering.
class ShowCardConfig {
  /// Creates show-card layout settings from explicit values.
  ShowCardConfig({
    required this.actionMode,
    required this.style,
    required this.inlineTopMargin,
  });

  /// Parses `actions.showCard` from HostConfig JSON.
  factory ShowCardConfig.fromJson(Map<String, dynamic> json) {
    return ShowCardConfig(
      actionMode: json['actionMode']?.toString() ?? 'inline',
      style: json['style']?.toString() ?? 'emphasis',
      inlineTopMargin: json['inlineTopMargin'] as int? ?? 16,
    );
  }

  /// How the revealed card is presented (`inline` or `popup`).
  final String actionMode;

  /// Container style applied to the shown card (`default` or `emphasis`).
  final String style;

  /// Top margin in pixels when [actionMode] is `inline`.
  final int inlineTopMargin;
}

/// HostConfig `actions` section controlling action set layout and button
/// chrome.
class ActionsConfig {
  /// Creates action-set layout settings from explicit values.
  ActionsConfig({
    required this.actionsOrientation,
    required this.actionAlignment,
    required this.buttonSpacing,
    required this.maxActions,
    required this.spacing,
    required this.showCard,
    required this.iconPlacement,
    required this.iconSize,
  });

  /// Parses `actions` from HostConfig JSON.
  factory ActionsConfig.fromJson(Map<String, dynamic> json) {
    return ActionsConfig(
      actionsOrientation:
          json['actionsOrientation']?.toString() ?? 'horizontal',
      actionAlignment: json['actionAlignment']?.toString() ?? 'stretch',
      buttonSpacing: json['buttonSpacing'] as int? ?? 10,
      maxActions: json['maxActions'] as int? ?? 5,
      spacing: json['spacing']?.toString() ?? 'default',
      showCard: ShowCardConfig.fromJson(json['showCard'] ?? {}),
      iconPlacement: json['iconPlacement']?.toString() ?? 'aboveTitle',
      iconSize: json['iconSize'] as int? ?? 30,
    );
  }

  /// Layout direction for action buttons (`horizontal` or `vertical`).
  final String actionsOrientation;

  /// How buttons align within the action strip.
  final String actionAlignment;

  /// Pixel gap between adjacent action buttons.
  final int buttonSpacing;

  /// Maximum number of actions shown before overflow handling.
  final int maxActions;

  /// Spacing token applied around the action set.
  final String spacing;

  /// ShowCard-specific presentation settings.
  final ShowCardConfig showCard;

  /// Where action icons render relative to button title text.
  final String iconPlacement;

  /// Icon size in pixels for actions that include an icon.
  final int iconSize;
}
