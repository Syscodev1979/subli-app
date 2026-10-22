import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/club_app_bar.dart';
import '../../../core/widgets/club_drawer.dart';
import '../../auth/data/auth_providers.dart';
import '../../chat/data/chat_providers.dart';
import '../../chat/presentation/chat_button.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/post_category.dart';
import '../domain/search_keywords.dart';
import 'category_style.dart';
import 'composer_bar.dart';
import 'feed_chrome.dart';
import 'feed_controller.dart';
import 'feed_end.dart';
import 'feed_error_message.dart';
import 'feed_palette.dart';
import 'feed_query.dart';
import 'feed_skeleton.dart';
import 'post_card.dart';
import 'scroll_to_top_button.dart';

/// A klub kezdőoldala: a hírfolyam.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  FeedChrome? _chrome;
  Timer? _searchTimer;
  var _searchOpen = false;
  var _showTopButton = false;
  var _atTop = true;
  double? _lastOffset;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _chrome = ref.read(feedChromeProvider);
    _chrome!.scrollToTopAndRefresh = _scrollToTopAndRefresh;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _chrome?.scrollToTopAndRefresh = null;
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocus.dispose();
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

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _lastOffset = 0;
    if (_atTop && !_showTopButton) return;
    setState(() {
      _atTop = true;
      _showTopButton = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final offset = position.pixels;
    final delta = _lastOffset == null ? 0.0 : offset - _lastOffset!;
    _lastOffset = offset;
    final atTop = offset < 48;
    final far = offset > position.viewportDimension * 2;
    var show = _showTopButton;
    if (atTop || delta < -6) {
      show = false;
    } else if (far && delta > 6) {
      show = true;
    }
    if (show != _showTopButton || atTop != _atTop) {
      setState(() {
        _showTopButton = show;
        _atTop = atTop;
      });
    }
    if (position.maxScrollExtent <= 0) return;
    if (offset < position.maxScrollExtent - 240) return;
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

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    ref.read(feedSearchProvider.notifier).clear();
    _searchFocus.unfocus();
    setState(() => _searchOpen = false);
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(feedSearchProvider.notifier).setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(feedCategoryProvider, (previous, next) {
      if (previous != next) _jumpTop();
    });
    ref.listen(feedSearchProvider, (previous, next) {
      if (previous != next) _jumpTop();
    });

    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final feed = ref.watch(feedControllerProvider);
    final search = ref.watch(feedSearchProvider);
    final category = ref.watch(feedCategoryProvider);
    final newest = ref.watch(newestPostIdProvider).asData?.value;
    final loaded = feed.asData?.value.posts ?? const [];
    final hasNew = newest != null && loaded.every((post) => post.id != newest);
    final showNew = _atTop && hasNew && search.trim().isEmpty;
    final highlights = searchTerms(search);

    return Scaffold(
      backgroundColor: FeedPalette.background(context),
      endDrawer: const ClubDrawer(),
      appBar: ClubAppBar(
        title: _searchOpen
            ? TextField(
                key: const ValueKey('feed-search'),
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: FeedPalette.title(context)),
                decoration: InputDecoration(
                  hintText: 'Keresés a bejegyzésekben…',
                  hintStyle: TextStyle(color: FeedPalette.muted(context)),
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: IconButton(
                    tooltip: 'Bezárás',
                    onPressed: _closeSearch,
                    icon: const Icon(Icons.close),
                  ),
                ),
              )
            : null,
        actions: [
          if (!_searchOpen)
            IconButton(
              tooltip: 'Keresés',
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
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
      body: Stack(
        children: [
          feed.when(
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
                  SliverToBoxAdapter(
                    child: _EmptyFeed(
                      message: _emptyMessage(
                        search: search,
                        category: category,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final currentUser = user;
                      if (currentUser == null) return const SizedBox.shrink();
                      if (index >= view.posts.length) {
                        if (view.loadingMore) {
                          return const FeedSkeleton(cards: 1);
                        }
                        return const FeedEndMark();
                      }
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              index == view.posts.length - 1 &&
                                  !view.loadingMore &&
                                  view.hasMore
                              ? 24
                              : 8,
                        ),
                        child: PostTile(
                          post: view.posts[index],
                          user: currentUser,
                          highlights: highlights,
                        ),
                      );
                    }, childCount: view.posts.length + _tail(view)),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !showNew,
              child: ExcludeSemantics(
                excluding: !showNew,
                child: AnimatedOpacity(
                  opacity: showNew ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: _NewPostsPill(onTap: _scrollToTopAndRefresh),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.paddingOf(context).bottom + 56 + 12,
            child: ScrollToTopButton(
              visible: _showTopButton,
              onPressed: _scrollToTop,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.paddingOf(context).bottom,
            child: ChatButton(
              unread: ref.watch(unreadConversationCountProvider),
              onPressed: () => context.push(AppRoutes.chat),
            ),
          ),
        ],
      ),
    );
  }

  int _tail(FeedView view) {
    if (view.posts.isEmpty) return 0;
    if (view.loadingMore || !view.hasMore) return 1;
    return 0;
  }

  String? _emptyMessage({
    required String search,
    required PostCategory? category,
  }) {
    final query = search.trim();
    if (query.isNotEmpty) return 'Nincs találat erre: $query';
    if (category != null) return 'Nincs bejegyzés ebben a kategóriában.';
    return null;
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
          const SliverToBoxAdapter(child: _FeedHeader()),
          if (user case final current? when current.role.canWritePosts)
            SliverToBoxAdapter(child: ComposerBar(user: current)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ...slivers,
          SliverToBoxAdapter(
            child: SizedBox(
              height: 16 + 56 + 12 + 48 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedHeader extends ConsumerWidget {
  const _FeedHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(feedCategoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FeedTitle(),
        CategoryChipRow(
          includeAll: true,
          selected: selected,
          onSelected: (category) {
            ref.read(feedCategoryProvider.notifier).select(category);
          },
        ),
        const SizedBox(height: 12),
      ],
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
  const _EmptyFeed({this.message});

  final String? message;

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
            message ??
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

class _NewPostsPill extends StatelessWidget {
  const _NewPostsPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.burgundy,
      elevation: 3,
      shadowColor: const Color(0x66000000),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'Új bejegyzések ↑',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
