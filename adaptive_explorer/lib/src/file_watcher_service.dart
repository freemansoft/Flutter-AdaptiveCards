import 'dart:async';

import 'package:watcher/watcher.dart';

/// Service that watches files for changes.
class FileWatcherService {
  StreamSubscription<WatchEvent>? _templateSubscription;
  StreamSubscription<WatchEvent>? _dataSubscription;
  final _controller = StreamController<void>.broadcast();

  /// Stream that emits an event whenever a watched file changes.
  Stream<void> get fileChangedStream => _controller.stream;

  /// Starts watching the template file at [path].
  ///
  /// If a template file was already being watched, the previous watch is
  /// cancelled.
  void watchTemplateFile(String path) {
    unawaited(_templateSubscription?.cancel());
    final watcher = FileWatcher(path);
    _templateSubscription = watcher.events.listen((event) {
      if (event.type == ChangeType.MODIFY) {
        _controller.add(null);
      }
    });
  }

  /// Starts watching the data file at [path].
  ///
  /// If a data file was already being watched, the previous watch is cancelled.
  void watchDataFile(String path) {
    unawaited(_dataSubscription?.cancel());
    final watcher = FileWatcher(path);
    _dataSubscription = watcher.events.listen((event) {
      if (event.type == ChangeType.MODIFY) {
        _controller.add(null);
      }
    });
  }

  /// Stops watching the template file.
  void stopWatchingTemplate() {
    unawaited(_templateSubscription?.cancel());
    _templateSubscription = null;
  }

  /// Stops watching the data file.
  void stopWatchingData() {
    unawaited(_dataSubscription?.cancel());
    _dataSubscription = null;
  }

  /// Stops watching all files.
  void stopWatching() {
    stopWatchingTemplate();
    stopWatchingData();
  }

  /// Disposes resources used by the service.
  void dispose() {
    stopWatching();
    unawaited(_controller.close());
  }
}
