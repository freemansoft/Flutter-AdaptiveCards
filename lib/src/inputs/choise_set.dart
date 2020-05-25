import 'package:flutter/material.dart';

import '../additional.dart';
import '../base.dart';

class AdaptiveChoiceSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveChoiceSet({Key key, this.adaptiveMap}) : super(key: key);

  final Map adaptiveMap;

  @override
  _AdaptiveChoiceSetState createState() => _AdaptiveChoiceSetState();
}

class _AdaptiveChoiceSetState extends State<AdaptiveChoiceSet> with AdaptiveInputMixin, AdaptiveElementMixin {
  // Map from title to value
  Map<String, String> choices = Map();

  // Contains the values (the things to send as request)
  Set<String> _selectedChoice = Set();

  bool isCompact;
  bool isMultiSelect;

  @override
  void initState() {
    super.initState();
    for (Map map in adaptiveMap["choices"]) {
      choices[map["title"]] = map["value"].toString();
    }
    isCompact = loadCompact();
    isMultiSelect = adaptiveMap["isMultiSelect"] ?? false;
    _selectedChoice.addAll(value.split(","));
  }

  @override
  void appendInput(Map map) {
    map[id] = _selectedChoice;
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
    return DropdownButton<String>(
      items: choices.keys
          .map((choice) => DropdownMenuItem<String>(
                value: choices[choice],
                child: Text(choice),
              ))
          .toList(),
      onChanged: select,
      value: _selectedChoice.single,
    );
  }

  Widget _buildExpandedSingleSelect() {
    return Column(
      children: choices.keys.map((key) {
        return RadioListTile<String>(
          value: choices[key],
          onChanged: select,
          groupValue: _selectedChoice.contains(choices[key]) ? choices[key] : null,
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
          value: _selectedChoice.contains(choices[key]),
          onChanged: (_) {
            select(choices[key]);
          },
          title: Text(key),
        );
      }).toList(),
    );
  }

  void select(String choice) {
    if (!isMultiSelect) {
      _selectedChoice.clear();
      _selectedChoice.add(choice);
    } else {
      if (_selectedChoice.contains(choice)) {
        _selectedChoice.remove(choice);
      } else {
        _selectedChoice.add(choice);
      }
    }
    setState(() {});
  }

  bool loadCompact() {
    if (!adaptiveMap.containsKey("style")) return false;
    if (adaptiveMap["style"] == "compact") return true;
    if (adaptiveMap["style"] == "expanded") return false;
    throw StateError("The style of the ChoiceSet needs to be either compact or expanded");
  }
}
