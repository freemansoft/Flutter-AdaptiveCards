# flutter_adaptive_cards_host_fs

Backend invoke bridge for [flutter_adaptive_cards_fs](../flutter_adaptive_cards_fs) — serialize host callbacks, POST to your flow-service, parse responses, and apply patches to the rendered card.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';

final cardKey = GlobalKey<RawAdaptiveCardState>();

AdaptiveCardBackendHandlers(
  client: HttpAdaptiveCardBackendClient(
    endpoint: Uri.parse('https://api.example.com/adaptive-card/invoke'),
  ),
  cardKey: cardKey,
  onError: (error) => log('invoke failed', error: error),
).wrap(
  RawAdaptiveCard.fromMap(
    key: cardKey,
    map: cardJson,
    hostConfigs: HostConfigs(),
  ),
  onCardReplaced: (map) => setState(() => cardJson = map),
);
```

Assign the same [cardKey] to both [AdaptiveCardBackendHandlers] and [RawAdaptiveCard.fromMap]. [InputChangeInvoke] callbacks use [InputChangeInvoke.cardState] directly; Submit and Execute use [cardKey].

## PlainJson request shape

```json
{
  "kind": "execute",
  "verb": "saveProfile",
  "actionId": "act1",
  "data": { "email": "user@example.com" }
}
```

Input changes include `inputId`, `value`, and optional `dataQuery` (Teams `Data.Query` shape).

## PlainJson response contract

**Patches + validation errors:**

```json
{
  "type": "adaptiveCard.invokeResponse",
  "effects": [
    {
      "type": "applyPatches",
      "elements": [
        {
          "id": "city",
          "choices": [{ "title": "Paris", "value": "paris" }]
        }
      ]
    },
    {
      "type": "setInputErrors",
      "errors": { "email": "Invalid format" }
    }
  ]
}
```

**Full card replacement:**

```json
{
  "type": "adaptiveCard.invokeResponse",
  "card": { "type": "AdaptiveCard", "version": "1.5", "body": [] }
}
```

Effects apply in order: `applyPatches` → `setInputErrors` → `replaceCard`.

## Teams adapter

Use [TeamsInvokeAdapter.toMap] / [TeamsInvokeAdapter.responseFromMap] for Bot Framework–shaped invoke activities:

```dart
AdaptiveCardBackendHandlers(
  client: client,
  cardKey: cardKey,
  requestAdapter: TeamsInvokeAdapter.toMap,
  responseParser: TeamsInvokeAdapter.responseFromMap,
  ...
)
```

## Custom client

Implement [AdaptiveCardBackendClient] for gRPC, WebSocket, or in-memory mocks:

```dart
class MyBackendClient implements AdaptiveCardBackendClient {
  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    // ...
  }
}
```
