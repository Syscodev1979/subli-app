import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import 'feed_palette.dart';

/// A hírfolyam tetején görgethető keresősáv.
class FeedSearchBar extends StatelessWidget {
  const FeedSearchBar({
    required this.controller,
    required this.focusNode,
    required this.active,
    required this.onChanged,
    required this.onClear,
    required this.onCancel,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('feed-search'),
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: FeedPalette.title(context), fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Keresés a Hírfolyamban…',
                hintStyle: TextStyle(color: FeedPalette.muted(context)),
                prefixIcon: Icon(
                  Icons.search,
                  color: FeedPalette.muted(context),
                ),
                suffixIcon: active && hasText
                    ? IconButton(
                        tooltip: 'Törlés',
                        onPressed: onClear,
                        icon: Icon(
                          Icons.close,
                          color: FeedPalette.muted(context),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: FeedPalette.field(context),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (active)
            TextButton(
              onPressed: onCancel,
              child: Text(
                'Mégse',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.burgundyDarkMode
                      : AppColors.burgundy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
