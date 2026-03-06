import 'dart:async';
import 'dart:convert';

import 'package:adaptive_explorer/src/file_watcher_service.dart';
import 'package:adaptive_explorer/src/template_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/flutter_adaptive_cards.dart';
import 'package:json_editor_flutter/json_editor_flutter.dart';

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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _templateManager = TemplateManager();
  final _fileWatcherService = FileWatcherService();

  late final TabController _tabController;

  Map<String, dynamic>? _templateJson;
  Map<String, dynamic>? _dataJson;
  Map<String, dynamic>? _mergedJson;
  String? _errorMessage;

  // Tracks in-editor edits so Save can write the latest version.
  Map<String, dynamic>? _editedTemplateJson;
  Map<String, dynamic>? _editedDataJson;

  double _splitFraction = 0.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fileWatcherService.fileChangedStream.listen((_) {
      unawaited(_reload());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fileWatcherService.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_templateManager.templatePath == null) return;
    final template = await _templateManager.getTemplateJson();
    final data = await _templateManager.getDataJson();
    final merged = await _templateManager.getMergedJson();
    if (mounted) {
      setState(() {
        _templateJson = template;
        _dataJson = data;
        _mergedJson = merged;
        _editedTemplateJson = template;
        _editedDataJson = data;
        _errorMessage = null;
      });
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
        _fileWatcherService.watchTemplateFile(path);
        await _reload();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error opening template: $e');
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
        _fileWatcherService.watchDataFile(path);
        await _reload();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error opening data: $e');
      }
    }
  }

  Future<void> _saveTemplate() async {
    final toSave = _editedTemplateJson ?? _templateJson;
    if (toSave == null) return;
    final success = await _templateManager.saveTemplateJson(toSave);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Template saved.' : 'Failed to save template.',
          ),
        ),
      );
    }
  }

  Future<void> _saveData() async {
    final toSave = _editedDataJson ?? _dataJson;
    if (toSave == null) return;
    final success = await _templateManager.saveDataJson(toSave);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Data saved.' : 'Failed to save data.'),
        ),
      );
    }
  }

  // Determine whether the Save button should be active for the current tab.
  bool get _canSaveCurrentTab {
    final index = _tabController.index;
    if (index == 0) return _templateJson != null;
    if (index == 1) return _dataJson != null;
    return false; // Merged is read-only
  }

  Future<void> _saveCurrentTab() async {
    final index = _tabController.index;
    if (index == 0) {
      await _saveTemplate();
    } else if (index == 1) {
      await _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Explorer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Template'),
            Tab(text: 'Data'),
            Tab(text: 'Merged'),
          ],
        ),
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
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              return TextButton.icon(
                onPressed: _canSaveCurrentTab
                    ? () => unawaited(_saveCurrentTab())
                    : null,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              );
            },
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

    if (_templateJson == null) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final previewWidget = _buildPreview();
        final editorWidget = _buildEditorTabView();

        if (isLandscape) {
          // Landscape: preview left, editor right.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: (_splitFraction * 1000).toInt(),
                child: previewWidget,
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    setState(() {
                      _splitFraction += details.delta.dx / constraints.maxWidth;
                      _splitFraction = _splitFraction.clamp(0.1, 0.9);
                    });
                  },
                  child: Container(
                    width: 8,
                    color: Colors.transparent,
                    child: const Center(child: VerticalDivider(width: 1)),
                  ),
                ),
              ),
              Expanded(
                flex: ((1 - _splitFraction) * 1000).toInt(),
                child: editorWidget,
              ),
            ],
          );
        } else {
          // Portrait: preview top, editor bottom.
          return Column(
            children: [
              Expanded(
                flex: (_splitFraction * 1000).toInt(),
                child: previewWidget,
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    setState(() {
                      _splitFraction +=
                          details.delta.dy / constraints.maxHeight;
                      _splitFraction = _splitFraction.clamp(0.1, 0.9);
                    });
                  },
                  child: Container(
                    height: 8,
                    color: Colors.transparent,
                    child: const Center(child: Divider(height: 1)),
                  ),
                ),
              ),
              Expanded(
                flex: ((1 - _splitFraction) * 1000).toInt(),
                child: editorWidget,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildPreview() {
    final cardData = _mergedJson;
    if (cardData == null) {
      return const Center(child: Text('No preview available'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdaptiveCardsRoot.map(
        key: ValueKey(jsonEncode(cardData)),
        content: cardData,
        hostConfigs: HostConfigs(),
        showDebugJson: false,
        listView: true,
      ),
    );
  }

  Widget _buildEditorTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildJsonEditor(
          data: _templateJson,
          onChanged: (updated) {
            _editedTemplateJson = updated;
          },
          readOnly: false,
          emptyMessage: 'No template loaded',
        ),
        _buildJsonEditor(
          data: _dataJson,
          onChanged: (updated) {
            _editedDataJson = updated;
          },
          readOnly: false,
          emptyMessage: 'No data loaded',
        ),
        _buildJsonEditor(
          data: _mergedJson,
          onChanged: null,
          readOnly: true,
          emptyMessage: 'No merged result available',
        ),
      ],
    );
  }

  Widget _buildJsonEditor({
    required Map<String, dynamic>? data,
    required ValueChanged<Map<String, dynamic>>? onChanged,
    required bool readOnly,
    required String emptyMessage,
  }) {
    if (data == null) {
      return Center(child: Text(emptyMessage));
    }
    return JsonEditor(
      key: ValueKey(jsonEncode(data)),
      json: jsonEncode(data),
      onChanged: (value) {
        if (!readOnly && value is Map<String, dynamic>) {
          onChanged?.call(value);
        }
      },
      enableKeyEdit: !readOnly,
      enableValueEdit: !readOnly,
      enableMoreOptions: !readOnly,
    );
  }
}
