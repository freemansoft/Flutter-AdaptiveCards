# This document describes how adaptive card styles are mapped to Flutter Themes

Create a new set of classes in a hostconfig folder in lib.  Create configuration model objects based on this json schema https://github.com/microsoft/AdaptiveCards/blob/main/schemas/host-config.json for each element in "definitions". The "hostconfig" definition is special and is the top level configuration contains direct or indirect references to the other configurations.  In a JSON serialization try the first object would be the hostconfig.

The hostconfig classes should be able to convert all of the json in https://github.com/microsoft/AdaptiveCards/tree/master/samples/HostConfig to turn into flutter hostconfig classes.

The adaptive card widgets in this project consume or are built using json that fits the schema in <https://github.com/microsoft/AdaptiveCards/tree/main/schemas/1.6.0>.

## Classes impacted

All of the classes currently using the ReferenceResolver should be impacted by this change.  This includes the following types:

- `containers`
- `elements`
- `actions`
- `intputs`

Some classes are not in the schemas provided but may also be impacted

- `charts` several
- `badge`
- `carousel`
- `progress_bar` `progress_ring`
- `tabset`


### Badge

The badge should operate similar to container.  It should look at the  container foreground code in reference_resolver.dart as an example of how to use the new style objects like we did for containers

- refactor resolveBadgeForegroundColor   to operate similarly to resolveContainerForegroundColor using the badge_styles_config.dart. Badge uses 'filled' and 'tint' instead of container 'default and emphasis'

-Refactor the resolveBadgeBackgroundColor to operate similarly to resolveContainerForegroundColor, instead using badge_styles.dart.  Badge uses 'filled' and 'tint' instead of container 'default and emphasis'

## Example

The "default" property in any hostconfig object represents the default values that exist for the $ref type when used in that object. In the example below the "heading" is of type `TexStyleConfig`.  the "default" structure represents teh default values for the properties "weight", "size", "color", "fontType", "isSubtle".  You can see here that the "columnHeader" and "heading" property have different default values.

```json
"TextStylesConfig": {
			"type": "object",
			"description": "Sets default properties for text of a given style",
			"properties": {
				"heading": {
					"$ref": "#/definitions/TextStyleConfig",
					"default": {
						"weight": "bolder",
						"size": "large",
						"color": "default",
						"fontType": "default",
						"isSubtle": false
					}
				},
				"columnHeader": {
					"$ref": "#/definitions/TextStyleConfig",
					"default": {
						"weight": "bolder",
						"size": "default",
						"color": "default",
						"fontType": "default",
						"isSubtle": false
					}
				}
			}
		},
```

Some of the configs can keyed by enum or by a string representing the enum.  Text is displayed in the `foregroundColor` as defined in `ForegroundColorConfig` below we see that the color can be asked for with a string that can have the value "default", "accent", "dark", "light", "good", "warning" or "attention".  There should be a funciton on the ForegroundColorsConfig object that returns a FontColorConfig based on the passed in foreground color name.


```json
	"ForegroundColorsConfig": {
			"type": "object",
			"description": "Controls various font colors",
			"properties": {
				"default": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF000000",
						"subtle": "#B2000000"
					}
				},
				"accent": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF0000FF",
						"subtle": "#B20000FF"
					}
				},
				"dark": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF101010",
						"subtle": "#B2101010"
					}
				},
				"light": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FFFFFFFF",
						"subtle": "#B2FFFFFF"
					}
				},
				"good": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF008000",
						"subtle": "#B2008000"
					}
				},
				"warning": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FFFFD700",
						"subtle": "#B2FFD700"
					}
				},
				"attention": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF8B0000",
						"subtle": "#B28B0000"
					}
				}
			}
		},
```

## Changes to the reference_resolver

The reference resolver should accept a json hostconfig as its constructor parameter. It should deserialize that into the model objects generated above. The `ReferenceResolver` should have functions to get any the top level properties of the HostConfig object that was injected into the ReferenceResolver. Each of those functions should return the deserialized model object for that property and type.

## Changes to the existing code that calls ReferenceResolver

Change the existing code that uses ReferenceResolver to use the new host and type oriented.  In some places the same could is used by two different classes or completely different types. Those calls to the same function should be split so they can each looik in their own type based configuration.

There are places in the code that call `InheritedReferenceResolver.of...` `.resolve<something>` like `resolveImageSizes()` those calls should all call the correct property getter on the correct configuration object.

A call from `ImageSet` to get the image sizes
```dart
 InheritedReferenceResolver.of(
      context,).resolver.resolveImageSizes(sizeDescription);
```

would become
```dart
InheritedReferenceResolver.of(
      context,).resolver.getImageSetConfig().imageSize(sizeDescription);
```

## Testing

This feature needs test that validate loading a hostconfig json that can populate a configuration graph


## Full hostconfig schema

```json
{
	"definitions": {
		"AdaptiveCardConfig": {
			"type": "object",
			"description": "Toplevel options for `AdaptiveCards`",
			"properties": {
				"allowCustomStyle": {
					"type": "boolean",
					"description": "Controls whether custom styling is allowed",
					"default": true
				}
			}
		},
		"ActionsConfig": {
			"type": "object",
			"description": "Options for `Action`s",
			"properties": {
				"actionsOrientation": {
					"type": "string",
					"description": "Controls how buttons are laid out",
					"default": "horizontal",
					"enum": [
						"horizontal",
						"vertical"
					]
				},
				"actionAlignment": {
					"type": "string",
					"description": "Control layout of buttons",
					"default": "stretch",
					"enum": [
						"left",
						"center",
						"right",
						"stretch"
					]
				},
				"buttonSpacing": {
					"type": "integer",
					"description": "Controls how much spacing to use between buttons",
					"default": 10
				},
				"maxActions": {
					"type": "integer",
					"description": "Controls how many actions are allowed in total",
					"default": 5
				},
				"spacing": {
					"type": "string",
					"description": "Controls overall spacing of action element",
					"default": "default",
					"enum": [
						"default",
						"none",
						"small",
						"medium",
						"large",
						"extraLarge",
						"padding"
					]
				},
				"showCard": {
					"$ref": "#/definitions/ShowCardConfig"
				},
				"iconPlacement": {
					"type": "string",
					"description": "Controls where to place the action icon",
					"default": "aboveTitle",
					"enum": [
						"aboveTitle",
						"leftOfTitle"
					]
				},
				"iconSize": {
					"type": "integer",
					"description": "Controls size of action icon",
					"default": 30
				}
			}
		},
		"ContainerStyleConfig": {
			"type": "object",
			"description": "Controls styling of a container",
			"properties": {
				"backgroundColor": {
					"type": [
						"string",
						"null"
					],
					"default": "#FFFFFFFF"
				},
				"foregroundColors": {
					"$ref": "#/definitions/ForegroundColorsConfig"
				}
			}
		},
		"ContainerStylesConfig": {
			"type": "object",
			"description": "Controls styling for default and emphasis containers",
			"properties": {
				"default": {
					"$ref": "#/definitions/ContainerStyleConfig",
					"description": "Default container style"
				},
				"emphasis": {
					"$ref": "#/definitions/ContainerStyleConfig",
					"description": "Container style to use for emphasis"
				}
			}
		},
		"ErrorMessageConfig": {
			"type": "object",
			"description": "Controls styling for input error messages",
			"version": "1.3",
			"properties": {
				"size": {
					"type": "string",
					"description": "Font size to use for the error message",
					"default": "default",
					"enum": [
						"small",
						"default",
						"medium",
						"large",
						"extraLarge"
					]
				},
				"spacing": {
					"type": "string",
					"description": "Amount of spacing to be used between input and error message",
					"default": "default",
					"enum": [
						"default",
						"none",
						"small",
						"medium",
						"large",
						"extraLarge",
						"padding"
					]
				},
				"weight": {
					"type": "string",
					"description": "Font weight that should be used for error messages",
					"default": "default",
					"enum": [
						"lighter",
						"default",
						"bolder"
					]
				}
			}
		},
		"FactSetConfig": {
			"type": "object",
			"description": "Controls the display of `FactSet`s",
			"properties": {
				"title": {
					"$ref": "#/definitions/FactSetTextConfig",
					"default": {
						"weight": "bolder",
						"size": "default",
						"color": "default",
						"fontType": "default",
						"isSubtle": false,
						"wrap": true,
						"maxWidth": 150
					}
				},
				"value": {
					"$ref": "#/definitions/FactSetTextConfig",
					"default": {
						"weight": "default",
						"size": "default",
						"color": "default",
						"fontType": "default",
						"isSubtle": false,
						"wrap": true,
						"maxWidth": 0
					}
				},
				"spacing": {
					"type": "integer",
					"default": 10
				}
			}
		},
		"FontColorConfig": {
			"type": "object",
			"properties": {
				"default": {
					"type": [
						"string",
						"null"
					],
					"description": "Color to use when displaying default text"
				},
				"subtle": {
					"type": [
						"string",
						"null"
					],
					"description": "Color to use when displaying subtle text"
				}
			}
		},
		"FontSizesConfig": {
			"type": "object",
			"description": "Controls font size metrics for different text styles",
			"properties": {
				"small": {
					"type": "integer",
					"description": "Small font size",
					"default": 10
				},
				"default": {
					"type": "integer",
					"description": "Default font size",
					"default": 12
				},
				"medium": {
					"type": "integer",
					"description": "Medium font size",
					"default": 14
				},
				"large": {
					"type": "integer",
					"description": "Large font size",
					"default": 17
				},
				"extraLarge": {
					"type": "integer",
					"description": "Extra large font size",
					"default": 20
				}
			}
		},
		"FontWeightsConfig": {
			"type": "object",
			"description": "Controls font weight metrics",
			"properties": {
				"lighter": {
					"type": "integer",
					"default": 200
				},
				"default": {
					"type": "integer",
					"default": 400
				},
				"bolder": {
					"type": "integer",
					"default": 800
				}
			}
		},
		"ForegroundColorsConfig": {
			"type": "object",
			"description": "Controls various font colors",
			"properties": {
				"default": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF000000",
						"subtle": "#B2000000"
					}
				},
				"accent": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF0000FF",
						"subtle": "#B20000FF"
					}
				},
				"dark": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF101010",
						"subtle": "#B2101010"
					}
				},
				"light": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FFFFFFFF",
						"subtle": "#B2FFFFFF"
					}
				},
				"good": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF008000",
						"subtle": "#B2008000"
					}
				},
				"warning": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FFFFD700",
						"subtle": "#B2FFD700"
					}
				},
				"attention": {
					"$ref": "#/definitions/FontColorConfig",
					"default": {
						"default": "#FF8B0000",
						"subtle": "#B28B0000"
					}
				}
			}
		},
		"ImageSetConfig": {
			"type": "object",
			"description": "Controls how `ImageSet`s are displayed",
			"properties": {
				"imageSize": {
					"type": "string",
					"description": "Controls individual image sizing",
					"enum": [
						"auto",
						"stretch",
						"small",
						"medium",
						"large"
					],
					"default": "auto"
				},
				"maxImageHeight": {
					"type": "integer",
					"description": "Constrain image height to this value",
					"default": 100
				}
			}
		},
		"ImageSizesConfig": {
			"type": "object",
			"description": "Controls `Image` sizes",
			"properties": {
				"small": {
					"type": "integer",
					"description": "Small image size value",
					"default": 80
				},
				"medium": {
					"type": "integer",
					"description": "Medium image size value",
					"default": 120
				},
				"large": {
					"type": "integer",
					"description": "Large image size value",
					"default": 180
				}
			}
		},
		"InputsConfig": {
			"type": "object",
			"description": "Controls display and behavior of Input types",
			"version": "1.3",
			"properties": {
				"label": {
					"$ref": "#/definitions/LabelConfig"
				},
				"errorMessage": {
					"$ref": "#/definitions/ErrorMessageConfig"
				}
			}
		},
		"InputLabelConfig": {
			"type": "object",
			"description": "Controls display of input labels",
			"version": "1.3",
			"properties": {
				"color": {
					"type": "string",
					"description": "Color of the label",
					"default": "default",
					"enum": [
						"default",
						"dark",
						"light",
						"accent",
						"good",
						"warning",
						"attention"
					]
				},
				"isSubtle": {
					"type": "boolean",
					"description": "Whether the label should be displayed using a lighter weight font",
					"default": false
				},
				"size": {
					"type": "string",
					"description": "Size of the label text",
					"default": "default",
					"enum": [
						"small",
						"default",
						"medium",
						"large",
						"extraLarge"
					]
				},
				"suffix": {
					"type": "string",
					"description": "Suffix that should be appended to labels of this type"
				},
				"weight": {
					"type": "string",
					"default": "default",
					"description": "Font weight that should be used for this type of label",
					"enum": [
						"Lighter",
						"Default",
						"Bolder"
					]
				}
			}
		},
		"LabelConfig": {
			"type": "object",
			"description": "Controls display of input labels",
			"version": "1.3",
			"properties": {
				"inputSpacing": {
					"type": "string",
					"description": "Amount of spacing to be used between label and input",
					"default": "default",
					"enum": [
						"default",
						"none",
						"small",
						"medium",
						"large",
						"extraLarge",
						"padding"
					]
				},
				"requiredInputs": {
					"$ref": "#/definitions/InputLabelConfig",
					"description": "Label config for required Inputs"
				},
				"optionalInputs": {
					"$ref": "#/definitions/InputLabelConfig",
					"description": "Label config for optional Inputs"
				}
			}
		},
		"MediaConfig": {
			"type": "object",
			"version": "1.1",
			"description": "Controls the display and behavior of `Media` elements",
			"properties": {
				"defaultPoster": {
					"type": "string",
					"format": "uri",
					"description": "URI to image to display when play button hasn't been invoked"
				},
				"playButton": {
					"type": "string",
					"format": "uri",
					"description": "Image to display as play button"
				},
				"allowInlinePlayback": {
					"type": "boolean",
					"description": "Whether to display media inline or invoke externally",
					"default": true
				}
			}
		},
		"SeparatorConfig": {
			"type": "object",
			"description": "Controls how separators are displayed",
			"properties": {
				"lineThickness": {
					"type": "integer",
					"description": "Thickness of separator line",
					"default": 1
				},
				"lineColor": {
					"type": [
						"string",
						"null"
					],
					"description": "Color to use when drawing separator line",
					"default": "#B2000000"
				}
			}
		},
		"ShowCardConfig": {
			"type": "object",
			"description": "Controls behavior and styling of `Action.ShowCard`",
			"properties": {
				"actionMode": {
					"type": "string",
					"description": "Controls how the card is displayed. Note: Popup show cards are not recommended for cards with input validation, and may be deprecated in the future.",
					"enum": [
						"inline",
						"popup"
					],
					"default": "inline"
				},
				"style": {
					"$ref": "#/definitions/ContainerStyleConfig",
					"default": "emphasis"
				},
				"inlineTopMargin": {
					"type": "integer",
					"description": "Amount of margin to use when displaying the card",
					"default": 16
				}
			}
		},
		"SpacingsConfig": {
			"type": "object",
			"description": "Controls how elements are to be laid out",
			"properties": {
				"small": {
					"type": "integer",
					"description": "Small spacing value",
					"default": 3
				},
				"default": {
					"type": "integer",
					"description": "Default spacing value",
					"default": 8
				},
				"medium": {
					"type": "integer",
					"description": "Medium spacing value",
					"default": 20
				},
				"large": {
					"type": "integer",
					"description": "Large spacing value",
					"default": 30
				},
				"extraLarge": {
					"type": "integer",
					"description": "Extra large spacing value",
					"default": 40
				},
				"padding": {
					"type": "integer",
					"description": "Padding value",
					"default": 20
				}
			}
		},
		"FactSetTextConfig": {
			"type": "object",
			"description": "Parameters controlling the display of text in a fact set",
			"properties": {
				"size": {
					"type": "string",
					"description": "Size of font for fact set text",
					"enum": [
						"default",
						"small",
						"medium",
						"large",
						"extraLarge"
					],
					"default": "default"
				},
				"weight": {
					"type": "string",
					"description": "Weight of font for fact set text",
					"enum": [
						"normal",
						"lighter",
						"bolder"
					],
					"default": "normal"
				},
				"color": {
					"type": "string",
					"description": "Color of font for fact set text",
					"enum": [
						"default",
						"dark",
						"light",
						"accent",
						"good",
						"warning",
						"attention"
					],
					"default": "default"
				},
				"fontType": {
					"type": "string",
					"description": "Font Type for fact set text",
					"enum": [
						"default",
						"monospace"
					],
					"default": "default"
				},
				"isSubtle": {
					"type": "boolean",
					"description": "Indicates if fact set text should be subtle",
					"default": false
				},
				"wrap": {
					"type": "boolean",
					"description": "Indicates if fact set text should wrap",
					"default": true
				},
				"maxWidth": {
					"type": "integer",
					"description": "Maximum width of fact set text",
					"default": 0
				}
			}
		},
		"TextStyleConfig": {
			"type": "object",
			"description": "Sets default properties for text of a given style",
			"properties": {
				"size": {
					"type": "string",
					"description": "Default font size for text of this style",
					"enum": [
						"default",
						"small",
						"medium",
						"large",
						"extraLarge"
					],
					"default": "default"
				},
				"weight": {
					"type": "string",
					"description": "Default font weight for text of this style",
					"enum": [
						"normal",
						"lighter",
						"bolder"
					],
					"default": "normal"
				},
				"color": {
					"type": "string",
					"description": "Default font color for text of this style",
					"enum": [
						"default",
						"dark",
						"light",
						"accent",
						"good",
						"warning",
						"attention"
					],
					"default": "default"
				},
				"fontType": {
					"type": "string",
					"description": "Default font type for text of this style",
					"enum": [
						"default",
						"monospace"
					],
					"default": "default"
				},
				"isSubtle": {
					"type": "boolean",
					"description": "Whether text of this style should be subtle by default",
					"default": false
				}
			}
		},
		"TextStylesConfig": {
			"type": "object",
			"description": "Sets default properties for text of a given style",
			"properties": {
				"heading": {
					"$ref": "#/definitions/TextStyleConfig",
					"default": {
						"weight": "bolder",
						"size": "large",
						"color": "default",
						"fontType": "default",
						"isSubtle": false
					}
				},
				"columnHeader": {
					"$ref": "#/definitions/TextStyleConfig",
					"default": {
						"weight": "bolder",
						"size": "default",
						"color": "default",
						"fontType": "default",
						"isSubtle": false
					}
				}
			}
		},
		"TextBlockConfig": {
			"type": "object",
			"description": "Configuration settings for TextBlocks",
			"properties": {
				"headingLevel": {
					"type": "integer",
					"description": "When displaying a `TextBlock` element with the `heading` style, this is the heading level exposed to accessibility tools.",
					"default": 2
				}
			}
		},
		"HostConfig": {
			"type": "object",
			"description": "Contains host-configurable settings",
			"properties": {
				"supportsInteractivity": {
					"type": "boolean",
					"description": "Control whether interactive `Action`s are allowed to be invoked",
					"default": true
				},
				"imageBaseUrl": {
					"type": "string",
					"format": "uri",
					"description": "Base URL to be used when loading resources"
				},
				"fontFamily": {
					"type": "string",
					"description": "Font face to use when rendering text",
					"default": "Calibri"
				},
				"actions": {
					"$ref": "#/definitions/ActionsConfig"
				},
				"adaptiveCard": {
					"$ref": "#/definitions/AdaptiveCardConfig"
				},
				"containerStyles": {
					"$ref": "#/definitions/ContainerStylesConfig"
				},
				"imageSizes": {
					"$ref": "#/definitions/ImageSizesConfig"
				},
				"imageSet": {
					"$ref": "#/definitions/ImageSetConfig"
				},
				"factSet": {
					"$ref": "#/definitions/FactSetConfig"
				},
				"fontSizes": {
					"$ref": "#/definitions/FontSizesConfig"
				},
				"fontWeights": {
					"$ref": "#/definitions/FontWeightsConfig"
				},
				"spacing": {
					"$ref": "#/definitions/SpacingsConfig"
				},
				"separator": {
					"$ref": "#/definitions/SeparatorConfig"
				},
				"media": {
					"$ref": "#/definitions/MediaConfig"
				},
				"inputs": {
					"$ref": "#/definitions/InputsConfig"
				},
				"textBlock": {
					"$ref": "#/definitions/TextBlockConfig"
				},
				"textStyles": {
					"$ref": "#/definitions/TextStylesConfig"
				}
			}
		}
	}
}
```