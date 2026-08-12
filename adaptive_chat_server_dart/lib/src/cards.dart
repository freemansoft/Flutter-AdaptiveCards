/// Server-authored Adaptive Card bubbles and the response envelope.
///
/// All bubble alignment and fill live here, in the card JSON, so the client
/// stays "dumb" and renders each card full-width and stacked.
library;

import 'package:adaptive_chat_server_dart/src/store.dart';

const _version = '1.5';

// Chat bubbles span ~75% of the row: weighted columns 3:1 (= 75% / 25%). The
// empty spacer column pushes the bubble to one side.
const _bubbleWeight = 3;
const _spacerWeight = 1;

Map<String, dynamic> _bubble(
  List<Map<String, dynamic>> items, {
  required String style,
  required bool alignRight,
  required String label,
}) {
  final container = <String, dynamic>{
    'type': 'Container',
    'style': style,
    'roundedCorners': true,
    'items': items,
  };
  final content = <String, dynamic>{
    'type': 'Column',
    'width': _bubbleWeight,
    'items': [container],
  };
  final spacer = <String, dynamic>{
    'type': 'Column',
    'width': _spacerWeight,
    'items': <dynamic>[],
  };
  final columns = alignRight ? [spacer, content] : [content, spacer];
  final labelBlock = <String, dynamic>{
    'type': 'TextBlock',
    'text': label,
    'wrap': true,
    if (alignRight) 'horizontalAlignment': 'Right',
  };
  return {
    'type': 'AdaptiveCard',
    'version': _version,
    'body': [
      labelBlock,
      {'type': 'ColumnSet', 'columns': columns},
    ],
  };
}

/// A single full-width styled container — no ColumnSet, so it spans the row.
///
/// Used for card replies. The 75% [_bubble] layout relies on `ColumnSet`,
/// whose columns are wrapped in `IntrinsicHeight` by the renderer; a
/// `Carousel` inside gates its subtree behind a `LayoutBuilder` that cannot
/// answer the intrinsic-height pass, so the card renders blank / asserts.
/// Card replies skip the ColumnSet and render full-width instead.
Map<String, dynamic> _fullWidthBubble(
  List<Map<String, dynamic>> items, {
  required String style,
  required String label,
}) {
  final container = <String, dynamic>{
    'type': 'Container',
    'style': style,
    'roundedCorners': true,
    'items': items,
  };
  return {
    'type': 'AdaptiveCard',
    'version': _version,
    'body': [
      {'type': 'TextBlock', 'text': label, 'wrap': true},
      container,
    ],
  };
}

List<Map<String, dynamic>> _textItems(String text) => [
  {'type': 'TextBlock', 'text': text, 'wrap': true},
];

/// Right-aligned accent bubble for the user's message.
///
/// [label] is the role text shown above the bubble; callers (the client,
/// via the request body) may override it, and it defaults to
/// [defaultUserLabel].
Map<String, dynamic> userBubble(
  String text, {
  String label = defaultUserLabel,
}) =>
    _bubble(_textItems(text), style: 'accent', alignRight: true, label: label);

/// Left-aligned emphasis bubble for a Markdown text assistant reply.
///
/// The `TextBlock` renders GitHub-flavored Markdown, so this is the default
/// reply shape used before the card path existed. [label] defaults to
/// [defaultAssistantLabel]; see [userBubble].
Map<String, dynamic> assistantBubble(
  String text, {
  String label = defaultAssistantLabel,
}) => _bubble(
  _textItems(text),
  style: 'emphasis',
  alignRight: false,
  label: label,
);

/// Full-width emphasis container holding a model card fragment.
///
/// [label] defaults to [defaultAssistantLabel]; see [userBubble].
Map<String, dynamic> assistantCardBubble(
  List<Map<String, dynamic>> bodyItems, {
  String label = defaultAssistantLabel,
}) => _fullWidthBubble(bodyItems, style: 'emphasis', label: label);

/// Full-width "attention"-styled card with no role label.
///
/// Used for server-authored system notices (e.g. an expired conversation)
/// that are not attributed to either bubble role — see [userBubble] and
/// [assistantBubble] for those.
Map<String, dynamic> noticeCard(List<Map<String, dynamic>> bodyItems) {
  final container = <String, dynamic>{
    'type': 'Container',
    'style': 'attention',
    'roundedCorners': true,
    'items': bodyItems,
  };
  return {
    'type': 'AdaptiveCard',
    'version': _version,
    'body': [container],
  };
}

/// Wire envelope: pre-styled cards plus self/postNext links.
Map<String, dynamic> envelope(
  String cid,
  String iid,
  List<Message> messages,
) => {
  'conversationId': cid,
  'interactionId': iid,
  'messages': messages.map((m) => m.card).toList(),
  'links': {
    'self': '/conversations/$cid/interactions/$iid',
    'postNext': '/conversations/$cid/interactions',
  },
};
