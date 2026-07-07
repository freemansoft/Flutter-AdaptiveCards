---
doc_type: how-to
---

# Templating: writing tests

How to build the `flutter_adaptive_template_fs` test fixtures and validate template/data
expansion. For the templating language itself (`$data`, `$when`, expressions, custom functions),
see [`adaptive-template-design.md`](adaptive-template-design.md).

Each of the features and capabilities in the language reference must have unit tests to validate and prevent regression. The unit tests should use JSON template and JSON data files that live in the testing directory `packages/flutter_adaptive_template_fs/test`. We want the unit test JSON to be in JSON files and not embedded in the tests themselves for future usage and analysis.

Testing template and data JSON can be found in the adaptive card templating service [on GitHub](https://github.com/microsoft/adaptivecards-templates/tree/master/templates). The project can copy over. The team should prioritize templates and data in separate files but can also pull in JSON that has a `$data` section and then the template to be filled with the `$data`. Some of the examples have a `$SampleData` section in the template that can be used to validate the template. For testing, if we find that in a copied example then the `$SampleData` can be removed from the JSON and then be passed as the data JSON along with the modified template when executing the test.

1. Copy sample JSON from <https://github.com/microsoft/adaptivecards-templates/tree/master/templates> to use in the test. The examples in the language reference should also be made into tests with the JSON being put in JSON files and read by the tests.
2. Create a unit test that loads the sample template/data JSON pair and merges them. The developer should create an expected output JSON file and verify the merged template/data against the expected output.
