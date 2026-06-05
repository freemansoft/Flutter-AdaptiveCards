import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_adaptive_cards_fs/src/resolved_input_state.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.ChoiceSet.html
///
class SearchModel {
  SearchModel({required this.id, required this.name});
  final String id;
  final String name;

  ///this method will prevent the override of toString
  String modelAsString() {
    return '#$id $name';
  }

  ///custom comparing function to check if two users are equal
  bool isEqual(SearchModel model) {
    return id == model.id;
  }

  @override
  String toString() => name;
}

class AdaptiveChoiceSet extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
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

class AdaptiveChoiceSetState extends ConsumerState<AdaptiveChoiceSet>
    with
        AdaptiveInputMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  // Contains the values (the things to send as request)
  final Set<String> _selectedChoices = {};

  late bool isFiltered;
  late bool isCompact;
  late bool isMultiSelect;
  DataQuery? dataQuery;

  TextEditingController controller = TextEditingController();
  bool _initialValueSynced = false;

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
      controller.text = _selectedChoices.isNotEmpty
          ? _selectedChoices.first
          : '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Map<String, String> _parseChoices(Object? raw) {
    if (raw is! List) return const {};
    final result = <String, String>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final choice = Choice.fromJson(Map<String, dynamic>.from(entry));
      result[choice.title] = choice.value;
    }
    return result;
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
    final choices = _parseChoices(input.map['choices']);

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

  Widget _buildFiltered(
    ResolvedInputState input,
    Map<String, String> choices,
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
          final list = choices.keys
              .map((key) => SearchModel(id: key, name: choices[key] ?? ''))
              .toList();
          await rawRootCardWidgetState.searchList(list, (dynamic value) {
            setState(() {
              select(value?.id, choices);
            });
          }, inputId: id);
        },
      ),
    );
  }

  /// This is built when multiSelect is false and isCompact is true
  Widget _buildCompact(Map<String, String> choices) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: generateWidgetKey(adaptiveMap),

          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: TextStyle(
            color: styleResolver.resolveInputForegroundColor(
              context: context,
              style: null,
            ),
            backgroundColor: styleResolver.resolveInputBackgroundColor(
              context: context,
              style: null,
            ),
          ),
          items: choices.keys
              .map(
                (key) => DropdownMenuItem<String>(
                  key: generateWidgetKey(adaptiveMap, suffix: key),
                  value: choices[key],
                  child: Text(key),
                ),
              )
              .toList(),
          onChanged: (choice) => select(choice, choices),
          value: _selectedChoices.isNotEmpty ? _selectedChoices.single : null,
        ),
      ),
    );
  }

  Widget _buildExpandedSingleSelect(Map<String, String> choices) {
    return RadioGroup<String>(
      key: generateWidgetKey(adaptiveMap),
      groupValue: _selectedChoices.isNotEmpty ? _selectedChoices.single : null,
      onChanged: (choice) => select(choice, choices),
      child: Column(
        children: choices.keys.map((key) {
          return RadioListTile<String>(
            key: generateWidgetKey(adaptiveMap, suffix: key),

            value: choices[key]!,
            title: Text(key),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedMultiSelect(Map<String, String> choices) {
    return Column(
      children: choices.keys.map((key) {
        return CheckboxListTile(
          key: generateWidgetKey(adaptiveMap, suffix: key),

          controlAffinity: ListTileControlAffinity.leading,
          value: _selectedChoices.contains(choices[key]),
          onChanged: (value) {
            select(choices[key], choices);
          },
          title: Text(key),
        );
      }).toList(),
    );
  }

  void select(String? choice, Map<String, String> choices) {
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

    /// notify the card that the value has changed so it can invoke custom behavior
    rawRootCardWidgetState.changeValue(id, choice, dataQuery: dataQuery);
    final joined = _selectedChoices.join(',');
    setDocumentInputValue(joined);
    notifyUserInputValueChanged(joined, committed: true);
    setState(() {
      controller.text = _selectedChoices.isNotEmpty
          ? _selectedChoices.first
          : '';
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
      controller.text = _selectedChoices.isNotEmpty
          ? _selectedChoices.first
          : '';
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

  bool loadFiltered() {
    if (style == null) return false;
    if (style?.toLowerCase() == 'filtered') {
      return true;
    }

    return false;
  }
}
