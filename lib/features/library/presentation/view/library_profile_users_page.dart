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
import '../../domain/entities/library_profile.dart';
import '../viewmodel/library_profile_users_viewmodel.dart';

class LibraryProfileUsersPage extends StatelessWidget {
  final bool showFollowers;
  final String? ownerUid;

  const LibraryProfileUsersPage({
    super.key,
    required this.showFollowers,
    this.ownerUid,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryProfileUsersViewModel(
        getFollowersUseCase: sl(),
        getFollowingUseCase: sl(),
        showFollowers: showFollowers,
        ownerUid: ownerUid,
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
    final colors = context.colors;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colors.surface,
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

class _ProfileUsersBody extends StatefulWidget {
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
  State<_ProfileUsersBody> createState() => _ProfileUsersBodyState();
}

class _ProfileUsersBodyState extends State<_ProfileUsersBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LibraryProfileUser> get _filteredUsers {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return widget.users;

    return widget.users.where((user) {
      return user.name.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  void _handleSearchChanged(String value) {
    setState(() => _query = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const LoadingDialog(message: 'Loading profiles...', inline: true);
    }

    if (widget.errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ProfileUsersHeader(title: widget.title, count: 0),
          _MessageState(
            icon: Icons.error_outline,
            message: widget.errorMessage!,
          ),
        ],
      );
    }

    if (widget.users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ProfileUsersHeader(title: widget.title, count: 0),
          _MessageState(
            icon: Icons.people_outline,
            message: 'No ${widget.title.toLowerCase()} yet.',
          ),
        ],
      );
    }

    final filteredUsers = _filteredUsers;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: filteredUsers.isEmpty ? 3 : filteredUsers.length + 2,
      separatorBuilder: (_, index) {
        if (index == 0) return const SizedBox(height: 10);
        if (index == 1) return const SizedBox(height: 18);
        return const SizedBox(height: 14);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ProfileUsersHeader(
            title: widget.title,
            count: widget.users.length,
          );
        }

        if (index == 1) {
          return _ProfileSearchBar(
            controller: _searchController,
            hintText: 'Search ${widget.title.toLowerCase()}',
            onChanged: _handleSearchChanged,
          );
        }

        if (filteredUsers.isEmpty) {
          return _MessageState(
            icon: Icons.search_off,
            message: 'No matching profiles found.',
          );
        }

        final user = filteredUsers[index - 2];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ProfileUserCard(
            user: user,
            onTap: () {
              context.push(
                AppRouter.exploreCreatorDetail,
                extra: ExploreCreatorDetailArgs(creatorUid: user.uid),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProfileSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _ProfileSearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: context.colors.surfaceContainerHighest.withValues(
            alpha: 0.46,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
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
        ),
      ),
    );
  }
}

class _ProfileUsersHeader extends StatelessWidget {
  final String title;
  final int count;

  const _ProfileUsersHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'profile' : 'profiles'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(
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
      ),
    );
  }
}

class _ProfileUserCard extends StatelessWidget {
  final LibraryProfileUser user;
  final VoidCallback onTap;

  const _ProfileUserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.72),
                      width: 1.4,
                    ),
                  ),
                  child: _ProfileUserAvatar(imagePath: user.imageUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 16,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.76,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${_compactCount(user.followerCount)} followers',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.64),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MessageState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        children: [
          Image.asset('assets/images/empty_page.png', height: 118),
          const SizedBox(height: 18),
          Icon(icon, size: 30, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileUserAvatar extends StatelessWidget {
  final String imagePath;

  const _ProfileUserAvatar({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.trim().isNotEmpty;

    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white,
      child: hasImage
          ? ClipOval(
              child: AppRemoteOrAssetImage(
                imagePath: imagePath,
                width: 52,
                height: 52,
              ),
            )
          : const Icon(Icons.person, color: AppColors.primary, size: 30),
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}
