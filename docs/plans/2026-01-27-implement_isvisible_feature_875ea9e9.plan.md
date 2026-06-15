---
name: Implement IsVisible Feature
overview: Add `isVisible` property support to all adaptive card elements, allowing dynamic show/hide functionality via a boolean state property that wraps elements with Flutter's `Visibility` widget.
todos:
  - id: "1"
    content: Add AdaptiveVisibilityMixin to adaptive_mixins.dart with isVisible state management and setIsVisible() method
    status: completed
  - id: "2"
    content: Update text_block.dart to apply mixin and wrap SeparatorElement with Visibility widget
    status: completed
  - id: "3"
    content: Update container.dart to apply mixin and wrap SeparatorElement with Visibility widget
    status: completed
  - id: "4"
    content: Update all remaining element State classes in elements/ directory (15+ files)
    status: completed
  - id: "5"
    content: Update all container State classes in containers/ directory (7 files)
    status: completed
  - id: "6"
    content: Update all input State classes in inputs/ directory (6 files)
    status: completed
  - id: "7"
    content: Update action State classes in elements/actions/ subdirectory (9 files)
    status: completed
  - id: "8"
    content: Create is_visible_test.dart with test for thing1/thing2 visibility behavior
    status: completed
isProject: false
---

# Implementing isVisible Feature for Adaptive Card Elements

> **Status:** **Implemented.** Living docs: [`reactive-riverpod.md`](../reactive-riverpod.md#visibility-isvisible). Duplicate draft archived: [`2026-01-26-implement_isvisible_feature_066e549a.plan.md`](../archive/plans/2026-01-26-implement_isvisible_feature_066e549a.plan.md).

## Overview

This plan implements the `isVisible` property for all adaptive card elements, enabling dynamic visibility control. The implementation follows the pattern where each element's `SeparatorElement` is wrapped with a `Visibility` widget controlled by state.

## Architecture

The implementation uses a mixin pattern to add visibility functionality to all adaptive elements:

1. **Visibility Mixin**: Add `AdaptiveVisibilityMixin` to `adaptive_mixins.dart` that:
   - Manages `isVisible` state (initialized from `adaptiveMap['isVisible']`)
   - Provides `setIsVisible(bool visible)` method to update visibility
   - Handles JSON parsing: `'true'`/`'false'` strings, boolean values, and null/absent (defaults to `true`)

2. **Element Updates**: Modify all adaptive element `build()` methods to:
   - Apply the `AdaptiveVisibilityMixin` to their State classes
   - Wrap `SeparatorElement` with `Visibility(visible: isVisible, child: SeparatorElement(...))`

3. **Test**: Create a widget test that validates visibility behavior

## Implementation Details

### 1. Create Visibility Mixin

**File**: `packages/flutter_adaptive_cards/lib/src/adaptive_mixins.dart`

Add a new mixin after `AdaptiveTextualInputMixin`:

```dart
mixin AdaptiveVisibilityMixin<T extends AdaptiveElementWidgetMixin> on State<T>
    implements AdaptiveElementMixin<T> {
  late bool isVisible;

  @override
  void initState() {
    super.initState();
    // Parse isVisible from adaptiveMap
    // Handle: 'true'/'false' strings, boolean, null/absent (default true)
    final isVisibleValue = adaptiveMap['isVisible'];
    if (isVisibleValue == null) {
      isVisible = true;
    } else if (isVisibleValue is bool) {
      isVisible = isVisibleValue;
    } else if (isVisibleValue is String) {
      isVisible = isVisibleValue.toLowerCase() == 'true';
    } else {
      isVisible = true; // default
    }
  }

  /// Update visibility and trigger rebuild
  void setIsVisible(bool visible) {
    if (isVisible != visible) {
      setState(() {
        isVisible = visible;
      });
    }
  }
}
```

### 2. Update All Element State Classes

Apply `AdaptiveVisibilityMixin` to all State classes that use `AdaptiveElementMixin`. This includes:

**Elements** (`packages/flutter_adaptive_cards/lib/src/elements/`):
- `text_block.dart` - `AdaptiveTextBlockState`
- `image.dart` - `AdaptiveImageState`
- `action_set.dart` - `ActionSetState`
- `accordion.dart` - `AdaptiveAccordionState`
- `badge.dart` - `AdaptiveBadgeState`
- `carousel.dart` - `AdaptiveCarouselState`
- `code_block.dart` - `AdaptiveCodeBlockState`
- `compound_button.dart` - `AdaptiveCompoundButtonState`
- `media.dart` - `AdaptiveMediaState`
- `progress_bar.dart` - `AdaptiveProgressBarState`
- `progress_ring.dart` - `AdaptiveProgressRingState`
- `rating.dart` - `AdaptiveRatingState`
- `tab_set.dart` - `AdaptiveTabSetState`
- All action states in `actions/` subdirectory

**Containers** (`packages/flutter_adaptive_cards/lib/src/containers/`):
- `container.dart` - `AdaptiveContainerState`
- `column.dart` - `AdaptiveColumnState`
- `column_set.dart` - `AdaptiveColumnSetState`
- `fact_set.dart` - `AdaptiveFactSetState`
- `image_set.dart` - `AdaptiveImageSetState`
- `table.dart` - `AdaptiveTableState`

**Inputs** (`packages/flutter_adaptive_cards/lib/src/inputs/`):
- `text.dart` - `AdaptiveTextInputState`
- `number.dart` - `AdaptiveNumberInputState`
- `date.dart` - `AdaptiveDateInputState`
- `time.dart` - `AdaptiveTimeInputState`
- `toggle.dart` - `AdaptiveToggleInputState`
- `choice_set.dart` - `AdaptiveChoiceSetState`

**Cards**:
- `adaptive_card_element.dart` - `AdaptiveCardElementState` (if needed)

For each State class, add the mixin:
```dart
class XxxState extends State<Xxx>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
```

### 3. Wrap SeparatorElement with Visibility

In each element's `build()` method, wrap the `SeparatorElement` with `Visibility`:

**Pattern** (example from `text_block.dart`):
```dart
@override
Widget build(BuildContext context) {
  // ... existing code ...

  return Visibility(
    visible: isVisible,
    child: SeparatorElement(
      adaptiveMap: adaptiveMap,
      widgetState: widgetState,
      child: // ... existing child widget ...
    ),
  );
}
```

**Note**: Some elements may have more complex widget trees. The `Visibility` widget should wrap the outermost `SeparatorElement` that contains the element's main content.

### 4. Create Test

**File**: `packages/flutter_adaptive_cards/test/elements/is_visible_test.dart`

Create a test that:
- Creates an adaptive card with two TextBlock elements (`thing1` and `thing2`)
- `thing1` has `isVisible: true`
- `thing2` has `isVisible: false`
- Verifies `thing1` text is found in widget tree
- Verifies `thing2` text is NOT found in widget tree
- Changes `thing2.isVisible` to `true` via `setIsVisible()`
- Verifies both texts are now visible

## Files to Modify

1. `packages/flutter_adaptive_cards/lib/src/adaptive_mixins.dart` - Add mixin
2. All element State classes (30+ files) - Add mixin and wrap with Visibility
3. `packages/flutter_adaptive_cards/test/elements/is_visible_test.dart` - New test file

## Implementation Order

1. Add `AdaptiveVisibilityMixin` to `adaptive_mixins.dart`
2. Update a few representative elements first (e.g., `text_block.dart`, `container.dart`) to validate the pattern
3. Apply the pattern to all remaining elements
4. Create and run the test
5. Verify all elements compile and work correctly

## Edge Cases

- Handle string `'true'`/`'false'` from JSON (common in adaptive cards)
- Default to `true` when property is absent or null
- Ensure `setIsVisible()` triggers `setState()` for proper rebuilds
- `Visibility` widget with `visible: false` removes widget from tree (not just hides it visually)