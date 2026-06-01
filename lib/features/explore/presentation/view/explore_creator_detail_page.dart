import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/entities/explore_recipe.dart';
import '../viewmodel/explore_creator_detail_viewmodel.dart';
import '../widgets/explore_empty_state.dart';
import '../widgets/explore_recipe_grid.dart';

class ExploreCreatorDetailPage extends StatelessWidget {
  final String creatorUid;

  const ExploreCreatorDetailPage({super.key, required this.creatorUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreCreatorDetailViewModel(
        creatorUid: creatorUid,
        getCreatorDetailUseCase: sl(),
        toggleCreatorFollowUseCase: sl(),
        toggleFavouriteUseCase: sl(),
      ),
      child: const _ExploreCreatorDetailView(),
    );
  }
}

class _ExploreCreatorDetailView extends StatefulWidget {
  const _ExploreCreatorDetailView();

  @override
  State<_ExploreCreatorDetailView> createState() =>
      _ExploreCreatorDetailViewState();
}

class _ExploreCreatorDetailViewState extends State<_ExploreCreatorDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ExploreCreatorRecipeTab.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<ExploreCreatorDetailViewModel>().selectTab(
      ExploreCreatorRecipeTab.values[_tabController.index],
    );
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _showRecipeImage(ExploreRecipe recipe) async {
    await showRecipeMediaDialog(context, recipe.imagePath);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExploreCreatorDetailViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Creator Details',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
        actions: [
          IconButton(
            onPressed: _showComingSoonMessage,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _CreatorBody(
        viewModel: viewModel,
        tabController: _tabController,
        onComingSoonTap: _showComingSoonMessage,
        onImageLongPress: _showRecipeImage,
      ),
    );
  }
}

class _CreatorBody extends StatelessWidget {
  final ExploreCreatorDetailViewModel viewModel;
  final TabController tabController;
  final VoidCallback onComingSoonTap;
  final ValueChanged<ExploreRecipe> onImageLongPress;

  const _CreatorBody({
    required this.viewModel,
    required this.tabController,
    required this.onComingSoonTap,
    required this.onImageLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading creator...', inline: true);
    }

    final creator = viewModel.creator;
    final error = viewModel.errorMessage;
    if (creator == null || error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error ?? 'Creator unavailable',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadCreator,
      child: Column(
        children: [
          _CreatorHeader(
            creator: creator,
            isUpdatingFollow: viewModel.isUpdatingFollow,
            onFollowTap: viewModel.toggleFollow,
            onFollowersTap: () {
              context.push(
                AppRouter.libraryProfileUsers,
                extra: LibraryProfileUsersArgs(
                  showFollowers: true,
                  ownerUid: creator.summary.uid,
                ),
              );
            },
            onFollowingTap: () {
              context.push(
                AppRouter.libraryProfileUsers,
                extra: LibraryProfileUsersArgs(
                  showFollowers: false,
                  ownerUid: creator.summary.uid,
                ),
              );
            },
          ),
          AppSegmentedTabs(
            controller: tabController,
            tabs: ExploreCreatorRecipeTab.values.map(_creatorTabLabel).toList(),
            margin: EdgeInsets.zero,
            isScrollable: false,
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: ExploreCreatorRecipeTab.values.map((tab) {
                return CustomScrollView(
                  key: PageStorageKey(tab),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _RecipeGrid(
                      recipes: viewModel.visibleRecipesFor(tab),
                      onComingSoonTap: onComingSoonTap,
                      onFavouriteTap: viewModel.toggleFavourite,
                      onImageLongPress: onImageLongPress,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorHeader extends StatelessWidget {
  final ExploreCreatorDetail creator;
  final bool isUpdatingFollow;
  final Future<bool> Function() onFollowTap;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;

  const _CreatorHeader({
    required this.creator,
    required this.isUpdatingFollow,
    required this.onFollowTap,
    required this.onFollowersTap,
    required this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = creator.summary;
    final colors = context.colors;

    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/creator_hero.png'),
          fit: BoxFit.fill,
        ),
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.86)),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _CreatorDetailAvatar(imagePath: summary.avatarPath),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              summary.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          creator.isFollowing
                              ? FilledButton.icon(
                                  onPressed: isUpdatingFollow
                                      ? null
                                      : () => onFollowTap(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    minimumSize: const Size(0, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text(
                                    'Following',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: isUpdatingFollow
                                      ? null
                                      : () => onFollowTap(),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: colors.primary,
                                    side: BorderSide(color: colors.primary),
                                    elevation: 0,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    minimumSize: const Size(0, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(
                                    'Follow',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                      if (creator.bio.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          creator.bio,
                          style: context.text.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _CreatorMetric(
                    value: '${creator.postCount}',
                    label: 'Posts',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreatorMetric(
                    value: _compactCount(summary.followerCount),
                    label: 'Followers',
                    onTap: onFollowersTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CreatorMetric(
                    value: '${creator.followingCount}',
                    label: 'Following',
                    onTap: onFollowingTap,
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

class _CreatorMetric extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _CreatorMetric({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeGrid extends StatelessWidget {
  final List<ExploreRecipe> recipes;
  final VoidCallback onComingSoonTap;
  final ValueChanged<String> onFavouriteTap;
  final ValueChanged<ExploreRecipe> onImageLongPress;

  const _RecipeGrid({
    required this.recipes,
    required this.onComingSoonTap,
    required this.onFavouriteTap,
    required this.onImageLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ExploreEmptyState(onExploreNow: onComingSoonTap),
      );
    }

    return ExploreRecipeSliverGrid(
      recipes: recipes,
      onCommentTap: (_) => onComingSoonTap(),
      onFavouriteTap: onFavouriteTap,
      onImageLongPress: onImageLongPress,
      onRecipeTap: (recipe) {
        context.push(
          AppRouter.exploreRecipeDetail,
          extra: ExploreRecipeDetailArgs(recipeId: recipe.id),
        );
      },
    );
  }
}

class _CreatorDetailAvatar extends StatelessWidget {
  final String imagePath;

  const _CreatorDetailAvatar({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.trim().isNotEmpty;

    return CircleAvatar(
      radius: 38,
      backgroundColor: Colors.white,
      child: hasImage
          ? ClipOval(
              child: AppRemoteOrAssetImage(
                imagePath: imagePath,
                width: 76,
                height: 76,
              ),
            )
          : const Icon(Icons.person, color: AppColors.primary, size: 44),
    );
  }
}

String _creatorTabLabel(ExploreCreatorRecipeTab tab) {
  switch (tab) {
    case ExploreCreatorRecipeTab.all:
      return 'All';
    case ExploreCreatorRecipeTab.popular:
      return 'Popular';
    case ExploreCreatorRecipeTab.recent:
      return 'Recent';
  }
}

String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}
