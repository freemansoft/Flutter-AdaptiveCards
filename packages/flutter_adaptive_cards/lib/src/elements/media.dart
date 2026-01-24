import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_adaptive_cards/src/utils/adaptive_image_utils.dart';
import 'package:video_player/video_player.dart';

/// Implements
/// * https://adaptivecards.io/explorer/Media.html
/// * https://adaptivecards.io/explorer/MediaSource.html
class AdaptiveMedia extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveMedia({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveMediaState createState() => AdaptiveMediaState();
}

class AdaptiveMediaState extends State<AdaptiveMedia>
    with AdaptiveElementMixin {
  late VideoPlayerController videoPlayerController;
  ChewieController? controller;

  late String sourceUrl;
  late String? postUrl;
  late String altText;

  FadeAnimation imageFadeAnim = const FadeAnimation(
    child: Icon(Icons.play_arrow, size: 100),
  );

  @override
  void initState() {
    super.initState();

    // https://adaptivecards.io/explorer/MediaSource.html
    sourceUrl = adaptiveMap['sources'][0]['url']?.toString() ?? '';

    // https://pub.dev/packages/video_player
    if (Platform.isWindows || Platform.isLinux) {
      debugPrint(
        'this will throw an `init() has not been implemented` exception'
        ' because the video player is not supported on some platforms',
      );
    }

    // We could use mediaConfig.allowInlinePlayback to decide whether to initialize player
    // but for now we'll respect it as a hint for the UI if needed.
    unawaited(initializePlayer());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final resolver = InheritedReferenceResolver.of(context).resolver;
    final mediaConfig = resolver.getMediaConfig();

    postUrl = adaptiveMap['poster']?.toString() ?? mediaConfig?.defaultPoster;
    if (postUrl != null && postUrl!.isEmpty) postUrl = null;
  }

  Future<void> initializePlayer() async {
    videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(sourceUrl),
    );

    try {
      await videoPlayerController.initialize();
    } catch (e) {
      debugPrint(
        'video not supported on this platform: $sourceUrl $e',
      );
      rethrow;
    }

    controller = ChewieController(
      aspectRatio: 3 / 2,
      autoPlay: false,
      looping: true,
      videoPlayerController: videoPlayerController,
    );

    setState(() {});
  }

  @override
  void dispose() {
    unawaited(videoPlayerController.dispose());
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget getVideoPlayer() {
      return Chewie(controller: controller!);
    }

    Widget getPlaceholder() {
      return postUrl != null
          ? AdaptiveImageUtils.getImage(postUrl!)
          : Container();
    }

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: controller == null ? getPlaceholder() : getVideoPlayer(),
        ),
      ),
    );
  }
}
