// Builds the admin rate us screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
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
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => AdminRateUsViewModel(
        getAllRatingsUseCase: sl<GetAllRatingsUseCase>(),
        getUserProfileUseCase: sl<GetUserProfileUseCase>(),
      ),
      child: const _AdminRateUsPageView(),
    );
  }
}

/// Defines behavior for admin rate us page view.
class _AdminRateUsPageView extends StatelessWidget {
  /// Handles the admin rate us page view operation.
  const _AdminRateUsPageView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminRateUsViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage Ratings', centerTitle: true),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : Column(
        children: [
          _buildStatisticsPanel(context, viewModel),
          _buildFilterControls(context, viewModel),
          /// Creates a expanded instance.
          Expanded(child: _buildRatingsList(context, viewModel)),
        ],
      ),
    );
  }

  /// Handles the build statistics panel operation.
  Widget _buildStatisticsPanel(BuildContext context, AdminRateUsViewModel viewModel) {
    final stats = viewModel.ratingStats;
    final totalRatings = stats['totalRatings'] as int;

    if (totalRatings == 0) return const SizedBox.shrink();

    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Creates a text instance.
            const Text('Overall Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            /// Creates a sized box instance.
            const SizedBox(height: 8),
            /// Creates a text instance.
            Text((stats['averageRating'] as double).toStringAsFixed(1),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            /// Creates a sized box instance.
            const SizedBox(height: 4),
            _buildStarRating((stats['averageRating'] as double).round(), size: 28),
            /// Creates a sized box instance.
            const SizedBox(height: 4),
            /// Creates a text instance.
            Text('$totalRatings reviews', style: TextStyle(color: Colors.grey[600])),
            /// Creates a sized box instance.
            const SizedBox(height: 12),
            ..._buildStarDistributionBars(
                stats['distribution'] as Map<int, int>,
                totalRatings,
                context
            ),
          ],
        ),
      ),
    );
  }

  /// Handles the build star rating operation.
  Widget _buildStarRating(int filledStars, {double size = 24}) {
    /// Handles the row operation.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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

  /// Handles the build star distribution bars operation.
  List<Widget> _buildStarDistributionBars(Map<int, int> distribution, int totalRatings, BuildContext context) {
    return distribution.entries.map((entry) {
      final percentage = totalRatings > 0 ? entry.value / totalRatings : 0.0;
      /// Handles the padding operation.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _buildStarRating(entry.key, size: 16),
            /// Creates a sized box instance.
            const SizedBox(width: 8),
            /// Creates a expanded instance.
            Expanded(
              child: Stack(
                children: [
                  /// Creates a container instance.
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  /// Creates a fractionally sized box instance.
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
            /// Creates a sized box instance.
            const SizedBox(width: 8),
            /// Creates a text instance.
            Text('${(percentage * 100).round()}%', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }

  /// Handles the build filter controls operation.
  Widget _buildFilterControls(BuildContext context, AdminRateUsViewModel viewModel) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          /// Creates a icon button instance.
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showStarFilterDialog(context, viewModel),
          ),
          /// Creates a icon button instance.
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptionsDialog(context, viewModel),
          ),
          /// Creates a expanded instance.
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

  /// Handles the show star filter dialog operation.
  void _showStarFilterDialog(BuildContext context, AdminRateUsViewModel viewModel) async {
    final selectedFilter = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Stars'),
        children: [
          /// Creates a simple dialog option instance.
          const SimpleDialogOption(
            child: Text('All Stars'),
          ),
          for (int i = 1; i <= 5; i++)
            /// Creates a simple dialog option instance.
            SimpleDialogOption(
              child: Text('$i Star${i > 1 ? 's' : ''}'),
              onPressed: () => Navigator.pop(context, i),
            ),
        ],
      ),
    );
    if (selectedFilter != null) viewModel.setStarFilter(selectedFilter);
  }

  /// Handles the show sort options dialog operation.
  void _showSortOptionsDialog(BuildContext context, AdminRateUsViewModel viewModel) async {
    final selectedOption = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sort Options'),
        children: [
          /// Creates a simple dialog option instance.
          SimpleDialogOption(
            child: const Text('Newest'),
            onPressed: () => Navigator.pop(context, 'newest'),
          ),
          /// Creates a simple dialog option instance.
          SimpleDialogOption(
            child: const Text('Oldest'),
            onPressed: () => Navigator.pop(context, 'oldest'),
          ),
          /// Creates a simple dialog option instance.
          SimpleDialogOption(
            child: const Text('Rating 5→1'),
            onPressed: () => Navigator.pop(context, '5to1'),
          ),
          /// Creates a simple dialog option instance.
          SimpleDialogOption(
            child: const Text('Rating 1→5'),
            onPressed: () => Navigator.pop(context, '1to5'),
          ),
        ],
      ),
    );
    if (selectedOption != null) viewModel.setSortOption(selectedOption);
  }

  /// Handles the build ratings list operation.
  Widget _buildRatingsList(BuildContext context, AdminRateUsViewModel viewModel) {
    if (viewModel.filteredRatings.isEmpty) {
      /// Handles the center operation.
      return const Center(child: Text('No ratings found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: viewModel.filteredRatings.length,
      itemBuilder: (context, index) {
        final rating = viewModel.filteredRatings[index];
        final userProfile = viewModel.getUserProfile(rating.userId);
        /// Handles the build rating item operation.
        return _buildRatingItem(context, rating, userProfile);
      },
    );
  }

  /// Handles the build rating item operation.
  Widget _buildRatingItem(BuildContext context, RatingEntity rating, UserProfile? userProfile) {
    final formattedDate = DateFormat('MMM dd, yyyy – hh:mm a').format(rating.updatedAt);
    final displayName = userProfile?.name ?? rating.userId;
    final profileImageUrl = userProfile?.profileImageUrl;

    /// Handles the container operation.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
          backgroundColor: Colors.grey[200],
          child: profileImageUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStarRating(rating.stars, size: 16),
            /// Creates a sized box instance.
            const SizedBox(height: 4),
            /// Creates a text instance.
            Text(rating.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ),
    );
  }
}
