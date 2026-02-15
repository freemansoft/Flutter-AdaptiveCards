class ShowCardConfig {
  ShowCardConfig({
    required this.actionMode,
    required this.style,
    required this.inlineTopMargin,
  });

  factory ShowCardConfig.fromJson(Map<String, dynamic> json) {
    return ShowCardConfig(
      actionMode: json['actionMode']?.toString() ?? 'inline',
      style: json['style']?.toString() ?? 'emphasis',
      inlineTopMargin: json['inlineTopMargin'] as int? ?? 16,
    );
  }

  final String actionMode;
  final String style;
  final int inlineTopMargin;
}

class ActionsConfig {
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

  final String actionsOrientation;
  final String actionAlignment;
  final int buttonSpacing;
  final int maxActions;
  final String spacing;
  final ShowCardConfig showCard;
  final String iconPlacement;
  final int iconSize;
}
