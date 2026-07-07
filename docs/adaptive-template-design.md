---
doc_type: reference
---

# Design for Microsoft AdaptiveCard Template Engine

> **Templating-language reference** (binding, `$data`, `$when`, expressions, custom functions) for
> the Dart engine in `packages/flutter_adaptive_template_fs`. How to write templating tests:
> [templating-testing.md](templating-testing.md). Feature-coverage status lives in the
> [`flutter_adaptive_template_fs` README](../packages/flutter_adaptive_template_fs/README.md).

The `flutter_adaptive_template_fs` engine separates an adaptive card's data from its layout: the template service applies the data JSON to the template JSON to produce renderable card JSON. It has no dependency on `flutter_adaptive_cards_fs` — either package can be used independently. This page is the [Microsoft templating language](https://learn.microsoft.com/en-us/adaptive-cards/templating/language) reference for the implemented behavior.

Data may be supplied as a separate data JSON, or embedded in a `"$data"` field on the root of the template JSON (as in the examples below).

## Binding features

- The ability merge data JSON and adaptivecard template json
- Using a binding syntax of `${property_name}`
- Binding expressions can be placed just about anywhere that static content can be
- The binding syntax starts with `${ and ends with }`. E.g., `${myProperty}`
- Use Dot-notation to access sub-objects of an object hierarchy. E.g., ${myParent.myChild}
- Graceful `null` handling ensures you won't get exceptions if you access a null property in an object graph
- Use Indexer syntax to retrieve properties by key or items in an array. E.g., `${myArray[0]}`
- "dot" notation can be used to navigate inside the data graph. Ex: `${address.zip}` would navigate you to the zip field of in the JSON data to

```json
"address":{
    "city": "Home Town",
    "state": "CA",
    "zip":90210
    }`
```

## Scopes with "$data"

A binding scope lets you set the _base_ of the data tree for the following template references. References below that point essentially include the scope as a prefix on the binding property names. You can set the binding scope back to null or the root of the data json by using `${$root}` as `$root` is a _magic word_ name. A long property reference of `${person.name}`
This came from <https://learn.microsoft.com/en-us/adaptive-cards/templating/language>

There are a few reserved keywords to access various binding scopes.

```JSON
{
    "${<property>}": "Implicitly binds to `$data.<property>`",
    "$data": "The current data object",
    "$root": "The root data object. Useful when iterating to escape to parent object",
    "$index": "The current index when iterating"
}
```

Assigning a data context to elements
To assign a "data context" to any element add a $data attribute to the element.

```JSON
{
    "type": "Container",
    "$data": "${mySubObject}",
    "items": [
        {
            "type": "TextBlock",
            "text": "This TextBlock is now scoped directly to 'mySubObject': ${mySubObjectProperty}"
        },
        {
            "type": "TextBlock",
            "text": "To break-out and access the root data, use: ${$root}"
        }
    ]
}
```

## Array Binding

An Adaptive Card element's `$data` property is bound to an array in the data JSON. That property should be an Array in the data JSON under the name that is the value of the `data` property. Elements in the template JSON will be repeated, as an array, for each item in the data JSON array.

Any binding expressions `${myProperty}` used in property values will be scoped to the individual item within the array.

The following sample creates a 2 Fact long FactSet from a data JSON. This exmaple came from <https://stackoverflow.com/questions/63738912/bind-an-array-with-dynamic-length-to-an-adaptive-card>

Template JSON

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.3",
  "body": [
    {
      "type": "TextBlock",
      "text": "${title}",
      "size": "Medium",
      "weight": "Bolder",
      "wrap": true,
      "separator": true
    },
    {
      "type": "FactSet",
      "facts": [
        {
          "$data": "${instructions}",
          "title": "${id}.",
          "value": "${text}"
        }
      ],
      "separator": true
    }
  ]
}
```

Data JSON

```json
{
  "title": "Instructions:",
  "instructions": [
    {
      "id": "1",
      "text": "blablablabla"
    },
    {
      "id": "2",
      "text": "qwerertzasdfadfds fasdf "
    }
  ]
}
```

Results in

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.3",
  "body": [
    {
      "type": "TextBlock",
      "text": "${title}",
      "size": "Medium",
      "weight": "Bolder",
      "wrap": true,
      "separator": true
    },
    {
      "type": "FactSet",
      "facts": [
        {
          "title": "1",
          "value": "blablablabla"
        },
        {
          "title": "2",
          "value": "qwerertzasdfadfds fasdf "
        }
      ],
      "separator": true
    }
  ]
}
```

## Basic Expression language support

The expression language supports simple conditional evaluation to set values `if(expression, trueValue, falseValue)`
The following example sets the color to 'good' if the priceChange value is greater than or equal to 0 and to `attention` if the priceChange value is less than 0

```JSON
{
    "type": "TextBlock",
    "color": "${if(priceChange >= 0, 'good', 'attention')}"
}
```

## Indexing into JSON strings with the $JSON function

You can navigate into an json string embedded in the data using `json(jsonString)`

### Example

This is an Azure DevOps response where the message property is a JSON-serialized string. In order to access values within the string, we need to use the json function in our template.

Data

```JSON
{
    "id": "1291525457129548",
    "status": 4,
    "author": "Matt Hidinger",
    "message": "{\"type\":\"Deployment\",\"buildId\":\"9542982\",\"releaseId\":\"129\",\"buildNumber\":\"20180504.3\",\"releaseName\":\"Release-104\",\"repoProvider\":\"GitHub\"}",
    "start_time": "2018-05-04T18:05:33.3087147Z",
    "end_time": "2018-05-04T18:05:33.3087147Z"
}
```

JSON Adaptive Card Template fragment

```JSON
{
    "type": "TextBlock",
    "text": "${json(message).releaseName}"
}
```

Results in the following JSON

JSON

```json
{
  "type": "TextBlock",
  "text": "Release-104"
}
```

## Conditional component removal or inclusion using the "$when"

To drop an entire element if a condition is met, use the `$when` property. If $when evaluates to false the element will not appear to the user.

The following JSON includes only one of the two text blocks based on the price being > 30 or <= 30

```JSON
{
    "type": "AdaptiveCard",
    "$data": {
        "price": "35"
    },
    "body": [
        {
            "type": "TextBlock",
            "$when": "${price > 30}",
            "text": "This thing is pricy!",
            "color": "attention",
        },
         {
            "type": "TextBlock",
            "$when": "${price <= 30}",
            "text": "Dang, this thing is cheap!",
            "color": "good"
        }
    ]
}
```

## Custom functions

Custom functions implemented in dart are not supported by the Dart Template library at this time

## Example Simple Template expansion

Template JSON

```json
{
  "type": "TextBlock",
  "text": "${firstName}"
}
```

Result JSON

```JSON
{
   "firstName": "Matt"
}
```

Resulting card json

```json
{
  "type": "TextBlock",
  "text": "Matt"
}
```

## AdaptiveCardTemplate — Dart class

`AdaptiveCardTemplate` is constructed with the JSON template; `expand(data)` then applies a data map and returns the merged card JSON. For a runnable Dart usage example, see the [`flutter_adaptive_template_fs` README — Usage](../packages/flutter_adaptive_template_fs/README.md#usage).

The original C# SDK API samples that guided this design (template expansion and custom-function registration) are archived at [`archive/specs/templating-csharp-design-samples.md`](archive/specs/templating-csharp-design-samples.md).

## Testing

How to build the templating test fixtures (JSON template/data pairs, expected-output validation,
sourcing samples from the Microsoft templates repo) is documented in the how-to companion:
[templating-testing.md](templating-testing.md).

## Data and Time Formatting

`DATE` and `TIME` formatting functins are implemented in flutter_adaptive_cards_fs and not `flutter_adaptive_template_fs`

## References

- Templates and Samples can be found at the [Legacy Adaptive Cards Site](https://adaptivecards.io/samples/)
- [Getting Started with Templating](https://learn.microsoft.com/en-us/adaptive-cards/templating/)
- [Templating Language Description](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)
- Demonstration adaptive cards service [on GitHub](https://github.com/microsoft/adaptivecards-templates) with some [sample templates](https://github.com/microsoft/adaptivecards-templates/tree/master/templates)
