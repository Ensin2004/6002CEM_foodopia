import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/library_profile.dart';
import '../viewmodel/library_profile_users_viewmodel.dart';

class LibraryProfileUsersPage extends StatelessWidget {
  final bool showFollowers;

  const LibraryProfileUsersPage({super.key, required this.showFollowers});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryProfileUsersViewModel(
        getFollowersUseCase: sl(),
        getFollowingUseCase: sl(),
        showFollowers: showFollowers,
      ),
      child: _LibraryProfileUsersView(showFollowers: showFollowers),
    );
  }
}

class _LibraryProfileUsersView extends StatelessWidget {
  final bool showFollowers;

  const _LibraryProfileUsersView({required this.showFollowers});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LibraryProfileUsersViewModel>();
    final title = showFollowers ? 'Followers' : 'Following';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: title,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.loadUsers,
          child: _ProfileUsersBody(
            title: title,
            users: viewModel.users,
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
          ),
        ),
      ),
    );
  }
}

class _ProfileUsersBody extends StatelessWidget {
  final String title;
  final List<LibraryProfileUser> users;
  final bool isLoading;
  final String? errorMessage;

  const _ProfileUsersBody({
    required this.title,
    required this.users,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingDialog(message: 'Loading profiles...', inline: true);
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
          ),
        ],
      );
    }

    if (users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 96),
          Image.asset('assets/images/empty_page.png', height: 140),
          const SizedBox(height: 16),
          Text(
            'No ${title.toLowerCase()} yet.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          onTap: () {
            context.push(
              AppRouter.exploreCreatorDetail,
              extra: ExploreCreatorDetailArgs(creatorUid: user.uid),
            );
          },
          leading: CircleAvatar(
            backgroundColor: context.colors.surfaceContainerHighest,
            backgroundImage: _imageProvider(user.imageUrl),
          ),
          title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${_compactCount(user.followerCount)} followers',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
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
