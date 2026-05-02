---
name: code-review
description: >
  Quality gate and checklist for reviewing changes in the Flutter-AdaptiveCards monorepo.
  Covers monorepo hygiene, AC spec compliance, theming, keys, accessibility, and testing.
  Use this for both manual and AI-assisted final reviews before proposing changes.
---

# Code Review Protocol

Use this skill as a "Final Gate" for any PR or significant change. Cross-reference with specialized skills (`adaptive-cards-spec-compliance`, `adaptive-cards-element-registry`, `flutter-adaptive-cards-testing`) as needed.

---

## 1. Monorepo Hygiene & Consistency

- [ ] **FVM usage**: Are all commands (`flutter`, `dart`) executed via `fvm`?
- [ ] **Analysis**: Does the code pass `fvm flutter analyze`? (Compliance with `very_good_analysis`).
- [ ] **Changelog**: Has `CHANGELOG.md` been updated in the affected packages following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)?
- [ ] **Formatting**: Has `dart_format` been run on all modified files?

---

## 2. `flutter_adaptive_cards_fs` Checklist

### Registration & Pattern Compliance

- [ ] **Registry**: Is the new element/action added to `CardTypeRegistry` or `ActionTypeRegistry`?
- [ ] **Mixins**: Does the element correctly implement `AdaptiveElementWidgetMixin` (Widget) and `AdaptiveElementMixin` + `AdaptiveVisibilityMixin` (State)?
- [ ] **Inputs**: If it's an input, does it use `AdaptiveInputMixin` and register its value correctly?

### Theming & Styling

- [ ] **ReferenceResolver**: Does the element use `styleReferenceResolverProvider` for all colors, font sizes, and spacing?
- [ ] **Theme Awareness**: Has it been verified in both **Light** and **Dark** modes?
- [ ] **HostConfig**: Does it respect spacing, separator, and padding properties from JSON via `SeparatorElement`?

### Keys & Identity

- [ ] **Deterministic Keys**: Is the outer widget key generated via `generateAdaptiveWidgetKey(adaptiveMap)`?
- [ ] **Internal Keys**: For inputs or sub-elements, are keys generated using the `id` (e.g., `ValueKey(id)` or `ValueKey('${id}_suffix')`)? _Crucial for testing stability._

### Accessibility

- [ ] **Semantics**: Does the widget use `Semantics` or `semanticLabel` where appropriate?
- [ ] **Alt-text**: For images or icons, is the `altText` (if provided in JSON) used as a semantic label?

### Exports

- [ ] **Public API**: Is the new class/widget exported in `lib/flutter_adaptive_cards_fs.dart`?
- [ ] **Extension API**: Is it exported in `lib/flutter_adaptive_cards_extend.dart` if intended for customization by consumers?

---

## 3. `flutter_adaptive_template_fs` Checklist

- [ ] **Expression Evaluation**: Are new AST nodes or functions implemented in both the parser and the evaluator?
- [ ] **Reserved Keywords**: Are `$data`, `$root`, `$index`, and `$when` handled correctly during expansion?
- [ ] **Scope Integrity**: Does nesting `$data` correctly shift the resolution context?

---

## 4. Testing Protocol

- [ ] **Key-First Searching**: All `find.text()` or `find.byType()` calls in tests should be replaced with `find.byKey()` whenever a key is available.
- [ ] **JSON Samples**: Is there a new file in `test/samples/` demonstrating the feature/fix?
- [ ] **Golden Tests**:
  - Have golden tests been added/updated for UI changes?
  - **Note**: Golden tests must be ran on a Linux machine (usually CI) for canonical reference images. Local Mac/Windows goldens may differ slightly.

---

## Review Output Template

When performing a review, summarize findings using this format:

```markdown
### Code Review Summary

- **Package**: [e.g. flutter_adaptive_cards_fs]
- **Hygiene**: [PASS/FAIL] (Analysis, Changelog, Formatting)
- **Compliance**: [PASS/FAIL] (Registry, Spec, Theming)
- **Testing**: [PASS/FAIL] (Keys, Samples, Goldens)

#### Details

- [Specific feedback regarding keys, accessibility, etc.]
```
