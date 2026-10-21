import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../domain/post.dart';
import 'feed_palette.dart';

/// Videó előnézet. A lejátszás csak koppintásra indul.
class PostVideoView extends StatefulWidget {
  const PostVideoView({required this.media, super.key});

  final PostMedia media;

  @override
  State<PostVideoView> createState() => _PostVideoViewState();
}

class _PostVideoViewState extends State<PostVideoView> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  var _starting = false;

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie;
    final ratio = _ratio;
    if (chewie != null) {
      return AspectRatio(
        aspectRatio: ratio,
        child: Chewie(controller: chewie),
      );
    }
    final thumb = widget.media.thumbUrl;
    return AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumb != null)
            CachedNetworkImage(
              imageUrl: thumb,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  ColoredBox(color: FeedPalette.field(context)),
              errorWidget: (context, url, error) =>
                  ColoredBox(color: FeedPalette.field(context)),
            )
          else
            ColoredBox(color: FeedPalette.field(context)),
          Center(
            child: _starting
                ? const CircularProgressIndicator()
                : IconButton(
                    tooltip: 'Lejátszás',
                    onPressed: _play,
                    icon: const Icon(Icons.play_circle_fill, size: 64),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x66000000),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double get _ratio {
    final width = widget.media.width;
    final height = widget.media.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 16 / 9;
    }
    return (width / height).clamp(0.6, 1.9);
  }

  Future<void> _play() async {
    if (_starting || _chewie != null) return;
    setState(() => _starting = true);
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.media.url),
    );
    try {
      await controller.initialize();
    } catch (error) {
      await controller.dispose();
      if (mounted) setState(() => _starting = false);
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    final chewie = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
    );
    setState(() {
      _video = controller;
      _chewie = chewie;
      _starting = false;
    });
  }
}
