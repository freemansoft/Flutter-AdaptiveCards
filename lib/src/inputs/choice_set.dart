import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../riverpod_providers.dart';

import '../adaptive_mixins.dart';
import '../additional.dart';
import '../utils.dart';

///
/// https://adaptivecards.io/explorer/Input.ChoiceSet.html
///
class SearchModel {
  final String id;
  final String name;

  SearchModel({required this.id, required this.name});

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

class AdaptiveChoiceSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveChoiceSet({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveChoiceSetState createState() => AdaptiveChoiceSetState();
}

class AdaptiveChoiceSetState extends State<AdaptiveChoiceSet>
    with AdaptiveInputMixin, AdaptiveElementMixin {
  // Map from title to value
  final Map<String, String> _choices = {};

  // Contains the values (the things to send as request)
  final Set<String> _selectedChoices = {};

  String? label;
  late bool isRequired;
  late bool isFiltered;
  late bool isCompact;
  late bool isMultiSelect;

  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    label = adaptiveMap['label'];
    isRequired = adaptiveMap['isRequired'] ?? false;

    if (adaptiveMap['choices'] != null) {
      /// https://adaptivecards.io/explorer/Input.Choice.html
      for (Map map in adaptiveMap['choices']) {
        _choices[map['title']] = map['value'].toString();
      }
    }

    isFiltered = loadFiltered();
    isCompact = loadCompact();
    isMultiSelect = adaptiveMap['isMultiSelect'] ?? false;

    if (value.isNotEmpty) {
      _selectedChoices.addAll(value.split(','));
    }
  }

  @override
  void appendInput(Map map) {
    map[id] = _selectedChoices.join(',');
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      setState(() {
        _selectedChoices.clear();
        _selectedChoices.add(map[id]);

        controller.text =
            _selectedChoices.isNotEmpty ? _selectedChoices.single : '';
      });
    }
  }

  @override
  bool checkRequired() {
    var adaptiveCardElement = ProviderScope.containerOf(context, listen: false)
        .read(adaptiveCardElementStateProvider);
    var formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }

  @override
  void loadInput(Map map) {
    setState(() {
      _choices.clear();
      _selectedChoices.clear();

      map.forEach((key, value) {
        _choices[key] = value.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;
    if (isFiltered) {
      widget = _buildFiltered();
    } else if (isCompact) {
      if (isMultiSelect) {
        widget = _buildExpandedMultiSelect();
      } else {
        widget = _buildCompact();
      }
    } else {
      if (isMultiSelect) {
        widget = _buildExpandedMultiSelect();
      } else {
        widget = _buildExpandedSingleSelect();
      }
    }

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [loadLabel(label, isRequired), widget],
      ),
    );
  }

  Widget _buildFiltered() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: TextFormField(
        readOnly: true,
        style: const TextStyle(),
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
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
          hintText: placeholder,
          hintStyle: const TextStyle(),
          errorStyle: const TextStyle(height: 0),
        ),
        validator: (value) {
          if (!isRequired) return null;
          if (value == null || value.isEmpty) {
            return '';
          }
          return null;
        },
        onTap: () async {
          var list =
              _choices.keys
                  .map((key) => SearchModel(id: key, name: _choices[key] ?? ''))
                  .toList();
          await widgetState.searchList(list, (dynamic value) {
            setState(() {
              select(value?.id);
            });
          });
        },
      ),
    );
  }

  /// This is built when multiSelect is false and isCompact is true
  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 40.0,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: const TextStyle(),
          items:
              _choices.keys
                  .map(
                    (key) => DropdownMenuItem<String>(
                      value: _choices[key],
                      child: Text(key),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            select(value);
          },
          value: _selectedChoices.isNotEmpty ? _selectedChoices.single : null,
        ),
      ),
    );
  }

  Widget _buildExpandedSingleSelect() {
    return Column(
      children:
          _choices.keys.map((key) {
            return RadioListTile<String>(
              value: _choices[key]!,
              onChanged: (value) {
                select(value);
              },
              groupValue:
                  _selectedChoices.contains(_choices[key])
                      ? _choices[key]
                      : null,
              title: Text(key),
            );
          }).toList(),
    );
  }

  Widget _buildExpandedMultiSelect() {
    return Column(
      children:
          _choices.keys.map((key) {
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: _selectedChoices.contains(_choices[key]),
              onChanged: (value) {
                select(_choices[key]);
              },
              title: Text(key),
            );
          }).toList(),
    );
  }

  void select(String? choice) {
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

    widgetState.changeValue(id, choice);
    setState(() {
      controller.text =
          _selectedChoices.isNotEmpty ? _selectedChoices.single : '';
    });
  }

  bool loadCompact() {
    if (!adaptiveMap.containsKey('style')) return true;
    String style = adaptiveMap['style'].toString().toLowerCase();
    if (style == 'compact' || style == 'filtered') return true;
    if (style == 'expanded') return false;
    throw StateError(
      'The style of the ChoiceSet needs to be either compact or expanded',
    );
  }

  bool loadFiltered() {
    if (!adaptiveMap.containsKey('style')) return false;
    if (adaptiveMap['style'].toString().toLowerCase() == 'filtered') {
      return true;
    }

    return false;
  }
}
