import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/club_config.dart';
import '../../../app/constants.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../../core/utils/hungarian_date.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/age.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/admin_identity.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../../auth/presentation/user_labels.dart';
import '../../chat/data/chat_providers.dart';
import '../../feed/data/feed_providers.dart';
import '../../feed/presentation/feed_error_message.dart';
import 'admin_providers.dart';

/// Jóváhagyásra váró fiókok. Admin és edző éri el.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authGateProvider).asData?.value;
    final pending = ref.watch(pendingUsersProvider);
    final athletes = ref.watch(activeAthletesProvider);
    final reviewer = session is AuthSignedIn ? session.user : null;
    final designated = reviewer != null && isDesignatedAdmin(reviewer);

    return Scaffold(
      appBar: ClubAppBar(
        leading: IconButton(
          tooltip: 'Vissza a hírfolyamra',
          onPressed: () => context.go(AppRoutes.feed),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          if (designated) const _BackfillCard(),
          Expanded(
            child: pending.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Message(authErrorMessage(error)),
              data: (users) {
                if (users.isEmpty) {
                  return const _Message(
                    'Nincs jóváhagyásra váró regisztráció.',
                  );
                }
                final athleteList = athletes.asData?.value ?? const <AppUser>[];
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _PendingUserCard(
                      key: ValueKey(user.id),
                      user: user,
                      athletes: athleteList,
                      athletesLoading: athletes.isLoading,
                      canAssignRoles: designated,
                      canSetBelt: reviewer?.role.canReviewMembers ?? false,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackfillCard extends ConsumerStatefulWidget {
  const _BackfillCard();

  @override
  ConsumerState<_BackfillCard> createState() => _BackfillCardState();
}

class _BackfillCardState extends ConsumerState<_BackfillCard> {
  var _runningPosts = false;
  var _runningMembers = false;

  Future<void> _runPosts() async {
    setState(() => _runningPosts = true);
    try {
      final count = await ref
          .read(postRepositoryProvider)
          .backfillLegacyPosts();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$count bejegyzés frissítve.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedErrorMessage(error, saving: true))),
      );
    } finally {
      if (mounted) setState(() => _runningPosts = false);
    }
  }

  Future<void> _runMembers() async {
    setState(() => _runningMembers = true);
    try {
      final count = await ref.read(chatRepositoryProvider).backfillMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count tag került a taglistára.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedErrorMessage(error, saving: true))),
      );
    } finally {
      if (mounted) setState(() => _runningMembers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Karbantartás',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'A kategória nélküli bejegyzések hírré válnak, és kereshetővé. '
                'A célközönség nélküliek minden tagnak szólnak.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _runningPosts ? null : _runPosts,
                child: Text(_runningPosts ? 'Frissítés…' : 'Adatok frissítése'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Az aktív tagok bekerülnek a taglistába, hogy üzenetet lehessen írni nekik.',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _runningMembers ? null : _runMembers,
                child: Text(
                  _runningMembers ? 'Frissítés…' : 'Taglista frissítése',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _PendingUserCard extends ConsumerStatefulWidget {
  const _PendingUserCard({
    required this.user,
    required this.athletes,
    required this.athletesLoading,
    required this.canAssignRoles,
    required this.canSetBelt,
    super.key,
  });

  final AppUser user;
  final List<AppUser> athletes;
  final bool athletesLoading;
  final bool canAssignRoles;
  final bool canSetBelt;

  @override
  ConsumerState<_PendingUserCard> createState() => _PendingUserCardState();
}

class _PendingUserCardState extends ConsumerState<_PendingUserCard> {
  late UserRole _role = widget.user.role;
  final _childIds = <String>{};
  var _submitting = false;

  UserRole get _resultingRole =>
      widget.canAssignRoles ? _role : widget.user.role;

  Future<void> _approve({UserRole? asRole}) async {
    setState(() => _submitting = true);
    final assigned =
        asRole ??
        (widget.canAssignRoles && _role != widget.user.role ? _role : null);
    try {
      await ref
          .read(userRepositoryProvider)
          .approveUser(
            userId: widget.user.id,
            currentRole: widget.user.role,
            assignedRole: assigned,
            childIds: (assigned ?? _resultingRole) == UserRole.parent
                ? _childIds.toList()
                : const [],
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _submitting = true);
    try {
      await ref.read(userRepositoryProvider).rejectUser(widget.user.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;
    final under18 =
        user.role == UserRole.athlete &&
        user.birthDate != null &&
        isUnder18(user.birthDate!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(user.name, style: theme.textTheme.titleMedium),
            if (user.requestedCoach) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text(
                      'Edzőként jelentkezett',
                      style: TextStyle(
                        color: AppColors.burgundyDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(user.email),
            const SizedBox(height: 4),
            Text('${user.role.labelHu} · ${user.status.labelHu}'),
            if (user.birthDate != null)
              Text('Született: ${formatHungarianDate(user.birthDate!)}'),
            if (under18)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '18 év alatti sportoló. A fiókot szülői jóváhagyás után lehet aktiválni.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            if (_resultingRole == UserRole.parent) ...[
              const SizedBox(height: 12),
              Text('Gyermekkérések', style: theme.textTheme.titleSmall),
              if (user.childRequests.isEmpty)
                const Text('Nincs megadott gyermek.')
              else
                for (final child in user.childRequests)
                  Text(
                    '${child.name} · ${formatHungarianDate(child.birthDate)}',
                  ),
              const SizedBox(height: 12),
              Text(
                'Melyik aktív sportoló az övé?',
                style: theme.textTheme.titleSmall,
              ),
              if (widget.athletesLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (widget.athletes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Még nincs aktív sportoló. Jóváhagyás összekapcsolás nélkül is lehetséges.',
                  ),
                )
              else
                for (final athlete in widget.athletes)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _childIds.contains(athlete.id),
                    title: Text(athlete.name),
                    subtitle: athlete.birthDate == null
                        ? null
                        : Text(formatHungarianDate(athlete.birthDate!)),
                    onChanged: _submitting
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _childIds.add(athlete.id);
                              } else {
                                _childIds.remove(athlete.id);
                              }
                            });
                          },
                  ),
            ],
            if (widget.canSetBelt &&
                !user.requestedCoach &&
                user.role == UserRole.athlete) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: ClubConfig.beltByKey(user.beltRank)?.key,
                decoration: const InputDecoration(labelText: 'Övfokozat'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Nincs megadva'),
                  ),
                  for (final grade in ClubConfig.belts)
                    DropdownMenuItem(
                      value: grade.key,
                      child: Text(grade.caption),
                    ),
                ],
                onChanged: _submitting
                    ? null
                    : (key) async {
                        try {
                          await ref
                              .read(userRepositoryProvider)
                              .setBeltRank(userId: user.id, beltRank: key);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(authErrorMessage(error))),
                            );
                          }
                        }
                      },
              ),
            ],
            if (widget.canAssignRoles && !user.requestedCoach) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Szerepkör'),
                items: [
                  for (final role in UserRole.assignable)
                    DropdownMenuItem(value: role, child: Text(role.labelHu)),
                ],
                onChanged: _submitting
                    ? null
                    : (role) {
                        if (role != null) setState(() => _role = role);
                      },
              ),
            ],
            const SizedBox(height: 16),
            if (user.requestedCoach && !widget.canAssignRoles)
              const Text('Ezt a jelentkezést csak admin hagyhatja jóvá.')
            else if (user.requestedCoach)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _submitting
                        ? null
                        : () => _approve(asRole: UserRole.coach),
                    child: const Text('Jóváhagyás edzőként'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => _approve(asRole: UserRole.athlete),
                    child: const Text('Jóváhagyás sportolóként'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _submitting ? null : _reject,
                    child: const Text('Elutasítás'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : () => _approve(),
                      child: const Text('Jóváhagyás'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _reject,
                      child: const Text('Elutasítás'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
