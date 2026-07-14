import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/models/media_source.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
import 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/media_caption_source.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Implements
/// * https://adaptivecards.io/explorer/Media.html
/// * https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/media
/// * https://adaptivecards.io/explorer/MediaSource.html
/// * https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/media-source
class AdaptiveMedia extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
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

  /// Caption tracks parsed from `captionSources`.
  /// Rendering onto the video surface is host-dependent and not yet wired.
  late List<CaptionSource> captionSources;

  /// Whether the user has asked to play, which is what gates creating the
  /// network player. False until the poster is tapped.
  bool playbackRequested = false;

  @override
  void initState() {
    super.initState();

    // https://adaptivecards.io/explorer/MediaSource.html
    final List<MediaSource> sources = mediaSourcesFromJsonList(
      adaptiveMap['sources'],
    );
    sourceUrl = sources.isNotEmpty ? sources[0].url : '';

    // Accessibility label for the poster image; read before first build so the
    // placeholder path never reads an uninitialized field.
    altText = adaptiveMap['altText']?.toString() ?? '';

    // TODO(captions): render captionSources as VTT tracks on the video surface.
    captionSources = captionSourcesFromJsonList(adaptiveMap['captionSources']);

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

    // The player is created lazily: the poster is the click-to-play surface, so
    // no network player is opened until the user asks for playback. See
    // [startPlayback].
  }

  /// URI policy for [sourceUrl]; defaults to the safe standard policy until an
  /// ancestor [InheritedAdaptiveCardSecurityPolicy] is resolved in
  /// [didChangeDependencies].
  AdaptiveUriPolicy _uriPolicy = AdaptiveUriPolicy.standard;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _uriPolicy = InheritedAdaptiveCardSecurityPolicy.uriPolicyOf(context);

    final resolver = styleResolver;
    final mediaConfig = resolver.getMediaConfig();

    postUrl = adaptiveMap['poster']?.toString() ?? mediaConfig?.defaultPoster;
    if (postUrl != null && postUrl!.isEmpty) postUrl = null;
  }

  /// Handles the user tapping the poster: the card's `poster` is the
  /// click-to-play surface, so this is the only path that opens the player.
  Future<void> startPlayback() async {
    if (playbackRequested) return;
    setState(() => playbackRequested = true);
    await initializePlayer();
  }

  /// Initializes [videoPlayerController] and [controller] from [sourceUrl].
  ///
  /// [sourceUrl] comes from untrusted card JSON, so it is validated against the
  /// active URI policy before the network player is created; a denied URL skips
  /// initialization (leaving [videoPlayerController] null).
  Future<void> initializePlayer() async {
    if (_uriPolicy.validate(sourceUrl) case AdaptiveUriDenied(:final reason)) {
      assert(() {
        developer.log(
          'media source $sourceUrl blocked by policy: $reason',
          name: runtimeType.toString(),
        );
        return true;
      }());
      return;
    }
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
      // The player only exists because the user pressed play on the poster, so
      // playback starts as soon as it is ready.
      autoPlay: true,
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
    // A host swapping the source (e.g. a signed URL) on a card the user has not
    // played yet must not open a player behind their back; the new url is
    // picked up when they press play.
    if (!playbackRequested) {
      setState(() {});
      return;
    }
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

    // The poster is the click-to-play surface shown until the user starts
    // playback, per the Media spec — not a loading spinner. It also covers the
    // cases where there is no player at all (unsupported platform, or a source
    // the URI policy denied), where it stays put.
    Widget getPoster() {
      return Semantics(
        button: true,
        // The author's altText is the accessible name; the library owns no
        // strings, so an unlabeled poster stays unlabeled rather than
        // announcing an untranslated 'Play'.
        label: altText.isEmpty ? null : altText,
        child: GestureDetector(
          onTap: startPlayback,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Already named by the Semantics button above; labeling the image
              // too would announce the name twice.
              if (postUrl != null) AdaptiveImageUtils.getImage(postUrl!),
              const Center(child: Icon(Icons.play_arrow, size: 100)),
            ],
          ),
        ),
      );
    }

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: controller == null ? getPoster() : getVideoPlayer(),
          ),
        ),
      ),
    );
  }
}
