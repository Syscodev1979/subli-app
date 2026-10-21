import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../domain/post.dart';
import 'feed_palette.dart';
import 'post_video_view.dart';

/// A kártyán látható képrács és videó.
class PostMediaGallery extends StatelessWidget {
  const PostMediaGallery({required this.media, super.key});

  final List<PostMedia> media;

  @override
  Widget build(BuildContext context) {
    final images = [
      for (final item in media)
        if (item.type == PostMediaType.image) item,
    ];
    PostMedia? video;
    for (final item in media) {
      if (item.type == PostMediaType.video) {
        video = item;
        break;
      }
    }
    return Column(
      children: [
        if (images.isNotEmpty) _ImageGrid(images: images),
        if (video != null) PostVideoView(media: video),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images});

  final List<PostMedia> images;

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return AspectRatio(
        aspectRatio: _ratio(images.first),
        child: _cell(context, 0),
      );
    }
    if (images.length == 2) {
      return SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(child: _cell(context, 0)),
            const SizedBox(width: 2),
            Expanded(child: _cell(context, 1)),
          ],
        ),
      );
    }
    if (images.length == 3) {
      return SizedBox(
        height: 280,
        child: Row(
          children: [
            Expanded(child: _cell(context, 0)),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _cell(context, 1)),
                  const SizedBox(height: 2),
                  Expanded(child: _cell(context, 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final extra = images.length > 4 ? images.length - 4 : 0;
    return SizedBox(
      height: 280,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _cell(context, 0)),
                const SizedBox(width: 2),
                Expanded(child: _cell(context, 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _cell(context, 2)),
                const SizedBox(width: 2),
                Expanded(child: _cell(context, 3, extra: extra)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int index, {int extra = 0}) {
    return GestureDetector(
      onTap: () => _open(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: images[index].url,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                ColoredBox(color: FeedPalette.field(context)),
            errorWidget: (context, url, error) =>
                ColoredBox(color: FeedPalette.field(context)),
          ),
          if (extra > 0)
            ColoredBox(
              color: const Color(0x99000000),
              child: Center(
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => MediaViewer(images: images, initialIndex: index),
      ),
    );
  }

  double _ratio(PostMedia image) {
    final width = image.width;
    final height = image.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 4 / 3;
    }
    return (width / height).clamp(0.7, 1.8);
  }
}

/// Teljes képernyős képlapozó, csíptetős nagyítással.
class MediaViewer extends StatefulWidget {
  const MediaViewer({
    required this.images,
    required this.initialIndex,
    super.key,
  });

  final List<PostMedia> images;
  final int initialIndex;

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late var _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index].url,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
