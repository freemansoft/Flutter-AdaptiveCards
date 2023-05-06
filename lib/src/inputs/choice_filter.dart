import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_set.dart';

class ChoiceFilter extends StatefulWidget {
  ChoiceFilter({super.key, required this.data, required this.callback});

  final List<SearchModel>? data;
  final Function(dynamic value)? callback;

  @override
  _ChoiceFilterState createState() => _ChoiceFilterState();
}

class _ChoiceFilterState extends State<ChoiceFilter> {
  TextEditingController controller = new TextEditingController();

  List<SearchModel> _searchResult = [];
  List<SearchModel> _data = [];

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      _data = widget.data!;
    }
  }

  onSearchTextChanged(String text) async {
    setState(() {
      _searchResult.clear();
    });

    if (text.isEmpty) {
      return;
    }

    for (var item in _data) {
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
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.white,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
              side: BorderSide(color: Colors.grey),
            ),
            child: ListTile(
              leading: Icon(Icons.search),
              title: TextField(
                controller: controller,
                decoration: InputDecoration(
                    hintText: 'Search', border: InputBorder.none),
                onChanged: onSearchTextChanged,
              ),
              trailing: IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  controller.clear();
                  onSearchTextChanged('');
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: _searchResult.length != 0 || controller.text.isNotEmpty
              ? ListView.builder(
                  itemCount: _searchResult.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_searchResult[index].name),
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.callback != null) {
                          widget.callback!(_searchResult[index]);
                        }
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
                          if (widget.callback != null) {
                            widget.callback!(_data[index]);
                          }
                        });
                  },
                ),
        ),
      ],
    );
  }
}
