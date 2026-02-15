import 'dart:async';

import 'package:watcher/watcher.dart';

/// Service that watches a file for changes.
class FileWatcherService {
  StreamSubscription<WatchEvent>? _subscription;
  final _controller = StreamController<void>.broadcast();

  /// Stream that emits an event whenever the watched file changes.
  Stream<void> get fileChangedStream => _controller.stream;

  /// Starts watching the file at [path].
  ///
  /// If a file was already being watched, the previous watch is cancelled.
  void watchFile(String path) {
    unawaited(_subscription?.cancel());

    // watcher doesn't always work perfectly for single files across all
    // platforms. Sometimes it's better to watch the directory, but for now
    // let's try FileWatcher. If FileWatcher proves unreliable, we might need a
    // PollingFileWatcher or directory watch.
    final watcher = FileWatcher(path);

    _subscription = watcher.events.listen((event) {
      if (event.type == ChangeType.MODIFY) {
        _controller.add(null);
      }
    });
  }

  /// Stops watching the current file.
  void stopWatching() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  /// Disposes resources used by the service.
  void dispose() {
    stopWatching();
    unawaited(_controller.close());
  }
}
