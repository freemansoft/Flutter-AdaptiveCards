# Azure Bot Service Adaptive Expressions - Future Reference

> [!NOTE]
> **This document is for FUTURE REFERENCE ONLY** - Not part of standard Adaptive Cards specification.
>
> This describes the Azure AI Bot Service expression language and prebuilt functions, which are **separate from** the core Adaptive Cards specification. These expressions were designed specifically for Azure Bot Framework conversational AI scenarios.
>
> The standard Adaptive Cards specification (used by this library) does NOT include these expressions. We may consider adding this expression language to `flutter_adaptive_template` in the future if there is demand for Azure bot integration.
>
> **For standard Adaptive Cards templating**, see [JSON-Template-Design.md](./JSON-Template-Design.md) which documents the Microsoft Adaptive Cards templating language that IS implemented in this library.

## About This Document

This document catalogs the prebuilt expression functions available in the Azure Bot Service Adaptive Expressions framework. These are used in bot development but are not part of the standard Adaptive Cards specification.

Expressions can be part of any template

Prebuilt expressions are divided into the following function types:

| Function Type                        | Status |
| :----------------------------------- | :----- |
| String                               | [ ]    |
| Collection                           | [ ]    |
| Logical comparison                   | [ ]    |
| Conversion                           | [ ]    |
| Math                                 | [ ]    |
| Date                                 | [ ]    |
| Timex                                | [ ]    |
| URI parsing                          | [ ]    |
| Object manipulation and construction | [ ]    |
| Regular expression                   | [ ]    |
| Type checking                        | [ ]    |

- https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions?view=azure-bot-service-4.0#prebuilt-functions-sorted-alphabetically

## Prebuilt functions sorted alphabetically

### abs

Return the absolute value of the specified number.

```
abs(<number>)
```

**Examples**
These examples compute the absolute value:

```
abs(3.12134)
abs(-3.12134)
```

And both return the result 3.12134.

### add

Return the result from adding two or more numbers (pure number case) or concatenating two or more strings (other case).

```
add(<item1>, <item2>, ...)
```

**Example**
This example adds the specified numbers:

```
add(1, 1.5)
```

And returns the result 2.5.

This example concatenates the specified items:

```
add('hello', null)
add('hello', 'world')
```

And returns the results:

- hello
- helloworld

### addDays

Add a number of days to a timestamp in an optional locale format.

```
addDays('<timestamp>', <days>, '<format>'?, '<locale>'?)
```

[custom format pattern](https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)
[ISO 8601](https://www.w3.org/QA/Tips/iso-date)

**Example 1**
This example adds 10 days to the specified timestamp:

```
addDays('2018-03-15T13:00:00.000Z', 10)
```

And returns the result 2018-03-25T00:00:00.000Z.

**Example 2**
This example subtracts five days from the specified timestamp:

```
addDays('2018-03-15T00:00:00.000Z', -5)
```

And returns the result 2018-03-10T00:00:00.000Z.

**Example 3**
This example adds 1 day to the specified timestamp in the de-DE locale:

```
addDays('2018-03-15T13:00:00.000Z', 1, '', 'de-dE')
```

And returns the result 16.03.18 13:00:00.

### addHours

Add a number of hours to a timestamp in an optional locale format.

```
addHours('<timestamp>', <hours>, '<format>'?, '<locale>'?)
```

[custom format pattern](https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)
[ISO 8601](https://www.w3.org/QA/Tips/iso-date)

**Example 1**
This example adds 10 hours to the specified timestamp:

```
addHours('2018-03-15T00:00:00.000Z', 10)
```

And returns the result 2018-03-15T10:00:00.000Z.

**Example 2**
This example subtracts five hours from the specified timestamp:

```
addHours('2018-03-15T15:00:00.000Z', -5)
```

And returns the result 2018-03-15T10:00:00.000Z.

**Example 3**
This example adds 2 hours to the specified timestamp in the de-DE locale:

```
addHours('2018-03-15T13:00:00.000Z', 2, '', 'de-DE')
```

And returns the result 15.03.18 15:00:00.

### addMinutes

Add a number of minutes to a timestamp in an optional locale format.

```
addMinutes('<timestamp>', <minutes>, '<format>'?, '<locale>'?)
```

[custom format pattern](https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)
[ISO 8601](https://www.w3.org/QA/Tips/iso-date)

**Example 1**
This example adds 10 minutes to the specified timestamp:

```
addMinutes('2018-03-15T00:10:00.000Z', 10)
```

And returns the result 2018-03-15T00:20:00.000Z.

**Example 2**
This example subtracts five minutes from the specified timestamp:

```
addMinutes('2018-03-15T00:20:00.000Z', -5)
```

And returns the result 2018-03-15T00:15:00.000Z.

**Example 3**
This example adds 30 minutes to the specified timestamp in the de-DE locale:

```
addMinutes('2018-03-15T00:00:00.000Z', 30, '', 'de-DE')
```

And returns the result 15.03.18 13:30:00.

### addOrdinal

Return the ordinal number of the input number.

```
addOrdinal(<number>)
```

**Example**

```
addOrdinal(11)
addOrdinal(12)
addOrdinal(13)
addOrdinal(21)
addOrdinal(22)
addOrdinal(23)
```

And respectively returns these results:

- 11th
- 12th
- 13th
- 21st
- 22nd
- 23rd

### addProperty

Add a property and its value, or name-value pair, to a JSON object, and return the updated object. If the object already exists at runtime the function throws an error.

```
addProperty('<object>', '<property>', value)
```

**Example**
This example adds the accountNumber property to the customerProfile object, which is converted to JSON with the [json()](#json) function. The function assigns a value that is generated by the [newGuid()](#newguid) function, and returns the updated object:

```
addProperty(json('customerProfile'), 'accountNumber', newGuid())
```

### addSeconds

Add a number of seconds to a timestamp.

```
addSeconds('<timestamp>', <seconds>, '<format>'?)
```

[custom format pattern](https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)
[ISO 8601](https://www.w3.org/QA/Tips/iso-date)

**Example 1**
This example adds 10 seconds to the specified timestamp:

```
addSeconds('2018-03-15T00:00:00.000Z', 10)
```

And returns the result 2018-03-15T00:00:10.000Z.

**Example 2**
This example subtracts five seconds to the specified timestamp:

```
addSeconds('2018-03-15T00:00:30.000Z', -5)
```

And returns the result 2018-03-15T00:00:25.000Z.

### addToTime

Add a number of time units to a timestamp in an optional locale format. See also [getFutureTime()](#getfuturetime).

```
addToTime('<timestamp>', '<interval>', <timeUnit>, '<format>'?, '<locale>'?)
```

[custom format pattern](https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)
[ISO 8601](https://www.w3.org/QA/Tips/iso-date)

**Example 1**
This example adds one day to specified timestamp.

```
addToTime('2018-01-01T00:00:00.000Z', 1, 'Day')
```

And returns the result 2018-01-02T00:00:00.000Z.

**Example 2**
This example adds two weeks to the specified timestamp.

```
addToTime('2018-01-01T00:00:00.000Z', 2, 'Week', 'MM-DD-YY')
```

And returns the result in the 'MM-DD-YY' format as 01-15-18.

### all

Determine whether all elements of a sequence satisfy a condition.

```
all(<sequence>, <item>, <condition>)
```

**Examples**
These examples determine if all elements of a sequence satisfy a condition:

```
all(createArray(1, 'cool'), item, isInteger(item))
all(createArray(1, 2), item => isInteger(item))
```

And return the following results respectively:

- false, because both items in the sequence aren't integers.
- true, because both items in the sequence are integers.

### and

Check whether all expressions are true. Return true if all expressions are true, or return false if at least one expression is false.

```
and(<expression1>, <expression2>, ...)
```

**Example 1**
These examples check whether the specified Boolean values are all true:

```
and(true, true)
and(false, true)
and(false, false)
```

And respectively returns these results:

- Both expressions are true, so the functions returns true.
- One expression is false, so the functions returns false.
- Both expressions are false, so the function returns false.

**Example 2**
These examples check whether the specified expressions are all true:

```
and(equals(1, 1), equals(2, 2))
and(equals(1, 1), equals(1, 2))
and(equals(1, 2), equals(1, 3))
```

And respectively returns these results:

- Both expressions are true, so the functions returns true.
- One expression is false, so the functions returns false.
- Both expressions are false, so the functions returns false.

### any

Determine whether any elements of a sequence satisfy a condition.

```
any(<sequence>, <item>, <condition>)
```

**Examples**
These examples determine if all elements of a sequence satisfy a condition:

```
any(createArray(1, 'cool'), item, isInteger(item))
any(createArray('first', 'cool'), item => isInteger(item))
```

And return the following results respectively:

- true, because at least one item in the sequence is an integer
- false, because neither item in the sequence is an integer.

### average

Return the number average of a numeric array.

```
average(<numericArray>)
```

**Example**
This example calculates the average of the array in createArray():

```
average(createArray(1,2,3))
```

And returns the result 2.

### base64

Return the base64-encoded version of a string or byte array.

```
base64('<value>')
```

**Example 1**
This example converts the string hello to a base64-encoded string:

```
base64('hello')
```

And returns the result "aGVsbG8=".

**Example 2**
This example takes byteArr, which equals new byte[] { 3, 5, 1, 12 }:

```
base64('byteArr')
```

And returns the result "AwUBDA==".

### base64ToBinary

Return the binary array of a base64-encoded string.

```
base64ToBinary('<value>')
```

**Example**
This example converts the base64-encoded string AwUBDA== to a binary string:

```
base64ToBinary('AwUBDA==')
```

And returns the result new byte[] { 3, 5, 1, 12 }.

### base64ToString

Return the string version of a base64-encoded string, effectively decoding the base64 string.

```
base64ToString('<value>')
```

**Example**
This example converts the base64-encoded string aGVsbG8= to a decoded string:

```
base64ToString('aGVsbG8=')
```

And returns the result hello.

### binary

Return the binary version of a string.

```
binary('<value>')
```

**Example**
This example converts the string hello to a binary string:

```
binary('hello')
```

And returns the result new byte[] { 104, 101, 108, 108, 111 }.

### bool

Return the Boolean version of a value.

```
bool(<value>)
```

**Example**
These examples convert the specified values to Boolean values:

```
bool(1)
bool(0)
```

And respectively returns these results:

- true
- false

### ceiling

Return the largest integral value less than or equal to the specified number.

```
ceiling('<number>')
```

**Example**
This example returns the largest integral value less than or equal to the number 10.333:

```
ceiling(10.333)
```

And returns the integer 11.

### coalesce

Return the first non-null value from one or more parameters. Empty strings, empty arrays, and empty objects are not null.

```
coalesce(<object1>, <object2>, ...)
```

**Example**
These examples return the first non-null value from the specified values, or null when all the values are null:

```
coalesce(null, true, false)
coalesce(null, 'hello', 'world')
coalesce(null, null, null)
```

And respectively return:

- true
- hello
- null

### concat

Combine two or more objects, and return the combined objects in a list or string.

```
concat('<text1>', '<text2>', ...)
```

Expected return values:

- If all items are lists, a list will be returned.
- If there exists an item that isn't a list, a string will be returned.
- If a value is null, it's skipped and not concatenated.

**Example 1**
This example combines the strings Hello and World:

```
concat('Hello', 'World')
```

And returns the result HelloWorld.

**Example 2**
This example combines the lists [1,2] and [3,4]:

```
concat([1,2],[3,4])
```

And returns the result [1,2,3,4].

**Example 3**
These examples combine objects of different types:

```
concat('a', 'b', 1, 2)
concat('a', [1,2])
```

And return the following results respectively:

- The string ab12.
- The object aSystem.Collections.Generic.List 1[System.Object]. This is unreadable and best to avoid.

**Example 4**
These examples combine objects will null:

```
concat([1,2], null)
concat('a', 1, null)
```

And return the following results respectively:

- The list [1,2].
- The string a1.

### contains

Check whether a collection has a specific item. Return true if the item is found, or return false if not found. This function is case-sensitive.

```
contains('<collection>', '<value>')
contains([<collection>], '<value>')
```

This function works on the following collection types:

- A string to find a substring
- An array to find a value
- A dictionary to find a key

**Example 1**
This example checks the string hello world for the substring world:

```
contains('hello world', 'world')
```

And returns the result true.

**Example 2**
This example checks the string hello world for the substring universe:

```
contains('hello world', 'universe')
```

And returns the result false.

### count

Return the number of items in a collection.

```
count('<collection>')
count([<collection>])
```

**Examples**
These examples count the number of items in these collections:

```
count('abcd')
count(createArray(0, 1, 2, 3))
```

And both return the result 4.

### countWord

Return the number of words in a string

```
countWord('<text>')
```

**Example**
This example counts the number of words in the string hello world:

```
countWord("hello word")
```

And it returns the result 2.

### convertFromUTC

Convert a timestamp in an optional locale format from Universal Time Coordinated (UTC) to a target time zone.

```
convertFromUTC('<timestamp>', '<destinationTimeZone>', '<format>'?, '<locale>'?)
```

**Example 1**
These examples convert from UTC to Pacific Standard Time:

```
convertFromUTC('2018-02-02T02:00:00.000Z', 'Pacific Standard Time', 'MM-DD-YY')
convertFromUTC('2018-02-02T02:00:00.000Z', 'Pacific Standard Time')
```

And respectively return these results:

- 02-01-18
- 2018-01-01T18:00:00.0000000

### convertToUTC

Convert a timestamp in an optional locale format to Universal Time Coordinated (UTC) from the source time zone.

```
convertToUTC('<timestamp>', '<sourceTimeZone>', '<format>'?, '<locale>'?)
```

**Example 1**
This example converts a timestamp to UTC from Pacific Standard Time

```
convertToUTC('01/01/2018 00:00:00', 'Pacific Standard Time')
```

And returns the result 2018-01-01T08:00:00.000Z.

### createArray

Return an array from multiple inputs.

```
createArray('<object1>', '<object2>', ...)
```

**Example**
This example creates an array from the following inputs:

```
createArray('h', 'e', 'l', 'l', 'o')
```

And returns the result [h, e, l, l, o].

### dataUri

Return a data uniform resource identifier (URI) of a string.

```
dataUri('<value>')
```

**Example**

```
dataUri('hello')
```

Returns the result data:text/plain;charset=utf-8;base64,aGVsbG8=.

### dataUriToBinary

Return the binary version of a data uniform resource identifier (URI).

```
dataUriToBinary('<value>')
```

**Example**
This example creates a binary version for the following data URI:

```
dataUriToBinary('aGVsbG8=')
```

And returns the result new byte[] { 97, 71, 86, 115, 98, 71, 56, 61 }.

### dataUriToString

Return the string version of a data uniform resource identifier (URI).

```
dataUriToString('<value>')
```

**Example**
This example creates a string from the following data URI:

```
dataUriToString('data:text/plain;charset=utf-8;base64,aGVsbG8=')
```

And returns the result hello.

### date

Return the date of a specified timestamp in m/dd/yyyy format.

```
date('<timestamp>')
```

**Example**

```
date('2018-03-15T13:00:00.000Z')
```

Returns the result 3-15-2018.

### dateReadBack

Uses the date-time library to provide a date readback.

```
dateReadBack('<currentDate>', '<targetDate>')
```

**Example 1**

```
dateReadBack('2018-03-15T13:00:00.000Z', '2018-03-16T13:00:00.000Z')
```

Returns the result tomorrow.

### dateTimeDiff

Return the difference in ticks between two timestamps.

```
dateTimeDiff('<timestamp1>', '<timestamp2>')
```

**Example 1**
This example returns the difference in ticks between two timestamps:

```
dateTimeDiff('2019-01-01T08:00:00.000Z','2018-01-01T08:00:00.000Z')
```

And returns the number 315360000000000.

**Example 2**
This example returns the difference in ticks between two timestamps:

```
dateTimeDiff('2018-01-01T08:00:00.000Z', '2019-01-01T08:00:00.000Z')
```

Returns the result -315360000000000. The value is a negative number.

### dayOfMonth

Return the day of the month from a timestamp.

```
dayOfMonth('<timestamp>')
```

**Example**
This example returns the number for the day of the month from the following timestamp:

```
dayOfMonth('2018-03-15T13:27:36Z')
```

And returns the result 15.

### dayOfWeek

Return the day of the week from a timestamp.

```
dayOfWeek('<timestamp>')
```

**Example**
This example returns the number for the day of the week from the following timestamp:

```
dayOfWeek('2018-03-15T13:27:36Z')
```

And returns the result 3.

### dayOfYear

Return the day of the year from a timestamp.

```
dayOfYear('<timestamp>')
```

**Example**
This example returns the number of the day of the year from the following timestamp:

```
dayOfYear('2018-03-15T13:27:36Z')
```

And returns the result 74.

### div

Return the integer result from dividing two numbers. To return the remainder see [mod()](#mod).

```
div(<dividend>, <divisor>)
```

**Example**
Both examples divide the first number by the second number:

```
div(10, 5)
div(11, 5)
```

And return the result 2.

There exists some gap between Javascript and .NET SDK. For example, the following expression will return different results in Javascript and .NET SDK:

- If one of the parameters is a float, the result will also be a FLOAT with .NET SDK.
- If one of the parameters is a float, the result will be an INT with Javascript SDK.

### empty

Check whether an instance is empty. Return true if the input is empty. Empty means:

- input is null or undefined
- input is a null or empty string
- input is zero size collection
- input is an object with no property.

```
empty('<instance>')
empty([<instance>])
```

**Example**
These examples check whether the specified instance is empty:

```
empty('')
empty('abc')
empty([1])
empty(null)
```

And return these results respectively:

- true (empty string)
- false (string abc)
- false (one item)
- true (null object)

### endsWith

Check whether a string ends with a specific substring. Return true if the substring is found, or return false if not found. This function is case-insensitive.

```
endsWith('<text>', '<searchText>')
```

**Example 1**
This example checks whether the hello world string ends with the string world:

```
endsWith('hello world', 'world')
```

And it returns the result true.

**Example 2**
This example checks whether the hello world string ends with the string universe:

```
endsWith('hello world', 'universe')
```

And it returns the result false.

### EOL

Return the end of line (EOL) sequence text.

```
EOL()
```

**Example**
This example checks the end of the line sequence text:

```
EOL()
```

And returns the following strings:

- Windows: \r\n
- Mac or Linux: \n

### equals

Check whether both values, expressions, or objects are equivalent. Return true if both are equivalent, or return false if they're not equivalent.

```
equals('<object1>', '<object2>')
```

**Example**
These examples check whether the specified inputs are equivalent:

```
equals(true, 1)
equals('abc', 'abcd')
```

And returns these results respectively:

- true (equivalent)
- false (not equivalent)

### exists

Evaluates an expression for truthiness.

```
exists(expression)
```

**Example**
Say foo = {"bar": "value"}.

```
exists(foo.bar)
exists(foo.bar2)
```

And return these results respectively:

- true
- false

### exp

Return exponentiation of one number to another.

```
exp(realNumber, exponentNumber)
```

**Example**
This example computes the exponent:

```
exp(2, 2)
```

And returns the result 4.

### first

Return the first item from a string or array.

```
first('<collection>')
first([<collection>])
```

**Example**
These examples find the first item in the following collections:

```
first('hello')
first(createArray(0, 1, 2))
```

And return these results respectively:

- h
- 0

### flatten

Flatten an array into non-array values. You can optionally set the maximum depth to flatten to.

```
flatten([<collection>], '<depth>')
```

**Example 1**
This example flattens the following array:

```
flatten(createArray(1, createArray(2), createArray(createArray(3, 4), createArray(5, 6))))
```

And returns the result [1, 2, 3, 4, 5, 6].

**Example 2**
This example flattens the array to a depth of 1:

```
flatten(createArray(1, createArray(2), createArray(createArray(3, 4), createArray(5, 6))), 1)
```

And returns the result [1, 2, [3, 4], [5, 6]].

### float

Convert the string version of a floating-point number to a floating-point number.

```
float('<value>')
```

**Example**

```
float('10.333')
```

And returns the float 10.333.

### floor

Return the largest integral value less than or equal to the specified number.

```
floor('<number>')
```

**Example**

```
floor(10.333)
```

And returns the integer 10.

### foreach

Operate on each element and return the new collection.

```
foreach([<collection/instance>], <iteratorName>, <function>)
```

**Example 1**
This example generates a new collection:

```
foreach(createArray(0, 1, 2, 3), x, x + 1)
```

And returns the result [1, 2, 3, 4].

**Example 2**
These examples generate a new collection:

```
foreach(json("{'name': 'jack', 'age': '15'}"), x, concat(x.key, ':', x.value))
foreach(json("{'name': 'jack', 'age': '15'}"), x => concat(x.key, ':', x.value))
```

And return the result ['name:jack', 'age:15'].

### formatDateTime

Return a timestamp in an optional locale format.

```
formatDateTime('<timestamp>', '<format>'?, '<locale>'?)
```

[custom format pattern](https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)
[ISO 8601](https://www.w3.org/QA/Tips/iso-date)

**Example 1**

```
formatDateTime('03/15/2018 12:00:00', 'yyyy-MM-ddTHH:mm:ss')
```

And returns the result 2018-03-15T12:00:00.

**Example 2**

```
formatDateTime('2018-03-15', '', 'de-DE')
```

And returns the result 15.03.18 00:00:00.

### formatEpoch

Return a timestamp in an optional locale format in the specified format from UNIX time.

```
formatEpoch('<epoch>', '<format>'?, '<locale>'?)
```

**Example**

```
formatEpoch(1521118800, 'yyyy-MM-ddTHH:mm:ss.fffZ')
```

And returns the result 2018-03-15T12:00:00.000Z.

### formatNumber

Format a value to the specified number of fractional digits and an optional specified locale.

```
formatNumber('<number>', '<precision-digits>', '<locale>'?)
```

**Example 1**

```
formatNumber(10.333, 2)
```

And returns the string 10.33.

**Example 2**

```
formatNumber(12.123, 2, 'en-US')
formatNumber(1.551, 2, 'en-US')
formatNumber(12.123, 4, 'en-US')
```

And return the following results respectively:

- 12.12
- 1.55
- 12.1230

### formatTicks

Return a timestamp in an optional locale format in the specified format from ticks.

```
formatTicks('<ticks>', '<format>'?, '<locale>'?)
```

**Example 1**

```
formatTicks(637243624200000000, 'yyyy-MM-ddTHH:mm:ss.fffZ')
```

And returns the result 2020-05-06T11:47:00.000Z.

### getFutureTime

Return the current timestamp in an optional locale format plus the specified time units.

```
getFutureTime(<interval>, <timeUnit>, '<format>'?, '<locale>'?)
```

**Example 1**

```
getFutureTime(2, 'Week')
```

If current time is 2019-03-01T00:00:00.000Z, returns 2019-03-15T00:00:00.000Z.

### getNextViableDate

Return the next viable date of a Timex expression based on the current date and an optionally specified timezone.

```
getNextViableDate(<timexString>, <timezone>?)
```

### getNextViableTime

Return the next viable time of a Timex expression based on the current time and an optionally specified timezone.

```
getNextViableTime(<timexString>, <timezone>?)
```

### getPastTime

Return the current timestamp minus the specified time units.

```
getPastTime(<interval>, <timeUnit>, '<format>'?)
```

**Example 1**

```
getPastTime(5, 'Day')
```

If current time is 2018-02-01T00:00:00.000Z, returns 2018-01-27T00:00:00.000Z.

### getPreviousViableDate

Return the previous viable date of a Timex expression based on the current date and an optionally specified timezone.

```
getPreviousViableDate(<timexString>, <timezone>?)
```

### getPreviousViableTime

Return the previous viable time of a Timex expression based on the current date and an optionally specified timezone.

```
getPreviousViableTime(<timexString>, <timezone>?)
```

**Example**
If the date is 2020-06-12 and current time is 15:42:21:

```
getPreviousViableTime("TXX:52:14")
getPreviousViableTime("TXX:12:14", 'Europe/London')
```

And return the following strings respectively:

- T14:52:14
- T15:12:14

### getProperty

Return the value of a specified property or the root property from a JSON object.

#### Return the value of a specified property

```
getProperty(<JSONObject>, '<propertyName>')
```

**Example**
Say you have the following JSON object:

```json
{ "a:b": "a:b value", "c": { "d": "d key" } }
```

Then:

```
getProperty({"a:b": "value"}, 'a:b')
getProperty(c, 'd')
```

And return the following strings respectively:

- a:b value
- d key

#### Return the root property

```
getProperty('<propertyName>')
```

**Example**

```
getProperty("a:b")
```

Returns the string a:b value.

### getTimeOfDay

Returns time of day for a given timestamp.

```
getTimeOfDay('<timestamp>')
```

**Example**

```
getTimeOfDay('2018-03-15T08:00:00.000Z')
```

Returns the result morning.

### greater

Check whether the first value is greater than the second value. Return true if the first value is more, or return false if less.

```
greater(<value>, <compareTo>)
greater('<value>', '<compareTo>')
```

**Example**

```
greater(10, 5)
greater('apple', 'banana')
```

And return the following results respectively:

- true
- false

### greaterOrEquals

Check whether the first value is greater than or equal to the second value.

```
greaterOrEquals(<value>, <compareTo>)
greaterOrEquals('<value>', '<compareTo>')
```

**Example**

```
greaterOrEquals(5, 5)
greaterOrEquals('apple', 'banana')
```

And return the following results respectively:

- true
- false

### if

Check whether an expression is true or false. Based on the result, return a specified value.

```
if(<expression>, <valueIfTrue>, <valueIfFalse>)
```

**Example**

```
if(equals(1, 1), 'yes', 'no')
```

Returns yes.

### indexOf

Return the starting position or index value of a substring. This function is case-insensitive, and indexes start with the number 0.

```
indexOf('<text>', '<searchText>')
```

**Example 1**

```
indexOf('hello world', 'world')
```

Returns the result 6.

**Example 2**

```
indexOf(createArray('abc', 'def', 'ghi'), 'def')
```

Returns the result 1.

### indicesAndValues

Turn an array or object into an array of objects with index (current index) and value properties.

```
indicesAndValues('<collection or object>')
```

**Example 1**
Say items is ["zero", "one", "two"].

```
indicesAndValues(items)
```

Returns:

```json
[
  { "index": 0, "value": "zero" },
  { "index": 1, "value": "one" },
  { "index": 2, "value": "two" }
]
```

### int

Return the integer version of a string.

```
int('<value>')
```

**Example**

```
int('10')
```

Returns 10.

### intersection

Return a collection that has only the common items across the specified collections.

```
intersection([<collection1>], [<collection2>], ...)
intersection('<collection1>', '<collection2>', ...)
```

**Example**

```
intersection(createArray(1, 2, 3), createArray(101, 2, 1, 10), createArray(6, 8, 1, 2))
```

Returns [1, 2].

### isArray

Return true if a given input is an array.

```
isArray('<input>')
```

### isBoolean

Return true if a given input is a Boolean.

```
isBoolean('<input>')
```

### isDate

Return true if a given TimexProperty or Timex expression refers to a valid date.

```
isDate('<input>')
```

### isDateRange

Return true if a given TimexProperty or Timex expression refers to a valid date range.

```
isDateRange('<input>')
```

### isDateTime

Return true if a given input is a UTC ISO format (YYYY-MM-DDTHH:mm:ss.fffZ) timestamp string.

```
isDateTime('<input>')
```

### isDefinite

Return true if a given TimexProperty or Timex expression refers to a valid date.

```
isDefinite('<input>')
```

### isDuration

Return true if a given TimexProperty or Timex expression refers to a valid duration.

```
isDuration('<input>')
```

### isFloat

Return true if a given input is a floating-point number.

```
isFloat('<input>')
```

### isInteger

Return true if a given input is an integer number.

```
isInteger('<input>')
```

### isMatch

Return true if a given string matches a specified regular expression pattern.

```
isMatch('<target_string>', '<pattern>')
```

**Example**

```
isMatch('ab', '^[a-z]{1,2}$')
```

Returns true.

### isObject

Return true if a given input is a complex object.

```
isObject('<input>')
```

### isPresent

Return true if a given TimexProperty or Timex expression refers to the present.

```
isPresent('<input>')
```

### isString

Return true if a given input is a string.

```
isString('<input>')
```

### isTime

Return true if a given TimexProperty or Timex expression refers to a valid time.

```
isTime('<input>')
```

### isTimeRange

Return true if a given TimexProperty or Timex expression refers to a valid time range.

```
isTimeRange('<input>')
```

### join

Return a string that has all the items from an array, with each character separated by a delimiter.

```
join([<collection>], '<delimiter>')
```

**Example**

```
join(createArray('a', 'b', 'c'), '.')
```

Returns a.b.c.

### jPath

Check JSON or a JSON string for nodes or values that match a path expression.

```
jPath(<json>, '<path>')
```

**Example**
Say jsonStr is `{"Stores": ["Lambton Quay", "Willis Street"]}`.

```
jPath(jsonStr, "$..Stores")
```

Returns `["Lambton Quay", "Willis Street"]`.

### json

Return the JSON type value or object of a string or XML.

```
json('<value>')
```

**Example 1**

```
json('{"fullName": "Sophia Owen"}')
```

Returns the object `{ "fullName": "Sophia Owen" }`.

### jsonStringify

Return the JSON string of a value.

```
jsonStringify(null)
jsonStringify({a:'b'})
```

Returns:

- null
- {"a":"b"}

### last

Return the last item from a collection.

```
last('<collection>')
last([<collection>])
```

**Example**

```
last('abcd')
last(createArray(0, 1, 2, 3))
```

Returns:

- d
- 3

### lastIndexOf

Return the starting position or index value of the last occurrence of a substring.

```
lastIndexOf('<text>', '<searchText>')
```

**Example 1**

```
lastIndexOf('hello world', 'world')
```

Returns 6.

**Example 2**

```
lastIndexOf(createArray('abc', 'def', 'ghi', 'def'), 'def')
```

Returns 3.

### length

Return the length of a string.

```
length('<str>')
```

**Examples**

```
length('hello')
length('hello world')
```

Returns:

- 5
- 11

### less

Check whether the first value is less than the second value.

```
less(<value>, <compareTo>)
less('<value>', '<compareTo>')
```

**Example**

```
less(5, 10)
less('banana', 'apple')
```

Returns:

- true
- false

### lessOrEquals

Check whether the first value is less than or equal to the second value.

```
lessOrEquals(<value>, <compareTo>)
lessOrEquals('<value>', '<compareTo>')
```

**Example**

```
lessOrEquals(10, 10)
lessOrEquals('apply', 'apple')
```

Returns:

- true
- false

### max

Return the highest value from a list or array.

```
max(<number1>, <number2>, ...)
max([<number1>, <number2>, ...])
```

**Example**

```
max(1, 2, 3)
max(createArray(1, 2, 3))
```

Returns 3.

### merge

Merges multiple JSON objects or an array of objects together.

```
merge(<json1>, <json2>, ...)
```

**Example**

```
merge({k1:'v1'}, [{k2:'v2'}, {k3: 'v3'}], {k4:'v4'})
```

Returns `{ "k1": "v1", "k2": "v2", "k3": "v3", "k4": "v4" }`.

### min

Return the lowest value from a set of numbers or an array.

```
min(<number1>, <number2>, ...)
min([<number1>, <number2>, ...])
```

**Example**

```
min(1, 2, 3)
min(createArray(1, 2, 3))
```

Returns 1.

### mod

Return the remainder from dividing two numbers.

```
mod(<dividend>, <divisor>)
```

**Example**

```
mod(3, 2)
```

Returns 1.

### month

Return the month of the specified timestamp.

```
month('<timestamp>')
```

**Example**

```
month('2018-03-15T13:01:00.000Z')
```

Returns 3.

### mul

Return the product from multiplying two numbers.

```
mul(<multiplicand1>, <multiplicand2>)
```

**Example**

```
mul(1, 2)
mul(1.5, 2)
```

Returns:

- 2
- 3

### newGuid

Return a new Guid string.

```
newGuid()
```

**Example**

```
newGuid()
```

Returns a string in format `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`.

### not

Check whether an expression is false.

```
not(<expression>)
```

**Example**

```
not(false)
not(equals(1, 1))
```

Returns:

- true
- false

### or

Check whether at least one expression is true.

```
or(<expression1>, <expression2>, ...)
```

**Example**

```
or(true, false)
or(equals(1, 2), equals(1, 3))
```

Returns:

- true
- false

### rand

Return a random integer from a specified range (inclusive at start, exclusive at end).

```
rand(<minValue>, <maxValue>)
```

**Example**

```
rand(1, 5)
```

Returns 1, 2, 3, or 4.

### range

Return an integer array that starts from a specified integer.

```
range(<startIndex>, <count>)
```

**Example**

```
range(1, 4)
```

Returns [1, 2, 3, 4].

### removeProperty

Remove a property from an object and return the updated object.

```
removeProperty(<object>, '<property>')
```

**Example**

```
removeProperty(json('customerProfile'), 'accountLocation')
```

### replace

Replace a substring with the specified string. This function is case-sensitive.

```
replace('<text>', '<oldText>', '<newText>')
```

**Example 1**

```
replace('the old string', 'old', 'new')
```

Returns "the new string".

### replaceIgnoreCase

Replace a substring with the specified string. This function is case-insensitive.

```
replaceIgnoreCase('<text>', '<oldText>', '<newText>')
```

**Example**

```
replaceIgnoreCase('the old string', 'old', 'new')
```

Returns "the new string".

### resolve

Return string of a given TimexProperty or Timex expression if it refers to a valid time.

```
resolve('<timestamp>')
```

**Examples**

```
resolve(T14) // Returns 14:00:00
resolve(2020-12-20) // Returns 2020-12-20
```

### reverse

Reverse the order of the elements in a string or array.

```
reverse(<value>)
```

**Example**

```
reverse('hello') // Returns olleh
```

### round

Round a value to the nearest integer or to the specified number of fractional digits.

```
round('<number>', '<precision-digits>')
```

**Example 1**

```
round(10.333) // Returns 10
```

**Example 2**

```
round(10.3313, 2) // Returns 10.33
```

### select

Operate on each element and return the new collection of transformed elements.

```
select([<collection/instance>], <iteratorName>, <function>)
```

**Example 1**

```
select(createArray(0, 1, 2, 3), x, x + 1)
```

Returns [1, 2, 3, 4].

**Example 2**

```
select(json("{'name': 'jack', 'age': '15'}"), x, concat(x.key, ':', x.value))
```

Returns ['name:jack', 'age:15'].

### sentenceCase

Capitalize the first letter of the first word in a string.

```
sentenceCase('<text>', '<locale>'?)
```

**Example**

```
sentenceCase('abc def') // Returns "Abc def"
```

### setPathToValue

Retrieve the value of the specified property from the JSON object.

```
setPathToValue(<path>, <value>)
```

### setProperty

Set the value of an object's property and return the updated object.

```
setProperty(<object>, '<property>', <value>)
```

### skip

Remove items from the front of a collection, and return all the other items.

```
skip([<collection>], <count>)
```

**Example**

```
skip(createArray(0, 1, 2, 3), 1) // Returns [1, 2, 3]
```

### sortBy

Sort elements in the collection in ascending order.

```
sortBy([<collection>], '<property>')
```

**Example**

```
sortBy(createArray(1, 2, 0, 3)) // Returns [0, 1, 2, 3]
```

### sortByDescending

Sort elements in the collection in descending order.

```
sortByDescending([<collection>], '<property>')
```

**Example**

```
sortByDescending(createArray(1, 2, 0, 3)) // Returns [3, 2, 1, 0]
```

### split

Return an array that contains substrings based on the specified delimiter.

```
split('<text>', '<delimiter>'?)
```

**Example**

```
split('a**b**c', '**') // Returns ["a", "b", "c"]
```

### sqrt

Return the square root of a specified number.

```
sqrt(<number>)
```

**Example**

```
sqrt(9) // Returns 3
```

### startOfDay

Return the start of the day for a timestamp.

```
startOfDay('<timestamp>', '<format>'?, '<locale>'?)
```

### startOfHour

Return the start of the hour for a timestamp.

```
startOfHour('<timestamp>', '<format>'?, '<locale>'?)
```

### startOfMonth

Return the start of the month for a timestamp.

```
startOfMonth('<timestamp>', '<format>'?, '<locale>'?)
```

### startsWith

Check whether a string starts with a specific substring.

```
startsWith('<text>', '<searchText>')
```

**Example**

```
startsWith('hello world', 'hello') // Returns true
```

### string

Return the string version of a value.

```
string(<value>, '<locale>'?)
```

**Example**

```
string(10) // Returns "10"
```

### stringOrValue

Wrap string interpolation to get the real value.

```
stringOrValue(<string>)
```

### sub

Return the result from subtracting the second number from the first number.

```
sub(<minuend>, <subtrahend>)
```

**Example**

```
sub(10.3, 0.3) // Returns 10
```

### subArray

Returns a subarray from specified start and end positions.

```
subArray(<Array>, <startIndex>, <endIndex>)
```

**Example**

```
subArray(createArray('H','e','l','l','o'), 2, 5) // Returns ["l", "l", "o"]
```

### substring

Return characters from a string, starting from the specified position or index.

```
substring('<text>', <startIndex>, <length>)
```

**Example**

```
substring('hello world', 6, 5) // Returns "world"

### subtractFromTime
Subtract a number of time units from a timestamp.

```

subtractFromTime('<timestamp>', <interval>, '<timeUnit>', '<format>'?, '<locale>'?)

```

**Example 1**
```

subtractFromTime('2018-01-02T00:00:00.000Z', 1, 'Day') // Returns 2018-01-01T00:00:00.000Z

```

### sum
Return the result from adding numbers in a list.

```

sum([<list of numbers>])

```

**Example**
```

sum(createArray(1, 1.5)) // Returns 2.5

```

### take
Return items from the front of a collection.

```

take('<collection>', <count>)
take([<collection>], <count>)

```

**Example**
```

take('abcde', 3) // Returns abc
take(createArray(0, 1, 2, 3, 4), 3) // Returns [0, 1, 2]

```

### ticks
Return the ticks property value of a specified timestamp. (A tick is a 100-nanosecond interval).

```

ticks('<timestamp>')

```

**Example**
```

ticks('2018-01-01T08:00:00.000Z') // Returns 636503904000000000

```

### ticksToDays
Convert a ticks property value to the number of days.

```

ticksToDays(<ticks>)

```

### ticksToHours
Convert a ticks property value to the number of hours.

```

ticksToHours(<ticks>)

```

### ticksToMinutes
Convert a ticks property value to the number of minutes.

```

ticksToMinutes(<ticks>)

```

### titleCase
Capitalize the first letter of each word in a string.

```

titleCase('<text>', '<locale>'?)

```

**Example**
```

titleCase('abc def') // Returns "Abc Def"

```

### toLower
Return a string in lowercase.

```

toLower('<text>', '<locale>'?)

```

**Example**
```

toLower('Hello World') // Returns hello world

```

### toUpper
Return a string in uppercase.

```

toUpper('<text>', '<locale>'?)

```

**Example**
```

toUpper('Hello World') // Returns HELLO WORLD

```

### trim
Remove leading and trailing whitespace from a string.

```

trim('<text>')

```

**Example**
```

trim(' Hello World ') // Returns Hello World

```

### union
Return a collection that has all the items from the specified collections.

```

union('<collection1>', '<collection2>', ...)
union([<collection1>], [<collection2>], ...)

```

**Example**
```

union(createArray(1, 2, 3), createArray(1, 4)) // Returns [1, 2, 3, 4]

```

### unique
Remove all duplicates from an array.

```

unique([<collection>])

```

| Parameter | Required | Type | Description |
| :--- | :--- | :--- | :--- |
| `<collection>` | Yes | array | The collection to modify |

**Return value**
| Type | Description |
| :--- | :--- |
| array | New collection with duplicate elements removed |

**Example**
```

unique(createArray(1, 2, 1)) // Returns [1, 2]

```

### uriComponent
Return the binary version of a uniform resource identifier (URI) component.

```

uriComponent('<value>')

```

### uriComponentToString
Return the string version of a URI-encoded string.

```

uriComponentToString('<value>')

```

### uriHost
Return the host value of a URI.

```

uriHost('<uri>')

```

### uriPath
Return the path value of a URI.

```

uriPath('<uri>')

```

### uriPathAndQuery
Return the path and query value of a URI.

```

uriPathAndQuery('<uri>')

```

### uriPort
Return the port value of a URI.

```

uriPort('<uri>')

```

### uriQuery
Return the query value of a URI.

```

uriQuery('<uri>')

```

### uriScheme
Return the scheme value of a URI.

```

uriScheme('<uri>')

```

### utcNow
Return the current timestamp.

```

utcNow('<format>', '<locale>'?)

```

### where
Filter on each element and return the new collection of filtered elements which match a specific condition.

```

where([<collection/instance>], <iteratorName>, <function>)

```

**Example**
```

where(createArray(0, 1, 2, 3), x, x > 1) // Returns [2, 3]

```

### xml
Return the XML version of a string that contains a JSON object.

```

xml('<value>')

```

### xPath
Check XML for nodes or values that match an XPath expression.

```

xPath('<xml>', '<xpath>')

```

### year
Return the year of the specified timestamp.

```

year('<timestamp>')

```

**Example**
```

year('2018-03-15T00:00:00.000Z') // Returns 2018

```

```
