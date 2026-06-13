# Optional Packages and Extensions

**Status**: ✅ Current | **Category**: Architecture

This document explains why the monorepo splits Adaptive Cards capabilities across multiple packages, and how host applications should opt in to features that pull in third-party dependencies.

## Design goal

**`flutter_adaptive_cards_fs` stays lean.** Host apps that only render standard card JSON should not transitively depend on charting libraries, templating engines, or other heavy optional stacks unless they explicitly add those packages.

This is the same strategy used today for:

| Package | Purpose | Third-party deps avoided in core |
| ------- | ------- | -------------------------------- |
| [`flutter_adaptive_cards_fs`](../packages/flutter_adaptive_cards_fs/) | Core renderer (elements, inputs, actions, HostConfig) | — (baseline) |
| [`flutter_adaptive_template_fs`](../packages/flutter_adaptive_template_fs/) | Adaptive Cards templating (`$data`, `$when`, `json()`, etc.) | Templating evaluator not required for static cards |
| [`flutter_adaptive_charts_fs`](../packages/flutter_adaptive_charts_fs/) | `Chart.*` elements (bar, line, pie, donut, gauge) — bar/line/pie via [fl_chart](https://pub.dev/packages/fl_chart); gauge via `CustomPainter` in the same package | **fl_chart** not pulled into apps that never render charts |
| [`flutter_adaptive_cards_host_fs`](../packages/flutter_adaptive_cards_host_fs/) | Backend invoke bridge — serialize Submit/Execute/Refresh/`onChange`, POST, parse patches or full card replacement, wire `InheritedAdaptiveCardHandlers` | **`http`** and invoke glue not required for static or hand-wired hosts |

Future optional packages should follow the same pattern (see the completed [June 2026 implementation plan](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md) for refresh, Icon, chart chrome/gauge, and RichTextBlock work).

## Why charts are not in the core package

Charts are **Teams / documentation-hub extensions**, not part of the legacy [schema explorer](https://adaptivecards.io/explorer/) body-element list. They also depend on **fl_chart**, which:

- Adds rendering and layout code unrelated to most card hosts
- Has its own release cycle and platform constraints
- Is unnecessary for apps that never author or consume `Chart.*` JSON

Keeping charts in `flutter_adaptive_charts_fs` lets chart-free apps depend only on `flutter_adaptive_cards_fs` while chart-enabled apps add one explicit dependency and register chart types at startup.

Registered chart type strings (merge via `CardChartsRegistry.additionalChartElements`):

| Type string | Renderer |
| ----------- | -------- |
| `Chart.Line` | fl_chart line chart |
| `Chart.VerticalBar` | fl_chart vertical bar |
| `Chart.HorizontalBar` | fl_chart horizontal bar |
| `Chart.VerticalBar.Grouped` | fl_chart grouped/stacked vertical bars |
| `Chart.HorizontalBar.Stacked` | fl_chart stacked horizontal bars |
| `Chart.Pie` | fl_chart pie |
| `Chart.Donut` | fl_chart donut |
| `Chart.Gauge` | `CustomPainter` semicircular gauge (same package; not fl_chart) |

## Why templating is a separate package

[`flutter_adaptive_template_fs`](../packages/flutter_adaptive_template_fs/) implements the [Adaptive Cards templating language](https://learn.microsoft.com/en-us/adaptive-cards/templating/language). Many hosts receive **already-expanded** card JSON from a backend and never run templating on device. Splitting the evaluator:

- Avoids shipping templating logic to clients that do not need it
- Keeps the core renderer focused on widget construction and interaction
- Allows independent versioning and testing of template features

There is **no required dependency** from core → template or template → core at runtime; hosts compose them when needed.

## Why backend invoke is a separate package

[`flutter_adaptive_cards_host_fs`](../packages/flutter_adaptive_cards_host_fs/) implements the **serialize → POST → parse → apply** pipeline for bot-style card hosts. Many apps only render cards and wire **`InheritedAdaptiveCardHandlers`** manually; they should not pull in **`http`** or response-parsing logic.

The host package depends on **`flutter_adaptive_cards_fs`** (not the reverse) and provides:

| Component | Role |
| --------- | ---- |
| **`AdaptiveCardInvokeRequest`** / **`AdaptiveCardInvokeResponse`** | Typed invoke + effect models |
| **`PlainJsonInvokeAdapter`** / **`TeamsInvokeAdapter`** | Request/response JSON shapes |
| **`AdaptiveCardBackendClient`** / **`HttpAdaptiveCardBackendClient`** | Transport abstraction |
| **`AdaptiveCardBackendHandlers`** | Wraps a card subtree; connects `onSubmit`, `onExecute`, `onRefresh`, and `onChange` to the backend |

Response effects map to core document APIs: **`applyPatches`** (element overlays), **`setInputErrors`**, and **`replaceCard`** (full JSON swap via host callback). See [backend-host-integration.md](./backend-host-integration.md).

**Core prerequisite:** Teams-correct invoke payloads (`associatedInputs` on `Data.Query`, `Action.Submit`, and `Action.Execute`) ship in **`flutter_adaptive_cards_fs`** (Phase 1 of the same plan).

## Extension model (all optional features)

Optional capabilities integrate through the same **registry merge** pattern:

```dart
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_charts_fs/flutter_adaptive_charts_fs.dart';

AdaptiveCardsCanvas.map(
  content: cardJson,
  hostConfigs: hostConfigs,
  cardTypeRegistry: CardTypeRegistry(
    addedElements: {
      ...CardChartsRegistry.additionalChartElements,
      // ...other extension registries
    },
  ),
);
```

### Rules for new optional packages

1. **Depend on core, not the other way around** — `flutter_adaptive_cards_fs` must not depend on extension packages.
2. **Export a registry map** — e.g. `CardChartsRegistry.additionalChartElements`, not silent auto-registration inside core.
3. **Document opt-in** — README and [Implementation-Status.md](./Implementation-Status.md) must state that the feature is optional and list the extra `pubspec` dependency.
4. **Widgetbook / explorer** — **sample apps** may depend on all packages; production hosts choose subsets. [widgetbook](../widgetbook/) (demonstration gallery) merges chart registries for chart samples; [adaptive_explorer](../adaptive_explorer/README.md) does **not** render `Chart.*` types unless the host wires `CardChartsRegistry.additionalChartElements`. See [`documentation-scope.md`](documentation-scope.md).
5. **Split again only when necessary** — if a future extension needs a fundamentally different dependency tree than its siblings, consider a separate package rather than bloating an existing optional package. **`Chart.Gauge` stays in `flutter_adaptive_charts_fs`** (CustomPainter alongside fl_chart charts).

### Built-in vs optional elements

| Category | Location | Registration |
| -------- | -------- | ------------ |
| Standard schema elements (`TextBlock`, `Input.Text`, …) | Core `CardTypeRegistry` switch | Automatic |
| Hub / Teams extensions shipped with this repo (`Badge`, `Carousel`, `Icon`, …) | Core registry (no extra pubspec) | Automatic |
| Heavy or niche extensions (`Chart.*` including gauge) | Optional charts package | Host merges `CardChartsRegistry.additionalChartElements` |
| Backend invoke round-trips | Optional host package | Host wraps card with `AdaptiveCardBackendHandlers` |
| Host-specific widgets | Host app | Host merges `addedElements` |

## Consumer checklist

**Charts only**

```yaml
dependencies:
  flutter_adaptive_cards_fs: ^0.10.0
  flutter_adaptive_charts_fs: ^0.10.0
```

Merge `CardChartsRegistry.additionalChartElements` into `CardTypeRegistry.addedElements`.

**Templating only**

```yaml
dependencies:
  flutter_adaptive_cards_fs: ^0.10.0
  flutter_adaptive_template_fs: ^0.10.0
```

Expand template + data JSON with `Evaluator` before passing the result to `AdaptiveCardsCanvas`.

**Charts + templating**

Add both packages; expand template first, then render with merged chart registry.

**Backend invoke (flow-service / Teams-shaped API)**

```yaml
dependencies:
  flutter_adaptive_cards_fs: ^0.10.0
  flutter_adaptive_cards_host_fs: ^0.10.0
```

Wrap `RawAdaptiveCard` with `AdaptiveCardBackendHandlers` and a shared `GlobalKey<RawAdaptiveCardState>`. Provide `onCardReplaced` when the server may return full card JSON. See [package README](../packages/flutter_adaptive_cards_host_fs/README.md).

**Core only**

```yaml
dependencies:
  flutter_adaptive_cards_fs: ^0.10.0
```

Do not import chart, template, or host packages. Cards containing unknown `Chart.*` types render via element `fallback` or `AdaptiveUnknown`. Wire action callbacks manually via **`InheritedAdaptiveCardHandlers`** when not using the host package.

## Related documentation

- [Architecture-Overview.md](./Architecture-Overview.md) — package structure and extension points
- [Implementation-Status.md](./Implementation-Status.md) — spec coverage matrix
- [2026-06-08-refresh-icon-charts-text-features.plan.md](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md) — completed refresh, Icon, chart, and text workstreams
- [adaptive-template-design.md](./adaptive-template-design.md) — templating package design
- [backend-host-integration.md](./backend-host-integration.md) — invoke round-trips, response contract, error handling
- [2026-06-07-backend-host-integration-design.md](./superpowers/specs/2026-06-07-backend-host-integration-design.md) — design history (superseded for day-to-day use by guide above)
- [flutter_adaptive_cards_host_fs README](../packages/flutter_adaptive_cards_host_fs/README.md) — `AdaptiveCardBackendHandlers` quick start
- [flutter_adaptive_cards_fs README](../packages/flutter_adaptive_cards_fs/README.md) — core library usage
- [flutter_adaptive_charts_fs README](../packages/flutter_adaptive_charts_fs/README.md) — chart types and HostConfig color/layout
- [flutter_adaptive_template_fs README](../packages/flutter_adaptive_template_fs/README.md) — templating `Evaluator` API

---

_Last updated: 2026-06-09_
