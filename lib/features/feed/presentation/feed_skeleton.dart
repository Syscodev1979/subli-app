import 'package:flutter/material.dart';

import 'feed_palette.dart';

/// A bejegyzéskártya formáját utánzó, villódzó helyőrző.
class FeedSkeleton extends StatefulWidget {
  const FeedSkeleton({this.cards = 3, super.key});

  final int cards;

  @override
  State<FeedSkeleton> createState() => _FeedSkeletonState();
}

class _FeedSkeletonState extends State<FeedSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bone = FeedPalette.isDark(context)
        ? const Color(0xFF3A3638)
        : const Color(0xFFE4E0E2);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Column(
        children: [
          for (var index = 0; index < widget.cards; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _SkeletonCard(color: bone),
          ],
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FeedPalette.card(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bar(color: color, width: 140, height: 14),
                      const SizedBox(height: 8),
                      _Bar(color: color, width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Bar(color: color, width: double.infinity, height: 12),
            const SizedBox(height: 8),
            _Bar(color: color, width: double.infinity, height: 12),
            const SizedBox(height: 8),
            _Bar(color: color, width: 180, height: 12),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.width, required this.height});

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
