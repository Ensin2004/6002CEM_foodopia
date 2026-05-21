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
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/entities/explore_recipe.dart';
import '../viewmodel/explore_creator_detail_viewmodel.dart';
import '../widgets/explore_empty_state.dart';
import '../widgets/explore_recipe_card.dart';

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
        title: '',
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
      ),
    );
  }
}

class _CreatorBody extends StatelessWidget {
  final ExploreCreatorDetailViewModel viewModel;
  final TabController tabController;
  final VoidCallback onComingSoonTap;

  const _CreatorBody({
    required this.viewModel,
    required this.tabController,
    required this.onComingSoonTap,
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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _CreatorHeader(
                creator: creator,
                isUpdatingFollow: viewModel.isUpdatingFollow,
                onFollowTap: viewModel.toggleFollow,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Text(
                creator.bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyLarge,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AppSegmentedTabs(
              controller: tabController,
              tabs: ExploreCreatorRecipeTab.values
                  .map(_creatorTabLabel)
                  .toList(),
              margin: const EdgeInsets.only(top: 12),
              isScrollable: false,
            ),
          ),
          _RecipeGrid(
            recipes: viewModel.visibleRecipes,
            onComingSoonTap: onComingSoonTap,
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

  const _CreatorHeader({
    required this.creator,
    required this.isUpdatingFollow,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = creator.summary;
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppRemoteOrAssetAvatar(radius: 30, imagePath: summary.avatarPath),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: isUpdatingFollow ? null : () => onFollowTap(),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      creator.isFollowing ? Icons.check : Icons.add,
                      size: 15,
                    ),
                    label: Text(creator.isFollowing ? 'Following' : 'Follow'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CreatorMetric(
                      value: '${creator.postCount}',
                      label: 'Posts',
                    ),
                  ),
                  _MetricDivider(),
                  Expanded(
                    child: _CreatorMetric(
                      value: _compactCount(summary.followerCount),
                      label: 'Followers',
                    ),
                  ),
                  _MetricDivider(),
                  Expanded(
                    child: _CreatorMetric(
                      value: '${creator.followingCount}',
                      label: 'Following',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreatorMetric extends StatelessWidget {
  final String value;
  final String label;

  const _CreatorMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleLarge?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.border,
    );
  }
}

class _RecipeGrid extends StatelessWidget {
  final List<ExploreRecipe> recipes;
  final VoidCallback onComingSoonTap;

  const _RecipeGrid({required this.recipes, required this.onComingSoonTap});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ExploreEmptyState(onExploreNow: onComingSoonTap),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      sliver: SliverGrid.builder(
        itemCount: recipes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: width < 380 ? 216 : 220,
        ),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return ExploreRecipeCard(
            recipe: recipe,
            onComingSoonTap: onComingSoonTap,
            onTap: () {
              context.push(
                AppRouter.exploreRecipeDetail,
                extra: ExploreRecipeDetailArgs(recipeId: recipe.id),
              );
            },
          );
        },
      ),
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
