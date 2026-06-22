import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_adaptive_cards_fs/src/resolved_input_state.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.ChoiceSet.html
///
/// Renders `Input.ChoiceSet` in compact, expanded, or filtered styles.
///
/// Filtered style opens `ChoiceFilter` via `RawAdaptiveCard.searchList` over
/// resolved overlay `choices`. When `choices.data` is present, `dataQuery` is
/// parsed from JSON and passed to host `onChange` on selection. When
/// `associatedInputs` is `auto`, sibling input values are merged into
/// `parameters` before the host callback.
class AdaptiveChoiceSet extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a choice-set input from [adaptiveMap] JSON.
  AdaptiveChoiceSet({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveChoiceSetState createState() => AdaptiveChoiceSetState();
}

/// State for [AdaptiveChoiceSet]; handles selection UI and host callbacks.
class AdaptiveChoiceSetState extends ConsumerState<AdaptiveChoiceSet>
    with
        AdaptiveInputMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  /// Stored submit values (`choices[].value`), not display titles.
  final Set<String> _selectedChoices = {};

  /// Whether `style` is `filtered` (searchable picker).
  late bool isFiltered;

  /// Whether `style` is `compact` (dropdown) vs `expanded` (radio/checkbox).
  late bool isCompact;

  /// Whether multiple choices may be selected (`isMultiSelect`).
  late bool isMultiSelect;

  /// From `choices.data` when present; forwarded on [select] only.
  DataQuery? dataQuery;

  /// Text field backing compact/filtered display of the selected title(s).
  TextEditingController controller = TextEditingController();
  bool _initialValueSynced = false;
  bool _selectionReconcileScheduled = false;

  @override
  void initState() {
    super.initState();

    if (adaptiveMap.containsKey('choices.data')) {
      dataQuery = DataQuery.fromJson(
        adaptiveMap['choices.data'] as Map<String, dynamic>,
      );
    }

    isFiltered = loadFiltered();
    isCompact = loadCompact();
    isMultiSelect = adaptiveMap['isMultiSelect'] as bool? ?? false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialValueSynced) {
      _initialValueSynced = true;
      final next = readResolvedInput().valueAsString;
      _selectedChoices.addAll(
        next.isEmpty ? const <String>[] : next.split(','),
      );
      final choices = choicesFromJsonList(readResolvedInput().map['choices']);
      _syncSelectionControllerText(choices);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Set<String> _valuesFromResolved(ResolvedInputState input) {
    final resolved = input.valueAsString;
    if (resolved.isEmpty) {
      return {};
    }
    return resolved.split(',').toSet();
  }

  String? _singleChoiceValueFor(List<Choice> choices) {
    if (_selectedChoices.isEmpty) {
      return null;
    }
    final selected = _selectedChoices.single;
    final isValid = choices.any((choice) => choice.value == selected);
    return isValid ? selected : null;
  }

  /// Keeps widget selection in sync when resolved [choices] change under a stale value.
  ///
  /// Two common paths leave `_selectedChoices` or the document overlay out of step
  /// with the current choice list for a frame (or longer):
  ///
  /// - **Dependent inputs:** country `valueChangedAction` clears the city document
  ///   value, then the host repopulates city choices on the next frame — local
  ///   selection can still hold the previous city when the compact dropdown rebuilds.
  /// - **Data.Query / `loadInput`:** `select()` calls host `onChange` (which may
  ///   replace choices via `setChoices`) before `setDocumentInputValue`, so the
  ///   document can briefly hold a value that no longer exists in the new list.
  ///
  /// [_singleChoiceValueFor] keeps the rendered selection (the [DropdownMenu]
  /// `initialSelection` / expanded group value) consistent with the current
  /// [choices] on that stale frame by returning `null` for a value no longer in
  /// the list; this method finishes the job post-frame by syncing to the
  /// **valid intersection** of document value(s) and current [choices], or `''`
  /// when none apply. We must
  /// not call [onDocumentValueChanged] with the raw resolved value when it is
  /// invalid — that re-applies the stale value and causes an infinite rebuild loop
  /// (see `choice_set_data_query_test.dart`, loadInput-after-onChange case).
  void _scheduleSelectionReconcile(
    ResolvedInputState input,
    List<Choice> choices,
  ) {
    final choiceValues = choices.map((choice) => choice.value).toSet();
    final resolvedValues = _valuesFromResolved(input);
    // Target is only values still present in the current list — never stale ids.
    final validResolved = resolvedValues.where(choiceValues.contains).toSet();
    final target = validResolved.isEmpty ? '' : validResolved.join(',');
    final localInvalid = _selectedChoices.any(
      (value) => !choiceValues.contains(value),
    );
    final docInvalid = resolvedValues.any(
      (value) => !choiceValues.contains(value),
    );
    final docMismatch = !setEquals(_selectedChoices, resolvedValues);
    if (!localInvalid && !docMismatch && !docInvalid) {
      return;
    }
    if (_selectionReconcileScheduled) {
      return;
    }
    _selectionReconcileScheduled = true;
    // Post-frame: avoid setState while build is in progress (same pattern as
    // [AdaptiveInputMixin.listenForResolvedValueChanges]).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectionReconcileScheduled = false;
      if (!mounted) {
        return;
      }
      // Clear invalid or divergent document overlay before syncing local UI.
      if (docInvalid || docMismatch) {
        if (target.isEmpty) {
          clearDocumentInputValue();
        } else {
          setDocumentInputValue(target);
        }
      }
      onDocumentValueChanged(target);
    });
  }

  String _titleForStoredValue(String storedValue, List<Choice> choices) {
    for (final choice in choices) {
      if (choice.value == storedValue) {
        return choice.title;
      }
    }
    return storedValue;
  }

  /// Syncs [controller] text to the title of the current single selection.
  ///
  /// Both the filtered field and the compact [DropdownMenu] display through
  /// [controller], so each must reflect the selected choice's title (or empty
  /// when nothing is selected). Expanded styles do not use [controller].
  void _syncSelectionControllerText(List<Choice> choices) {
    if (!isFiltered && !isCompact) {
      return;
    }
    controller.text = _selectedChoices.isEmpty
        ? ''
        : _titleForStoredValue(_selectedChoices.first, choices);
  }

  @override
  void appendInput(Map map) {
    map[id] = _selectedChoices.join(',');
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      setDocumentInputValue(map[id]);
    }
  }

  @override
  bool checkRequired() {
    final input = readResolvedInput();
    if (input.isRequired && input.valueAsString.isEmpty) {
      setLocalValidationError();
      return false;
    }
    clearLocalValidationError();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    listenForResolvedValueChanges();
    final input = watchResolvedInput();
    final choices = choicesFromJsonList(input.map['choices']);
    _scheduleSelectionReconcile(input, choices);

    late Widget widget;
    if (isFiltered) {
      widget = _buildFiltered(input, choices);
    } else if (isCompact) {
      if (isMultiSelect) {
        widget = _buildExpandedMultiSelect(choices);
      } else {
        widget = _buildCompact(choices);
      }
    } else {
      if (isMultiSelect) {
        widget = _buildExpandedMultiSelect(choices);
      } else {
        widget = _buildExpandedSingleSelect(choices);
      }
    }

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            loadLabel(
              context: context,
              label: input.label,
              isRequired: input.isRequired,
            ),
            widget,
            loadErrorMessage(
              context: context,
              errorMessage: input.errorMessage,
              showError: input.isInvalid,
            ),
          ],
        ),
      ),
    );
  }

  /// Read-only field; tap opens `ChoiceFilter` over current resolved [choices].
  Widget _buildFiltered(
    ResolvedInputState input,
    List<Choice> choices,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: TextFormField(
        key: generateWidgetKey(adaptiveMap),
        readOnly: true,
        style: const TextStyle(),
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide()),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 1),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 1),
          ),
          filled: true,
          suffixIcon: const Icon(Icons.arrow_drop_down),
          hintText: input.placeholder,
          // required or box will exist even though field is hidden or half height
          hintStyle: const TextStyle(),
          errorStyle: const TextStyle(height: 0),
        ),
        validator: (value) {
          if (!input.isRequired) return null;
          if (value == null || value.isEmpty) {
            return '';
          }
          return null;
        },
        onTap: () async {
          // Snapshot at open time; modal does not observe later overlay updates.
          await rawRootCardWidgetState.searchList(choices, (Choice? value) {
            setState(() {
              select(value?.value, choices);
            });
          }, inputId: id);
        },
      ),
    );
  }

  /// Built when `isMultiSelect` is false and the style is `compact`.
  ///
  /// Uses Material 3 [DropdownMenu] (not the legacy `DropdownButton`) so the
  /// field supports type-ahead keyboard navigation — typing a character jumps to
  /// the matching choice, matching the web renderer's native `<select>`. Display
  /// text is driven by [controller], which the widget keeps in sync with the
  /// resolved single selection (see [_syncSelectionControllerText]); we cannot
  /// rely on `initialSelection` alone because [DropdownMenu] does not clear the
  /// field when the selection resets to a value absent from the entries.
  Widget _buildCompact(List<Choice> choices) {
    return DropdownMenu<String>(
      key: generateWidgetKey(adaptiveMap),
      controller: controller,
      initialSelection: _singleChoiceValueFor(choices),
      // `enableSearch` (true) makes typing *jump to / highlight* the matching
      // entry while keeping the full list visible — the closest analog to a
      // native HTML `<select>`. The alternative, `enableFilter` (not set here),
      // instead *narrows the list* to entries matching the typed text, behaving
      // more like the `filtered` style's search modal. We default to search to
      // preserve compact-dropdown semantics.
      //
      // TODO(hostconfig): expose this (search vs filter, and whether type-ahead
      // is enabled at all) via a future HostConfig setting so hosts can opt into
      // filtering.
      enableSearch: true,
      // Intentionally omit `requestFocusOnTap` so [DropdownMenu] applies its
      // platform-aware default: focusable (and thus keyboard type-ahead) on
      // desktop platforms where a physical keyboard is present (macOS/Linux/
      // Windows), and tap-only on mobile (iOS/Android/Fuchsia) so we don't pop
      // the soft keyboard for a simple dropdown. Forcing `true` would enable
      // type-ahead on phones, which is not the desired UX.
      //
      // TODO(hostconfig): a future HostConfig setting could let hosts override
      // this (e.g. force type-ahead on tablets that report an attached keyboard).
      expandedInsets: EdgeInsets.zero,
      textStyle: TextStyle(
        color: styleResolver.resolveInputForegroundColor(
          context: context,
          style: null,
        ),
        backgroundColor: styleResolver.resolveInputBackgroundColor(
          context: context,
          style: null,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onSelected: (choice) => select(choice, choices),
      dropdownMenuEntries: choices
          .map(
            (choice) => DropdownMenuEntry<String>(
              value: choice.value,
              label: choice.title,
            ),
          )
          .toList(),
    );
  }

  Widget _buildExpandedSingleSelect(List<Choice> choices) {
    return RadioGroup<String>(
      key: generateWidgetKey(adaptiveMap),
      groupValue: _singleChoiceValueFor(choices),
      onChanged: (choice) => select(choice, choices),
      child: Column(
        children: choices.map((choice) {
          return RadioListTile<String>(
            key: generateWidgetKey(adaptiveMap, suffix: choice.title),

            value: choice.value,
            title: Text(choice.title),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedMultiSelect(List<Choice> choices) {
    return Column(
      children: choices.map((choice) {
        return CheckboxListTile(
          key: generateWidgetKey(adaptiveMap, suffix: choice.title),

          controlAffinity: ListTileControlAffinity.leading,
          value: _selectedChoices.contains(choice.value),
          onChanged: (value) {
            select(choice.value, choices);
          },
          title: Text(choice.title),
        );
      }).toList(),
    );
  }

  /// Applies a user selection, updates document state, and notifies the host.
  void select(String? choice, List<Choice> choices) {
    if (!isMultiSelect) {
      _selectedChoices.clear();
      if (choice != null) {
        _selectedChoices.add(choice);
      }
    } else {
      if (_selectedChoices.contains(choice)) {
        _selectedChoices.remove(choice);
      } else {
        if (choice != null) {
          _selectedChoices.add(choice);
        }
      }
    }

    // Host callback; includes [dataQuery] when `choices.data` is configured.
    DataQuery? queryForHost = dataQuery;
    if (dataQuery != null) {
      final values = ref
          .read(adaptiveCardDocumentProvider.notifier)
          .collectInputValues();
      queryForHost = dataQuery!.withMergedSiblingInputs(
        values,
        excludeInputId: id,
      );
    }
    rawRootCardWidgetState.changeValue(id, choice, dataQuery: queryForHost);
    final joined = _selectedChoices.join(',');
    setDocumentInputValue(joined);
    notifyUserInputValueChanged(joined, committed: true);
    setState(() {
      _syncSelectionControllerText(choices);
    });
  }

  @override
  void onDocumentValueChanged(Object? valueFromDocument) {
    final next = valueFromDocument?.toString() ?? '';
    setState(() {
      _selectedChoices
        ..clear()
        ..addAll(
          next.isEmpty ? const <String>[] : next.split(','),
        );
      final choices = choicesFromJsonList(readResolvedInput().map['choices']);
      _syncSelectionControllerText(choices);
    });
  }

  /// JSON Schema definition "ChoiceInputStyle"
  bool loadCompact() {
    if (style == null) return true;
    final String ourStyle = style ?? ''.toLowerCase();
    if (ourStyle == 'compact' || ourStyle == 'filtered') return true;
    if (ourStyle == 'expanded') return false;
    throw StateError(
      'The style of the ChoiceSet needs to be either compact or expanded',
    );
  }

  /// Returns true when `style` is `filtered`.
  bool loadFiltered() {
    if (style == null) return false;
    if (style?.toLowerCase() == 'filtered') {
      return true;
    }

    return false;
  }
}
