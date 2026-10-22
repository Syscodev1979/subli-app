import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme_controller.dart';
import '../../app/theme_preference.dart';

/// Világos, sötét vagy a telefon témája.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themePreferenceProvider);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.contrast_outlined),
          title: Text(
            'Megjelenés',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        for (final preference in ThemePreference.values)
          ListTile(
            selected: preference == selected,
            leading: Icon(
              preference == selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(preference.label),
            onTap: () {
              ref.read(themePreferenceProvider.notifier).select(preference);
            },
          ),
      ],
    );
  }
}
