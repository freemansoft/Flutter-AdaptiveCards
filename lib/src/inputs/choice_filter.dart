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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            margin: const EdgeInsets.all(8.0),
            height: 40,
            child: TextField(
              style:
                  TextStyle(backgroundColor: Colors.white, color: Colors.black),
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0)),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                filled: true,
                fillColor: Colors.white,
                hoverColor: Colors.white,
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                // suffix: IconButton(
                //     icon: Icon(Icons.cancel, color: Colors.grey),
                //     onPressed: () {
                //       controller.clear();
                //       onSearchTextChanged('');
                //     }),
              ),
              onChanged: onSearchTextChanged,
            )),
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
