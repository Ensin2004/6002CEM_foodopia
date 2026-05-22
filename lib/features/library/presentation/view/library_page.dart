import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_segmented_tabs.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/entities/library_recipe.dart';
import '../viewmodel/library_viewmodel.dart';
import '../widgets/library_empty_state.dart';
import '../widgets/library_recipe_card.dart';

class LibraryPage extends StatelessWidget {
  final bool showAppBar;
  final VoidCallback? onExploreNow;

  const LibraryPage({super.key, this.showAppBar = false, this.onExploreNow});

  @override
  Widget build(BuildContext context) {
    final page = ChangeNotifierProvider(
      create: (_) => LibraryViewModel(
        getProfileUseCase: sl(),
        getRecipesUseCase: sl(),
        toggleFavouriteUseCase: sl(),
        updateProfileUseCase: sl(),
      ),
      child: _LibraryPageView(onExploreNow: onExploreNow),
    );

    if (!showAppBar) return page;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(title: 'Library'),
      body: page,
    );
  }
}

class _LibraryPageView extends StatefulWidget {
  final VoidCallback? onExploreNow;

  const _LibraryPageView({this.onExploreNow});

  @override
  State<_LibraryPageView> createState() => _LibraryPageViewState();
}

class _LibraryPageViewState extends State<_LibraryPageView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LibraryRecipeTab.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<LibraryViewModel>().selectTab(
      LibraryRecipeTab.values[_tabController.index],
    );
  }

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _showEditProfileSheet() async {
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
        child: _EditLibraryProfileSheet(profile: profile),
      ),
    );

    if (!mounted || updated != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  Future<void> _toggleFavourite(String recipeId) async {
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

    return _LibraryContent(
      viewModel: viewModel,
      tabController: _tabController,
      onExploreNow:
          widget.onExploreNow ?? () => context.push(AppRouter.explore),
      onComingSoonTap: _showComingSoonMessage,
      onEditProfileTap: _showEditProfileSheet,
      onFavouriteTap: _toggleFavourite,
    );
  }
}

class _LibraryContent extends StatelessWidget {
  final LibraryViewModel viewModel;
  final TabController tabController;
  final VoidCallback onExploreNow;
  final VoidCallback onComingSoonTap;
  final VoidCallback onEditProfileTap;
  final ValueChanged<String> onFavouriteTap;

  const _LibraryContent({
    required this.viewModel,
    required this.tabController,
    required this.onExploreNow,
    required this.onComingSoonTap,
    required this.onEditProfileTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading && viewModel.profile == null) {
      return const LoadingDialog(message: 'Loading library...', inline: true);
    }

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

    final recipes = viewModel.visibleRecipes;

    return SafeArea(
      top: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: _LibraryProfileHeader(
              profile: profile,
              postCount: viewModel.postCount,
              onMoreTap: onComingSoonTap,
              onEditProfileTap: onEditProfileTap,
            ),
          ),
          SliverToBoxAdapter(child: _LibraryTabs(tabController: tabController)),
          if (viewModel.shouldShowEmpty)
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
                  return LibraryRecipeCard(
                    recipe: recipe,
                    onComingSoonTap: onComingSoonTap,
                    onFavouriteTap: () => onFavouriteTap(recipe.id),
                    onTap: () async {
                      await context.push(
                        AppRouter.libraryRecipeDetail,
                        extra: LibraryRecipeDetailArgs(
                          recipeId: recipe.id,
                          isSelfPublished: recipe.isSelfPublished,
                          isPublished: recipe.isPublished,
                        ),
                      );
                      if (!context.mounted) return;
                      await viewModel.loadLibrary();
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
  final VoidCallback onMoreTap;
  final VoidCallback onEditProfileTap;

  const _LibraryProfileHeader({
    required this.profile,
    required this.postCount,
    required this.onMoreTap,
    required this.onEditProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final width = MediaQuery.sizeOf(context).width;
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
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: AppColors.primary,
                          size: 22,
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
                          ),
                        ),
                        _StatDivider(height: compact ? 34 : 40),
                        Expanded(
                          child: _ProfileStat(
                            value: profile.followingCount,
                            label: 'Following',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_ProfileMenuAction>(
                onSelected: (action) {
                  switch (action) {
                    case _ProfileMenuAction.editProfile:
                      onEditProfileTap();
                      break;
                    case _ProfileMenuAction.more:
                      onMoreTap();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ProfileMenuAction.editProfile,
                    child: Text('Edit Profile'),
                  ),
                  PopupMenuItem(
                    value: _ProfileMenuAction.more,
                    child: Text('More'),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProfileMenuAction { editProfile, more }

class _EditLibraryProfileSheet extends StatefulWidget {
  final LibraryProfile profile;

  const _EditLibraryProfileSheet({required this.profile});

  @override
  State<_EditLibraryProfileSheet> createState() =>
      _EditLibraryProfileSheetState();
}

class _EditLibraryProfileSheetState extends State<_EditLibraryProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    setState(() => _selectedImage = File(image.path));
  }

  Future<void> _save() async {
    final viewModel = context.read<LibraryViewModel>();
    final success = await viewModel.updateProfile(
      name: _nameController.text,
      bio: _bioController.text,
      imageFile: _selectedImage,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final message = viewModel.errorMessage ?? 'Unable to update profile.';
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
                    child: Text('Edit Profile', style: context.text.titleLarge),
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
              Center(
                child: GestureDetector(
                  onTap: viewModel.isSavingProfile ? null : _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: context.colors.surfaceContainerHighest,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : _imageProvider(widget.profile.imageUrl),
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                enabled: !viewModel.isSavingProfile,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bioController,
                enabled: !viewModel.isSavingProfile,
                minLines: 3,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _ProfileAvatar({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: context.colors.surfaceContainerHighest,
            backgroundImage: _imageProvider(imageUrl),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final int value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
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
      margin: const EdgeInsets.only(top: 18),
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

ImageProvider _imageProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return AssetImage(path);
}

String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}
