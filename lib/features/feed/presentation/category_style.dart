import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../domain/post_category.dart';

/// A kategória ikonja és színei. A kitöltött chip a saját színét kapja.
class CategoryStyle {
  const CategoryStyle({
    required this.icon,
    required this.color,
    required this.onColor,
    required this.foreground,
  });

  final IconData icon;
  final Color color;
  final Color onColor;
  final Color foreground;

  static CategoryStyle of(PostCategory category, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (category) {
      PostCategory.news => CategoryStyle(
        icon: Icons.article_outlined,
        color: const Color(0xFF5E5A5C),
        onColor: Colors.white,
        foreground: dark ? const Color(0xFFC8C2C4) : const Color(0xFF5E5A5C),
      ),
      PostCategory.announcement => CategoryStyle(
        icon: Icons.campaign,
        color: AppColors.burgundy,
        onColor: Colors.white,
        foreground: dark ? AppColors.burgundyDarkMode : AppColors.burgundy,
      ),
      PostCategory.result => const CategoryStyle(
        icon: Icons.emoji_events,
        color: AppColors.gold,
        onColor: Color(0xFF2B2308),
        foreground: AppColors.gold,
      ),
      PostCategory.training => CategoryStyle(
        icon: Icons.sports_martial_arts,
        color: AppColors.accentGreen,
        onColor: Colors.white,
        foreground: dark ? AppColors.mediaPhotoDark : AppColors.accentGreen,
      ),
      PostCategory.event => CategoryStyle(
        icon: Icons.calendar_month,
        color: const Color(0xFF2D6CDF),
        onColor: Colors.white,
        foreground: dark ? AppColors.mediaCameraDark : const Color(0xFF2D6CDF),
      ),
    };
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color = AppColors.burgundy,
    this.onColor = Colors.white,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? onColor
        : Theme.of(context).colorScheme.onSurface;
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? null
                : Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? onColor : color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    required this.selected,
    required this.onSelected,
    this.includeAll = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    super.key,
  });

  /// `null` az Összes, ha [includeAll] igaz.
  final PostCategory? selected;
  final ValueChanged<PostCategory?> onSelected;
  final bool includeAll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          if (includeAll) ...[
            CategoryChip(
              label: 'Összes',
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            const SizedBox(width: 8),
          ],
          for (final category in PostCategory.values) ...[
            CategoryChip(
              label: category.label,
              icon: CategoryStyle.of(category, brightness).icon,
              color: CategoryStyle.of(category, brightness).color,
              onColor: CategoryStyle.of(category, brightness).onColor,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
            if (category != PostCategory.event) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class CategoryLabel extends StatelessWidget {
  const CategoryLabel({required this.category, super.key});

  final PostCategory category;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category, Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.foreground.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 12, color: style.foreground),
            const SizedBox(width: 4),
            Text(
              category.label,
              style: TextStyle(
                color: style.foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
