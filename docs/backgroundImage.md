---
doc_type: reference
---

# The backgroundImage implementation needs to support both string and object versions

BackgroundImage can be specified as a string or an object. Everywhere a backgroundImage is specified, it can be a string or an object.  The string version is a URL to the image.  The object version has a URL and a fillMode.  The fillMode is an enum of 'cover', 'repeatHorizontally', 'repeatVertically', 'repeat'.

The individual components receive a Map and need to handle both cases.  They rely on functions in `adaptive_mixins.dart` to handle the Image generation.  Those methods either need to be changed to handle both cases or new methods need to be added.

## Esamples of backgroundimage specification

This is the object version
```json
    "backgroundImage": {
        "url": "https://adaptivecards.io/content/airplane.png",
        "fillMode": "repeat"
    },
```

The text version is

```json
    "backgroundImage": "https://adaptivecards.io/content/airplane.png",
```

## Existing functionality

* The function `getBackgroundImageFromMap()` in `adaptive_mixins.dart` accepts a Map and returns a `Widget?` (normalizing string/object form via `resolveBackgroundImage()`).

* The function `getBackgroundImage()` in `adaptive_mixins.dart` accepts a URL and returns a `Widget`.

## Test cases

1. Test cases must be created to verify that the backgroundImage url is identified correctly.
1. The image itself doesnt need to be downloaded. Just that the URL is correct and the fillMode is correct.

## Verification & Sizing Status

* **Verification Completed**: Confirmed both string and object background image formats parse and render correctly.
* **Layout Sizing & minHeight**: Implemented parsing and container layout-level constraints for `minHeight` on `AdaptiveContainer` and `AdaptiveColumn`.
* **Aspect Ratio Preservation**: Added specialized rendering behavior where containers or columns containing **only** a `backgroundImage` render it as a direct child widget (rather than in `BoxDecoration`), letting Flutter's layout engine dynamically scale the unconstrained dimension to perfectly preserve the original image's aspect ratio.
* **Tests**: Automated widget test cases added to `test/elements/background_image_test.dart` to verify this exact layout-level aspect ratio behavior.