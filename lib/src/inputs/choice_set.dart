import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:provider/provider.dart';

import '../additional.dart';
import '../base.dart';

class SearchModel {
  final String id;
  final String name;

  SearchModel({required this.id, required this.name});

  ///this method will prevent the override of toString
  String modelAsString() {
    return '#${this.id} ${this.name}';
  }

  ///custom comparing function to check if two users are equal
  bool isEqual(SearchModel model) {
    return this.id == model.id;
  }

  @override
  String toString() => name;
}

class AdaptiveChoiceSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveChoiceSet({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveChoiceSetState createState() => _AdaptiveChoiceSetState();
}

class _AdaptiveChoiceSetState extends State<AdaptiveChoiceSet>
    with AdaptiveInputMixin, AdaptiveElementMixin {
  // Map from title to value
  Map<String, String> _choices = {};

  // Contains the values (the things to send as request)
  Set<String> _selectedChoices = {};

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
    var adaptiveCardElement = context.read<AdaptiveCardElementState>();
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
    var widget;
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
          children: [loadLabel(label, isRequired), widget]),
    );
  }

  Widget _buildFiltered() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: TextFormField(
        readOnly: true,
        style: TextStyle(
          backgroundColor: Colors.white,
          color: Colors.black,
        ),
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
          contentPadding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
          ),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                width: 1,
                color: Colors.red,
              )),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(
                width: 1,
                color: Colors.redAccent,
              )),
          filled: true,
          fillColor: Colors.white,
          hoverColor: Colors.white,
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: Colors.black54,
          ),
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.black54),
          errorStyle: TextStyle(height: 0),
        ),
        validator: (value) {
          if (!isRequired) return null;
          if (value == null || value.isEmpty) {
            return '';
          }
          return null;
        },
        onTap: () async {
          var list = _choices.keys
              .map((key) => SearchModel(
                    id: key,
                    name: _choices[key] ?? '',
                  ))
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
        padding: EdgeInsets.all(8),
        height: 40.0,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.black54,
          ),
          style: const TextStyle(color: Colors.black),
          items: _choices.keys
              .map((key) => DropdownMenuItem<String>(
                    value: _choices[key],
                    child: Text(key),
                  ))
              .toList(),
          onChanged: (value) {
            select(value);
          },
          value: _selectedChoices.isNotEmpty ? _selectedChoices.single : null,
        )));
  }

  Widget _buildExpandedSingleSelect() {
    return Column(
      children: _choices.keys.map((key) {
        return RadioListTile<String>(
          value: _choices[key]!,
          onChanged: (value) {
            select(value);
          },
          groupValue:
              _selectedChoices.contains(_choices[key]) ? _choices[key] : null,
          title: Text(key),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedMultiSelect() {
    return Column(
      children: _choices.keys.map((key) {
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
        'The style of the ChoiceSet needs to be either compact or expanded');
  }

  bool loadFiltered() {
    if (!adaptiveMap.containsKey('style')) return false;
    if (adaptiveMap['style'].toString().toLowerCase() == 'filtered')
      return true;
    return false;
  }
}
