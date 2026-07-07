---
doc_type: how-to
---

# HostConfig serialization testing

How to write and run the serialization tests for HostConfig entities, plus the verification
checklist for a theme-fallback change. For what HostConfig is, the resolution pipeline, and the
theme-derived color fallback design, see [`hostconfig.md`](hostconfig.md).

## Serialization test requirements

Verify JSON deserialization for every HostConfig entity and that objects conform to `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config_schema.json`.

### Scope

- **Source classes**: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/` (excluding `host_config.dart` aggregator-only tests where entity tests suffice)
- **Test directory**: `packages/flutter_adaptive_cards_fs/test/hostconfig/`

### Conventions

One test file per entity, mirroring the Dart file name:

| Entity                         | Test file                           | JSON fixture                   |
| ------------------------------ | ----------------------------------- | ------------------------------ |
| `font_color_config.dart`       | `font_color_config_test.dart`       | `font_color_config.json`       |
| `container_styles_config.dart` | `container_styles_config_test.dart` | `container_styles_config.json` |
| …                              | `{entity}_test.dart`                | `{entity}.json`                |

Each entity test should:

1. Load the associated JSON file from disk (not an inline map/string in the test body)
2. Deserialize into the HostConfig type via `fromJson`
3. Assert individual properties in the same test

Additional checks:

- JSON fixtures produce valid HostConfig objects
- Property values match the fixture
- Empty `{}` fixtures resolve to **theme-derived** color defaults (see `ThemeColorFallbacks` tests in `fallback_configs_test.dart`)

### Running tests

From `packages/flutter_adaptive_cards_fs`:

```bash
fvm flutter test test/hostconfig/
fvm flutter test --exclude-tags=golden
```

## Verification checklist (theme fallback change)

- [ ] Empty `HostConfigs()` card background matches `Theme.of(context).colorScheme.surface` in light and dark
- [ ] Explicit HostConfig JSON colors override theme fallbacks
- [ ] `HostConfig.fromJson(..., theme: ThemeData.dark())` empty container styles use dark scheme defaults
- [ ] `ReferenceResolver` tests pass `colorFallbacks: ThemeColorFallbacks(ThemeData.light())` (or appropriate theme)
- [ ] Progress/badge/chart/separator resolution uses resolver fallbacks, not removed static color fields
