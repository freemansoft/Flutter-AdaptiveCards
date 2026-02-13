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

* The function `getBackgroundImageFromMap()` in `adaptive_mixins.dart`  accepts a Map and return an Image.

* The function `getBackgroundImage()` in `adaptive_mixins.dart`  accepts a URL and return an Image.

## Test cases

1. Test cases must be created to verify that the backgroundImage url is identified correctly.
1. The image itself doesnt need to be downloaded. Just that the URL is correct and the fillMode is correct.