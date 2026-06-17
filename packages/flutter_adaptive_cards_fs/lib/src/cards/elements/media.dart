import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/models/media_source.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Implements
/// * https://adaptivecards.io/explorer/Media.html
/// * https://adaptivecards.io/explorer/MediaSource.html
class AdaptiveMedia extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a media player from [adaptiveMap] JSON.
  AdaptiveMedia({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }
  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveMediaState createState() => AdaptiveMediaState();
}

/// State for [AdaptiveMedia]; initializes video playback and poster image.
class AdaptiveMediaState extends ConsumerState<AdaptiveMedia>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Underlying [VideoPlayerController] for the first `sources` entry.
  VideoPlayerController? videoPlayerController;

  /// Chewie UI wrapper; null until the video is initialized.
  ChewieController? controller;

  /// URL of the primary [MediaSource] from `sources`.
  late String sourceUrl;

  /// Poster image URL from `poster` or HostConfig default.
  late String? postUrl;

  /// Accessibility label for the poster image.
  late String altText;

  /// Placeholder fade animation shown before the player is ready.
  FadeAnimation imageFadeAnim = const FadeAnimation(
    child: Icon(Icons.play_arrow, size: 100),
  );

  @override
  void initState() {
    super.initState();

    // https://adaptivecards.io/explorer/MediaSource.html
    final List<MediaSource> sources = mediaSourcesFromJsonList(
      adaptiveMap['sources'],
    );
    sourceUrl = sources.isNotEmpty ? sources[0].url : '';

    // https://pub.dev/packages/video_player
    if (Platform.isWindows || Platform.isLinux) {
      assert(() {
        developer.log(
          'this will throw an `init() has not been implemented` exception'
          ' because the video player is not supported on some platforms',
          name: runtimeType.toString(),
        );
        return true;
      }());
    }

    // We could use mediaConfig.allowInlinePlayback to decide whether to initialize player
    // but for now we'll respect it as a hint for the UI if needed.
    unawaited(initializePlayer());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final resolver = styleResolver;
    final mediaConfig = resolver.getMediaConfig();

    postUrl = adaptiveMap['poster']?.toString() ?? mediaConfig?.defaultPoster;
    if (postUrl != null && postUrl!.isEmpty) postUrl = null;
  }

  /// Initializes [videoPlayerController] and [controller] from [sourceUrl].
  Future<void> initializePlayer() async {
    final player = VideoPlayerController.networkUrl(
      Uri.parse(sourceUrl),
    );
    videoPlayerController = player;

    try {
      await player.initialize();
    } on Object catch (e) {
      assert(() {
        developer.log(
          'video $sourceUrl not supported on this platform: $e',
          name: runtimeType.toString(),
        );
        return true;
      }());
      if (videoPlayerController == player) {
        videoPlayerController = null;
      }
      await player.dispose();
      return;
    }

    if (!mounted || videoPlayerController != player) {
      await player.dispose();
      return;
    }

    controller = ChewieController(
      aspectRatio: 3 / 2,
      autoPlay: false,
      looping: true,
      videoPlayerController: player,
    );

    setState(() {});
  }

  Future<void> _reinitializePlayer(String newUrl) async {
    sourceUrl = newUrl;
    controller?.dispose();
    controller = null;
    final previousPlayer = videoPlayerController;
    videoPlayerController = null;
    if (previousPlayer != null) {
      await previousPlayer.dispose();
    }
    if (!mounted) return;
    await initializePlayer();
  }

  @override
  void dispose() {
    final player = videoPlayerController;
    if (player != null) {
      unawaited(player.dispose());
    }
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Map<String, dynamic>?>(
      resolvedElementProvider(id),
      (previous, next) {
        final sources = mediaSourcesFromJsonList(next?['sources']);
        final nextUrl = sources.isNotEmpty ? sources[0].url : '';
        if (nextUrl == sourceUrl) return;
        unawaited(_reinitializePlayer(nextUrl));
      },
    );

    Widget getVideoPlayer() {
      return Chewie(controller: controller!);
    }

    Widget getPlaceholder() {
      return postUrl != null
          ? AdaptiveImageUtils.getImage(postUrl!, semanticsLabel: altText)
          : Container();
    }

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: controller == null ? getPlaceholder() : getVideoPlayer(),
          ),
        ),
      ),
    );
  }
}
