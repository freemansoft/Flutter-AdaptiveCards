/// The compose box, authored as an Adaptive Card so its `Action.Submit`
/// flows through the host-invoke path just like an in-card form would.
///
/// The Send action is the field's `inlineAction` (standard, v1.2+) rather
/// than a top-level `actions` entry, so it renders beside the text field. Its
/// `iconUrl` uses the Fluent-icon reference `icon:Send` so the button shows a
/// send glyph (alongside the "Send" title; icon-only rendering is a follow-up).
/// default hostconfig for `iconPlacement` is `aboveTitle`,
/// so the icon appears above the title text.
Map<String, dynamic> composeCard() => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': [
    {
      'type': 'Input.Text',
      'id': 'message',
      'placeholder': 'Type a message',
      'isMultiline': true,
      'inlineAction': {
        'type': 'Action.Submit',
        'id': 'send',
        'title': 'Send',
        'iconUrl': 'icon:Send',
      },
    },
  ],
};
