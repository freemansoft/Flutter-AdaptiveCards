import 'package:flutter/material.dart';

///
/// Returns a home button if there is no nav history
///
/// Intended to replace the back button if there is nothing to back up too
///
Widget? homeButtonIfNoHistory(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    return null;
  } else {
    return Builder(builder: (BuildContext context) {
      return IconButton(
        icon: const Icon(Icons.home),
        onPressed: () {
          Navigator.of(context).pushReplacementNamed('/');
        },
      );
    });
  }
}
