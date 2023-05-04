import 'package:flutter/material.dart';

import '../additional.dart';
import '../base.dart';

class AdaptiveChoiceSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveChoiceSet({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveChoiceSetState createState() => _AdaptiveChoiceSetState();
}

class _AdaptiveChoiceSetState extends State<AdaptiveChoiceSet>
    with AdaptiveInputMixin, AdaptiveElementMixin {
  // Map from title to value
  Map<String, String> choices = {};

  // Contains the values (the things to send as request)
  Set<String> _selectedChoices = {};

  late bool isFiltered;
  late bool isCompact;
  late bool isMultiSelect;

  @override
  void initState() {
    super.initState();
    for (Map map in adaptiveMap['choices']) {
      choices[map['title']] = map['value'].toString();
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
  Widget build(BuildContext context) {
    var widget;

    if (isCompact) {
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
      child: widget,
    );
  }

  /// This is built when multiSelect is false and isCompact is true
  Widget _buildCompact() {
    return Container(
        padding: EdgeInsets.all(8),
        height: 40.0,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey,
            width: 0.0,
          ),
        ),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.black,
          ),
          style: const TextStyle(color: Colors.black),
          items: choices.keys
              .map((key) => DropdownMenuItem<String>(
                    value: choices[key],
                    child: Text(key),
                  ))
              .toList(),
          onChanged: select,
          value: _selectedChoices.isNotEmpty ? _selectedChoices.single : null,
        )));
  }

  Widget _buildExpandedSingleSelect() {
    return Column(
      children: choices.keys.map((key) {
        return RadioListTile<String>(
          value: choices[key]!,
          onChanged: select,
          groupValue:
              _selectedChoices.contains(choices[key]) ? choices[key] : null,
          title: Text(key),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedMultiSelect() {
    return Column(
      children: choices.keys.map((key) {
        return CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          value: _selectedChoices.contains(choices[key]),
          onChanged: (_) {
            select(choices[key]);
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
    setState(() {});
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
