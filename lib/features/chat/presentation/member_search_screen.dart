import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/user_role.dart';
import '../../feed/domain/search_keywords.dart';
import '../../feed/presentation/author_avatar.dart';
import '../../feed/presentation/feed_palette.dart';
import '../data/chat_providers.dart';
import '../domain/club_member.dart';

/// Aktív tagok keresése egy új beszélgetéshez.
class MemberSearchScreen extends ConsumerStatefulWidget {
  const MemberSearchScreen({super.key});

  @override
  ConsumerState<MemberSearchScreen> createState() => _MemberSearchScreenState();
}

class _MemberSearchScreenState extends ConsumerState<MemberSearchScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  var _token = '';
  String? _openingId;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _token = _searchToken(value));
    });
  }

  Future<void> _open(ClubMember member) async {
    setState(() => _openingId = member.id);
    try {
      final id = await ref
          .read(chatRepositoryProvider)
          .startConversation(member.id);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.conversation(id));
    } catch (error) {
      if (!mounted) return;
      setState(() => _openingId = null);
      final message =
          error is FirebaseFunctionsException && error.message != null
          ? error.message!
          : 'Nem sikerült megnyitni a beszélgetést.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final myId = session is AuthSignedIn ? session.user.id : '';
    final members = ref.watch(membersProvider(_token));

    return Scaffold(
      backgroundColor: FeedPalette.background(context),
      appBar: AppBar(title: const Text('Új üzenet')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Keresés a tagok között…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: FeedPalette.field(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  const Center(child: Text('A taglista most nem tölthető be.')),
              data: (people) {
                final visible = [
                  for (final person in people)
                    if (person.id != myId) person,
                ];
                final coaches = [
                  for (final person in visible)
                    if (person.role == UserRole.coach) person,
                ];
                final rest = [
                  for (final person in visible)
                    if (person.role != UserRole.coach) person,
                ];
                if (visible.isEmpty) {
                  return const Center(child: Text('Nincs találat.'));
                }
                return ListView(
                  children: [
                    if (coaches.isNotEmpty) const _Section('Edzők'),
                    for (final person in coaches) _tile(person),
                    if (rest.isNotEmpty && coaches.isNotEmpty)
                      const _Section('Tagok'),
                    for (final person in rest) _tile(person),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(ClubMember person) {
    final busy = _openingId == person.id;
    return ListTile(
      leading: AuthorAvatar(
        name: person.name,
        photoUrl: person.photoUrl,
        radius: 22,
      ),
      title: Text(
        person.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(person.roleLabel),
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _openingId == null ? () => _open(person) : null,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.burgundy,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// A tagkereső első szava, ékezet és kisbetű nélkül. Két betű alatt üres.
String _searchToken(String query) {
  final folded = foldAccents(query.trim().toLowerCase());
  final word = folded
      .split(RegExp(r'\s+'))
      .firstWhere((part) => part.isNotEmpty, orElse: () => '');
  if (word.length < 2) return '';
  return word.length > 24 ? word.substring(0, 24) : word;
}
