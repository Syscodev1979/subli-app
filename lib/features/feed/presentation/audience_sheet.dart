import 'package:flutter/material.dart';

import '../../../app/club_colors.dart';
import '../../../app/club_config.dart';
import '../../../app/constants.dart';
import '../domain/post_audience.dart';
import 'feed_palette.dart';

/// A szerkesztő „Ki láthatja?” lapja. Legalább egy célközönség marad.
Future<List<PostAudience>?> showAudienceSheet(
  BuildContext context,
  List<PostAudience> current,
) {
  return showModalBottomSheet<List<PostAudience>>(
    context: context,
    showDragHandle: true,
    builder: (context) => _AudienceSheet(initial: current),
  );
}

class _AudienceSheet extends StatefulWidget {
  const _AudienceSheet({required this.initial});

  final List<PostAudience> initial;

  @override
  State<_AudienceSheet> createState() => _AudienceSheetState();
}

class _AudienceSheetState extends State<_AudienceSheet> {
  late List<PostAudience> _selected = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          key: const Key('audience-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Ki láthatja?',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final option in ClubConfig.audiences)
              CheckboxListTile(
                value: _selected.any((item) => item.value == option.key),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text('${option.emoji} ${option.label}'),
                subtitle: Text(option.description),
                onChanged: (checked) {
                  final choice = PostAudience.tryParse(option.key);
                  if (choice == null) return;
                  setState(() {
                    _selected = PostAudience.toggle(
                      _selected,
                      choice,
                      selected: checked ?? false,
                    );
                  });
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'A vezetőség mindig látja.',
                style: TextStyle(color: FeedPalette.muted(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('Kész'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A szerző alatti, koppintható célközönség-címke.
class AudienceChip extends StatelessWidget {
  const AudienceChip({required this.audience, required this.onTap, super.key});

  final List<PostAudience> audience;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ClubColors.of(context);
    final restricted = !PostAudience.isPublic(audience);
    final background = restricted
        ? AppColors.burgundyLight
        : colors.goldSurface;
    final foreground = restricted ? AppColors.burgundy : colors.onGoldSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('audience-chip'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: restricted
                ? Border.all(color: AppColors.burgundy, width: 1.5)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(
                  restricted ? Icons.lock_outline : Icons.groups_outlined,
                  size: 16,
                  color: foreground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ClubConfig.audienceChipLabel([
                      for (final item in audience) item.value,
                    ]),
                    maxLines: 2,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
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
