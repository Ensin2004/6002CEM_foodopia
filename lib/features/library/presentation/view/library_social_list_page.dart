import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../domain/entities/library_social_profile.dart';
import '../../domain/usecases/get_library_followers_usecase.dart';
import '../../domain/usecases/get_library_following_usecase.dart';
import '../viewmodel/library_social_list_viewmodel.dart';

class LibrarySocialListPage extends StatelessWidget {
  final LibrarySocialListType type;

  const LibrarySocialListPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibrarySocialListViewModel(
        getFollowersUseCase: sl<GetLibraryFollowersUseCase>(),
        getFollowingUseCase: sl<GetLibraryFollowingUseCase>(),
        type: type,
      ),
      child: const _LibrarySocialListView(),
    );
  }
}

class _LibrarySocialListView extends StatelessWidget {
  const _LibrarySocialListView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibrarySocialListViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: viewModel.title,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: SafeArea(child: _SocialListBody(viewModel: viewModel)),
    );
  }
}

class _SocialListBody extends StatelessWidget {
  final LibrarySocialListViewModel viewModel;

  const _SocialListBody({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return LoadingDialog(
        message: 'Loading ${viewModel.title}...',
        inline: true,
      );
    }

    final error = viewModel.errorMessage;
    if (error != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ),
      );
    }

    if (viewModel.shouldShowEmpty) {
      return _SocialEmptyState(title: viewModel.title);
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadProfiles,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: viewModel.profiles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final profile = viewModel.profiles[index];
          return _SocialProfileTile(profile: profile);
        },
      ),
    );
  }
}

class _SocialProfileTile extends StatelessWidget {
  final LibrarySocialProfile profile;

  const _SocialProfileTile({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          context.push(
            AppRouter.exploreCreatorDetail,
            extra: ExploreCreatorDetailArgs(creatorUid: profile.uid),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              AppRemoteOrAssetAvatar(
                imagePath: profile.imageUrl,
                radius: 24,
                backgroundColor: context.colors.surfaceContainerHighest,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialEmptyState extends StatelessWidget {
  final String title;

  const _SocialEmptyState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No $title yet',
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
