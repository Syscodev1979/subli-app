import 'package:flutter/material.dart';

import '../../../app/club_config.dart';
import 'feed_palette.dart';

/// Csatolt dokumentum: típusikon, középen rövidített név, méret és törlés.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    this.onTap,
    this.onRemove,
    super.key,
  });

  final String name;
  final int sizeBytes;
  final String? mimeType;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final kind =
        ClubConfig.documentTypeForMime(mimeType)?.kind ??
        ClubConfig.documentTypeForName(name)?.kind ??
        DocumentKind.pdf;
    final style = _style(kind);
    return Material(
      color: FeedPalette.field(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(style.icon, color: style.foreground),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      middleEllipsis(name),
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: FeedPalette.title(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatFileSize(sizeBytes),
                      style: TextStyle(
                        color: FeedPalette.muted(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Törlés',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindStyle {
  const _KindStyle(this.icon, this.foreground, this.background);

  final IconData icon;
  final Color foreground;
  final Color background;
}

_KindStyle _style(DocumentKind kind) {
  return switch (kind) {
    DocumentKind.pdf => const _KindStyle(
      Icons.picture_as_pdf,
      Color(0xFFC62828),
      Color(0xFFFDECEC),
    ),
    DocumentKind.word => const _KindStyle(
      Icons.description,
      Color(0xFF1565C0),
      Color(0xFFE8F1FB),
    ),
    DocumentKind.excel => const _KindStyle(
      Icons.table_chart,
      Color(0xFF2E7D32),
      Color(0xFFE7F6EA),
    ),
    DocumentKind.powerpoint => const _KindStyle(
      Icons.slideshow,
      Color(0xFFE65100),
      Color(0xFFFFF3E8),
    ),
  };
}

/// Hosszú fájlnév közepét cseréli három pontra, a kiterjesztés megmarad.
String middleEllipsis(String name, {int max = 28}) {
  if (name.length <= max) return name;
  final dot = name.lastIndexOf('.');
  final ext = dot > 0 && name.length - dot <= 6 ? name.substring(dot) : '';
  final room = max - ext.length - 1;
  if (room < 4) return '${name.substring(0, max - 1)}…';
  final head = room ~/ 2;
  final tail = room - head;
  final base = ext.isEmpty ? name : name.substring(0, name.length - ext.length);
  if (base.length <= head + tail) return name;
  return '${base.substring(0, head)}…${base.substring(base.length - tail)}$ext';
}

/// Például „2,4 MB”.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final value = bytes < 1024 * 1024 ? bytes / 1024 : bytes / (1024 * 1024);
  final unit = bytes < 1024 * 1024 ? 'KB' : 'MB';
  final text = value.toStringAsFixed(1).replaceAll('.', ',');
  final compact = text.endsWith(',0')
      ? text.substring(0, text.length - 2)
      : text;
  return '$compact $unit';
}
