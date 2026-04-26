import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../domain/entities/rating.dart';
import '../../../../domain/entities/user_profile.dart';
import '../../../../domain/usecases/get_all_ratings_usecase.dart';
import '../../../../domain/usecases/get_user_profile_usecase.dart';
import '../../../viewmodel/support/admin_rate_us_viewmodel.dart';

class AdminRateUsPage extends StatelessWidget {
  const AdminRateUsPage({super.key});

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
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildStatisticsPanel(context, viewModel),
          _buildFilterControls(context, viewModel),
          Expanded(child: _buildRatingsList(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel(BuildContext context, AdminRateUsViewModel viewModel) {
    final stats = viewModel.ratingStats;
    final totalRatings = stats['totalRatings'] as int;

    if (totalRatings == 0) return const SizedBox.shrink();

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
            const Text('Overall Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text((stats['averageRating'] as double).toStringAsFixed(1),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildStarRating((stats['averageRating'] as double).round(), size: 28),
            const SizedBox(height: 4),
            Text('$totalRatings reviews', style: TextStyle(color: Colors.grey[600])),
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

  Widget _buildStarRating(int filledStars, {double size = 24}) {
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

  List<Widget> _buildStarDistributionBars(Map<int, int> distribution, int totalRatings, BuildContext context) {
    return distribution.entries.map((entry) {
      final percentage = totalRatings > 0 ? entry.value / totalRatings : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            _buildStarRating(entry.key, size: 16),
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
            Text('${(percentage * 100).round()}%', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFilterControls(BuildContext context, AdminRateUsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showStarFilterDialog(context, viewModel),
          ),
          IconButton(
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

  void _showStarFilterDialog(BuildContext context, AdminRateUsViewModel viewModel) async {
    final selectedFilter = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Stars'),
        children: [
          const SimpleDialogOption(
            child: Text('All Stars'),
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

  void _showSortOptionsDialog(BuildContext context, AdminRateUsViewModel viewModel) async {
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
            child: const Text('Rating 5→1'),
            onPressed: () => Navigator.pop(context, '5to1'),
          ),
          SimpleDialogOption(
            child: const Text('Rating 1→5'),
            onPressed: () => Navigator.pop(context, '1to5'),
          ),
        ],
      ),
    );
    if (selectedOption != null) viewModel.setSortOption(selectedOption);
  }

  Widget _buildRatingsList(BuildContext context, AdminRateUsViewModel viewModel) {
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

  Widget _buildRatingItem(BuildContext context, RatingEntity rating, UserProfile? userProfile) {
    final formattedDate = DateFormat('MMM dd, yyyy – hh:mm a').format(rating.updatedAt);
    final displayName = userProfile?.name ?? rating.userId;
    final profileImageUrl = userProfile?.profileImageUrl;

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
            const SizedBox(height: 4),
            Text(rating.comment, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ),
    );
  }
}