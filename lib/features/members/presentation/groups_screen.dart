import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../../feed/presentation/feed_error_message.dart';
import '../data/group_repository.dart';
import '../domain/training_group.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    return Scaffold(
      appBar: _bar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Új csoport'),
      ),
      body: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(feedErrorMessage(error, saving: false)),
        ),
        data: (list) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (list.isEmpty) ...[
                const Text(
                  'Még nincs csoport. Ezeket felajánljuk, de nem kötelező létrehozni:',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final suggestion in suggestedGroups)
                      ActionChip(
                        label: Text(suggestion.name),
                        onPressed: () => ref.read(groupRepositoryProvider).createGroup(
                          name: suggestion.name,
                          color: suggestion.color,
                          description: suggestion.description,
                        ),
                      ),
                  ],
                ),
              ],
              for (final group in list)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: group.colorValue),
                    title: Text(group.name),
                    subtitle: group.description.isEmpty
                        ? null
                        : Text(group.description),
                    onTap: () => _edit(context, ref, group),
                    trailing: IconButton(
                      tooltip: 'Törlés',
                      onPressed: () => _delete(context, ref, group),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  ClubAppBar _bar(BuildContext context) {
    return ClubAppBar(
      leading: IconButton(
        tooltip: 'Vissza',
        onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.members),
        icon: const Icon(Icons.arrow_back),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, TrainingGroup? group) async {
    final name = TextEditingController(text: group?.name ?? '');
    final description = TextEditingController(text: group?.description ?? '');
    var color = group?.color ?? '#6B1E2E';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(group == null ? 'Új csoport' : 'Csoport szerkesztése'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Név'),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  TextField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Leírás'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final hex in const [
                        '#2E7D32',
                        '#1F6FEB',
                        '#6B1E2E',
                        '#C9A227',
                      ])
                        ChoiceChip(
                          label: const Text(' '),
                          selected: color == hex,
                          backgroundColor: _color(hex),
                          selectedColor: _color(hex),
                          onSelected: (_) => setLocal(() => color = hex),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Mégse'),
                ),
                FilledButton(
                  onPressed: name.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Mentés'),
                ),
              ],
            );
          },
        );
      },
    );
    final groupName = name.text.trim();
    final groupDescription = description.text.trim();
    name.dispose();
    description.dispose();
    if (saved != true || groupName.isEmpty) return;
    try {
      final repository = ref.read(groupRepositoryProvider);
      if (group == null) {
        await repository.createGroup(
          name: groupName,
          color: color,
          description: groupDescription,
        );
      } else {
        await repository.updateGroup(
          id: group.id,
          name: groupName,
          color: color,
          description: groupDescription,
          createdAt: group.createdAt,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, TrainingGroup group) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Csoport törlése'),
        content: Text('${group.name} kikerül a tagok csoportjaiból is.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(group.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    }
  }
}

Color _color(String hex) {
  final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
  return Color(0xFF000000 | value);
}
