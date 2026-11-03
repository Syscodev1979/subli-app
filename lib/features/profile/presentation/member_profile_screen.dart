import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/club_colors.dart';
import '../../../app/club_config.dart';
import '../../../app/constants.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/admin_identity.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../../chat/data/chat_providers.dart';
import '../../chat/domain/club_member.dart';
import '../../feed/presentation/author_avatar.dart';
import '../../feed/presentation/feed_error_message.dart';
import '../../feed/presentation/feed_palette.dart';
import '../../members/presentation/member_chips.dart';
import '../data/avatar_storage.dart';
import '../data/member_repository.dart';
import 'avatar_flow.dart';
import 'belt_badge.dart';

/// Másik tag profilja a `members` gyűjteményből. E-mail és születési dátum nincs.
class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authGateProvider).asData?.value;
    final viewer = session is AuthSignedIn ? session.user : null;
    if (viewer != null && viewer.id == userId) {
      return const ProfileRedirect();
    }
    final member = ref.watch(memberRepositoryProvider).watchMember(userId);
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
      body: StreamBuilder<ClubMember?>(
        stream: member,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final person = snapshot.data;
          if (person == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ez a profil nem elérhető.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final canEditPhoto =
              !ClubConfig.enforceAdultsOnly &&
              viewer != null &&
              viewer.role == UserRole.parent &&
              viewer.childIds.contains(person.id);
          final canSetBelt =
              viewer != null &&
              (isDesignatedAdmin(viewer) ||
                  (viewer.role == UserRole.coach &&
                      (person.role == UserRole.athlete ||
                          person.role == UserRole.parent)));
          return _MemberBody(
            person: person,
            canEditPhoto: canEditPhoto,
            canSetBelt: canSetBelt,
          );
        },
      ),
    );
  }
}

/// Saját azonosítóra a saját profil nyílik.
class ProfileRedirect extends StatefulWidget {
  const ProfileRedirect({super.key});

  @override
  State<ProfileRedirect> createState() => _ProfileRedirectState();
}

class _ProfileRedirectState extends State<ProfileRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _MemberBody extends ConsumerStatefulWidget {
  const _MemberBody({
    required this.person,
    required this.canEditPhoto,
    required this.canSetBelt,
  });

  final ClubMember person;
  final bool canEditPhoto;
  final bool canSetBelt;

  @override
  ConsumerState<_MemberBody> createState() => _MemberBodyState();
}

class _MemberBodyState extends ConsumerState<_MemberBody> {
  var _uploading = false;
  var _messaging = false;
  String? _beltOverride;

  Future<void> _editPhoto() async {
    try {
      await editAvatar(
        context: context,
        userId: widget.person.id,
        storage: ref.read(avatarStorageProvider),
        onUploading: (value) {
          if (mounted) setState(() => _uploading = value);
        },
        save: (photoUrl) {
          return ref
              .read(userRepositoryProvider)
              .updatePhotoUrl(userId: widget.person.id, photoUrl: photoUrl);
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  Future<void> _message() async {
    setState(() => _messaging = true);
    try {
      final id = await ref
          .read(chatRepositoryProvider)
          .startConversation(widget.person.id);
      if (!mounted) return;
      context.push(AppRoutes.conversation(id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedErrorMessage(error, saving: true))),
      );
    } finally {
      if (mounted) setState(() => _messaging = false);
    }
  }

  Future<void> _setBelt(String? key) async {
    setState(() => _beltOverride = key);
    try {
      await ref
          .read(userRepositoryProvider)
          .setBeltRank(userId: widget.person.id, beltRank: key);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Övfokozat mentve')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _beltOverride = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final beltKey = _beltOverride ?? person.beltRank;
    final belt = ClubConfig.beltByKey(beltKey);
    final gold = ClubColors.of(context).gold;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Center(
          child: SizedBox(
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
                    name: person.name,
                    photoUrl: person.photoUrl,
                    radius: 56,
                  ),
                ),
                if (_uploading)
                  const SizedBox(
                    width: 112,
                    height: 112,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                if (widget.canEditPhoto)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Material(
                      color: AppColors.burgundy,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploading ? null : _editPhoto,
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
          ),
        ),
        const SizedBox(height: 16),
        Text(
          person.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Center(child: _RoleChip(label: person.roleLabel)),
        if (person.groupIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          AssignedGroups(groupIds: person.groupIds),
        ],
        if (belt != null) ...[
          const SizedBox(height: 10),
          Center(child: BeltBadge(belt: belt)),
        ],
        if (widget.canSetBelt) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: ClubConfig.beltByKey(beltKey) == null
                ? null
                : beltKey,
            decoration: const InputDecoration(labelText: 'Övfokozat'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Nincs megadva'),
              ),
              for (final grade in ClubConfig.belts)
                DropdownMenuItem(value: grade.key, child: Text(grade.caption)),
            ],
            onChanged: _setBelt,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _messaging ? null : _message,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.burgundy,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: _messaging
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chat_bubble_outline),
          label: const Text(
            'Üzenet küldése',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
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
