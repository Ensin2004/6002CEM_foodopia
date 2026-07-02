import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
          totalResults: viewModel.totalRecipeCount,
          aiFlaggedResults: viewModel.aiFlaggedRecipeCount,
          onQueryChanged: viewModel.updateQuery,
          onSortChanged: viewModel.updateSortOption,
          onReviewFilterChanged: viewModel.updateReviewFilter,
        ),
        Expanded(child: _ModerationContent(viewModel: viewModel)),
      ],
    );
  }
}

class _ModerationHero extends StatelessWidget {
  final int totalResults;
  final int aiFlaggedResults;

  const _ModerationHero({
    required this.totalResults,
    required this.aiFlaggedResults,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.035), Colors.white],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moderation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review, manage, and take action on recipe activity.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/images/shield.png',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroMetric(
                icon: Icons.fact_check_outlined,
                label: 'Total results',
                value: totalResults.toString(),
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _HeroMetric(
                icon: Icons.flag_rounded,
                label: 'AI flagged',
                value: aiFlaggedResults.toString(),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}

class _ModerationHeader extends StatelessWidget {
  final TextEditingController controller;
  final AdminModerationSortOption sortOption;
  final AdminModerationReviewFilter reviewFilter;
  final int totalResults;
  final int aiFlaggedResults;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AdminModerationSortOption> onSortChanged;
  final ValueChanged<AdminModerationReviewFilter> onReviewFilterChanged;

  const _ModerationHeader({
    required this.controller,
    required this.sortOption,
    required this.reviewFilter,
    required this.totalResults,
    required this.aiFlaggedResults,
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
          _ModerationHero(
            totalResults: totalResults,
            aiFlaggedResults: aiFlaggedResults,
          ),
          const SizedBox(height: 12),
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
                const SizedBox(width: 8),
                _ReviewFilterPill(
                  label: 'Hidden',
                  selected: reviewFilter == AdminModerationReviewFilter.hidden,
                  onTap: () => onReviewFilterChanged(
                    AdminModerationReviewFilter.hidden,
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
            onFlagTap: () => _showAiFlagDialog(context, viewModel, recipe),
          );
        },
      ),
    );
  }

  Future<void> _showAiFlagDialog(
    BuildContext context,
    AdminModerationViewModel viewModel,
    AdminModerationRecipe recipe,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _AiFlagDialog(
        recipe: recipe,
        isRemoving: viewModel.isUpdatingVisibility,
        onRemoveFlag: () async {
          final success = await viewModel.clearRecipeAiFlag(recipe.id);
          if (!dialogContext.mounted) return;
          if (success) {
            Navigator.of(dialogContext).pop();
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                viewModel.errorMessage ?? 'Unable to remove AI flag.',
              ),
            ),
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
  final VoidCallback onFlagTap;

  const _ModerationRecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onMediaLongPress,
    required this.onFlagTap,
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

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium,
                          ),
                        ),
                        if (recipe.aiReviewFlagged) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'View AI flag',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            onPressed: onFlagTap,
                            icon: const Icon(
                              Icons.flag_rounded,
                              color: AppColors.error,
                              size: 19,
                            ),
                          ),
                        ],
                      ],
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(recipe.updatedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
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

class _AiFlagDialog extends StatelessWidget {
  final AdminModerationRecipe recipe;
  final bool isRemoving;
  final Future<void> Function() onRemoveFlag;

  const _AiFlagDialog({
    required this.recipe,
    required this.isRemoving,
    required this.onRemoveFlag,
  });

  @override
  Widget build(BuildContext context) {
    final checkedAt = recipe.aiReviewCheckedAt;
    final timeLabel = checkedAt == null
        ? 'Not recorded'
        : DateFormat('yyyy-MM-dd HH:mm').format(checkedAt);
    final reason = recipe.aiReviewFlagReason.trim().isEmpty
        ? 'No reason recorded.'
        : recipe.aiReviewFlagReason.trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI flag details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                recipe.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge,
              ),
              const SizedBox(height: 14),
              _FlagDetailRow(label: 'Flag time', value: timeLabel),
              const SizedBox(height: 10),
              Text(
                'Reason',
                style: context.text.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(reason, style: context.text.bodyMedium),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: isRemoving ? null : onRemoveFlag,
                  icon: isRemoving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Remove flag'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _FlagDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: context.text.bodyMedium)),
      ],
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
