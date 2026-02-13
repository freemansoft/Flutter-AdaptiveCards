# Hiding Adaptive elements based on the isVisble flag.

This document provides guidance to an LLM when implementing hide/show or visible yes/no behavior.

## Design Plan

Enable flag driven card visibility on all Adaptive Elements using a boolean property `isVisible` that is stored in a widget state variable and initialized at Widget `initState()` from the adaptivemap from `adaptiveMap['isVisible']`. External code can update widget state `isVisible` value and `setState()`.

Show/Hide is actually implemented using the flag and a `Visibility` widget in each widget's `build()` code. The `Visibility` widget should be at the outermost layer of the Adaptive Card's widget tree, essentially hiding all the rendering if `!isVisible`.

An adaptive Map may have 3 values for isVisible.

| adaptiveMap['isVisible'] | isVisible | isOffStage |
| ------------------------ | --------- | ---------- |
| `'true'`                 | True      | False      |
| `'false'`                | False     | True       |
| not set or null          | True      | False      |

## Implementation.

1. An AdaptiveCard's JSON may optionally include an `isVisible` `boolean` property at the Adaptive Card level that we will use to control visibility.
1. AdaptiveCardElement State objects all have an `isVisible` property that is populated from AdaptiveCard JSON in the card widget's `initState()` function.
1. Each AdaptiveElement Widget rendering is is to be modified so that `Visibility` instance wrap the existing `Separator` that exists in or near each build method.
1. The Value of an `isVisible` property is passed to the `Visibility` as the `visible` paramter.
1. Progams can change the value of the AdaptiveCardState `isVisible` property via a `setIsVisible(visible)` on the mixin function on a mixin that is already on every adaptive card element. Changing `isVisible` property cause a rebuild on that object and below.

## Testing

Create a single test.

1. Create a test that verifies both hide and show opeations.
1. The test should have two Adaptive Text Adaptive cards with `id`s thing1 and thing2 and text values `thing1` and `thing2`. One widget will have `isVisible:true` and one with `isVisible:false`.
1. The test can validate that one is visible and the other does not exist by searching by the widget tree by text value.
1. The test should validate that changing the isVisible values changes the filled displayed
