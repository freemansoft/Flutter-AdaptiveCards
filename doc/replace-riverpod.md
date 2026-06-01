# Riverpod removal (completed)

Riverpod has been removed from **`flutter_adaptive_cards_fs`**. Scoped DI uses **`InheritedReferenceResolver`** (nested for raw-card vs per-element scopes) plus **`InheritedAdaptiveCardHandlers`**.

## Replacement map

| Former Riverpod provider | Replacement |
| --- | --- |
| `rawAdaptiveCardStateProvider` | `InheritedReferenceResolver.rawCardScopeOf(context).rawAdaptiveCardState` |
| `cardTypeRegistryProvider` | `InheritedReferenceResolver.rawCardScopeOf(context).resolver.cardTypeRegistry` |
| `actionTypeRegistryProvider` | `InheritedReferenceResolver.rawCardScopeOf(context).resolver.actionTypeRegistry` |
| `styleReferenceResolverProvider` | `InheritedReferenceResolver.rawCardScopeOf(context).resolver` (or `ProviderScopeMixin.styleResolver`) |
| `adaptiveCardElementStateProvider` | `InheritedReferenceResolver.elementScopeOf(context).adaptiveCardElementState` |

## Widget tree

```text
AdaptiveCardsCanvas
  └── RawAdaptiveCard
        └── InheritedReferenceResolver  (outer: resolver with registries, root state)
              └── AdaptiveCardElement
                    └── InheritedReferenceResolver  (inner: element state)
                          └── elements / inputs / actions / …
```

Use **`rawCardScopeOf`** for registries and styling; **`elementScopeOf`** for form traversal and per-card registry.

## Reactive state (unchanged)

Input values, visibility, and show-card UI still use `StatefulWidget` + mixins and `setState`.
