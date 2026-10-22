import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/constants.dart';
import '../domain/search_keywords.dart';

final _linkPattern = RegExp(
  r'(https?:\/\/[^\s]+|www\.[^\s]+)',
  caseSensitive: false,
);

/// Szöveg, amelyben a http és www linkek megnyithatók.
class LinkText extends StatefulWidget {
  const LinkText({
    required this.text,
    required this.style,
    this.maxLines,
    this.highlights = const [],
    super.key,
  });

  final String text;
  final TextStyle style;
  final int? maxLines;
  final List<String> highlights;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  final List<_Segment> _segments = [];

  @override
  void initState() {
    super.initState();
    _setSegments(widget.text);
  }

  @override
  void didUpdateWidget(LinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.highlights != widget.highlights) {
      final previous = List<_Segment>.from(_segments);
      _setSegments(widget.text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final segment in previous) {
          segment.recognizer?.dispose();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final segment in _segments) {
      segment.recognizer?.dispose();
    }
    super.dispose();
  }

  void _setSegments(String text) {
    _segments
      ..clear()
      ..addAll(_parse(text));
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    return Text.rich(
      TextSpan(
        children: [
          for (final segment in _segments)
            if (segment.url != null)
              TextSpan(
                text: segment.text,
                style: style.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                recognizer: segment.recognizer,
              )
            else
              ..._highlighted(segment.text, style, context),
        ],
      ),
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null
          ? TextOverflow.visible
          : TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> _highlighted(
    String text,
    TextStyle style,
    BuildContext context,
  ) {
    final ranges = highlightRanges(text, widget.highlights);
    if (ranges.isEmpty) return [TextSpan(text: text, style: style)];
    final mark = Theme.of(context).brightness == Brightness.dark
        ? AppColors.goldDarkSurface
        : AppColors.goldLight;
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, range.start), style: style),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: style.copyWith(backgroundColor: mark),
        ),
      );
      cursor = range.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }
    return spans;
  }

  List<_Segment> _parse(String text) {
    final segments = <_Segment>[];
    var start = 0;
    for (final match in _linkPattern.allMatches(text)) {
      if (match.start > start) {
        segments.add(_Segment(text.substring(start, match.start)));
      }
      final raw = match.group(0) ?? '';
      final trimmed = raw.replaceFirst(RegExp(r'[),.!?]+$'), '');
      final trailing = raw.substring(trimmed.length);
      segments.add(
        _Segment(
          trimmed,
          url: trimmed,
          recognizer: TapGestureRecognizer()..onTap = () => _open(trimmed),
        ),
      );
      if (trailing.isNotEmpty) segments.add(_Segment(trailing));
      start = match.end;
    }
    if (start < text.length) segments.add(_Segment(text.substring(start)));
    if (segments.isEmpty) segments.add(_Segment(text));
    return segments;
  }

  Future<void> _open(String raw) async {
    final target = raw.toLowerCase().startsWith('www.') ? 'https://$raw' : raw;
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Segment {
  _Segment(this.text, {this.url, this.recognizer});

  final String text;
  final String? url;
  final TapGestureRecognizer? recognizer;
}
