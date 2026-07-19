# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.15.0]

### Added 0.15.0

- `Table` accessibility: header-row cells are now exposed to assistive technology
  as headers (`Semantics(header: true)`), and body cells are announced with their
  column header ("Status Delayed" rather than a context-free "Delayed"). Flutter's
  `Table` provides no row/column association, so cells previously carried no
  semantics at all. Cells are annotated, not merged, so a cell's `selectAction` or
  nested `Input.*` stays independently focusable. Columns whose header cell has no
  text (image-only) are left unlabeled rather than given a placeholder name.
- test: add golden verifying HostConfig container-style `backgroundColor` and ColumnSet `stretch`/`auto` alignment render as expected.
- feat: `Container` supports the Microsoft Teams [`roundedCorners`](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format) property (rounds the style fill + clips children), opt-in via `"roundedCorners": true`. The radius is resolved via a new HostConfig `cornerRadius` field (default 8, `HostConfig.fromJson` / `ReferenceResolver.resolveCornerRadius()`) rather than fixed. `ColumnSet`/`Column`/`Table`/`Image` are not wired yet.

### Fixed 0.15.0

- **`Media` `poster` is now visible until the user starts playback.** The poster was only rendered while the player was initializing, so it vanished a moment after the card appeared and authors effectively never saw it. The poster is now the click-to-play surface described by the spec: it shows a play button, and the `VideoPlayerController` is created only when the user taps it (no network player is opened for every `Media` element on card load). A poster-less `Media` still renders the play affordance so the video remains playable.

## [0.14.0]

### Added 0.14.0

- Add root `authentication` sign-in button support: parse the `authentication`
  object, render a sign-in region, and forward a `SigninActionInvoke` to the new
  nullable `onSignin` handler (falls back to `onOpenUrl` for URL values). SSO
  `tokenExchangeResource` is parsed but not exchanged.
- **`Table` `auto`/`stretch` column widths + cell `minHeight`** — the `Table` element now renders through Flutter's `Table` widget, so column `width` values `auto` (content-sized, consistent across rows) and `stretch` (fills remaining space) work alongside the existing numeric weights and `Npx` pixel widths. Cell `minHeight` is now applied. Equal row height and per-cell background fill are preserved via `TableCellVerticalAlignment.intrinsicHeight`; grid lines now use `TableBorder`. All existing cell behaviors (background color/image, header styling, `selectAction`, alignment, responsive `layouts`) are unchanged. Remaining `Table` gaps: `bleed` and cell-level `rtl`.
- **Behavioral tests for custom/extended elements** previously marked "Limited" (visibility-only coverage). New dedicated test files exercise element behavior: `Accordion` (per-section expand/collapse), `ProgressBar` and `ProgressRing` (determinate/indeterminate + `value` clamping; ring `label`/`labelPosition`), `TabSet` (tab rendering + tap-to-switch), `CarouselPage` (`items` + `showBorder`), and the read-only `Rating` display (filled/empty star rendering + defaults). README Tests column upgraded to ✅ for these rows.
- **Coverage tests for low-coverage classes** — Lifts `flutter_adaptive_cards_fs` line coverage from ~88.9% to ~90.1%; CI coverage floor raised 88 → 90.
- **Accessibility semantics for interactive elements.** `selectAction` targets are now exposed as buttons with an accessible name (the action `title`/`tooltip`); the `Rating` display and `Input.Rating` announce their value (`"x of y stars"`), with the interactive input adjustable via increase/decrease; and carousel page dots carry `"Go to slide N"` labels with selected state. Covered by `test/accessibility_semantics_test.dart`.
- **Input label → control association for `Input.Toggle`, `Input.Rating`, and `Input.ChoiceSet`.** The `Input.Toggle` switch, the `Input.Rating` star control, and the compact/filtered `Input.ChoiceSet` field now announce their input `label` (previously only a detached visual `Text`); expanded `Input.ChoiceSet` exposes the `label` as a group name while keeping each option individually focusable. Covered by `test/input_label_semantics_test.dart`.
- **Input label → control association for `Input.Text`, `Input.Number`, `Input.Date`, and `Input.Time`; spoken required state; and live-region validation errors.** These fields rendered their `label` only as a detached sibling `Text` (and `Input.Time` dropped the `label` entirely), so a screen reader announced no name when the control was focused. The field is now wrapped with `labelInputSemantics` (a layout-neutral `MergeSemantics` + `Semantics(label:)`) and the visible label is excluded from semantics, so focusing the control announces its name. Required fields — previously flagged only by a visual `*` — now append `", required"` to the spoken name, and `loadErrorMessage` marks the error text as a `liveRegion` so validation failures are announced when they appear. New helpers `inputSemanticsLabel` / `labelInputSemantics` in `utils.dart`. Covered by `test/input_label_semantics_test.dart` and `test/input_error_and_progress_a11y_test.dart`.
- **`ProgressBar` and `ProgressRing` value semantics.** Both indicators now expose their completion percentage (and, for the ring, its author `label`) to screen readers via the Flutter indicators' built-in `semanticsLabel` / `semanticsValue`; an indeterminate `ProgressBar` still carries a `"Progress"` label. Covered by `test/input_error_and_progress_a11y_test.dart`.
- **TextBlock heading level, FactSet fact grouping, and icon token de-duplication.** Heading-styled `TextBlock`s now emit `Semantics(headingLevel:)` sourced from HostConfig `textBlock.headingLevel` (default 2, clamped 1–6), so assistive tech can navigate by heading. `FactSet` now announces each fact as a single unit — the title node carries the combined `"title: value"` label and the value column is excluded from semantics — instead of reading the title and value as disconnected items (visual layout unchanged). An `Icon` carrying a `selectAction` with a `title`/`tooltip` no longer double-announces its Fluent token, since the `selectAction` button already provides the accessible name. Covered by `test/textblock_heading_and_factset_semantics_test.dart`.

### Changed 0.14.0

- **`Table` `firstRowAsHeader` now actually styles header text.** Header styling previously relied on an ambient `DefaultTextStyle`, which `AdaptiveTextBlock` overrides with its own explicit `TextStyle` — so header rows were never bolder than body rows. Header cells now bake the HostConfig `columnHeader` text style (weight/size/color/fontType/isSubtle) into each `TextBlock`'s appearance, with the element's own properties still winning when set.
- **README implementation status** — corrected the `Rating` row, which incorrectly claimed the read-only display element (`AdaptiveRating`) was "also registered as `Input.Rating`". `Rating` and `Input.Rating` are distinct widgets; added a separate `Input.Rating` row documenting the interactive star-picker input (`AdaptiveRatingInput`: `max`/`color`/`size`/`allowHalfSteps`, value submission, `isRequired`). Also corrected the Icon **Known gaps** row, which still listed "~68 icons" — `kFluentIconMap` now has ~200 entries (matching the Icon element row), so the gap impact drops to Low.
- **Internal cleanup (no behavior change)** — applied `dart format` across the package (fixing formatting drift in 34 files); guarded the per-cell `developer.log` in `AdaptiveTable.buildCellContent` with `assert(() { … }())` so it no longer runs in release builds; and inlined the no-op `getHeaderCellDecoration` wrapper in `table.dart`. Also added braces to a single-statement `if` in `area_grid_model.dart` surfaced by re-formatting (`curly_braces_in_flow_control_structures`).
- **Widget-key generation centralized.** Table key helpers (`AdaptiveTable.cellKey`/`columnKey`/`rowKey`/`tableColumnKey`) now delegate to shared `generateTable*Key` functions in `utils.dart`, and `ChoiceFilter` / the filtered-choice modal build their keys via `generateWidgetKeyFromId` instead of inline `ValueKey(...)`. Key values are unchanged; the format now has a single source that tests import. See [`docs/AdaptiveWidget-Key-Generation.md`](../../docs/AdaptiveWidget-Key-Generation.md).
- **README doc links** — the `ColumnSet` / `Column` implementation-status rows now point to the historical `Column-ColumnSet-Fill-Vertical-Height.md`, which moved to [`docs/archive/specs/`](../../docs/archive/specs/) as part of a documentation cleanup (the fixed-bug note is history, not current integration guidance). Feature behavior is unchanged.
- **README doc link** — the root `refresh` implementation-status row now points to [`docs/action-payloads-reference.md`](../../docs/action-payloads-reference.md#root-card-refresh-payload); the action invoke-payload sections were split out of `actions-architecture.md` into that dedicated reference (Diátaxis doc cleanup). Feature behavior is unchanged.

### Fixed 0.14.0

- **`selectAction` wrapper (`AdaptiveTappable`) now uses a deterministic widget key.** It previously minted a fresh UUID on every build, so the key changed each frame — the wrapper (and its wrapped Image/Icon/Container subtree) could not be reused by Flutter across rebuilds and could not be located in tests. The key is now `{id}_selectAction`, seeded from the wrapped element's id (`loadId`), with a stable positional seed for table cells (which have no injected id). New regression tests in `test/select_action_tappable_key_test.dart` pin the format and element reuse.
- **Interactive `Input.Rating` no longer asserts when semantics are enabled.** The adjustable rating declared `increase`/`decrease` actions without the `increasedValue`/`decreasedValue` that Flutter requires alongside a semantic `value`, which threw during the semantics build (e.g. with a screen reader or the Widgetbook Semantics addon). The rating now supplies all three.
- **Decorative images are no longer announced as "alt text not set".** Images without an `altText` (including container/cell background images) were labeled with a placeholder string, polluting screen-reader output. A null label now passes through so Flutter excludes the decorative image from the semantics tree; images with `altText` are unchanged.

## [0.13.0]

### Added 0.13.0

- **`Action.Http` (deprecated/legacy)** — the original Adaptive Cards HTTP action model (schema v1.0), superseded by `Action.Execute` (Universal Action Model, schema v1.4) and still used by Outlook Actionable Messages. Author-driven `GET`/`POST` action. `DefaultHttpAction` validates inputs, resolves `{{inputId.value}}` substitution (new `substituteInputValues` util) in `url`/`body`/header values, gates the resolved URL through the active URI policy, debug-flags card-controlled `Authorization`/`Cookie` headers, then forwards a new `HttpActionInvoke` (resolved request + raw `inputValues` + `actionId`) to the new **nullable** `InheritedAdaptiveCardHandlers.onHttp`. The core never performs the request; pair with `flutter_adaptive_cards_host_fs` for transport. Registered in `DefaultActionTypeRegistry` and the widget registry as `AdaptiveActionHttp`. See `docs/actions-architecture.md`.
- **Non-standard HostConfig `inputs.choiceSet` section** lets hosts tune the compact single-select `Input.ChoiceSet` dropdown (`DropdownMenu`) without touching element JSON: `enableSearch` (`bool`, default `true`) toggles type-ahead jump-to-match, and `requestFocusOnTap` (`bool?`, default `null`) overrides the platform-aware focus-on-tap default (`null` keeps it focusable on desktop, tap-only on mobile). Both default to the dropdown's prior hardcoded behavior, so omitting the section is a no-op. Replaces the two `TODO(hostconfig)` placeholders in `choice_set.dart`. See `docs/hostconfig.md`.
- **Icon catalog expanded** — `kFluentIconMap` grew from 69 to ~200 Fluent-name → Material-icon mappings (filled/regular where available) plus common aliases (`trash`/`bin`, `gear`, `pencil`, `email`/`envelope`, `user`/`contact`, `play`, `cart`, `dashboard`, `trophy`, `car`, `wifi`, …). Unknown names still fall back to `help_outline`. Material approximation remains intentionally partial; the full Fluent font is a deferred option.
- **`Layout.AreaGrid` + `grid.area`** — named-area responsive grids on `Container`, `Column`, `TableCell`, and the card root via a custom `RenderAdaptiveAreaGrid` (no new dependency): `%`/`px`/implied (equal-share) columns, `columnSpan`/`rowSpan`, `columnSpacing`/`rowSpacing`, and multiple `targetWidth`-selected grids (reusing `selectLayout` + `cardWidthBucketProvider`, so grids switch on resize). Elements place via `grid.area`; unplaced or unknown-area elements render below the grid (logged) rather than being dropped. `height: "stretch"` children fill their cell's row band. See [`Layout.AreaGrid` design](../../docs/superpowers/specs/2026-06-28-layout-areagrid-design.md).
- **Block `height: "stretch"`** is now honored on `Container`, `Column`, and the card root body in height-bounded contexts (e.g. `ColumnSet` columns and `Table` rows, which give children a bounded row band via `IntrinsicHeight`); it degrades to `auto` when the parent is unbounded (the common content-sized card body), so cards that don't set `height` are unchanged. Implemented via a shared `isStretchHeight` predicate and `buildStretchableColumn`, which uses a custom intrinsics-aware `RenderStretchColumn` (rather than a `LayoutBuilder`) so stretch works inside `IntrinsicHeight`. Charts and in-cell `TableCell` content stretch are deferred. See [block `height: stretch` design](../../docs/superpowers/specs/2026-06-28-block-height-stretch-design.md).
- **`Layout.Flow` finished** — `layouts`/`Layout.Flow` now applies to **`Column`** and **`TableCell`** (in addition to `Container` and the card root body), via a shared `buildLayoutChildren` helper. Adds `itemWidth` (fixed px) and `itemFit` parsing — `itemFit: "Fit"` is honored; **`itemFit: "Fill"` is not yet supported** and falls back to `Fit` with a one-time log. `itemWidth` items use a fixed `SizedBox` (skipping `IntrinsicWidth`), which also safely sizes flow items that can't report an intrinsic width; content-fit items keep `IntrinsicWidth` so they shrink to content instead of filling the row. `selectLayout` now prefers the most-specific (narrowest-range) relational `targetWidth` match, and an unbounded card width logs and defaults to the `wide` bucket. **`ColumnSet` is intentionally excluded — it has no `layouts` property in the Adaptive Cards spec.** See [finish-Layout.Flow design](../../docs/superpowers/specs/2026-06-27-finish-layout-flow-design.md).

### Changed 0.13.0

- **Single-select compact `Input.ChoiceSet` now uses Material 3 `DropdownMenu`:** replaced the legacy `DropdownButton` so the field supports type-ahead keyboard navigation (typing a character jumps to the matching choice, Enter selects it), restoring parity with the web renderer's native `<select>`. Type-ahead is **platform-aware**: enabled on desktop platforms (macOS/Linux/Windows) where a physical keyboard is present, and the field is tap-only on mobile (iOS/Android/Fuchsia) so it does not pop the soft keyboard for a simple dropdown. Uses `enableSearch` (highlight/jump, full list stays visible) rather than `enableFilter` (narrow the list); both this and the focus policy are flagged as future HostConfig options. Display text is driven by the input controller and kept in sync with the resolved selection; selection still stores choice values. Multi-select compact and expanded styles are unchanged. Golden `sample2` images were regenerated for the new dropdown rendering.
- **Docs:** the core component **Implementation status** tables (Card Elements, Containers, Root `AdaptiveCard` properties, Inputs, Actions, HostConfig, Common properties, Custom/Extended elements), the status **legend**, and the core **`### Known gaps`** table moved from `docs/Implementation-Status.md` into this README so they publish to pub.dev. The central matrix is now an index of pointers + project roadmap/history; future component-status and known-gaps edits go in this README (the doc-sync gate and `code-review` skill were updated accordingly).
- **Docs:** element/action/model class doc comments now link to the current canonical Microsoft schema reference (`learn.microsoft.com/en-us/adaptive-cards/schema-explorer/<element>`) alongside the legacy `adaptivecards.io/explorer` link. Hub/Teams extension types (Carousel, Badge, ProgressBar, `Action.Popover`, etc.) keep only the legacy link since they have no schema-explorer page. Also fixed a `httfps://` typo in `Input.Text`'s doc comment.
- **Docs:** README now has an **Implementation status** section linking (via absolute GitHub URLs, so they resolve on pub.dev) to the central [`docs/Implementation-Status.md`](../../docs/Implementation-Status.md) matrix plus the per-package chart and templating status sections. The Charts and Templating detail tables moved out of the central matrix into their own packages' READMEs.

### Fixed 0.13.0

- **`backgroundImage` on an item-less `Container`/`Column` now fills the element again:** since the HostConfig style pipeline added `horizontalAlignment` inheritance (#13), a background-image-only column under an inherited `horizontalAlignment` (e.g. a `ColumnSet` with `"horizontalAlignment": "Center"`, as in the image-carousel sample) had its image shrunk and centered by the Container's content `alignment` instead of filling the cell. The image is now wrapped to fill the width (height from `minHeight` / the stretched row band). It stays a foreground widget rather than a `DecorationImage` so **SVG** background images keep rendering. Regression test: `background_image_fill_test.dart`.
- **Dependent `Input.ChoiceSet` (`Data.Query`) no longer drops the selected value:** the dependent-choice-set sample handler re-applied the resolved city choices on the city `onChange`. Because `applyUpdates` treats "new `choices` without a `value`" as a stale-value reset, the value the user just selected was cleared on the next frame. The handler now passes `value: invoke.value` when repopulating choices so the selection persists; a regression test (`dependent_choice_set_test.dart`) now asserts the submitted city value survives the Data.Query re-apply.

### Tests 0.13.0

- Added unit and widget tests to raise line coverage toward the new CI coverage gate: `Action.InsertImage`, `ReferenceResolver` style/color/font resolution, `AdaptiveCardDocumentNotifier` patch-map and clear/session paths, and `RawAdaptiveCard` host-facade methods (`setText`, `setFacts`, `setActionEnabled`, `loadInput`, `changeValue`, `showError`, …).
- Filled the previously-`TODO`'d `Action.ResetInputs` gaps for `Input.Date` and `Input.Time`: `action_reset_inputs_test.dart` now verifies a changed Date and Time each revert to their original card-JSON value after a global reset.
- Resolved the long-standing `TODO`s in `basic_test.dart`: the `TextBlock`/`FactSet`-value `find.text` assertions now pass using `findRichText: true` (those render as `MarkdownBody`/`RichText`, not plain `Text`), and the `Input.Date` show-card flow now sets a value and asserts it reaches the host `onSubmit` payload.
- **Golden baselines refreshed (macOS)** — icon-bearing goldens (`v1_5_icon_demo`, `v1_6_icon_catalog`, `v1_6_accordion`, `v1_6_rating`, `sample1*`, `sample2*`, `sample5*`) now render real Material/Fluent icon glyphs instead of empty tofu boxes, thanks to `flutter_adaptive_cards_test_support` loading the bundled **MaterialIcons** font in golden tests. Linux CI baselines refresh on the next build.

## [0.12.0]

### Security 0.12.0

- **`AdaptiveUriPolicy` / `AdaptiveFetchPolicy` for card-controlled URLs:** new `lib/src/security/` layer validates untrusted URLs (scheme allowlist, loopback/private-host blocking, optional host allowlist) and bounds card-initiated fetches (byte cap + timeout). Exposed via `InheritedAdaptiveCardSecurityPolicy` and optional `RawAdaptiveCard` / `AdaptiveCardsCanvas.network` parameters; defaults to a production-safe policy.
- **`Action.OpenUrl` and markdown links are validated before launch:** `DefaultOpenUrlAction.tap` rejects disallowed schemes/hosts (e.g. `javascript:`, private IPs) before forwarding to the host handler or `url_launcher`; markdown `TextBlock` links route through the same gate.
- **SSRF guards on remote fetches:** `Action.OpenUrlDialog` content fetch and `NetworkAdaptiveCardContentProvider` now validate the URL and cap the response body before requesting.
- **Optional image/media URL gating:** `AdaptiveImageUtils.getImage`/`getImageProvider` accept a policy (denied URLs render a placeholder), and `AdaptiveMedia` validates its source before creating the network player.

### Fixed 0.12.0

- **`Input.Text` no longer caps input at 20 characters when `maxLength` is omitted:** the length limit is applied only when `maxLength` is present and greater than 0 (Adaptive Cards spec: absent `maxLength` means no limit).
- **`Input.Text` / `Input.Number` fast-typing no longer drops characters or resets cursor:** `AdaptiveInputMixin.listenForResolvedValueChanges` previously captured the resolved value at listener-fire time and echoed it back via a post-frame callback. When two keystrokes arrived in the same frame, the stale captured value overwrote the controller and reset the IME cursor (selection to offset -1), desynchronising the IME and dropping characters. The post-frame callback now reads the latest resolved value at execution time (`readResolvedInput().valueRaw`), making the echo a no-op when the controller already reflects the current document state.
- **`Media` poster placeholder no longer throws `LateInitializationError`:** `AdaptiveMediaState.altText` is now initialized from the card's `altText` (defaulting to empty) in `initState`, so the poster placeholder shown while the video loads (or when its source is policy-blocked) renders instead of crashing. `altText` is not overlayable, so it is read from the baseline map like `Image`.
- **`CodeBlock` reads spec `codeSnippet` property:** `AdaptiveCodeBlockState.initState` now reads `adaptiveMap['codeSnippet']` first (spec-correct property) and falls back to `adaptiveMap['code']` for backward compatibility. Previously any spec-compliant CodeBlock rendered empty.

### Changed 0.12.0

- **`CompoundButton` now honors `selectAction`:** tapping the button resolves and dispatches its `selectAction` (e.g. `Action.OpenUrl`, `Action.Submit`) via the action registry. When no `selectAction` is present the button renders disabled instead of being a no-op. Also removed a stale markdown TODO in `TextBlock` (markdown is already implemented via `flutter_markdown_plus`; no behavior change).
- **`Input.Number`, `Input.Date`, and `Input.Time` now validate `min`/`max` bounds on Submit/Execute:** out-of-range values block the action and mark the input invalid instead of submitting silently.
- **Action `mode: secondary` + overflow:** secondary-mode actions, and any actions beyond HostConfig `maxActions`, now collapse into a reveal-on-demand "•••" overflow toggle instead of being silently dropped (applies to both `ActionSet` and card-level actions).
- **Action `iconPlacement`:** action buttons now honor `actions.iconPlacement`; the default `aboveTitle` stacks the icon over the label (previously always icon-left).

### Added 0.12.0

- **`revealPasswordEnabled` per-element overlay:** `ElementOverlay` gains a `revealPasswordEnabled` field; `AdaptiveCardDocumentNotifier` exposes `setRevealPasswordEnabled` / `clearRevealPasswordEnabled`; `resolvedElementProvider` merges the override into the resolved map; `ResolvedInputState.revealPasswordEnabledOverride` reads it; and `RawAdaptiveCardState` exposes matching facade methods. The field is preserved across `Action.ResetInputs` (like `isVisible`), not cleared.
- **Responsive layout (`targetWidth` + `Layout.Flow`):** elements gate visibility by card width via `targetWidth` (named buckets `veryNarrow`/`narrow`/`standard`/`wide` plus `atLeast:`/`atMost:`), and `Container` + the card root body honor a `layouts` array, reflowing from a vertical stack to a wrapping `Layout.Flow` (with `columnSpacing`/`rowSpacing`, item alignment, and optional `minItemWidth`/`maxItemWidth`). Width buckets come from a new HostConfig `hostWidthBreakpoints` section (spec defaults when absent) and are published to the element subtree via the scoped Riverpod `cardWidthBucketProvider` (a thin nested `ProviderScope` inside the root `LayoutBuilder` overrides it with the measured bucket, leaving the outer card scope stable). `Layout.AreaGrid`/`grid.area` and `itemFit` remain deferred.
- **Pure range-validation helpers:** `input_range_validation.dart` with `numberInputValueIsValid`, `dateInputValueIsValid`, and `timeInputValueIsValid` — Flutter-free pure functions for `Input.Number`, `Input.Date`, and `Input.Time` bound validation, mirroring `input_text_validation.dart`.
- **`Image.backgroundColor`:** painted behind the image (visible through transparent PNGs).
- **`Badge.shape`:** `square` / `rounded` / `circular` mapped to corner radius.
- **`CompoundButton.badge`:** trailing badge label rendered when present.
- **`Carousel` `timer` / `orientation` / `loop`:** auto-advance (periodic timer), vertical scroll direction, and wrap-around paging.
- **`Media.captionSources`:** parsed into a typed `CaptionSource` model (VTT rendering on the video surface remains a follow-up).

## [0.11.0]

### Added 0.11.0

- **`Action.Popover` registry pattern:** `GenericPopoverAction` abstract class and `DefaultPopoverAction` implementation added. `Action.Popover` is now registered in `DefaultActionTypeRegistry` and follows the same injectable handler pattern as Submit, Execute, OpenUrl, ToggleVisibility, and ResetInputs. Host apps can override the default dialog behavior by supplying a custom `ActionTypeRegistry`.
- **`AdaptivePopoverContainer`** extracted to its own file (`popover_container.dart`) to avoid a circular dependency between `default_actions.dart` and `popover.dart`; re-exported from `popover.dart` for backward compatibility.

### Changed 0.11.0

- **`AdaptiveActionPopoverState`** refactored to resolve its action handler from the registry in `didChangeDependencies()` (matching `AdaptiveActionSubmitState` / `AdaptiveActionExecuteState`). The inline `onTapped()` method and `popupParentResolver` field have been removed; dialog-show logic now lives in `DefaultPopoverAction`. `AdaptiveActionMixin` added to state mixins.
- **`AdaptiveVisibilityMixin` / `AdaptiveActionStateMixin`:** converted from `on State<T>` to `on ConsumerState<T>`; visibility and action state now read via `ref.watch` / `ref.read` instead of `ProviderScope.containerOf(context)` + manual `ProviderSubscription`. Removes all manual `didChangeDependencies` subscription setup and `dispose` cleanup in these mixins.
- **All display and structural element widgets** (`AdaptiveColumn`, `AdaptiveColumnSet`, `AdaptiveContainer`, `AdaptiveImageSet`, `AdaptiveTable`, `AdaptiveAccordion`, `ActionSet`, `AdaptiveCarousel`, `AdaptiveCodeBlock`, `AdaptiveCompoundButton`, `AdaptiveIcon`, `AdaptiveProgressBar`, `AdaptiveProgressRing`, `AdaptiveTabSet`, `AdaptiveTextBlock`, `AdaptiveRichTextBlock`, `AdaptiveBadge`, `AdaptiveImage`, `AdaptiveMedia`, `AdaptiveRating`, `AdaptiveFactSet`, `IconButtonAction`) converted from `StatefulWidget`/`State` to `ConsumerStatefulWidget`/`ConsumerState`. Internal refactor; no public API changes.
- Removed duplicate `assets/fonts/` tree; golden tests load Roboto from `flutter_adaptive_cards_test_support`.

### Fixed 0.11.0

- **`ProviderScope` brightness key bug:** removed `key: ValueKey<Brightness?>` from the inner `ProviderScope` in `RawAdaptiveCard`. The key caused Flutter to destroy and recreate the entire `ProviderScope` subtree on every brightness toggle, wiping `AdaptiveCardDocumentNotifier` state (all input values, overlays, and visibility). Theme propagation continues to work via `didChangeDependencies` — no key is needed. Regression tests added in `test/elements/theme_change_overlay_test.dart`.

### Overlay gaps remediation 0.11.0 (Waves 1–3)

- **`RichTextBlock`:** runtime **`inlines`** overlay; host **`setInlines`** / **`clearInlines`** on **`RawAdaptiveCardState`**; widget listener via `resolvedElementProvider`.
- **Optional-package overlay hooks:** **`ElementOverlayExtension`**, **`CardOverlayExtensionRegistry`**, and **`CardTypeRegistry.overlayExtensions`** — generic `extensionPayloads` merge in core (chart types live in `flutter_adaptive_charts_fs`).
- **`OverlayCapabilityRegistry`:** **`ElementOverlayField`** / **`ActionOverlayField`** enums and **`CardTypeRegistry.overlayCapabilities`** for per JSON `type` overlay discovery; debug validation in **`applyUpdates`** (assert in debug builds).
- Public exports: **`ElementOverlayExtension`**, **`OverlayCapabilityRegistry`**, and overlay field enums from **`flutter_adaptive_cards_fs.dart`**; optional-package authors import **`package:flutter_adaptive_cards_fs/flutter_adaptive_cards_extend_fs.dart`** for overlay extension hooks.
- Docs: [`docs/overlay-properties-by-type.md`](../../docs/overlay-properties-by-type.md) — host index of patch keys by element type.
- **`Input.Rating`:** new **`AdaptiveRatingInput`** with full overlay contract (`value`, `label`, `isRequired`, validation); registry split from read-only **`Rating`** (`AdaptiveRating`); shared **`RatingStars`** widget.
- **`Input.Toggle`:** reactive `label`, `isRequired`, and validation UI via `watchResolvedInput()`.
- **`Badge`:** reactive `text` overlay (`setText` / `applyUpdates`) via `resolvedElementProvider`.
- **`Action.Popover`:** `isEnabled`, `title`, and `tooltip` overlays via shared **`IconButtonAction`** chrome.
- **`Media`:** reactive URL overlay — `setUrl` merges into `sources[0].url`; player re-inits on URL change.
- **`Rating` (display):** reactive `value`, `max`, `color`, and `size` via `resolvedElementProvider` listener.
- **`Action.*` `iconUrl`:** runtime overlay via **`ActionOverlay.iconUrl`**; merged in **`resolvedActionProvider`**; **`AdaptiveActionStateMixin`** updates **`IconButtonAction`** reactively; host **`applyUpdates`** / **`applyUpdatesFromMap`** with **`clearIconUrl`**.

## [0.10.0]

- **Root card `refresh` (v1.4+):** parse `refresh.action`, `userIds`, and `expires` via **`RefreshConfig`**; manual refresh affordance (top-right icon) when `refresh.action` is set; one-shot auto-refresh after first frame when `expires` is in the past; **`refresh.userIds`** gates auto-refresh only (via **`AdaptiveCardsCanvas.currentUserId`** / **`currentUserIdProvider`**).
- **`RefreshActionInvoke`** and optional **`InheritedAdaptiveCardHandlers.onRefresh`**; falls back to **`onExecute`** with merged input **`data`** when `onRefresh` is unset.
- Public export of **`RefreshConfig`** from `flutter_adaptive_cards_fs.dart`.
- Tests: **`test/models/refresh_config_test.dart`**, **`test/refresh/refresh_action_test.dart`**.
- Public exports for **`RawAdaptiveCard`**, **`RawAdaptiveCardState`**, and **`DataQuery`** (host integration and backend invoke wiring).
- **Data.Query `associatedInputs`:** sibling input values merged into `DataQuery.parameters` on `InputChangeInvoke` when `auto` (default).
- **Action.Submit / Action.Execute `associatedInputs`:** `"none"` skips input merge into invoke `data`.
- **`Icon` element** (v1.5 documentation hub): **`AdaptiveIcon`** registered for type `Icon`; Fluent name catalog (~68 common names) via **`fluent_icon_map.dart`** with Material icon fallbacks; `size`, `color`, and `style` (`Filled` / `Regular`) tokens; optional **`selectAction`** via **`AdaptiveTappable`**.
- **Chart color tokens:** **`chart_colors_config.dart`** — HostConfig palette + categorical, sequential, and diverging palettes plus Teams semantic tokens (`categoricalBlue`, `sequential5`, `divergingRed`, `good`, …).
- **`ReferenceResolver`:** **`resolveChartPalette({colorSet})`** selects named palettes; **`resolveChartColor()`** resolves semantic chart tokens before hex parsing.
- Tests: **`test/elements/icon_test.dart`**, **`test/hostconfig/chart_color_sets_test.dart`**, **`test/golden_icon_test.dart`**.
- **`RichTextBlock` + `TextRun` (v1.2):** **`AdaptiveRichTextBlock`** with per-run styling (`weight`, `color`, `italic`, `underline`, `highlight`, `fontType`, `size`) and **`selectAction`** via **`TapGestureRecognizer`**; **`TextRunModel.fromJson`**.
- **`TextBlock`:** plain **`Text`** path honors **`maxLines`**, **`TextOverflow.ellipsis`**, and HostConfig **`color`** / **`isSubtle`** when **`supportMarkdown`** is false; **`AdaptiveCardsCanvas.supportMarkdown`** now flows into **`CardTypeRegistry`**.
- Tests: **`test/elements/rich_text_block_test.dart`**, **`test/elements/text_block_test.dart`**, **`test/golden_rich_text_block_test.dart`**.
- Shared parse helpers: **`parseIsVisible()`** and **`parseHostConfigColor()`** in `utils.dart` (HostConfig color parsing and visibility baseline parsing).
- Public export of **`InheritedAdaptiveCardHandlers`** from `flutter_adaptive_cards_fs.dart` (for test support and host callback wiring without `implementation_imports`).
- Tests: **`test/utils/parse_helpers_test.dart`**; merged static **`isVisible`** cases into **`test/elements/is_visible_test.dart`**.
- **`flutter_adaptive_cards_fs` test harness** now re-exports **`flutter_adaptive_cards_test_support`** from `test/utils/test_utils.dart`; golden tests use shared `configureTestView`, `getGoldenPath`, and `getV16SampleForGoldenTest`.
- **`flutter_test_config.dart`** delegates to shared **`adaptiveCardsTestExecutable`** (HTTP overrides + Roboto font loading).
- Removed unused **`mockito`** dev dependency from this package.
- Dead legacy sources: **`adaptive_element.dart`**, **`basic_markdown.dart`** (superseded by registry / `flutter_markdown`).
- Orphan test fixtures and placeholder test: **`choice_set_radio.json`**, **`example15.json`**, **`test/elements/text_block_text.dart`**, duplicate root **`test/is_visible_test.dart`**.
- **`AGENTS.md`** documentation links (`doc/` → `docs/`).
- Public exports for **`Choice`**, **`Fact`**, and **`MediaSource`** from `flutter_adaptive_cards_fs.dart`.
- List parse helpers: `choicesFromJsonList` / `choicesToJsonList`, `factsFromJsonList`, `mediaSourcesFromJsonList`.
- Runtime **`facts`** overlay on `FactSet` elements (`setFacts`, `clearFacts`, `applyUpdates` / `applyUpdatesFromMap`).
- Widgetbook **FactSet → Facts overlay (knob)** demo for interactive overlay testing.
- Shared **`parseAdaptiveDateValue`** / **`formatAdaptiveDateValue`** helpers for `Input.Date` (`date_input_utils.dart`).
- **`ChildStyler`** implements container style and horizontal-alignment inheritance via nested `styleReferenceResolverProvider` overrides.
- **`ReferenceResolver.resolveTextBlockStyle()`**, **`resolveImageIsPerson()`**, and **`resolveEffectiveHorizontalAlignment()`**.
- **`AdaptiveCardBrightnessMode`** (`auto` / `light` / `dark`) on `RawAdaptiveCard` and `AdaptiveCardsCanvas`.
- Style inheritance diagrams in [`docs/adaptive-style.md`](../../docs/adaptive-style.md#style-inheritance-data-flow).
- Tests: `test/style/inheritance_test.dart`.
- **`ElementOverlay.choices`** now stores `List<Choice>` internally; resolved element JSON still exposes `choices` as maps for widget compatibility.
- **`Input.ChoiceSet`** filtered modal uses **`Choice`** instead of internal **`SearchModel`**.
- **`AdaptiveFactSet`** and **`AdaptiveMedia`** parse child lists via shared typed helpers.
- Container **background** uses only each element's own `style`; foreground palette uses **`inheritedContainerStyle`** from ancestors.
- **`TextBlock`** applies HostConfig `TextStylesConfig` for `heading` / `columnHeader`; table header rows use `columnHeader` defaults.
- **`Image`** `person` clipping applies only when `style` is `person` (not other style names).
- Theme brightness changes re-resolve styles via brightness-keyed root `ProviderScope`.
- **`ThemeColorFallbacks`:** HostConfig color fallbacks derived from `ThemeData.colorScheme` (`theme_color_fallbacks.dart`); replaces hardcoded light-theme colors previously in **`FallbackConfigs`**.
- **`ReferenceResolver`:** required **`colorFallbacks`** parameter; **`resolveProgressColor()`**; foreground, container, chart, separator, and badge resolution uses theme-derived defaults when HostConfig omits values.
- **`RawAdaptiveCard`:** wires **`ThemeColorFallbacks(Theme.of(context))`** into the resolver on each build.
- **HostConfig JSON parsers** (`FontColorConfig`, `ForegroundColorsConfig`, `ContainerStyleConfig`, `ContainerStylesConfig`, `HostConfig.fromJson`): optional **`theme:`** / **`ThemeColorFallbacks.forParsing`** for parse-time color defaults.
- Documentation: **[`docs/hostconfig.md`](../../docs/hostconfig.md)** (replaces **`docs/hostconfig_tests.md`**) — theme fallback pipeline, Widgetbook notes, and serialization test conventions.
- Regenerated linux and macos golden baselines for theme-derived HostConfig color fallbacks.
- **`Input.Date`** `initData` / `initInput` seeding: controller no longer receives placeholder text; submit and overlay values use `yyyy-MM-dd` per spec. Hosts that relied on ISO-8601 in `onChange` callbacks should expect `yyyy-MM-dd` instead.
- **`Input.ChoiceSet`** `loadInput`: selection reconcile clears the value overlay (`clearInputValue`) instead of writing `''`, matching legacy `loadInput` / `setChoices` behavior.
- **Root card `refresh` (v1.4+):** parse `refresh.action`, `userIds`, and `expires` via **`RefreshConfig`**; manual refresh affordance (top-right icon) when `refresh.action` is set; one-shot auto-refresh after first frame when `expires` is in the past; **`refresh.userIds`** gates auto-refresh only (via **`AdaptiveCardsCanvas.currentUserId`** / **`currentUserIdProvider`**).
- **`RefreshActionInvoke`** and optional **`InheritedAdaptiveCardHandlers.onRefresh`**; falls back to **`onExecute`** with merged input **`data`** when `onRefresh` is unset.
- Public export of **`RefreshConfig`** from `flutter_adaptive_cards_fs.dart`.
- Tests: **`test/models/refresh_config_test.dart`**, **`test/refresh/refresh_action_test.dart`**.
- Public exports for **`RawAdaptiveCard`**, **`RawAdaptiveCardState`**, and **`DataQuery`** (host integration and backend invoke wiring).
- **Data.Query `associatedInputs`:** sibling input values merged into `DataQuery.parameters` on `InputChangeInvoke` when `auto` (default).
- **Action.Submit / Action.Execute `associatedInputs`:** `"none"` skips input merge into invoke `data`.
- **`Icon` element** (v1.5 documentation hub): **`AdaptiveIcon`** registered for type `Icon`; Fluent name catalog (~68 common names) via **`fluent_icon_map.dart`** with Material icon fallbacks; `size`, `color`, and `style` (`Filled` / `Regular`) tokens; optional **`selectAction`** via **`AdaptiveTappable`**.
- **Chart color tokens:** **`chart_colors_config.dart`** — HostConfig palette + categorical, sequential, and diverging palettes plus Teams semantic tokens (`categoricalBlue`, `sequential5`, `divergingRed`, `good`, …).
- **`ReferenceResolver`:** **`resolveChartPalette({colorSet})`** selects named palettes; **`resolveChartColor()`** resolves semantic chart tokens before hex parsing.
- Tests: **`test/elements/icon_test.dart`**, **`test/hostconfig/chart_color_sets_test.dart`**, **`test/golden_icon_test.dart`**.

## [0.9.0]

### Added 0.9.0

- Filtered `Input.ChoiceSet` modal lists and typeahead search; choice **titles** drive search while submit, `onChange`, and `Data.Query` use choice **values**.
- Dependent `Input.ChoiceSet` support via `valueChangedAction` and host-driven `applyUpdates` / `Data.Query` cascade.
- **`OpenUrlActionInvoke`**, **`OpenUrlDialogActionInvoke`**, and **`InputChangeInvoke`** public models exported from `flutter_adaptive_cards_fs.dart`.
- Tests: `test/actions/open_url_action_invoke_test.dart`, `test/actions/open_url_dialog_action_invoke_test.dart`.

### Changed 0.9.0

- **`onSubmit`** now receives **`SubmitActionInvoke`** instead of a bare `Map`. Use `invoke.actionId` and `invoke.data` (merged action `data` + input values).
- **`onExecute`** now receives **`ExecuteActionInvoke`** instead of a bare `Map`. Use `invoke.verb`, `invoke.actionId`, and `invoke.data`.
- **`GenericExecuteAction.tap`** no longer takes a separate `verb` argument; read action metadata from `adaptiveMap` in custom implementations (or delegate to `ExecuteActionInvoke.fromActionMap`).
- **`onOpenUrl`** now receives **`OpenUrlActionInvoke`** (`url`, optional `actionId`) instead of a bare `String`.
- **`onOpenUrlDialog`** now receives **`OpenUrlDialogActionInvoke`** (`url`, optional `actionId`) instead of a bare `String`.
- **`onChange`** now receives **`InputChangeInvoke`** (`inputId`, `value`, `dataQuery`, `cardState`) instead of four separate parameters.
- **`AdaptiveCardsCanvas.onChange`** and **`RawAdaptiveCard.onChange`** use the same **`InputChangeInvoke`** type.
- Fixed semantic binding error when dismissing the filtered ChoiceSet modal panel (clear control separated from `InputDecoration.suffix`).

### Removed

- Unused **`onSubmit`**, **`onExecute`**, and **`onOpenUrl`** fields on **`AdaptiveCardsCanvasState`**. Use **`InheritedAdaptiveCardHandlers`** for Submit, Execute, and OpenUrl callbacks.

## [0.8.0]

- Migrated all modifyable state to be reactive using riverpod via overlay on top of adaptive card json: [ElementOverlay and ActionOverlay](lib/src/riverpod/adaptive_card_document.dart)
  - Elements value, error messages, error state, isVisble and many other attributes
  - Actions isEnabled and other attributes
- Implemented regex validation in input field
- Added AI skills flutter and dart provided by flutter and dart teams.
- Added AI superpowers

### Added 0.8.0

- **`AdaptiveElementUpdate`** / **`AdaptiveActionUpdate`** and bulk **`applyUpdates`** / **`applyUpdatesFromMap`** on the document notifier and **`RawAdaptiveCardState`**.
- **`ElementOverlay.isRequired`** and **`ElementOverlay.url`**; **`AdaptiveInputMixin`** listens for resolved `isRequired`; **`AdaptiveImage`** listens for resolved `url`.
- **Tier 3 overlays:** **`label`**, **`placeholder`** on inputs; **`title`**, **`tooltip`** on actions; merged via **`applyUpdates`** / **`applyUpdatesFromMap`**; **`AdaptiveInputMixin`** and **`AdaptiveActionStateMixin`** update UI reactively.
- **`initData`** supports scalar values or per-id patch maps; **`seedInputValues`** delegates to **`applyUpdates`** (single revision).
- Default **Submit** / **Execute** required-field checks use resolved **`isRequired`** (overlay ?? baseline).
- **`Input.Text`** **`regex`** validation (AC 1.3): pattern checked on field blur and on **Submit** / **Execute** via shared **`textInputValueIsValid`**; invalid values set **`isInvalid`** and show **`errorMessage`**.
- Tests: `test/riverpod/apply_updates_test.dart`, `test/inputs/cascade_choice_set_test.dart`, `test/inputs/is_required_overlay_test.dart`, `test/elements/image_url_overlay_test.dart`, `test/actions/submit_required_overlay_test.dart`.
- Tests: `test/inputs/input_text_validation_test.dart`, `test/inputs/input_text_regex_test.dart`, `test/golden_input_text_regex_test.dart` (sample `test/samples/ac-qv-event.json`).
- Design spec: [`docs/superpowers/specs/2026-06-03-dynamic-property-updates-design.md`](../../docs/superpowers/specs/2026-06-03-dynamic-property-updates-design.md).
- **`resetInput(id)`** on the document notifier and **`RawAdaptiveCardState`**; **`AdaptiveInputMixin.resetInput()`** delegates to the notifier.
- Factory reset clears input overlays including **`label`**, **`placeholder`**, and **`isRequired`** (resolved → baseline JSON). See [`docs/reactive-riverpod.md`](../../docs/reactive-riverpod.md#reset-semantics).
- Design spec: [`docs/superpowers/specs/2026-06-03-overlay-reset-semantics-design.md`](../../docs/superpowers/specs/2026-06-03-overlay-reset-semantics-design.md).
- **`Action.ResetInputs`** **`targetInputIds`**: reset only listed input ids; omitted property resets all inputs; empty array resets nothing. Shared executor used by action button tap and input **`valueChangedAction`**.
- **`valueChangedAction`** on **`Input.*`**: when the user changes a field, runs embedded **`Action.ResetInputs`** (e.g. dependent ChoiceSet / country–city). Discrete inputs fire immediately; **`Input.Text`** / **`Input.Number`** fire on focus loss or editing complete, not each keystroke.
- Document notifier **`resetInputs(List<String> ids)`** — batch factory reset in one revision (same overlay rules as **`resetInput(id)`**).
- Sample `test/samples/action_reset_inputs_targeted.json`; tests for targeted reset and **`valueChangedAction`**; Widgetbook **`Actions.Reset (targeted)`** use case.
- Design spec: [`docs/superpowers/specs/2026-06-04-action-resetinputs-targetinputids-design.md`](../../docs/superpowers/specs/2026-06-04-action-resetinputs-targetinputids-design.md).

### Changed 0.8.0

- **Scoped dependency injection** now uses nested **`InheritedReferenceResolver`** widgets instead of Riverpod:
  - Outer scope (from `RawAdaptiveCard`): `resolver` (includes `cardTypeRegistry` / `actionTypeRegistry`), `rawAdaptiveCardState` — read via `InheritedReferenceResolver.rawCardScopeOf(context)`.
  - Inner scope (from each `AdaptiveCardElement`): `adaptiveCardElementState` — read via `InheritedReferenceResolver.elementScopeOf(context)`.
- **`ProviderScopeMixin`** unchanged by name; implementations now read the inherited scopes above (no `ref`, `ConsumerWidget`, or app-level `ProviderScope` required).
- Host-facing callbacks remain on **`InheritedAdaptiveCardHandlers`**.
- See [`doc/replace-riverpod.md`](../../doc/replace-riverpod.md) for the migration map from former provider names.

- Updated to Dart SDK 3.12 and Flutter 3.44
- Regenerated golden test images for Flutter 3.44 rendering changes
- Refactored `HostConfig` classes by extracting bundled classes (e.g. from `miscellaneous_configs.dart` and `font_config.dart`) into dedicated individual files under `lib/src/hostconfig/` to improve maintainability.
- Updated `AdaptiveColumn`, `AdaptiveContainer`, and internal utilities to strictly use `ReferenceResolver` as a facade for accessing HostConfig values (e.g. `resolveSpacing()`), removing direct dependencies on underlying config objects like `SpacingsConfig`.
- Created `doc/Architecture-Overview.md` to document system architecture, package structure, internal state management, and extensibility points.
- Consolidated documentation around known gaps and priority issues into `doc/Implementation-Status.md`.
- **`ReferenceResolver`** no longer carries `cardTypeRegistry` or `actionTypeRegistry`. It is a HostConfig/theme facade only. Element and action factories are provided via Riverpod `cardTypeRegistryProvider` and `actionTypeRegistryProvider` (see [`doc/reactive-riverpod.md`](../../doc/reactive-riverpod.md)).
- **`Input.ChoiceSet`** reads effective choices from `resolvedElementProvider` instead of local-only state.
- **`RawAdaptiveCardState.loadInput`** and **`initInput`** delegate to the document notifier (no element-tree walk).
- **`initData`** seeds input overlays via `seedInputValues` post-frame.
- **`resetAllInputs`** / **`resetInput(id)`** factory-reset input overlays to baseline (value, choices, validation, **`isRequired`**, **`label`**, **`placeholder`**); preserve input `isVisible` and typeahead session fields only.
- **`ElementOverlay.choices`** — runtime overlay for `Input.ChoiceSet` dynamic option lists; merged via `resolvedElementProvider`.
- Document notifier APIs: `setChoices`, `appendChoices`, `seedInputValues`, `setDataQuerySession`.
- **`DataQuery.count` / `DataQuery.skip`** — spec fields for typeahead pagination.
- **`ActionOverlay`** and `actionOverlaysById` on `AdaptiveCardDocument` for AC 1.5 action `isEnabled`.
- **`resolvedActionProvider(id)`** — merged baseline + action overlay map for `Action.*` nodes.
- Document notifier: `setInputError`, `clearInputError`, `setActionEnabled`, `setActionsEnabled`.
- **`ElementOverlay.errorMessage`** and **`ElementOverlay.isInvalid`** merged via `resolvedElementProvider`.
- **`AdaptiveActionStateMixin`** — reactive `isEnabled` for `IconButtonAction` and `Action.ShowCard`.
- Host helpers on **`RawAdaptiveCardState`**: `setInputError`, `clearInputError`, `setActionEnabled`.
- **`ElementOverlay.text`** — runtime replacement of `TextBlock` `"text"`; merged via `resolvedElementProvider`.
- Document notifier: `setText`, `clearText`; **`AdaptiveTextBlock`** listens for resolved `text`.
- Host helpers: **`RawAdaptiveCardState.setText`** / **`clearText`**.
- Tests: `test/elements/text_block_text_overlay_test.dart`.
- Tests: `test/inputs/input_error_overlay_test.dart`, `test/actions/action_enabled_overlay_test.dart`, sample `test/samples/v1.5/action_is_enabled.json`.
- **`resetAllInputs`** clears validation overlays on inputs; preserves `actionOverlaysById`.
- **`setInputValue`** clears host validation overlays when the user edits an input.

## [0.7.0]

- Added `selectAction` support to `TableCell` (`AdaptiveTable`), wrapped via `AdaptiveTappable` to enable action handlers when cells are tapped.
- Added full `selectAction` support and tap testing validation on `AdaptiveCardElement`, `AdaptiveContainer`, `AdaptiveColumn`, and `AdaptiveImage` (fixed tap hit-tests using base64 URI elements)..
- change landscape / portrait breakpoint handling for AdaptiveCardElement
- `parseTextString` now accepts an optional `locale` parameter for correct date/time localization.
- `AdaptiveTextBlock` now passes the current `Localizations.maybeLocaleOf(context)` to `parseTextString` for region-aware date/time macro expansion.
- Insured `AdaptiveElementMixin` properly unregisters widgets on `dispose`.
- Fixed `minHeight` parameter parsing and constraint application on `AdaptiveColumn` and `AdaptiveContainer` elements (supporting raw pixel and integer formats).
- Fixed background image aspect-ratio sizing on `AdaptiveColumn` and `AdaptiveContainer` elements when they only contain a `backgroundImage` and have `minHeight` or pixel `width` constraints set, ensuring the other dimension scales dynamically to preserve original image proportions.
- Tests for `Data.Query` ChoiceSet flows: `loadInput` refresh after mount and from
  `onChange`, `setDataQuerySession` merge into resolved `choices.data`, and
  `initData` with `choices.data` (`choice_set_data_query_test.dart`,
  `init_data_overlay_test.dart`, `adaptive_card_document_notifier_test.dart`).

## [0.6.0]

- Bumped versions to 0.6.0 for next development cycle
- Updated to Dart SDK 3.11 and Flutter 3.41
- Removed `uuid` package dependency and replaced it with Flutter's native `UniqueKey()` for widget key generation.
- Removed unused `tinycolor2` package dependency to reduce library footprint.
- Renamed `AdaptiveCardsRoot` to `AdaptiveCardsCanvas`
- Inject `id` attributes into the JSON tree in the `AdaptiveCardsCanvas` so that all objects have ids when not provided. Note that this changes the provided JSON. You can see this in the adaptive_explorer app in the merged tab.
- Fixed `resetInputs()` to correctly clear and revert underlying UI state (text controllers, selectors, etc.) across all `Input` element types.
- Fixed `Input.Time` validation logic which previously rejected valid times. Improved the displayed error message format.
- Fixed Cupertino Time Picker overlay dismissal to pop the modal itself instead of the root navigator.

## [0.5.0]

- version numbers were sync'd to 0.5.0
- Added `ChartColorsConfig` to `HostConfig` to allow custom color palettes for charts.
- Added `ReferenceResolver` with `resolveChartPalette` and `resolveChartColor` methods.
- migrated more hard coded styles to the resolver
- Abstracted `ProviderScope` getter functions into a new `ProviderScopeMixin` away from `AdaptiveElementMixin`.

## [0.4.0] - 2026-04-14

- version numbers were sync'd to the flutter_adaptive_charts_fs 0.4.0

## [0.3.0] - 2026-04-12

- First version to be published on pub.dev out of the freemansoft repo
- Added the adaptive_explorer app
- Set versions on all projects to 0.3.0
- renamed package `flutter_adaptive_cards` to `flutter_adaptive_cards_plus` to avoid pub.dev name collision
- add data query support
- Renamed AdaptiveCard to AdaptiveCardsRoot
- Input field widgets now use the input id as their `ValueKey` (e.g. `ValueKey('myInputId')`)
- Parent/adaptive card keys for inputs use the suffix `_adaptive` (e.g. `ValueKey('${id}_adaptive')`)
- Selector item keys use the format `${id}_${itemKey}` (e.g. `ValueKey('myChoiceSet_Choice 1')`)
- `RawAdaptiveCard.searchList` now accepts an optional `inputId` which is propagated to the choice-filter modal so the modal search field can be keyed and tested.
- Tests and examples were updated to reflect the new keys (non-golden tests updated, new `text_input_test.dart` added).
- **Behavior change:** Non-input adaptive widgets now use `generateAdaptiveWidgetKey()` for their widget keys instead of `generateWidgetKey()`. Update any tests or consumers that relied on the old keys.
- Consumers should update any tests or code that relied on the old `<id>_input` keys to the new naming scheme.
- change name to `flutter_adaptive_cards_fs` to avoid conflict on pub.dev with package published 12/2025
- Added dynamic dark mode support to `RawAdaptiveCard` by listening to `Theme.of(context).brightness`.
- Enabled `verticalContentAlignment` on `AdaptiveContainer`.
- Fixed action `resolveOrientation` to use `ActionsConfig` values from HostConfig.
- Added basic `"fallback": "drop"` support for elements that fail to map or are unknown.
- Added `resolveInputForegroundColor` to `ReferenceResolver` and updated `ChoiceSet` dropdown to use it for better theme-aware coloring.
- Added `{{DATE(timestamp, FORMAT)}}` and `{{TIME(timestamp)}}` macro replacements in `TextBlock` and `FactSet` elements using a new `DateTimeUtils` utility.
- Added `intl` dependency for robust date parsing and localization approximations.
- **Golden Image Reorganization:** Restructured golden images into platform-specific subdirectories (`test/gold_files/linux/`, `test/gold_files/macos/`, etc.).
- **Dynamic Golden Resolution:** Added `getGoldenPath` helper in `test_utils.dart` to automatically select the appropriate golden directory based on the host platform.

## [0.2.1](https://github.com/freemansoft/Flutter-AdaptiveCards/compare/0.20...0.2.1) 2025-09-23

- Converted provider to riverpod 3 9/2025
- Updated libraries major-versions 9/2025
- Ipdated for flutter 3.24 9/2025
- Tested with ios 26 simulator and macos 26.0 9/2025
- Pointed at https microsoft images which causes CORS issue in web example app 9/2025
- Updated to the current Flutter
- Migrating all style into the Resolver so that all AdaptiveCard text styles are mapped there. Future create themeing for this
- Enabling workflow - or at least thinking about it
- Added Accordion, Badge, Carosel, CodeBlock, ProgressBar, ProgressRing, PieChart, BarChart
- Added `fvm` for flutter version management - currently 3.38.5
- BackgroundImage support for Container. Fixed support for fillMode
- Migrated to widgetbook 1.0.0 and deleted example app. This lost the lab and lab_web utilities
- Added hostconfig objects and integrated them and fallback hostconfig into the AdaptiveCard widgets.
- Addeed SVG support for images - but not background images
- Added Inline in-memory image support - png
- All elements have repeatable id values if not specified in the json (hashcode(adaptiveMap))
- Changed action path again (simplified)
- Put provider back in for raw and adaptive card element
- Added keys for the Adaptive cards
- Added calcuated and specified ids
- Added keys to the input fields in the input adaptive cards and atual input widgets for testing
- Migrated the hostconfig from InheritedReferenceResolver to riverpod provider_scope
- Selection applied via AdaptiveTappable to AdaptiveCard Element and Containers
- Add tooltips to actions
- Migrate from flutter_markdown to flutter_markdown_plus as `flutter_markdown` is deprecated
- Add template and data json merge support - Adaptive Cards 1.3
- Updated table support suing LLM

## [0.2.0](https://github.com/freemansoft/Flutter-AdaptiveCards/compare/0.1.2...0.2.0) - 2023-??-??

This is a placeholder until someone figures out how to do the release numbers and do releases.
Mostly because I didn't want this to overlay the 2020 Neohelden version.

### Merged 0.2.0

### Commits 0.2.0
