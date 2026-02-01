import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards/src/inputs/choice_set.dart';

class ChoiceFilter extends StatefulWidget {
  const ChoiceFilter({super.key, required this.data, required this.callback});

  final List<SearchModel>? data;
  final Function(dynamic value)? callback;

  @override
  ChoiceFilterState createState() => ChoiceFilterState();
}

class ChoiceFilterState extends State<ChoiceFilter> {
  final TextEditingController _searchController = TextEditingController();

  final List<SearchModel> _searchResult = [];
  List<SearchModel> _data = [];

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

    for (final item in _data) {
      if (item.name.toLowerCase().contains(text.toLowerCase())) {
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
              return TextFormField(
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
                  suffix: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            _searchController.clear();
                            onSearchTextChanged('');
                          },
                        ),
                ),
                onChanged: onSearchTextChanged,
              );
            },
          ),
        ),
        Expanded(
          child: _searchResult.isNotEmpty || _searchController.text.isNotEmpty
              ? ListView.builder(
                  itemCount: _searchResult.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_searchResult[index].name),
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
                    return ListTile(
                      title: Text(_data[index].name),
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
