# This document describes the expected behavior for AdaptiveColumns inside AdaptiveColumnSets

All of the AdaptiveColumn widgets in an AdaptiveColumnSet should configured to be the same height. They are currently different heights

AdaptiveColumnSet is a layout driven container that contain a list of AdaptiveColumn. The AdaptiveColumns each contain a list of child containers and adaptive components that fill the AdaptiveColumn. The size and number of those AdaptiveColumn children is not known until layout time.

> [!NOTE]
> **This issue has been FIXED**. This document is kept for historical reference.
>
> - **Fix**: `IntrinsicHeight` wrapper with `CrossAxisAlignment.stretch` on Row
> - **Verified**: Test in `test/column_height_test.dart` passes
> - **Date Fixed**: Before 2026-02-13

## Original Problem Description behavior

The AdaptiveColumnSet and AdaptiveColumn should have the following behavior.

- AdaptiveColumnSet is sized vertically to contain the tallest of the contained AdaptiveColumn. Code is in `column_set.dart`.
- AdaptiveColumn expand to the height of the AdaptiveColumnSet colum they are in. Code is in `column.dart`
- All of the AdaptiveColumn in an AdpativeColumnSet have the same height

## Problematic behavior

The behavior is currently broken.

- AdaptiveColumnSet is sized vertically to contain the tallest of the contained AdaptiveColumn
- AdaptiveColumn shrink in height to contain the all of the child elements. AdaptiveColumn independently size vertically.
- All of the AdaptiveColumn in an AdpativeColumnSet can be different height based on their child heights.

## Test

All tests for this should be run with the `--update-goldens` flag
