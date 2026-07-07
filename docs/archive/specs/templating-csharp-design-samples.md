# Templating — C# SDK design samples (historical)

> 🗄️ **Historical.** Extracted from `docs/adaptive-template-design.md`. These C# SDK samples
> (from the [Microsoft templating SDK docs](https://learn.microsoft.com/en-us/adaptive-cards/templating/sdk))
> guided the original Dart design — "the Dart API should be similar." The Dart engine is now
> implemented; for runnable **Dart** usage see the
> [`flutter_adaptive_template_fs` README](../../../packages/flutter_adaptive_template_fs/README.md#usage).
> Kept only as a record of the original design intent.

## Sample C# interface

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

## Sample Custom Functions

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
