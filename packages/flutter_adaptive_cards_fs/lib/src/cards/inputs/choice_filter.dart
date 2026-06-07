import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';

/// Typeahead list inside the filtered `Input.ChoiceSet` bottom sheet.
///
/// Shows choice **titles**, filters locally as the user types, and returns the
/// selected [Choice] via [callback] (parent stores the submit **value**).
///
/// Choice rows are fixed for the lifetime of the sheet: they come from the
/// snapshot passed as [data] when the modal opens. Hosts that need fresh rows
/// after async loads should close and reopen the picker (or apply overlay
/// choices before the user taps the field).
class ChoiceFilter extends StatefulWidget {
  const ChoiceFilter({super.key, required this.data, required this.callback});

  /// Resolved choices at modal open time.
  final List<Choice>? data;

  /// Called with the tapped [Choice] after [Navigator.pop].
  final void Function(Choice? value)? callback;

  @override
  ChoiceFilterState createState() => ChoiceFilterState();
}

class ChoiceFilterState extends State<ChoiceFilter> {
  final TextEditingController _searchController = TextEditingController();

  final List<Choice> _searchResult = [];
  List<Choice> _data = [];

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      _data = widget.data!;
    }
  }

  Future<void> onSearchTextChanged(String text) async {
    setState(_searchResult.clear);

    if (text.isEmpty) {
      return;
    }

    // Client-side match on choice titles only (not submit values).
    for (final item in _data) {
      if (item.title.toLowerCase().contains(text.toLowerCase())) {
        setState(() {
          _searchResult.add(item);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          height: 40,
          child: Builder(
            builder: (context) {
              final String keyValue = (widget.key is ValueKey<String>)
                  ? (widget.key! as ValueKey<String>).value
                  : 'choiceFilter';
              // Keep the clear control out of [InputDecoration.suffix]. Suffix
              // semantics can get an inverted rect during sheet dismiss when
              // semantics are enabled (Widgetbook Semantics addon).
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(keyValue),
                      autofocus: true,
                      style: const TextStyle(),
                      controller: _searchController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(),
                        ),
                        filled: true,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: onSearchTextChanged,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () {
                        _searchController.clear();
                        unawaited(onSearchTextChanged(''));
                      },
                    ),
                ],
              );
            },
          ),
        ),
        Expanded(
          // Empty search: all [_data]. Non-empty: [_searchResult] from title match.
          child: _searchResult.isNotEmpty || _searchController.text.isNotEmpty
              ? ListView.builder(
                  itemCount: _searchResult.length,
                  itemBuilder: (context, index) {
                    final String keyValue = (widget.key is ValueKey<String>)
                        ? (widget.key! as ValueKey<String>).value
                        : 'choiceFilter';
                    return ListTile(
                      key: ValueKey(
                        '${keyValue}_${_searchResult[index].title}',
                      ),
                      title: Text(_searchResult[index].title),
                      onTap: () {
                        Navigator.pop(context);
                        widget.callback?.call(_searchResult[index]);
                      },
                    );
                  },
                )
              : ListView.builder(
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final String keyValue = (widget.key is ValueKey<String>)
                        ? (widget.key! as ValueKey<String>).value
                        : 'choiceFilter';
                    return ListTile(
                      key: ValueKey('${keyValue}_${_data[index].title}'),
                      title: Text(_data[index].title),
                      onTap: () {
                        Navigator.pop(context);
                        widget.callback?.call(_data[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
