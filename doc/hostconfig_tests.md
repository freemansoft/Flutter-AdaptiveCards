# Create a hostconfig serialization test for every hostconfig

Create a plan to verify json deserialization works for host configs and verify the host config objects json matches the json schema in packages/flutter_adapative_cards/lib/src/hostconfig/host_config_schema.json

The host config files are json serializable dart file in pacakages/flutter_adaptive_cards_plus/lib/src/hostconfig ignoring the file host_config.dart. There should be on etest for each class tested. The tests for each hostconfig entity type shoiuld be in a test file with the same name. Ex: The tests for `font_color_config.dart` should be in `font_color_config_test.dart` The new test should use an actual JSON file and not a json string or map inside the test itself. Each hostconfig entity and test should have its own associated json file. `font_color_config.dart` has a test file `font_color_config.json`

- The single test should load the json and convert it into the associated hostConfig entity. Properties should be validated in the single test.

- Files under test are located in packages/flutter_adaptive_cards_plus/lib/src/hostconfig
  Test files are located in packages/flutter_adaptive_cards_plus/test/hostconfig

- verify the json can create host config objects
- verify the individual properties are correct
