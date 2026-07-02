part of 'explore_recipe_detail_page.dart';

/// Displays the community section of the recipe detail page, including author information,
/// related recipes, ratings, and comments with nested reply functionality.
class _CommunityTab extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;
  final bool isPublished;
  final bool isAdminModeration;

  const _CommunityTab({
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
    required this.isPublished,
    required this.isAdminModeration,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    // Limits related recipes to a maximum of 4 for display.
    final relatedRecipes = recipe.relatedRecipes.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Author profile section with avatar, bio, and follow/unfollow button.
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.4),
              ),
              child: _RecipeDetailAvatar(
                imagePath: recipe.authorAvatarPath,
                radius: 24,
                imageSize: 48,
                iconSize: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.author, style: textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    recipe.community.authorBio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
            // Follow/unfollow button only shown for other users' recipes.
            if (!recipe.isCreatedByCurrentUser) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 36,
                child: recipe.isFollowingAuthor
                    ? FilledButton.icon(
                  onPressed: () => viewModel.toggleCreatorFollow(),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Following'),
                )
                    : OutlinedButton(
                  onPressed: () => viewModel.toggleCreatorFollow(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    side: BorderSide(color: context.colors.primary),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Follow'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        /// Related recipes section with navigation to creator detail page.
        Row(
          children: [
            Text('More Recipes', style: textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () {
                context.push(
                  AppRouter.exploreCreatorDetail,
                  extra: ExploreCreatorDetailArgs(
                    creatorUid: recipe.creatorUid,
                  ),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Displays related recipe cards in a horizontal row.
        if (relatedRecipes.isEmpty)
          Text(
            'No recent recipes from this creator yet.',
            style: textTheme.bodySmall,
          )
        else
          SizedBox(
            height: 102,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculates equal width for each recipe card.
                final itemWidth = (constraints.maxWidth - 30) / 4;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: relatedRecipes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return SizedBox(
                      width: itemWidth,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == relatedRecipes.length - 1 ? 0 : 10,
                        ),
                        child: _RelatedRecipeCard(item: item),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        const SizedBox(height: 18),
        /// Segmented control for switching between Ratings and Comments tabs.
        AppPillSegmentedControl(
          labels: const ['Ratings', 'Comments'],
          selectedIndex: ExploreCommunityTab.values.indexOf(
            viewModel.selectedCommunityTab,
          ),
          onChanged: (index) =>
              viewModel.selectCommunityTab(ExploreCommunityTab.values[index]),
        ),
        const SizedBox(height: 24),
        // Conditionally renders the ratings panel or comments panel based on selection.
        if (viewModel.selectedCommunityTab == ExploreCommunityTab.ratings)
          _RatingsPanel(
            viewModel: viewModel,
            recipe: recipe,
            isPublished: isPublished,
            isSubmitting: viewModel.isSubmittingCommunityAction,
            canRate: !isAdminModeration && !recipe.isCreatedByCurrentUser,
            disabledMessage: isAdminModeration
                ? 'Admins cannot rate recipes'
                : 'You cannot rate your own recipe',
            onRatingSelected: (rating) =>
                _submitRating(context, viewModel, rating),
          )
        else
          ExploreCommentsPanel(
            viewModel: viewModel,
            recipe: recipe,
            isSubmitting: viewModel.isSubmittingCommunityAction,
            canInteract: !isAdminModeration,
            onAddComment: (content) =>
                _submitComment(context, viewModel, content),
            onToggleLike: (commentId) => viewModel.toggleCommentLike(commentId),
            onReply: (commentId, content) => viewModel.addCommentReply(
              commentId: commentId,
              content: content,
            ),
            onToggleReplyLike: viewModel.toggleReplyLike,
            onReplyToReply: (replyPath, content) => viewModel.addReplyToReply(
              replyPath: replyPath,
              content: content,
            ),
          ),
      ],
    );
  }

  /// Submits a rating and displays a snackbar with the result.
  Future<void> _submitRating(
      BuildContext context,
      ExploreRecipeDetailViewModel viewModel,
      int rating,
      ) async {
    final success = await viewModel.submitRating(rating.toDouble());
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Rating submitted.'
                : viewModel.communityActionErrorMessage ??
                'Unable to submit rating.',
          ),
        ),
      );
  }

  /// Submits a comment and displays a snackbar with the result.
  Future<void> _submitComment(
      BuildContext context,
      ExploreRecipeDetailViewModel viewModel,
      String content,
      ) async {
    final success = await viewModel.addComment(content);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Comment posted.'
                : viewModel.communityActionErrorMessage ??
                'Unable to post comment.',
          ),
        ),
      );
  }
}

/// Card widget displaying a related recipe with circular thumbnail and title.
class _RelatedRecipeCard extends StatelessWidget {
  final ExploreRecipeSummary item;

  const _RelatedRecipeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // Navigates to the selected related recipe detail page.
        context.push(
          AppRouter.exploreRecipeDetail,
          extra: ExploreRecipeDetailArgs(recipeId: item.id),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 1.6),
              ),
              child: ClipOval(
                child: AppRecipeMediaPreview(
                  mediaPath: item.imagePath,
                  fit: BoxFit.cover,
                  playOverlaySize: 28,
                  playIconSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Container widget with border, shadow, and background for community sections.
class _CommunitySectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CommunitySectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Panel displaying rating statistics, breakdown, and the rate recipe card.
class _RatingsPanel extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final bool isPublished;
  final bool isSubmitting;
  final bool canRate;
  final String disabledMessage;
  final ValueChanged<int> onRatingSelected;

  const _RatingsPanel({
    required this.viewModel,
    required this.recipe,
    required this.isPublished,
    required this.isSubmitting,
    required this.canRate,
    required this.disabledMessage,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// Rating summary card with average rating, stars, and breakdown bars.
        _CommunitySectionCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 104,
                  height: 112,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isPublished
                            ? recipe.rating.toStringAsFixed(1)
                            : 'No rating',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _RatingStars(size: 22, rating: recipe.rating),
                      const SizedBox(height: 4),
                      Text(
                        isPublished
                            ? '${recipe.ratingCount} ratings'
                            : 'Unpublished',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Rating breakdown bars showing distribution of each star level.
              Expanded(
                child: Column(
                  children: recipe.community.ratingBreakdown.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Row(
                              children: [
                                Text(
                                  '${row.stars}',
                                  style: textTheme.bodySmall,
                                ),
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: recipe.ratingCount == 0
                                  ? 0
                                  : row.count / recipe.ratingCount,
                              color: context.colors.primary,
                              backgroundColor: AppColors.background,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${row.count}',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        /// Rate recipe card with star selection and submit button.
        _RateRecipeCard(
          isSubmitting: isSubmitting,
          canRate: canRate,
          disabledMessage: disabledMessage,
          hasRated: recipe.hasRatedByCurrentUser,
          onRatingSelected: onRatingSelected,
        ),
        const SizedBox(height: 14),
        /// View ratings card with filter controls and review list.
        _ViewRatingsCard(
          reviews: viewModel.visibleReviews,
          starFilter: viewModel.ratingStarFilter,
          dateFilter: viewModel.ratingDateFilter,
          onFiltersChanged: viewModel.updateRatingFilters,
        ),
      ],
    );
  }
}

/// Card for rating a recipe with interactive star selection.
class _RateRecipeCard extends StatefulWidget {
  final bool isSubmitting;
  final bool canRate;
  final String disabledMessage;
  final bool hasRated;
  final ValueChanged<int> onRatingSelected;

  const _RateRecipeCard({
    required this.isSubmitting,
    required this.canRate,
    required this.disabledMessage,
    required this.hasRated,
    required this.onRatingSelected,
  });

  @override
  State<_RateRecipeCard> createState() => _RateRecipeCardState();
}

class _RateRecipeCardState extends State<_RateRecipeCard> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return _CommunitySectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate this Recipe', style: textTheme.titleMedium),
          Text(
            widget.canRate
                ? widget.hasRated
                      ? 'You already rated this recipe'
                      : 'Tap a star to rate'
                : widget.disabledMessage,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (widget.isSubmitting)
            const LoadingDialog(message: 'Submitting rating...', inline: true)
          else if (!widget.canRate)
            const SizedBox.shrink()
          else
            Column(
              children: [
                // Five interactive stars for rating selection.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return InkResponse(
                      onTap: widget.hasRated
                          ? null
                          : () => setState(() => _selectedRating = rating),
                      radius: 26,
                      child: Icon(
                        rating <= _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.secondary,
                        size: 34,
                      ),
                    );
                  }),
                ),
                if (_selectedRating > 0 || widget.hasRated) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.hasRated
                          ? null
                          : () => widget.onRatingSelected(_selectedRating),
                      style: widget.hasRated
                          ? FilledButton.styleFrom(
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.textSecondary,
                      )
                          : null,
                      child: Text(widget.hasRated ? 'Rated' : 'Submit Rating'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// Card displaying ratings with filter controls and review tiles.
class _ViewRatingsCard extends StatelessWidget {
  final List<ExploreReview> reviews;
  final ExploreRatingStarFilter starFilter;
  final ExploreCommunityDateFilter dateFilter;
  final void Function({
  required ExploreRatingStarFilter star,
  required ExploreCommunityDateFilter date,
  })
  onFiltersChanged;

  const _ViewRatingsCard({
    required this.reviews,
    required this.starFilter,
    required this.dateFilter,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return _CommunitySectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text('View Ratings', style: textTheme.titleMedium),
              const Spacer(),
              // Dropdown menu for filtering by star rating or date.
              _CompactPopupDropdown(
                label: _ratingsDropdownLabel(starFilter, dateFilter),
                items: [
                  ...ExploreRatingStarFilter.values.map(
                        (filter) => _CompactPopupItem(
                      value: 'star:${filter.name}',
                      label: _ratingStarLabel(filter),
                    ),
                  ),
                  ...ExploreCommunityDateFilter.values.map(
                        (filter) => _CompactPopupItem(
                      value: 'date:${filter.name}',
                      label: _dateFilterLabel(filter),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value.startsWith('star:')) {
                    final filter = ExploreRatingStarFilter.values.firstWhere(
                          (item) => item.name == value.substring(5),
                    );
                    onFiltersChanged(star: filter, date: dateFilter);
                  } else if (value.startsWith('date:')) {
                    final filter = ExploreCommunityDateFilter.values.firstWhere(
                          (item) => item.name == value.substring(5),
                    );
                    onFiltersChanged(star: starFilter, date: filter);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No ratings yet', style: textTheme.bodySmall),
            )
          else
          // Lists all visible reviews.
            ...reviews.map((review) => _ReviewTile(review: review)),
        ],
      ),
    );
  }

  static String _ratingStarLabel(ExploreRatingStarFilter filter) {
    switch (filter) {
      case ExploreRatingStarFilter.all:
        return 'All';
      case ExploreRatingStarFilter.one:
        return '1 star';
      case ExploreRatingStarFilter.two:
        return '2 star';
      case ExploreRatingStarFilter.three:
        return '3 star';
      case ExploreRatingStarFilter.four:
        return '4 star';
      case ExploreRatingStarFilter.five:
        return '5 star';
    }
  }

  static String _dateFilterLabel(ExploreCommunityDateFilter filter) {
    switch (filter) {
      case ExploreCommunityDateFilter.all:
        return 'All';
      case ExploreCommunityDateFilter.latest:
        return 'Latest';
      case ExploreCommunityDateFilter.oldest:
        return 'Oldest';
    }
  }

  static String _ratingsDropdownLabel(
      ExploreRatingStarFilter star,
      ExploreCommunityDateFilter date,
      ) {
    if (star == ExploreRatingStarFilter.all &&
        date == ExploreCommunityDateFilter.all) {
      return 'All';
    }
    final parts = <String>[];
    if (star != ExploreRatingStarFilter.all) parts.add(_ratingStarLabel(star));
    if (date != ExploreCommunityDateFilter.all) {
      parts.add(_dateFilterLabel(date));
    }
    return parts.join(', ');
  }
}

/// Tile displaying a single review with avatar, author, time, and rating stars.
class _ReviewTile extends StatelessWidget {
  final ExploreReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _RecipeDetailAvatar(
                imagePath: review.avatarPath,
                radius: 18,
                imageSize: 36,
                iconSize: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.author, style: textTheme.labelLarge),
                    Text(review.timeAgo, style: textTheme.bodySmall),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                child: _RatingStars(size: 18, rating: review.rating),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for compact popup menu items.
class _CompactPopupItem {
  final String value;
  final String label;

  const _CompactPopupItem({required this.value, required this.label});
}

/// Compact dropdown button with custom styling for filter menus.
class _CompactPopupDropdown extends StatelessWidget {
  final String label;
  final List<_CompactPopupItem> items;
  final ValueChanged<String> onSelected;

  const _CompactPopupDropdown({
    required this.label,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem(value: item.value, child: Text(item.label));
        }).toList();
      },
      child: Container(
        height: 30,
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown filter specifically for comment date sorting.
class _CommentFilterDropdown extends StatelessWidget {
  final String label;
  final List<_CompactPopupItem> items;
  final ValueChanged<String> onSelected;

  const _CommentFilterDropdown({
    required this.label,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem(value: item.value, child: Text(item.label));
        }).toList();
      },
      child: Container(
        height: 38,
        constraints: const BoxConstraints(minWidth: 74, maxWidth: 108),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget displayed when no comments exist.
class _CommentsEmptyState extends StatelessWidget {
  const _CommentsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            Image.asset(
              'assets/images/empty_page.png',
              width: 150,
              height: 128,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              'No comments yet',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start the conversation below.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a row of star icons for rating visualization.
class _RatingStars extends StatelessWidget {
  final double size;
  final double rating;

  const _RatingStars({required this.size, required this.rating});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final isFilled = index < rating.round();
          return Icon(
            Icons.star,
            size: size,
            color: isFilled ? AppColors.secondary : AppColors.border,
          );
        }),
      ),
    );
  }
}

/// Panel displaying comments with sorting filter, input field, and nested reply threads.
class ExploreCommentsPanel extends StatefulWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final bool isSubmitting;
  final bool canInteract;
  final ValueChanged<String> onAddComment;
  final ValueChanged<String> onToggleLike;
  final Future<bool> Function(String commentId, String content) onReply;
  final ValueChanged<String> onToggleReplyLike;
  final Future<bool> Function(String replyPath, String content) onReplyToReply;

  const ExploreCommentsPanel({
    super.key,
    required this.viewModel,
    required this.recipe,
    required this.isSubmitting,
    required this.canInteract,
    required this.onAddComment,
    required this.onToggleLike,
    required this.onReply,
    required this.onToggleReplyLike,
    required this.onReplyToReply,
  });

  @override
  State<ExploreCommentsPanel> createState() => _ExploreCommentsPanelState();
}

class _ExploreCommentsPanelState extends State<ExploreCommentsPanel> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Submits the comment and clears the input field.
  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty || widget.isSubmitting) return;
    widget.onAddComment(content);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.viewModel.visibleComments;

    return _CommunitySectionCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${comments.length} Comments',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join the conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Date filter dropdown for comments.
              _CommentFilterDropdown(
                label: _commentDateLabel(widget.viewModel.commentDateFilter),
                items: ExploreCommunityDateFilter.values.map((filter) {
                  return _CompactPopupItem(
                    value: filter.name,
                    label: _commentDateLabel(filter),
                  );
                }).toList(),
                onSelected: (value) {
                  final filter = ExploreCommunityDateFilter.values.firstWhere(
                        (item) => item.name == value,
                  );
                  widget.viewModel.updateCommentDateFilter(filter);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (comments.isEmpty)
            const _CommentsEmptyState()
          else
            Column(
              children: comments.map((comment) {
                return _CommentTile(
                  comment: comment,
                  isSubmitting: widget.isSubmitting,
                  canInteract: widget.canInteract,
                  onToggleLike: () => widget.onToggleLike(comment.id),
                  onReply: (content) => widget.onReply(comment.id, content),
                  onToggleReplyLike: widget.onToggleReplyLike,
                  onReplyToReply: widget.onReplyToReply,
                );
              }).toList(),
            ),
          if (widget.canInteract) ...[
            const SizedBox(height: 10),
            // Comment input text field with send button.
            TextField(
              controller: _commentController,
              minLines: 1,
              maxLines: 3,
              enabled: !widget.isSubmitting,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
              decoration: InputDecoration(
                hintText: 'Add a comment',
                prefixIcon: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.textSecondary.withValues(alpha: 0.45),
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.colors.primary,
                    width: 1.4,
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: widget.isSubmitting ? null : _submitComment,
                  icon: Icon(
                    Icons.send,
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            if (widget.isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LoadingDialog(
                  message: 'Posting comment...',
                  inline: true,
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _commentDateLabel(ExploreCommunityDateFilter filter) {
    switch (filter) {
      case ExploreCommunityDateFilter.all:
        return 'All';
      case ExploreCommunityDateFilter.latest:
        return 'Latest';
      case ExploreCommunityDateFilter.oldest:
        return 'Oldest';
    }
  }
}

/// Tile displaying a single comment with reply functionality and nested replies.
class _CommentTile extends StatefulWidget {
  final ExploreComment comment;
  final bool isSubmitting;
  final bool canInteract;
  final VoidCallback onToggleLike;
  final Future<bool> Function(String content) onReply;
  final ValueChanged<String> onToggleReplyLike;
  final Future<bool> Function(String replyPath, String content) onReplyToReply;

  const _CommentTile({
    required this.comment,
    required this.isSubmitting,
    required this.canInteract,
    required this.onToggleLike,
    required this.onReply,
    required this.onToggleReplyLike,
    required this.onReplyToReply,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  /// Submits a reply and closes the reply input on success.
  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || widget.isSubmitting || !widget.canInteract) return;
    final success = await widget.onReply(content);
    if (!mounted) return;
    if (success) {
      _replyController.clear();
      setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentBodyRow(
              avatarPath: comment.avatarPath,
              author: comment.author,
              timeAgo: comment.timeAgo,
              content: comment.content,
              likes: comment.likes,
              isLiked: comment.isLiked,
              titleStyle: context.text.titleMedium,
              contentStyle: context.text.bodyLarge,
              onToggleLike: widget.isSubmitting || !widget.canInteract
                  ? null
                  : widget.onToggleLike,
              onReplyTap: widget.isSubmitting || !widget.canInteract
                  ? null
                  : () => setState(() => _isReplying = !_isReplying),
            ),
            if (comment.replies.isNotEmpty) ...[
              const SizedBox(height: 10),
              _RepliesTimeline(
                replies: comment.replies,
                isSubmitting: widget.isSubmitting,
                canInteract: widget.canInteract,
                onToggleLike: widget.onToggleReplyLike,
                onReply: widget.onReplyToReply,
              ),
            ],
            if (_isReplying) ...[
              const SizedBox(height: 8),
              _ReplyInputField(
                controller: _replyController,
                enabled: !widget.isSubmitting,
                onSubmit: _submitReply,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Row displaying comment content with avatar, author, timestamp, and action buttons.
class _CommentBodyRow extends StatelessWidget {
  final String avatarPath;
  final String author;
  final String timeAgo;
  final String content;
  final int likes;
  final bool isLiked;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final VoidCallback? onToggleLike;
  final VoidCallback? onReplyTap;

  const _CommentBodyRow({
    required this.avatarPath,
    required this.author,
    required this.timeAgo,
    required this.content,
    required this.likes,
    required this.isLiked,
    required this.titleStyle,
    required this.contentStyle,
    required this.onToggleLike,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    const avatarRadius = 20.0;
    const avatarSize = 38.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecipeDetailAvatar(
              imagePath: avatarPath,
              radius: avatarRadius,
              imageSize: avatarSize,
              iconSize: avatarRadius,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _DatePill(label: timeAgo),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _HeartLikeButton(
              likes: likes,
              isLiked: isLiked,
              onTap: onToggleLike,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          overflow: TextOverflow.visible,
          style: contentStyle?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onReplyTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Reply',
            style: context.text.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped date label with subtle styling.
class _DatePill extends StatelessWidget {
  final String label;

  const _DatePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodySmall?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.72),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Heart-shaped like button with like count and toggle functionality.
class _HeartLikeButton extends StatelessWidget {
  final int likes;
  final bool isLiked;
  final VoidCallback? onTap;

  const _HeartLikeButton({
    required this.likes,
    required this.isLiked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isLiked
        ? AppColors.primary
        : AppColors.textSecondary.withValues(alpha: 0.72);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(width: 5),
            Text(
              '$likes',
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline display for nested replies with visual branch lines.
class _RepliesTimeline extends StatelessWidget {
  final List<ExploreCommentReply> replies;
  final bool isSubmitting;
  final bool canInteract;
  final ValueChanged<String> onToggleLike;
  final Future<bool> Function(String replyPath, String content) onReply;

  const _RepliesTimeline({
    required this.replies,
    required this.isSubmitting,
    required this.canInteract,
    required this.onToggleLike,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        children: replies.asMap().entries.map((entry) {
          final index = entry.key;
          final reply = entry.value;
          return _ReplyBranch(
            isLast: index == replies.length - 1,
            child: _ReplyTile(
              reply: reply,
              isSubmitting: isSubmitting,
              canInteract: canInteract,
              onToggleLike: onToggleLike,
              onReply: onReply,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Visual branch connector for nested reply threads.
class _ReplyBranch extends StatelessWidget {
  final Widget child;
  final bool isLast;

  const _ReplyBranch({required this.child, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomPaint(
            painter: _ReplyBranchPainter(
              color: AppColors.textSecondary.withValues(alpha: 0.42),
              isLast: isLast,
            ),
            child: const SizedBox(width: 8),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Custom painter for drawing reply branch lines.
class _ReplyBranchPainter extends CustomPainter {
  final Color color;
  final bool isLast;

  const _ReplyBranchPainter({required this.color, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const branchY = 18.0;
    final x = size.width * 0.45;

    // Draws vertical line and horizontal connector.
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, isLast ? branchY : size.height),
      paint,
    );
    canvas.drawLine(Offset(x, branchY), Offset(size.width, branchY), paint);
  }

  @override
  bool shouldRepaint(covariant _ReplyBranchPainter oldDelegate) {
    return color != oldDelegate.color || isLast != oldDelegate.isLast;
  }
}

/// Tile displaying a single reply with nested reply support.
class _ReplyTile extends StatefulWidget {
  final ExploreCommentReply reply;
  final bool isSubmitting;
  final bool canInteract;
  final ValueChanged<String> onToggleLike;
  final Future<bool> Function(String replyPath, String content) onReply;

  const _ReplyTile({
    required this.reply,
    required this.isSubmitting,
    required this.canInteract,
    required this.onToggleLike,
    required this.onReply,
  });

  @override
  State<_ReplyTile> createState() => _ReplyTileState();
}

class _ReplyTileState extends State<_ReplyTile> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  /// Submits a nested reply and closes the input on success.
  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || widget.isSubmitting || !widget.canInteract) return;
    final success = await widget.onReply(widget.reply.documentPath, content);
    if (!mounted) return;
    if (success) {
      _replyController.clear();
      setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reply = widget.reply;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentBodyRow(
            avatarPath: reply.avatarPath,
            author: reply.author,
            timeAgo: reply.timeAgo,
            content: reply.content,
            likes: reply.likes,
            isLiked: reply.isLiked,
            titleStyle: context.text.titleSmall,
            contentStyle: context.text.bodyMedium,
            onToggleLike: widget.isSubmitting || !widget.canInteract
                ? null
                : () => widget.onToggleLike(reply.documentPath),
            onReplyTap: widget.isSubmitting || !widget.canInteract
                ? null
                : () => setState(() => _isReplying = !_isReplying),
          ),
          if (reply.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: _RepliesTimeline(
                replies: reply.replies,
                isSubmitting: widget.isSubmitting,
                canInteract: widget.canInteract,
                onToggleLike: widget.onToggleLike,
                onReply: widget.onReply,
              ),
            ),
          ],
          if (_isReplying) ...[
            const SizedBox(height: 8),
            _ReplyInputField(
              controller: _replyController,
              enabled: !widget.isSubmitting,
              onSubmit: _submitReply,
            ),
          ],
        ],
      ),
    );
  }
}

/// Input field for writing replies to comments or replies.
class _ReplyInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;

  const _ReplyInputField({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 3,
      enabled: enabled,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: 'Write a reply',
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.colors.primary, width: 1.4),
        ),
        suffixIcon: IconButton(
          onPressed: enabled ? onSubmit : null,
          icon: const Icon(Icons.send),
        ),
      ),
    );
  }
}

/// Avatar widget with fallback to person icon when image is unavailable.
class _RecipeDetailAvatar extends StatelessWidget {
  final String imagePath;
  final double radius;
  final double imageSize;
  final double iconSize;

  const _RecipeDetailAvatar({
    required this.imagePath,
    required this.radius,
    required this.imageSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: hasImage
          ? ClipOval(
        child: AppRemoteOrAssetImage(
          imagePath: imagePath,
          width: imageSize,
          height: imageSize,
        ),
      )
          : Icon(Icons.person, color: AppColors.primary, size: iconSize),
    );
  }
}
