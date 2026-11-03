import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/club_config.dart';
import '../../../app/constants.dart';
import '../../../core/utils/hungarian_date.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/admin_identity.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/domain/user_status.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../../auth/presentation/user_labels.dart';
import '../../chat/data/chat_providers.dart';
import '../../feed/presentation/feed_error_message.dart';
import '../data/group_repository.dart';
import '../data/member_admin_actions.dart';
import '../domain/training_group.dart';

/// Admin adatlap egy tagról.
class MemberAdminScreen extends ConsumerWidget {
  const MemberAdminScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authGateProvider).asData?.value;
    final users = ref.watch(allUsersProvider);
    final groups = ref.watch(groupsProvider);
    final actor = session is AuthSignedIn ? session.user : null;
    return users.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text(feedErrorMessage(error, saving: false))),
      ),
      data: (list) {
        AppUser? member;
        for (final user in list) {
          if (user.id == userId) member = user;
        }
        if (member == null || actor == null) {
          return const Scaffold(
            body: Center(child: Text('A tag nem található.')),
          );
        }
        return MemberAdminView(
          member: member,
          actor: actor,
          groups: groups.asData?.value ?? const [],
          candidates: list,
        );
      },
    );
  }
}

class MemberAdminView extends ConsumerStatefulWidget {
  const MemberAdminView({
    required this.member,
    required this.actor,
    required this.groups,
    required this.candidates,
    this.onDelete,
    super.key,
  });

  final AppUser member;
  final AppUser actor;
  final List<TrainingGroup> groups;
  final List<AppUser> candidates;

  /// Tesztben a törlés helye. Élesben a Cloud Function fut.
  final Future<void> Function()? onDelete;

  @override
  ConsumerState<MemberAdminView> createState() => _MemberAdminViewState();
}

class _MemberAdminViewState extends ConsumerState<MemberAdminView> {
  late final TextEditingController _name;
  late UserRole _role;
  late UserStatus _status;
  late String? _belt;
  late DateTime? _birthDate;
  late Set<String> _groupIds;
  late Set<String> _childIds;
  late Set<String> _parentIds;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _apply(widget.member);
  }

  @override
  void didUpdateWidget(MemberAdminView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.member.id != widget.member.id) _apply(widget.member);
  }

  void _apply(AppUser member) {
    _name = TextEditingController(text: member.name);
    _role = member.role;
    _status = member.status;
    _belt = ClubConfig.beltByKey(member.beltRank) == null ? null : member.beltRank;
    _birthDate = member.birthDate;
    _groupIds = {...member.groupIds};
    _childIds = {...member.childIds};
    _parentIds = {...member.parentIds};
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _locked {
    return widget.member.id == widget.actor.id ||
        isDesignatedAdmin(widget.member) ||
        widget.member.role == UserRole.admin;
  }

  /// A szülő csak akkor marad a listában, ha a tag már az, és a klub nem
  /// engedi új szülő választását. Így a legördülő nem törik el.
  List<UserRole> get _roleChoices {
    final roles = [...UserRole.assignableRoles];
    if (!roles.contains(_role) && UserRole.assignable.contains(_role)) {
      roles.add(_role);
    }
    return roles;
  }

  List<UserStatus> get _statuses {
    return [
      if (widget.member.status == UserStatus.pending) UserStatus.pending,
      UserStatus.active,
      UserStatus.suspended,
      UserStatus.rejected,
    ];
  }

  Future<void> _save() async {
    final roleChanged = _role != widget.member.role;
    final statusChanged = _status != widget.member.status;
    if (roleChanged || statusChanged) {
      final accepted = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Megerősítés',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (roleChanged)
                  Text(
                    'Szerepkör: ${widget.member.role.labelHu} → ${_role.labelHu}',
                  ),
                if (statusChanged)
                  Text(
                    'Státusz: ${widget.member.status.labelHu} → ${_status.labelHu}',
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Mentés'),
                ),
              ],
            ),
          );
        },
      );
      if (accepted != true || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).saveMember(
        actorId: widget.actor.id,
        before: widget.member,
        name: _name.text,
        role: _locked ? widget.member.role : _role,
        status: _locked ? widget.member.status : _status,
        beltRank: _belt,
        groupIds: _groupIds.toList(),
        birthDate: _birthDate,
        childIds: _childIds.toList(),
        parentIds: _parentIds.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mentve.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _message() async {
    try {
      final id = await ref
          .read(chatRepositoryProvider)
          .startConversation(widget.member.id);
      if (mounted) context.push(AppRoutes.conversation(id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    }
  }

  Future<void> _suspend() async {
    setState(() => _status = UserStatus.suspended);
    await _save();
  }

  Future<void> _delete() async {
    final name = widget.member.name;
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tag végleges törlése'),
        content: Text('$name fiókja és profilja törlődik. A bejegyzései megmaradnak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mégse'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tovább'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;
    final typed = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final matches = typed.text.trim() == name.trim();
            return AlertDialog(
              title: const Text('Tag végleges törlése'),
              content: TextField(
                controller: typed,
                decoration: InputDecoration(
                  labelText: 'Írd be a tag nevét: $name',
                ),
                onChanged: (_) => setLocal(() {}),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Mégse'),
                ),
                FilledButton(
                  key: const Key('confirm-delete-member'),
                  onPressed: matches ? () => Navigator.pop(context, true) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.burgundy,
                  ),
                  child: const Text('Tag végleges törlése'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final custom = widget.onDelete;
      if (custom != null) {
        await custom();
      } else {
        await ref.read(memberAdminActionsProvider).deleteMember(widget.member.id);
      }
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups;
    final athletes = widget.candidates.where(
      (user) => user.role == UserRole.athlete && user.status == UserStatus.active,
    );
    final parents = widget.candidates.where(
      (user) => user.role == UserRole.parent && user.status == UserStatus.active,
    );
    return Scaffold(
      appBar: ClubAppBar(
        leading: IconButton(
          tooltip: 'Vissza a tagokhoz',
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.members),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Név'),
          ),
          const SizedBox(height: 12),
          if (!_locked)
            DropdownButtonFormField<UserRole>(
              initialValue: _roleChoices.contains(_role) ? _role : UserRole.athlete,
              decoration: const InputDecoration(labelText: 'Szerepkör'),
              items: [
                for (final role in _roleChoices)
                  DropdownMenuItem(value: role, child: Text(role.labelHu)),
              ],
              onChanged: _saving
                  ? null
                  : (role) {
                      if (role != null) setState(() => _role = role);
                    },
            ),
          const SizedBox(height: 12),
          if (!_locked)
            DropdownButtonFormField<UserStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Státusz'),
              items: [
                for (final status in _statuses)
                  DropdownMenuItem(value: status, child: Text(status.labelHu)),
              ],
              onChanged: _saving
                  ? null
                  : (status) {
                      if (status != null) setState(() => _status = status);
                    },
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _belt,
            decoration: const InputDecoration(labelText: 'Lovas szint'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Nincs megadva'),
              ),
              for (final grade in ClubConfig.belts)
                DropdownMenuItem(value: grade.key, child: Text(grade.caption)),
            ],
            onChanged: _saving ? null : (value) => setState(() => _belt = value),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Születési dátum'),
            subtitle: Text(
              _birthDate == null ? 'Nincs megadva' : formatHungarianDate(_birthDate!),
            ),
            trailing: TextButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birthDate ?? DateTime(2012),
                        firstDate: DateTime(1930),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _birthDate = picked);
                    },
              child: const Text('Módosítás'),
            ),
          ),
          const SizedBox(height: 8),
          Text('Csoportok', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 6,
            children: [
              for (final group in groups)
                FilterChip(
                  label: Text(group.name),
                  selected: _groupIds.contains(group.id),
                  onSelected: _saving
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _groupIds.add(group.id);
                            } else {
                              _groupIds.remove(group.id);
                            }
                          });
                        },
                ),
            ],
          ),
          if (!ClubConfig.enforceAdultsOnly && _role == UserRole.parent) ...[
            const SizedBox(height: 12),
            Text('Gyermekek', style: Theme.of(context).textTheme.titleMedium),
            for (final child in athletes)
              CheckboxListTile(
                value: _childIds.contains(child.id),
                title: Text(child.name),
                onChanged: _saving
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            _childIds.add(child.id);
                          } else {
                            _childIds.remove(child.id);
                          }
                        });
                      },
              ),
          ],
          if (!ClubConfig.enforceAdultsOnly && _role == UserRole.athlete) ...[
            const SizedBox(height: 12),
            Text('Szülők', style: Theme.of(context).textTheme.titleMedium),
            for (final parent in parents)
              CheckboxListTile(
                value: _parentIds.contains(parent.id),
                title: Text(parent.name),
                onChanged: _saving
                    ? null
                    : (checked) {
                        setState(() {
                          if (checked == true) {
                            _parentIds.add(parent.id);
                          } else {
                            _parentIds.remove(parent.id);
                          }
                        });
                      },
              ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _saving ? null : _save, child: const Text('Mentés')),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _message,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Üzenet küldése'),
          ),
          if (!_locked) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : _suspend,
              child: const Text('Felfüggesztés'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('delete-member'),
              onPressed: _saving ? null : _delete,
              style: FilledButton.styleFrom(backgroundColor: AppColors.burgundy),
              child: const Text('Tag végleges törlése'),
            ),
          ],
        ],
        ),
      ),
    );
  }
}
