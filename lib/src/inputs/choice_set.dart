import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/utils.dart';
import 'package:provider/provider.dart';

import '../additional.dart';
import '../base.dart';

class SearchModel {
  final String id;
  final String name;

  SearchModel({required this.id, required this.name});

  factory SearchModel.fromJson(Map<String, dynamic> json) {
    return SearchModel(id: json["id"], name: json["name"]);
  }

  static List<SearchModel>? fromJsonList(List? list) {
    if (list == null) return null;
    return list.map((item) => SearchModel.fromJson(item)).toList();
  }

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

  @override
  void initState() {
    super.initState();

    label = adaptiveMap['label'];
    isRequired = adaptiveMap['isRequired'] ?? false;

    for (Map map in adaptiveMap['choices']) {
      _choices[map['title']] = map['value'].toString();
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
      });
    }
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
    var rawAdaptiveCardState = context.watch<RawAdaptiveCardState>();

    var widget;
    if (isFiltered) {
      widget = _buildFiltered(rawAdaptiveCardState);
    } else if (isCompact) {
      if (isMultiSelect) {
        widget = _buildExpandedMultiSelect(rawAdaptiveCardState);
      } else {
        widget = _buildCompact(rawAdaptiveCardState);
      }
    } else {
      if (isMultiSelect) {
        widget = _buildExpandedMultiSelect(rawAdaptiveCardState);
      } else {
        widget = _buildExpandedSingleSelect(rawAdaptiveCardState);
      }
    }

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [loadLabel(label, isRequired), widget]),
    );
  }

  Widget _customPopupItemBuilder(
      BuildContext context, SearchModel item, bool isSelected) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: !isSelected
          ? null
          : BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(
                color: Colors.grey,
                width: 0.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
            ),
      child: ListTile(
        dense: true,
        selected: isSelected,
        title: Text(item.name, style: TextStyle(color: Colors.black)),
      ),
    );
  }

  Widget _buildFiltered(RawAdaptiveCardState state) {
    return Container(
        height: 40.0,
        child: DropdownSearch<SearchModel>(
          compareFn: (i, s) => i.isEqual(s),
          items: _choices.keys
              .map((key) => SearchModel(
                    id: key,
                    name: _choices[key] ?? '',
                  ))
              .toList(),
          // dropdownDecoratorProps: DropDownDecoratorProps(
          //   dropdownSearchDecoration: InputDecoration(
          //     filled: true,
          //     fillColor: Colors.white,
          //     border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(4.0)),
          //   ),
          // ),
          popupProps: PopupPropsMultiSelection.modalBottomSheet(
            showSelectedItems: true,
            showSearchBox: true,
            itemBuilder: _customPopupItemBuilder,
            searchFieldProps: TextFieldProps(
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 0.0),
                    borderRadius: BorderRadius.circular(4.0)),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
            ),
          ),
          onChanged: (value) {
            select(state, value?.id);
          },
          selectedItem: _selectedChoices.isNotEmpty
              ? SearchModel(
                  id: _selectedChoices.single,
                  name: _choices[_selectedChoices.single] ?? '')
              : null,
        ));
  }

  /// This is built when multiSelect is false and isCompact is true
  Widget _buildCompact(RawAdaptiveCardState state) {
    return Container(
        padding: EdgeInsets.all(8),
        height: 40.0,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey,
            width: 0.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
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
          items: _choices.keys
              .map((key) => DropdownMenuItem<String>(
                    value: _choices[key],
                    child: Text(key),
                  ))
              .toList(),
          onChanged: (value) {
            select(state, value);
          },
          value: _selectedChoices.isNotEmpty ? _selectedChoices.single : null,
        )));
  }

  Widget _buildExpandedSingleSelect(RawAdaptiveCardState state) {
    return Column(
      children: _choices.keys.map((key) {
        return RadioListTile<String>(
          value: _choices[key]!,
          onChanged: (value) {
            select(state, value);
          },
          groupValue:
              _selectedChoices.contains(_choices[key]) ? _choices[key] : null,
          title: Text(key),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedMultiSelect(RawAdaptiveCardState state) {
    return Column(
      children: _choices.keys.map((key) {
        return CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          value: _selectedChoices.contains(_choices[key]),
          onChanged: (value) {
            select(state, _choices[key]);
          },
          title: Text(key),
        );
      }).toList(),
    );
  }

  void select(RawAdaptiveCardState state, String? choice) {
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

    state.changeValue(id, choice);
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
