import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../adaptive_mixins.dart';
import '../additional.dart';
import '../utils.dart';

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
    child: Icon(Icons.play_arrow, size: 100.0),
  );

  @override
  void initState() {
    super.initState();

    postUrl = adaptiveMap['poster'];
    // https://adaptivecards.io/explorer/MediaSource.html
    sourceUrl = adaptiveMap['sources'][0]['url'];
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(sourceUrl),
    );

    try {
      await videoPlayerController.initialize();
    } catch (e) {
      debugPrint('$sourceUrl $e');
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
    videoPlayerController.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget getVideoPlayer() {
      return Chewie(controller: controller!);
    }

    Widget getPlaceholder() {
      return postUrl != null ? Image.network(postUrl!) : Container();
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
