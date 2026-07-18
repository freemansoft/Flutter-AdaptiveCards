import 'package:flutter/material.dart';

void main() => runApp(const AdaptiveChatApp());

/// Root of the Adaptive Chat SDUI demo.
class AdaptiveChatApp extends StatelessWidget {
  /// Creates the app.
  const AdaptiveChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Chat',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Adaptive Chat')),
        body: const Center(child: Text('Adaptive Chat')),
      ),
    );
  }
}
