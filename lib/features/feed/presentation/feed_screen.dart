import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../../core/widgets/club_drawer.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import 'composer_bar.dart';
import 'feed_chrome.dart';
import 'feed_controller.dart';
import 'feed_error_message.dart';
import 'feed_palette.dart';
import 'feed_skeleton.dart';
import 'post_card.dart';

/// A klub kezdőoldala: a hírfolyam.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  FeedChrome? _chrome;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _chrome = ref.read(feedChromeProvider);
    _chrome!.scrollToTopAndRefresh = _scrollToTopAndRefresh;
  }

  @override
  void dispose() {
    _chrome?.scrollToTopAndRefresh = null;
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _scrollToTopAndRefresh() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    await _refresh();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(feedErrorMessage(error, saving: false))),
        );
      }
    }
  }

  Future<void> _refresh() async {
    try {
      await ref.read(feedControllerProvider.notifier).refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(feedErrorMessage(error, saving: false))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final feed = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: FeedPalette.background(context),
      endDrawer: const ClubDrawer(),
      appBar: ClubAppBar(
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
      body: feed.when(
        loading: () => _FeedFrame(
          controller: _scrollController,
          onRefresh: _refresh,
          user: user,
          slivers: const [SliverToBoxAdapter(child: FeedSkeleton())],
        ),
        error: (error, _) => _FeedFrame(
          controller: _scrollController,
          onRefresh: _refresh,
          user: user,
          slivers: [
            SliverToBoxAdapter(
              child: _FeedMessage(
                message: feedErrorMessage(error, saving: false),
                onRetry: () => ref.invalidate(feedControllerProvider),
              ),
            ),
          ],
        ),
        data: (view) => _FeedFrame(
          controller: _scrollController,
          onRefresh: _refresh,
          user: user,
          slivers: [
            if (view.posts.isEmpty)
              const SliverToBoxAdapter(child: _EmptyFeed())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final currentUser = user;
                  if (currentUser == null) return const SizedBox.shrink();
                  if (index >= view.posts.length) {
                    return const FeedSkeleton(cards: 1);
                  }
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          index == view.posts.length - 1 && !view.loadingMore
                          ? 24
                          : 8,
                    ),
                    child: PostTile(post: view.posts[index], user: currentUser),
                  );
                }, childCount: view.posts.length + (view.loadingMore ? 1 : 0)),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedFrame extends StatelessWidget {
  const _FeedFrame({
    required this.controller,
    required this.onRefresh,
    required this.user,
    required this.slivers,
  });

  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final AppUser? user;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _FeedTitle()),
          if (user case final current? when current.role.canWritePosts)
            SliverToBoxAdapter(child: ComposerBar(user: current)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ...slivers,
        ],
      ),
    );
  }
}

class _FeedTitle extends StatelessWidget {
  const _FeedTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        'Hírfolyam',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: FeedPalette.title(context),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          const Icon(
            Icons.sports_martial_arts,
            size: 56,
            color: AppColors.burgundy,
          ),
          const SizedBox(height: 16),
          Text(
            'Még nincs bejegyzés. Hamarosan itt lesznek a klub hírei!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FeedPalette.title(context),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FeedPalette.title(context),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Újra')),
        ],
      ),
    );
  }
}
