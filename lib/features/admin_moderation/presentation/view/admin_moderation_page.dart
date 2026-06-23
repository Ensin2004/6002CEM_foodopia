import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../domain/entities/admin_moderation_recipe.dart';
import '../viewmodel/admin_moderation_viewmodel.dart';

/// Simple admin moderation screen for reviewing user recipes.
class AdminModerationPage extends StatelessWidget {
  /// Creates a new admin moderation page instance.
  const AdminModerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<AdminModerationViewModel>(),
      child: const _AdminModerationView(),
    );
  }
}

class _AdminModerationView extends StatefulWidget {
  const _AdminModerationView();

  @override
  State<_AdminModerationView> createState() => _AdminModerationViewState();
}

class _AdminModerationViewState extends State<_AdminModerationView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminModerationViewModel>();

    return Column(
      children: [
        _ModerationHeader(
          controller: _searchController,
          sortOption: viewModel.sortOption,
          reviewFilter: viewModel.reviewFilter,
          onQueryChanged: viewModel.updateQuery,
          onSortChanged: viewModel.updateSortOption,
          onReviewFilterChanged: viewModel.updateReviewFilter,
        ),
        Expanded(child: _ModerationContent(viewModel: viewModel)),
      ],
    );
  }
}

class _ModerationHeader extends StatelessWidget {
  final TextEditingController controller;
  final AdminModerationSortOption sortOption;
  final AdminModerationReviewFilter reviewFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AdminModerationSortOption> onSortChanged;
  final ValueChanged<AdminModerationReviewFilter> onReviewFilterChanged;

  const _ModerationHeader({
    required this.controller,
    required this.sortOption,
    required this.reviewFilter,
    required this.onQueryChanged,
    required this.onSortChanged,
    required this.onReviewFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 24),
                hintText: 'Search recipes or creators',
                suffixIcon: SizedBox(
                  width: controller.text.trim().isEmpty ? 56 : 102,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (controller.text.trim().isNotEmpty)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            controller.clear();
                            onQueryChanged('');
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      IconButton(
                        tooltip: 'Sort and filter',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showSortFilterSheet(context),
                        icon: const Icon(Icons.filter_alt, size: 24),
                      ),
                    ],
                  ),
                ),
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
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              children: [
                _ReviewFilterPill(
                  label: 'All',
                  selected: reviewFilter == AdminModerationReviewFilter.all,
                  onTap: () =>
                      onReviewFilterChanged(AdminModerationReviewFilter.all),
                ),
                const SizedBox(width: 8),
                _ReviewFilterPill(
                  label: 'Pending',
                  selected: reviewFilter == AdminModerationReviewFilter.pending,
                  onTap: () => onReviewFilterChanged(
                    AdminModerationReviewFilter.pending,
                  ),
                ),
                const SizedBox(width: 8),
                _ReviewFilterPill(
                  label: 'Reviewed',
                  selected: reviewFilter == AdminModerationReviewFilter.reviewed,
                  onTap: () => onReviewFilterChanged(
                    AdminModerationReviewFilter.reviewed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSortFilterSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<AdminModerationSortOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SortFilterSheet(selected: sortOption),
    );
    if (selected != null) onSortChanged(selected);
  }
}

class _ReviewFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReviewFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelLarge?.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortFilterSheet extends StatelessWidget {
  final AdminModerationSortOption selected;

  const _SortFilterSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text('Sort and Filter', style: context.text.titleLarge),
          const SizedBox(height: 12),
          _SortOptionTile(
            title: 'Alphabetical A-Z',
            value: AdminModerationSortOption.alphabetAZ,
            selected: selected,
          ),
          _SortOptionTile(
            title: 'Alphabetical Z-A',
            value: AdminModerationSortOption.alphabetZA,
            selected: selected,
          ),
          _SortOptionTile(
            title: 'Latest',
            value: AdminModerationSortOption.newest,
            selected: selected,
          ),
          _SortOptionTile(
            title: 'Oldest',
            value: AdminModerationSortOption.oldest,
            selected: selected,
          ),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String title;
  final AdminModerationSortOption value;
  final AdminModerationSortOption selected;

  const _SortOptionTile({
    required this.title,
    required this.value,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, overflow: TextOverflow.ellipsis),
      trailing: selected == value
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}

class _ModerationContent extends StatelessWidget {
  final AdminModerationViewModel viewModel;

  const _ModerationContent({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const LoadingDialog(message: 'Loading recipes...', inline: true);
    }

    final error = viewModel.errorMessage;
    if (error != null) {
      return RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.58,
              child: _ModerationMessage(
                icon: Icons.error_outline,
                title: 'Unable to load recipes',
                message: error,
              ),
            ),
          ],
        ),
      );
    }

    final recipes = viewModel.visibleRecipes;
    if (recipes.isEmpty) {
      return RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.58,
              child: const _ModerationMessage(
                icon: Icons.verified_user_outlined,
                title: 'No recipes to review',
                message: 'Public recipes posted by users will appear here.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _ModerationRecipeCard(
            recipe: recipe,
            onTap: () => context.push(
              AppRouter.exploreRecipeDetail,
              extra: ExploreRecipeDetailArgs(
                recipeId: recipe.id,
                isAdminModeration: true,
                isPublished:
                    recipe.reviewStatus != AdminModerationReviewStatus.hidden,
              ),
            ),
            onMediaLongPress: () =>
                showRecipeMediaDialog(context, recipe.imagePath),
          );
        },
      ),
    );
  }
}

class _ModerationRecipeCard extends StatelessWidget {
  final AdminModerationRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onMediaLongPress;

  const _ModerationRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onMediaLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onMediaLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: onMediaLongPress,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: AppRecipeMediaPreview(mediaPath: recipe.imagePath),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${recipe.creatorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatusChip(
                          label: 'Public',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: recipe.reviewStatus ==
                                  AdminModerationReviewStatus.reviewed
                              ? 'Reviewed'
                              : recipe.reviewStatus ==
                                    AdminModerationReviewStatus.hidden
                              ? 'Hidden'
                              : 'Pending',
                          color: recipe.reviewStatus ==
                                  AdminModerationReviewStatus.reviewed
                              ? AppColors.primary
                              : recipe.reviewStatus ==
                                    AdminModerationReviewStatus.hidden
                              ? AppColors.error
                              : AppColors.secondary,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ModerationMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ModerationMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', width: 150),
            const SizedBox(height: AppSpacing.md),
            Icon(icon, size: 42, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
