import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class Video {
  Video._privateConstructor();
  static final Video _instance = Video._privateConstructor();
  factory Video() {
    return _instance;
  }

  Widget Youtube(String videoId) {
    // final controller = YoutubePlayerController();
    // controller.loadVideoById(videoId: videoId);
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
    return YoutubePlayer(
      controller: controller,
      aspectRatio: 16 / 9,
    );
  }
}
