/// The compose box, authored as an Adaptive Card so its `Action.Submit`
/// flows through the host-invoke path just like an in-card form would.
Map<String, dynamic> composeCard() => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': [
    {
      'type': 'Input.Text',
      'id': 'message',
      'placeholder': 'Type a message',
      'isMultiline': true,
    },
  ],
  'actions': [
    {'type': 'Action.Submit', 'id': 'send', 'title': 'Send'},
  ],
};
