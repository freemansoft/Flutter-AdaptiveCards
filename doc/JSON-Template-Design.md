# Design for Microsoft AdaptiveCard Template Engine

This is the initial design document for a Dart based templating engine located in `packages/flutter_adaptive_template` to be used in conjuction with the flutter adpaptive cards library located in `pacagkesflutter_adaptive_cards` in this repository. There is no cross package dependencies. Both flutter_adaptive_template and flutter_adaptive_cards can be used independently. The purpose of this engine is to separate the data in an adaptive card from the layout.  The template service applies the data json to the template json creating a renderable adaptive card json.  This page describes the templating language <https://learn.microsoft.com/en-us/adaptive-cards/templating/language> and should be used as the source.

This design supports separate template an data json but the standard also supports the data being part of the data in a "$data" field on the root of the JSON. You can see this in the examples.

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

A binding scope lets you set the _base_ of the data tree for the following template references. References below that point essentially include the scope as a prefix on the binding property names.  You can set the binding scope back to null or the root of the data json by using `${$root}` as `$root` is a _magic word_ name.  A long property reference of `${person.name}`
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

An Adaptive Card element's `$data` property is bound to an array in the data JSON. That property should be an Array in the data JSON under the name that is the value of the `data` property.  Elements in the template JSON will be repeated, as an array, for each item in the data JSON array.

Any binding expressions `${myProperty}` used in property values will be scoped to the individual item within the array.

The following sample creates a 2 Fact long FactSet from a data JSON.  This exmaple came from <https://stackoverflow.com/questions/63738912/bind-an-array-with-dynamic-length-to-an-adaptive-card>

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
  {
    "title": "Instructions:",
    "instructions": [{
            "id": "1",
            "text": "blablablabla"
        },
        {
            "id": "2",
            "text": "qwerertzasdfadfds fasdf "
        }
    ]
  }
}
```


Results in

```json
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


## AdaptiveCardTemplate - Dart Class

The template library initializes with the JSON template.  Then later calls apply data to to the template.

### Sample C# interface

The following contains the C# API. The samples came from <https://learn.microsoft.com/en-us/adaptive-cards/templating/sdk>. The Dart API shouild be similiar.

```csharp
// Create a Template instance from the template payload
AdaptiveCardTemplate template = new AdaptiveCardTemplate(templateJson);

// You can use any serializable object as your data
var myData = new
{
    Name = "Matt Hidinger"
};

// "Expand" the template - this generates the final Adaptive Card payload
string cardJson = template.Expand(myData);
```

### Sample Custom Fucntions

```csharp
string jsonTemplate = @"{
    ""type"": ""AdaptiveCard"",
    ""version"": ""1.0"",
    ""body"": [{
        ""type"": ""TextBlock"",
        ""text"": ""${stringFormat(strings.myName, person.firstName, person.lastName)}""
    }]
}";

string jsonData = @"{
    ""strings"": {
        ""myName"": ""My name is {0} {1}""
    },
    ""person"": {
        ""firstName"": ""Andrew"",
        ""lastName"": ""Leader""
    }
}";

AdaptiveCardTemplate template = new AdaptiveCardTemplate(jsonTemplate);

var context = new EvaluationContext
{
    Root = jsonData
};

// a custom function is added
AdaptiveExpressions.Expression.Functions.Add("stringFormat", (args) =>
{
    string formattedString = "";

    // argument is packed in sequential order as defined in the template
    // For example, suppose we have "${stringFormat(strings.myName, person.firstName, person.lastName)}"
    // args will have following entries
    // args[0]: strings.myName
    // args[1]: person.firstName
    // args[2]: strings.lastName
    if (args[0] != null && args[1] != null && args[2] != null)
    {
        string formatString = args[0];
        string[] stringArguments = {args[1], args[2] };
        formattedString = string.Format(formatString, stringArguments);
    }
    return formattedString;
});

string cardJson = template.Expand(context);
```

## Testing

Each of the features and capabilities described above must have unit tests to validate and prevent regression. The unit tests should use json template and json data files that should be part of the testing directory. in `packages/flutter_adaptive_template/test`. We want the unit test JSON to be in json files and not embedded in the tests themselves for future usage and analysis.

Testing template and data JSON can be found in the adaptive card templating service [on GitHub](https://github.com/microsoft/adaptivecards-templates/tree/master/templates). The project can copy over.  The team should prioritize templates and data in separate files but an also pull in JSON that has a $data section and then the template to be filed with the $data.  Some of the examples have a "$SampleData" section in the template that can be used to validate the template.  For testing, if we find that in a copied example then the $SampleData can be removed from the json and then be passed as the data json along with the modified template when executing the test.

1. Copy sample json from https://github.com/microsoft/adaptivecards-templates/tree/master/templates to use in the test. The examples in this document should also be made into tests with the json being put in json files and read by the tests
1. Create a unit test that loads the sample template/data json pair and merges them.  The developer should create an expected output json file and verify the merged template/data with the expected output.

## Data and Time Formatting

`DATE` and `TIME` formatting functins are implemented in flutter_adaptive_cards and not `flutter_adaptive_template`

## References

- Templates and Samples can be found at the [Legacy Adaptive Cards Site](https://adaptivecards.io/samples/)
- [Getting Started with Templating](https://learn.microsoft.com/en-us/adaptive-cards/templating/)
- [Templating Language Description](https://learn.microsoft.com/en-us/adaptive-cards/templating/language)
- Demonstration adaptive cards service [on GitHub](https://github.com/microsoft/adaptivecards-templates) with some [sample templates](https://github.com/microsoft/adaptivecards-templates/tree/master/templates)