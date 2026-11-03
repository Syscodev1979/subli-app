import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/club_config.dart';
import '../../../app/constants.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../auth/domain/age.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/domain/user_status.dart';
import '../../auth/presentation/user_labels.dart';
import '../../feed/presentation/author_avatar.dart';
import '../../feed/presentation/feed_error_message.dart';
import '../data/group_repository.dart';
import '../data/member_admin_actions.dart';
import '../domain/member_directory.dart';
import '../domain/training_group.dart';
import 'member_chips.dart';

/// Az összes regisztrált tag. Csak a kijelölt admin éri el.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider);
    final groups = ref.watch(groupsProvider);
    return Scaffold(
      appBar: _bar(context),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(feedErrorMessage(error, saving: false)),
          ),
        ),
        data: (members) => MembersDirectoryView(
          members: members,
          groups: groups.asData?.value ?? const [],
          onOpen: (user) => context.push(AppRoutes.memberAdmin(user.id)),
          onGroups: () => context.push(AppRoutes.groups),
        ),
      ),
    );
  }

  ClubAppBar _bar(BuildContext context) {
    return ClubAppBar(
      leading: IconButton(
        tooltip: 'Vissza a hírfolyamra',
        onPressed: () => context.go(AppRoutes.feed),
        icon: const Icon(Icons.arrow_back),
      ),
    );
  }
}

class MembersDirectoryView extends StatefulWidget {
  const MembersDirectoryView({
    required this.members,
    required this.groups,
    required this.onOpen,
    required this.onGroups,
    super.key,
  });

  final List<AppUser> members;
  final List<TrainingGroup> groups;
  final ValueChanged<AppUser> onOpen;
  final VoidCallback onGroups;

  @override
  State<MembersDirectoryView> createState() => _MembersDirectoryViewState();
}

class _MembersDirectoryViewState extends State<MembersDirectoryView> {
  final _search = TextEditingController();
  UserStatus? _status;
  UserRole? _role;
  String? _groupId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = memberCounts(widget.members);
    final visible = filterMembers(
      widget.members,
      MemberDirectoryQuery(
        search: _search.text,
        status: _status,
        role: _role,
        groupId: _groupId,
      ),
    );
    final date = DateFormat.yMMMd('hu');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${counts.active} aktív · ${counts.pending} várakozó · ${counts.suspended} felfüggesztett',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Keresés név vagy e-mail alapján',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final status in UserStatus.values)
                    FilterChip(
                      label: Text(status.labelHu),
                      selected: _status == status,
                      onSelected: (selected) {
                        setState(() => _status = selected ? status : null);
                      },
                    ),
                  for (final role in UserRole.assignable)
                    FilterChip(
                      label: Text(role.labelHu),
                      selected: _role == role,
                      onSelected: (selected) {
                        setState(() => _role = selected ? role : null);
                      },
                    ),
                  for (final group in widget.groups)
                    FilterChip(
                      label: Text(group.name),
                      selected: _groupId == group.id,
                      onSelected: (selected) {
                        setState(() => _groupId = selected ? group.id : null);
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.group_work_outlined, size: 18),
                    label: const Text('Csoportok'),
                    onPressed: widget.onGroups,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = visible[index];
              final minor = user.birthDate != null && isUnder18(user.birthDate!);
              return Card(
                child: InkWell(
                  onTap: () => widget.onOpen(user),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthorAvatar(
                          name: user.name,
                          photoUrl: user.photoUrl,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name),
                              Text(user.email),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(user.role.labelHu),
                                  ),
                                  MemberStatusChip(
                                    label: user.status.labelHu,
                                    color: statusColor(user.status.value),
                                  ),
                                  if (!ClubConfig.enforceAdultsOnly && minor)
                                    const Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text('Kiskorú'),
                                    ),
                                ],
                              ),
                              Text(
                                [
                                  ?ClubConfig.beltByKey(user.beltRank)?.caption,
                                  date.format(user.createdAt.toLocal()),
                                ].join(' · '),
                              ),
                              GroupChips(groups: groupsOf(user, widget.groups)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
