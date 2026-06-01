// Builds the admin rate us screen.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../app/routers/app_router.dart';
import '../../../../../../app/routers/router_args.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/entities/rating.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/usecases/account/get_user_profile_usecase.dart';
import '../../../../domain/usecases/support/rating/get_all_ratings_usecase.dart';
import '../../../viewmodel/support/admin_rate_us_viewmodel.dart';

/// Defines behavior for admin rate us page.
class AdminRateUsPage extends StatelessWidget {
  /// Creates a admin rate us page instance.
  const AdminRateUsPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminRateUsViewModel(
        getAllRatingsUseCase: sl<GetAllRatingsUseCase>(),
        getUserProfileUseCase: sl<GetUserProfileUseCase>(),
      ),
      child: const _AdminRateUsPageView(),
    );
  }
}

class _AdminRateUsPageView extends StatelessWidget {
  const _AdminRateUsPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminRateUsViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage Ratings', centerTitle: true),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : Column(
              children: [
                _buildStatisticsPanel(context, viewModel),
                _buildFilterControls(context, viewModel),
                Expanded(child: _buildRatingsList(context, viewModel)),
              ],
            ),
    );
  }

  Widget _buildStatisticsPanel(
    BuildContext context,
    AdminRateUsViewModel viewModel,
  ) {
    final stats = viewModel.ratingStats;
    final totalRatings = stats['totalRatings'] as int;

    if (totalRatings == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Overall Rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              (stats['averageRating'] as double).toStringAsFixed(1),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildStarRating(
              (stats['averageRating'] as double).round(),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              '$totalRatings reviews',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ..._buildStarDistributionBars(
              stats['distribution'] as Map<int, int>,
              totalRatings,
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int filledStars, {double size = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < filledStars ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        ),
      ),
    );
  }

  List<Widget> _buildStarDistributionBars(
    Map<int, int> distribution,
    int totalRatings,
    BuildContext context,
  ) {
    return distribution.entries.map((entry) {
      final percentage = totalRatings > 0 ? entry.value / totalRatings : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 92, child: _buildStarRating(entry.key, size: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percentage * 100).round()}%',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFilterControls(
    BuildContext context,
    AdminRateUsViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Filter by stars',
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showStarFilterDialog(context, viewModel),
          ),
          IconButton(
            tooltip: 'Sort ratings',
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptionsDialog(context, viewModel),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: viewModel.setSearchTerm,
            ),
          ),
        ],
      ),
    );
  }

  void _showStarFilterDialog(
    BuildContext context,
    AdminRateUsViewModel viewModel,
  ) async {
    final selectedFilter = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Stars'),
        children: [
          SimpleDialogOption(
            child: const Text('All Stars'),
            onPressed: () => Navigator.pop(context, 0),
          ),
          for (int i = 1; i <= 5; i++)
            SimpleDialogOption(
              child: Text('$i Star${i > 1 ? 's' : ''}'),
              onPressed: () => Navigator.pop(context, i),
            ),
        ],
      ),
    );
    if (selectedFilter != null) viewModel.setStarFilter(selectedFilter);
  }

  void _showSortOptionsDialog(
    BuildContext context,
    AdminRateUsViewModel viewModel,
  ) async {
    final selectedOption = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sort Options'),
        children: [
          SimpleDialogOption(
            child: const Text('Newest'),
            onPressed: () => Navigator.pop(context, 'newest'),
          ),
          SimpleDialogOption(
            child: const Text('Oldest'),
            onPressed: () => Navigator.pop(context, 'oldest'),
          ),
          SimpleDialogOption(
            child: const Text('Rating (High to Low)'),
            onPressed: () => Navigator.pop(context, '5to1'),
          ),
          SimpleDialogOption(
            child: const Text('Rating (Low to High)'),
            onPressed: () => Navigator.pop(context, '1to5'),
          ),
        ],
      ),
    );
    if (selectedOption != null) viewModel.setSortOption(selectedOption);
  }

  Widget _buildRatingsList(
    BuildContext context,
    AdminRateUsViewModel viewModel,
  ) {
    if (viewModel.filteredRatings.isEmpty) {
      return const Center(child: Text('No ratings found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: viewModel.filteredRatings.length,
      itemBuilder: (context, index) {
        final rating = viewModel.filteredRatings[index];
        final userProfile = viewModel.getUserProfile(rating.userId);
        return _buildRatingItem(context, rating, userProfile);
      },
    );
  }

  Widget _buildRatingItem(
    BuildContext context,
    RatingEntity rating,
    UserProfile? userProfile,
  ) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'MMM dd, yyyy - hh:mm a',
    ).format(rating.updatedAt);
    final displayName = userProfile?.name ?? rating.userId;
    final profileImageUrl = userProfile?.profileImageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : null,
              backgroundColor: Colors.grey[200],
              child: profileImageUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildStarRating(rating.stars, size: 18),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'View details',
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () => context.push(
                AppRouter.ratingDetail,
                extra: RatingDetailArgs(
                  rating: rating,
                  userProfile: userProfile,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
