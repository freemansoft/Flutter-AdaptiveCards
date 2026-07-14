import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../utils/test_utils.dart';

/// 1x1 transparent PNG, so the poster renders from memory with no network I/O.
const String _posterDataUri =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// Fake platform so `VideoPlayerController.initialize()` actually succeeds in a
/// widget test, letting us observe *when* the player is created.
class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int createCount = 0;
  int playCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    createCount++;
    return 1;
  }

  /// Reports the video as initialized as soon as the controller subscribes.
  /// Emitting any earlier would race the subscription and be dropped.
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    late final StreamController<VideoEvent> events;
    events = StreamController<VideoEvent>(
      onListen: () {
        events.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 10),
            size: const Size(640, 480),
          ),
        );
      },
    );
    return events.stream;
  }

  @override
  Future<void> play(int playerId) async => playCount++;

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.expand();
}

Map<String, dynamic> _cardWithMedia() => {
  'type': 'AdaptiveCard',
  'body': [
    {
      'type': 'Media',
      'id': 'clip',
      'poster': _posterDataUri,
      'altText': 'Overview video',
      'sources': [
        {'url': 'https://example.com/clip.mp4'},
      ],
    },
  ],
};

void main() {
  late _FakeVideoPlayerPlatform fake;

  setUp(() {
    fake = _FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fake;
  });

  testWidgets(
    'Media shows the poster with a play affordance and creates no player '
    'until the user asks to play',
    (tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: _cardWithMedia(),
          title: 'media poster before playback',
          scrollable: true,
        ),
      );
      await tester.pumpAndSettle();

      // The poster is what the user sees before playback, not the video.
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byType(Chewie), findsNothing);

      // Nothing is fetched until the user opts in.
      expect(fake.createCount, 0);
    },
  );

  testWidgets('tapping the Media poster starts playback and shows the player', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _cardWithMedia(),
        title: 'media poster tap',
        scrollable: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(fake.createCount, 1);
    expect(find.byType(Chewie), findsOneWidget);
    expect(fake.playCount, greaterThan(0));
  });
}
