import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../meal_plan/domain/services/meal_calorie_guidance_service.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/entities/library_recipe.dart';
import '../viewmodel/library_viewmodel.dart';
import '../widgets/library_empty_state.dart';
import '../widgets/library_recipe_card.dart';

const int _libraryDescriptionWordLimit = 20;

// Builds the library screen with profile details, recipe tabs, refresh support, and optional meal-plan selection behavior.
class LibraryPage extends StatelessWidget {
  final bool showAppBar;
  final VoidCallback? onExploreNow;
  final String? focusedRecipeId;
  final bool? focusedRecipeIsPublished;
  final MealPlanSelectionArgs? mealPlanSelection;

  const LibraryPage({
    super.key,
    this.showAppBar = false,
    this.onExploreNow,
    this.focusedRecipeId,
    this.focusedRecipeIsPublished,
    this.mealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Opens the private tab first when navigation focuses an unpublished recipe.
    final initialTab = focusedRecipeIsPublished == false
        ? LibraryRecipeTab.private
        : LibraryRecipeTab.public;
    final page = ChangeNotifierProvider(
      create: (_) => LibraryViewModel(
        getProfileUseCase: sl(),
        getFollowersUseCase: sl(),
        getFollowingUseCase: sl(),
        getRecipesUseCase: sl(),
        toggleFavouriteUseCase: sl(),
        updateProfileUseCase: sl(),
        initialTab: initialTab,
      ),
      child: _LibraryPageView(
        onExploreNow: onExploreNow,
        focusedRecipeId: focusedRecipeId,
        initialTab: initialTab,
        mealPlanSelection: mealPlanSelection,
      ),
    );

    if (!showAppBar) return page;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: mealPlanSelection == null ? 'Library' : 'Add from Your Library',
        leading: mealPlanSelection == null
            ? null
            : IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.chevron_left),
              ),
      ),
      body: page,
    );
  }
}

class _LibraryPageView extends StatefulWidget {
  final VoidCallback? onExploreNow;
  final String? focusedRecipeId;
  final LibraryRecipeTab initialTab;
  final MealPlanSelectionArgs? mealPlanSelection;

  const _LibraryPageView({
    this.onExploreNow,
    this.focusedRecipeId,
    required this.initialTab,
    this.mealPlanSelection,
  });

  @override
  State<_LibraryPageView> createState() => _LibraryPageViewState();
}

class _LibraryPageViewState extends State<_LibraryPageView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _focusedRecipeId;

  @override
  void initState() {
    super.initState();
    _focusedRecipeId = widget.focusedRecipeId;
    _tabController = TabController(
      length: LibraryRecipeTab.values.length,
      vsync: this,
      initialIndex: LibraryRecipeTab.values.indexOf(widget.initialTab),
    );
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void didUpdateWidget(covariant _LibraryPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focusChanged = oldWidget.focusedRecipeId != widget.focusedRecipeId;
    final tabChanged = oldWidget.initialTab != widget.initialTab;
    if (!focusChanged && !tabChanged) return;

    _focusedRecipeId = widget.focusedRecipeId;
    final nextIndex = LibraryRecipeTab.values.indexOf(widget.initialTab);
    if (_tabController.index != nextIndex) {
      _tabController.animateTo(nextIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = context.read<LibraryViewModel>();
      viewModel.selectTab(widget.initialTab);
      viewModel.loadLibrary();
    });
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_focusedRecipeId != null) {
      setState(() => _focusedRecipeId = null);
    }
    // Syncs the selected recipe tab with the view model after manual tab changes.
    context.read<LibraryViewModel>().selectTab(
      LibraryRecipeTab.values[_tabController.index],
    );
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _showEditDescriptionSheet() async {
    // Opens the library description editor and confirms successful profile updates.
    final viewModel = context.read<LibraryViewModel>();
    final profile = viewModel.profile;
    if (profile == null) return;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _EditLibraryDescriptionSheet(profile: profile),
      ),
    );

    if (!mounted || updated != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Description updated')));
  }

  Future<void> _toggleFavourite(String recipeId) async {
    // Updates a recipe favourite state and shows an error message when saving fails.
    final viewModel = context.read<LibraryViewModel>();
    final success = await viewModel.toggleFavourite(recipeId);
    if (!mounted || success) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ?? 'Unable to update favourite.',
          ),
        ),
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
    final viewModel = context.watch<LibraryViewModel>();

    /*
      Displays the owned recipe library by connecting the LibraryViewModel to the page UI.
      The screen loads profile data, separates recipes into Public, Private, and Favourites tabs,
      handles recipe focus after navigation, supports pull-to-refresh, and opens recipe details,
      follower lists, favourite updates, and the edit-description bottom sheet.
    */
    return _LibraryContent(
      viewModel: viewModel,
      tabController: _tabController,
      onExploreNow:
          widget.onExploreNow ?? () => context.push(AppRouter.explore),
      onComingSoonTap: _showComingSoonMessage,
      onEditDescriptionTap: _showEditDescriptionSheet,
      onFavouriteTap: _toggleFavourite,
      // Opens the followers list from the profile statistics row.
      onFollowersTap: () => context.push(
        AppRouter.libraryProfileUsers,
        extra: const LibraryProfileUsersArgs(showFollowers: true),
      ),
      // Opens the following list from the profile statistics row.
      onFollowingTap: () => context.push(
        AppRouter.libraryProfileUsers,
        extra: const LibraryProfileUsersArgs(showFollowers: false),
      ),
      focusedRecipeId: _focusedRecipeId,
      mealPlanSelection: widget.mealPlanSelection,
    );
  }
}

class _LibraryContent extends StatelessWidget {
  final LibraryViewModel viewModel;
  final TabController tabController;
  final VoidCallback onExploreNow;
  final VoidCallback onComingSoonTap;
  final VoidCallback onEditDescriptionTap;
  final ValueChanged<String> onFavouriteTap;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;
  final String? focusedRecipeId;
  final MealPlanSelectionArgs? mealPlanSelection;

  const _LibraryContent({
    required this.viewModel,
    required this.tabController,
    required this.onExploreNow,
    required this.onComingSoonTap,
    required this.onEditDescriptionTap,
    required this.onFavouriteTap,
    required this.onFollowersTap,
    required this.onFollowingTap,
    this.focusedRecipeId,
    this.mealPlanSelection,
  });

  @override
  Widget build(BuildContext context) {
    // Shows an inline loading state while the profile and recipe list are first loaded.
    if (viewModel.isLoading && viewModel.profile == null) {
      return const LoadingDialog(message: 'Loading library...', inline: true);
    }

    // Shows the load failure message when profile data is unavailable.
    final error = viewModel.errorMessage;
    if (error != null && viewModel.profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ),
      );
    }

    final profile = viewModel.profile;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Displays profile details, recipe post count, and connection statistics.
          _LibraryProfileHeader(
            profile: profile,
            postCount: viewModel.postCount,
            onEditDescriptionTap: onEditDescriptionTap,
            onFollowersTap: onFollowersTap,
            onFollowingTap: onFollowingTap,
          ),
          // Provides segmented navigation between Public, Private, and Favourites recipes.
          _LibraryTabs(tabController: tabController),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: LibraryRecipeTab.values.map((tab) {
                return _LibraryRecipeResults(
                  key: PageStorageKey(tab),
                  tab: tab,
                  recipes: _focusedFirst(viewModel.visibleRecipesFor(tab)),
                  isEmpty: viewModel.shouldShowEmptyFor(tab),
                  onRefresh: viewModel.loadLibrary,
                  onExploreNow: onExploreNow,
                  focusedRecipeId: focusedRecipeId,
                  mealPlanSelection: mealPlanSelection,
                  onComingSoonTap: onComingSoonTap,
                  onFavouriteTap: onFavouriteTap,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<LibraryRecipe> _focusedFirst(List<LibraryRecipe> recipes) {
    // Moves the focused recipe to the first grid position after returning from detail navigation.
    final focusedId = focusedRecipeId;
    if (focusedId == null || focusedId.isEmpty) return recipes;

    final focusedIndex = recipes.indexWhere((recipe) => recipe.id == focusedId);
    if (focusedIndex <= 0) return recipes;

    return [
      recipes[focusedIndex],
      ...recipes.take(focusedIndex),
      ...recipes.skip(focusedIndex + 1),
    ];
  }
}

class _LibraryRecipeResults extends StatelessWidget {
  final LibraryRecipeTab tab;
  final List<LibraryRecipe> recipes;
  final bool isEmpty;
  final Future<void> Function() onRefresh;
  final VoidCallback onExploreNow;
  final String? focusedRecipeId;
  final MealPlanSelectionArgs? mealPlanSelection;
  final VoidCallback onComingSoonTap;
  final ValueChanged<String> onFavouriteTap;

  const _LibraryRecipeResults({
    super.key,
    required this.tab,
    required this.recipes,
    required this.isEmpty,
    required this.onRefresh,
    required this.onExploreNow,
    required this.focusedRecipeId,
    required this.mealPlanSelection,
    required this.onComingSoonTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      // Reloads profile and recipe data when the library grid is pulled down.
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: PageStorageKey(tab),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (isEmpty)
            // Shows the explore prompt when the selected tab has no recipes.
            SliverFillRemaining(
              hasScrollBody: false,
              child: LibraryEmptyState(onExploreNow: onExploreNow),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 720
                      ? 3
                      : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 282,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final recipe = recipes[index];
                  // Prevents duplicate meal-plan selection for recipes already added.
                  final disabled =
                      mealPlanSelection?.existingRecipeIds.contains(
                        recipe.id,
                      ) ??
                      false;
                  return LibraryRecipeCard(
                    recipe: recipe,
                    isHighlighted: recipe.id == focusedRecipeId,
                    disabled: disabled,
                    // Adds calorie guidance only while choosing a recipe for a meal plan.
                    calorieGuidance: mealPlanSelection == null
                        ? null
                        : MealCalorieGuidanceService().evaluate(
                            budget: mealPlanSelection!.calorieBudget,
                            mealCalories: recipe.nutrition.calories,
                          ),
                    onComingSoonTap: onComingSoonTap,
                    onFavouriteTap: () => onFavouriteTap(recipe.id),
                    // Opens the recipe media preview after a long press on the card image.
                    onImageLongPress: () =>
                        showRecipeMediaDialog(context, recipe.imagePath),
                    // Opens the recipe detail page and refreshes the library after returning.
                    onTap: () async {
                      final result = await context.push(
                        AppRouter.libraryRecipeDetail,
                        extra: LibraryRecipeDetailArgs(
                          recipeId: recipe.id,
                          isSelfPublished: recipe.isSelfPublished,
                          isPublished: recipe.isPublished,
                          isModerationHidden: recipe.isModerationHidden,
                          moderationHiddenReason:
                              recipe.moderationHiddenReason,
                          mealPlanSelection: mealPlanSelection,
                        ),
                      );
                      if (!context.mounted) return;
                      if (result == true && mealPlanSelection != null) {
                        context.pop(true);
                        return;
                      }
                      await onRefresh();
                    },
                  );
                }, childCount: recipes.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryProfileHeader extends StatelessWidget {
  final LibraryProfile profile;
  final int postCount;
  final VoidCallback onEditDescriptionTap;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;

  const _LibraryProfileHeader({
    required this.profile,
    required this.postCount,
    required this.onEditDescriptionTap,
    required this.onFollowersTap,
    required this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final width = MediaQuery.sizeOf(context).width;
    // Reduces avatar and statistic height on narrow screens.
    final compact = width < 380;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProfileAvatar(
                imageUrl: profile.imageUrl,
                size: compact ? 74 : 86,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: compact ? 24 : 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(value: postCount, label: 'Posts'),
                        ),
                        _StatDivider(height: compact ? 34 : 40),
                        Expanded(
                          child: _ProfileStat(
                            value: profile.followersCount,
                            label: 'Followers',
                            onTap: onFollowersTap,
                          ),
                        ),
                        _StatDivider(height: compact ? 34 : 40),
                        Expanded(
                          child: _ProfileStat(
                            value: profile.followingCount,
                            label: 'Following',
                            onTap: onFollowingTap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  profile.bio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Opens the bottom sheet used for updating the library description.
              IconButton(
                tooltip: 'Edit description',
                onPressed: onEditDescriptionTap,
                icon: const Icon(Icons.edit_outlined),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditLibraryDescriptionSheet extends StatefulWidget {
  final LibraryProfile profile;

  const _EditLibraryDescriptionSheet({required this.profile});

  @override
  State<_EditLibraryDescriptionSheet> createState() =>
      _EditLibraryDescriptionSheetState();
}

class _EditLibraryDescriptionSheetState
    extends State<_EditLibraryDescriptionSheet> {
  late final TextEditingController _bioController;
  late int _wordCount;

  @override
  void initState() {
    super.initState();
    final initialBio = _limitWords(
      widget.profile.bio,
      _libraryDescriptionWordLimit,
    );
    _bioController = TextEditingController(text: initialBio);
    _wordCount = _countWords(initialBio);
    _bioController.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _bioController.removeListener(_updateWordCount);
    _bioController.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    // Refreshes the visible word counter only when the count changes.
    final nextCount = _countWords(_bioController.text);
    if (nextCount == _wordCount) return;
    setState(() => _wordCount = nextCount);
  }

  Future<void> _save() async {
    // Saves the trimmed description through the library profile view model.
    final viewModel = context.read<LibraryViewModel>();
    final success = await viewModel.updateProfile(
      name: widget.profile.name,
      bio: _limitWords(_bioController.text, _libraryDescriptionWordLimit),
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final message = viewModel.errorMessage ?? 'Unable to update description.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryViewModel>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 20),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Description',
                      style: context.text.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: viewModel.isSavingProfile
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                enabled: !viewModel.isSavingProfile,
                // Restricts the description field to the library word limit.
                inputFormatters: const [
                  _WordLimitTextInputFormatter(_libraryDescriptionWordLimit),
                ],
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_wordCount/$_libraryDescriptionWordLimit',
                  style: context.text.bodySmall?.copyWith(
                    color: _wordCount >= _libraryDescriptionWordLimit
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: viewModel.isSavingProfile ? null : _save,
                child: viewModel.isSavingProfile
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Description'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordLimitTextInputFormatter extends TextInputFormatter {
  final int maxWords;

  const _WordLimitTextInputFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final limitedText = _limitWords(newValue.text, maxWords);
    if (limitedText == newValue.text) return newValue;

    final selectionOffset = newValue.selection.end;
    final nextOffset = selectionOffset > limitedText.length
        ? limitedText.length
        : selectionOffset;
    return TextEditingValue(
      text: limitedText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }
}

int _countWords(String value) {
  return RegExp(r'\S+').allMatches(value.trim()).length;
}

String _limitWords(String value, int maxWords) {
  final matches = RegExp(r'\S+').allMatches(value).toList();
  if (matches.length <= maxWords) return value;
  return value.substring(0, matches[maxWords - 1].end);
}

class _ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _ProfileAvatar({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: hasImage
            ? ClipOval(
                child: AppRemoteOrAssetImage(
                  imagePath: imageUrl,
                  width: size,
                  height: size,
                ),
              )
            : const Icon(Icons.person, color: AppColors.primary, size: 42),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _ProfileStat({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                _compactCount(value),
                maxLines: 1,
                style: context.text.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final double height;

  const _StatDivider({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: height, color: AppColors.border);
  }
}

class _LibraryTabs extends StatelessWidget {
  final TabController tabController;

  const _LibraryTabs({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabs(
      controller: tabController,
      tabs: LibraryRecipeTab.values.map(_tabLabel).toList(),
      isScrollable: false,
    );
  }

  static String _tabLabel(LibraryRecipeTab tab) {
    switch (tab) {
      case LibraryRecipeTab.public:
        return 'Public';
      case LibraryRecipeTab.private:
        return 'Private';
      case LibraryRecipeTab.favourites:
        return 'Favourites';
    }
  }
}

String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}
