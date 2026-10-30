import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../data/group_repository.dart';
import '../domain/training_group.dart';

class GroupChips extends StatelessWidget {
  const GroupChips({required this.groups, super.key});

  final List<TrainingGroup> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final group in groups)
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(group.name),
            backgroundColor: group.colorValue.withValues(alpha: 0.16),
            side: BorderSide(color: group.colorValue),
            labelStyle: TextStyle(color: group.colorValue),
          ),
      ],
    );
  }
}

class AssignedGroups extends ConsumerWidget {
  const AssignedGroups({required this.groupIds, super.key});

  final List<String> groupIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider).asData?.value ?? const <TrainingGroup>[];
    final mine = [
      for (final group in groups)
        if (groupIds.contains(group.id)) group,
    ];
    return GroupChips(groups: mine);
  }
}

class MemberStatusChip extends StatelessWidget {
  const MemberStatusChip({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.14),
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}

Color statusColor(String status) {
  return switch (status) {
    'active' => AppColors.accentGreen,
    'pending' => AppColors.gold,
    'suspended' => AppColors.burgundy,
    _ => const Color(0xFF6B6570),
  };
}
