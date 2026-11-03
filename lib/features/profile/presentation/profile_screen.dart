import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/club_colors.dart';
import '../../../app/club_config.dart';
import '../../../app/constants.dart';
import '../../../core/utils/hungarian_date.dart';
import '../../../core/widgets/appearance_section.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/domain/user_status.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../chat/domain/club_member.dart';
import '../../feed/presentation/author_avatar.dart';
import '../../feed/presentation/feed_palette.dart';
import '../data/avatar_storage.dart';
import '../data/member_repository.dart';
import 'avatar_flow.dart';
import '../../members/presentation/member_chips.dart';
import 'belt_badge.dart';
import 'profile_footer.dart';

/// A bejelentkezett tag saját profilja.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    return Scaffold(
      backgroundColor: FeedPalette.background(context),
      appBar: ClubAppBar(
        leading: IconButton(
          tooltip: 'Vissza',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.feed),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _ProfileBody(user: user),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.user});

  final AppUser user;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  var _uploading = false;

  Future<void> _editPhoto() async {
    try {
      await editAvatar(
        context: context,
        userId: widget.user.id,
        storage: ref.read(avatarStorageProvider),
        onUploading: (value) {
          if (mounted) setState(() => _uploading = value);
        },
        save: (photoUrl) {
          return ref
              .read(userRepositoryProvider)
              .updateOwnProfile(
                userId: widget.user.id,
                photoUrl: photoUrl,
                clearPhoto: photoUrl == null,
              );
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  Future<void> _editName() async {
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: widget.user.name),
    );
    if (saved == null || !mounted) return;
    final error = validateName(saved);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    try {
      await ref
          .read(userRepositoryProvider)
          .updateOwnProfile(userId: widget.user.id, name: saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profil frissítve')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  Future<void> _editBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.user.birthDate ?? DateTime(now.year - 10),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Születési dátum',
      cancelText: 'Mégse',
      confirmText: 'Rendben',
    );
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .updateOwnProfile(userId: widget.user.id, birthDate: picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profil frissítve')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final belt = user.role == UserRole.athlete
        ? ClubConfig.beltByKey(user.beltRank)
        : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Center(
          child: _Avatar(
            user: user,
            uploading: _uploading,
            onCamera: _editPhoto,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Center(child: _RoleChip(role: user.role)),
        if (user.role == UserRole.athlete) ...[
          const SizedBox(height: 10),
          Center(
            child: belt == null
                ? Text(
                    'Nincs megadva övfokozat',
                    style: TextStyle(color: FeedPalette.muted(context)),
                  )
                : BeltBadge(belt: belt),
          ),
        ],
        const SizedBox(height: 20),
        _InfoCard(
          label: 'Név',
          value: user.name,
          trailing: TextButton(
            onPressed: _editName,
            child: const Text('Szerkesztés'),
          ),
        ),
        _InfoCard(label: 'E-mail', value: user.email),
        _InfoCard(
          label: 'Születési dátum',
          value: user.birthDate == null
              ? 'Nincs megadva'
              : formatHungarianDate(user.birthDate!),
          trailing: user.status == UserStatus.pending
              ? TextButton(
                  onPressed: _editBirthDate,
                  child: const Text('Szerkesztés'),
                )
              : null,
        ),
        if (user.groupIds.isEmpty)
          const _InfoCard(label: 'Edzéscsoport', value: 'Még nincs megadva')
        else
          AssignedGroups(groupIds: user.groupIds),
        if (!ClubConfig.enforceAdultsOnly &&
            user.role == UserRole.parent &&
            user.childIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Gyermekeim',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final childId in user.childIds) _ChildCard(childId: childId),
        ],
        const SizedBox(height: 12),
        Card(
          color: FeedPalette.card(context),
          elevation: 0,
          child: const AppearanceSection(),
        ),
        const SizedBox(height: 8),
        Card(
          color: FeedPalette.card(context),
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Kijelentkezés'),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ),
        const ProfileFooter(),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.user,
    required this.uploading,
    required this.onCamera,
  });

  final AppUser user;
  final bool uploading;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final gold = ClubColors.of(context).gold;
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold, width: 2),
            ),
            child: AuthorAvatar(
              name: user.name,
              photoUrl: user.photoUrl,
              radius: 56,
            ),
          ),
          if (uploading)
            const SizedBox(
              width: 112,
              height: 112,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Material(
              color: AppColors.burgundy,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: uploading ? null : onCamera,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.photo_camera,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      UserRole.admin => 'Admin',
      UserRole.coach => 'Edző',
      UserRole.athlete => 'Sportoló',
      UserRole.parent => 'Szülő',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.burgundyLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.burgundy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: FeedPalette.card(context),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(color: FeedPalette.muted(context), fontSize: 13),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: FeedPalette.title(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}

class _ChildCard extends ConsumerWidget {
  const _ChildCard({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberRepositoryProvider).watchMember(childId);
    return StreamBuilder<ClubMember?>(
      stream: member,
      builder: (context, snapshot) {
        final child = snapshot.data;
        final belt = ClubConfig.beltByKey(child?.beltRank);
        return Card(
          color: FeedPalette.card(context),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: child == null
                ? null
                : () => context.push(AppRoutes.member(child.id)),
            leading: AuthorAvatar(
              name: child?.name ?? '?',
              photoUrl: child?.photoUrl,
              radius: 22,
            ),
            title: Text(
              child?.name ?? 'A gyermek profilja még nem elérhető',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: belt == null
                ? null
                : BeltBadge(belt: belt, compact: true),
          ),
        );
      },
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Név'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Teljes név'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mégse'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Mentés'),
        ),
      ],
    );
  }
}
