import 'dart:async';

import 'package:adaptive_explorer/src/file_watcher_service.dart';
import 'package:adaptive_explorer/src/template_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';

void main() {
  runApp(const AdaptiveExplorerApp());
}

/// The root widget of the application.
class AdaptiveExplorerApp extends StatelessWidget {
  /// Creates a new [AdaptiveExplorerApp].
  const AdaptiveExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Explorer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// The main page of the application.
class HomePage extends StatefulWidget {
  /// Creates a new [HomePage].
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _templateManager = TemplateManager();
  final _fileWatcherService = FileWatcherService();

  Map<String, dynamic>? _currentCardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fileWatcherService.fileChangedStream.listen((_) {
      unawaited(_reload());
    });
  }

  @override
  void dispose() {
    _fileWatcherService.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    // If we have a template, reload it
    if (_templateManager.templatePath != null) {
      final merged = await _templateManager.getMergedTemplate();
      if (mounted) {
        setState(() {
          _currentCardData = merged;
          _errorMessage = null;
        });
      }
    }
  }

  Future<void> _openTemplate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await _templateManager.loadTemplate(path);

        // Start watching the file
        _fileWatcherService.watchFile(path);

        await _reload();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error opening template: $e';
        });
      }
    }
  }

  Future<void> _openData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await _templateManager.loadData(path);

        await _reload();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error opening data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Explorer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            onPressed: () => unawaited(_openTemplate()),
            icon: const Icon(Icons.file_open),
            label: const Text('Open Template'),
          ),
          TextButton.icon(
            onPressed: () => unawaited(_openData()),
            icon: const Icon(Icons.data_object),
            label: const Text('Open Data'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (_currentCardData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a template to view'),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AdaptiveCard.memory(
            content: _currentCardData!,
            hostConfigs: HostConfigs(),
            showDebugJson: false,
            listView: true,
          ),
        ),
      ),
    );
  }
}
