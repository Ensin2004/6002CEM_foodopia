import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/entities/explore_recipe.dart';
import '../viewmodel/explore_viewmodel.dart';
import '../widgets/explore_empty_state.dart';
import '../widgets/explore_recipe_card.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreViewModel(getRecipesUseCase: sl()),
      child: const _ExplorePageView(),
    );
  }
}

class _ExplorePageView extends StatefulWidget {
  const _ExplorePageView();

  @override
  State<_ExplorePageView> createState() => _ExplorePageViewState();
}

class _ExplorePageViewState extends State<_ExplorePageView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ExploreRecipeTab.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<ExploreViewModel>().selectTab(
      ExploreRecipeTab.values[_tabController.index],
    );
  }

  void _selectTab(ExploreRecipeTab tab) {
    final index = ExploreRecipeTab.values.indexOf(tab);
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
    context.read<ExploreViewModel>().selectTab(tab);
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Coming soon')),
      );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExploreViewModel>();

    return SafeArea(
      top: false,
      child: Column(
        children: [
          _ExploreFilters(
            tabController: _tabController,
            onSearchChanged: viewModel.updateQuery,
            onComingSoonTap: _showComingSoonMessage,
          ),
          Expanded(
            child: _ExploreContent(
              viewModel: viewModel,
              onExploreNow: () => _selectTab(ExploreRecipeTab.all),
              onComingSoonTap: _showComingSoonMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreContent extends StatelessWidget {
  final ExploreViewModel viewModel;
  final VoidCallback onExploreNow;
  final VoidCallback onComingSoonTap;

  const _ExploreContent({
    required this.viewModel,
    required this.onExploreNow,
    required this.onComingSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading recipes...', inline: true);
    }

    final error = viewModel.errorMessage;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (viewModel.shouldShowFollowingEmpty) {
      return ExploreEmptyState(onExploreNow: onExploreNow);
    }

    final recipes = viewModel.visibleRecipes;
    if (recipes.isEmpty) {
      return Center(
        child: Text(
          'No recipes found',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : width >= 600 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: width < 380 ? 216 : 220,
      ),
      itemCount: recipes.length,
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
    );
  }
}

class _ExploreFilters extends StatelessWidget {
  final TabController tabController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onComingSoonTap;

  const _ExploreFilters({
    required this.tabController,
    required this.onSearchChanged,
    required this.onComingSoonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onComingSoonTap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 25,
                      height: 30,
                    ),
                    icon: const Icon(
                      Icons.sort,
                      size: 25,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onComingSoonTap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 25,
                      height: 30,
                    ),
                    icon: const Icon(
                      Icons.filter_alt,
                      size: 25,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: onComingSoonTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ALL',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: TextField(
                  onChanged: onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search food, brand, category, ...',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AppSegmentedTabs(
                controller: tabController,
                tabs: ExploreRecipeTab.values.map(_tabLabel).toList(),
                isScrollable: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _tabLabel(ExploreRecipeTab tab) {
    switch (tab) {
      case ExploreRecipeTab.all:
        return 'All';
      case ExploreRecipeTab.popular:
        return 'Popular';
      case ExploreRecipeTab.recent:
        return 'Recent';
      case ExploreRecipeTab.following:
        return 'Following';
    }
  }
}
