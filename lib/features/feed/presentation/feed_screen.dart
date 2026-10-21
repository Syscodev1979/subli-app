import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/club_drawer.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/auth_error_message.dart';
import 'feed_controller.dart';
import 'post_card.dart';

/// Hírfolyam: kitűzött bejegyzések felül, alatta a legújabbak.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels < position.maxScrollExtent - 240) return;
    _loadMore();
  }

  Future<void> _loadMore() async {
    try {
      await ref.read(feedControllerProvider.notifier).loadMore();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  Future<void> _refresh() async {
    try {
      await ref.read(feedControllerProvider.notifier).refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final feed = ref.watch(feedControllerProvider);
    final canWrite = user?.role.canWritePosts ?? false;

    return Scaffold(
      endDrawer: const ClubDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Row(
          children: [
            _ClubLogo(),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                AppInfo.clubName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (buttonContext) {
              return IconButton(
                tooltip: 'Menü',
                onPressed: () => Scaffold.of(buttonContext).openEndDrawer(),
                icon: const Icon(Icons.menu),
              );
            },
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton(
              tooltip: 'Új bejegyzés',
              onPressed: () => context.push(AppRoutes.newPost),
              child: const Icon(Icons.add),
            )
          : null,
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => RefreshIndicator(
          onRefresh: _refresh,
          child: _MessageList(
            message: authErrorMessage(error),
            onRetry: () => ref.invalidate(feedControllerProvider),
          ),
        ),
        data: (view) => RefreshIndicator(
          onRefresh: _refresh,
          child: view.posts.isEmpty
              ? const _MessageList(message: 'Még nincs bejegyzés.')
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(top: 6, bottom: canWrite ? 88 : 24),
                  itemCount: view.posts.length + (view.loadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= view.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final currentUser = user;
                    if (currentUser == null) return const SizedBox.shrink();
                    return PostTile(post: view.posts[index], user: currentUser);
                  },
                ),
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (onRetry != null)
          Center(
            child: TextButton(onPressed: onRetry, child: const Text('Újra')),
          ),
      ],
    );
  }
}

/// A klublogó helye, amíg a címer nem kerül az appba.
class _ClubLogo extends StatelessWidget {
  const _ClubLogo();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Klublogó',
      excludeSemantics: true,
      child: const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.burgundyLight,
        child: Icon(
          Icons.sports_martial_arts,
          size: 18,
          color: AppColors.burgundy,
        ),
      ),
    );
  }
}
