import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/admin_home_dashboard.dart';
import '../models/admin_home_dashboard_model.dart';

/// Remote data source for the admin home dashboard.
///
/// Firestore collections provide live metrics, help tickets, and app feedback.
/// Static quick-access metadata stays local because navigation labels and icons
/// belong to the presentation contract rather than stored business records.
class AdminHomeRemoteDataSource {
  /// Firebase Authentication instance.
  final FirebaseAuth auth;

  /// Firestore instance for database operations.
  final FirebaseFirestore firestore;

  /// Creates a new admin home remote data source instance.
  const AdminHomeRemoteDataSource({
    required this.auth,
    required this.firestore,
  });

  // =========================================================================
  // DASHBOARD
  // =========================================================================

  /// Retrieves the admin home dashboard.
  Future<AdminHomeDashboardModel> getDashboard(String fallbackAdminName) async {
    // Resolve the admin's display name.
    final adminName = await _resolveAdminName(fallbackAdminName);

    // Load metric data.
    final metricData = await _loadMetricData();

    // Load pending reviews.
    final pendingReviews = await _loadPendingReviews();

    // Load feedback items.
    final feedbackItems = await _loadFeedbackItems();

    // Build and return the dashboard.
    return AdminHomeDashboardModel(
      adminName: adminName,
      metrics: _buildMetrics(metricData),
      quickAccessItems: _quickAccessItems,
      pendingReviews: pendingReviews,
      feedbackItems: feedbackItems,
    );
  }

  // =========================================================================
  // ADMIN NAME RESOLUTION
  // =========================================================================

  /// Resolve a friendly admin display name.
  ///
  /// Priority order:
  /// - Firestore users/{uid}.name
  /// - Firestore firstName + lastName
  /// - Firebase Auth displayName
  /// - Route-provided fallback name
  Future<String> _resolveAdminName(String fallbackAdminName) async {
    // Get the current user.
    final currentUser = auth.currentUser;

    // Clean the fallback name.
    final fallback = _cleanText(fallbackAdminName);

    // Return fallback if no user.
    if (currentUser == null) return fallback.isEmpty ? 'Admin' : fallback;

    // Get user document from Firestore.
    final snapshot = await firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final data = snapshot.data();

    // Try Firestore full name.
    if (data != null) {
      final fullName = _cleanText(data['name']);
      if (fullName.isNotEmpty) return fullName;

      // Try Firestore first + last name.
      final firstName = _cleanText(data['firstName']);
      final lastName = _cleanText(data['lastName']);
      final joinedName = [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' ');

      if (joinedName.isNotEmpty) return joinedName;
    }

    // Try Firebase Auth display name.
    final authName = _cleanText(currentUser.displayName);
    if (authName.isNotEmpty) return authName;

    // Return fallback.
    return fallback.isEmpty ? 'Admin' : fallback;
  }

  // =========================================================================
  // METRIC DATA LOADING
  // =========================================================================

  /// Load collections required for dashboard metric calculations.
  ///
  /// Full snapshots keep the implementation compatible with the current app
  /// schema, including documents without createdAt values from older records.
  Future<_AdminMetricData> _loadMetricData() async {
    // Load users.
    final usersSnapshot = await firestore
        .collection('users')
        .get()
        .timeout(const Duration(seconds: 8));

    // Load recipes.
    final recipesSnapshot = await firestore
        .collection('recipes')
        .get()
        .timeout(const Duration(seconds: 8));

    // Load ratings.
    final ratingsSnapshot = await _ratingsCollection.get().timeout(
      const Duration(seconds: 8),
    );

    return _AdminMetricData(
      users: usersSnapshot.docs,
      recipes: recipesSnapshot.docs,
      ratings: ratingsSnapshot.docs,
    );
  }

  // =========================================================================
  // METRIC BUILDING
  // =========================================================================

  /// Builds metrics from loaded data.
  List<AdminMetric> _buildMetrics(_AdminMetricData data) {
    // Get date ranges.
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 7));
    final previousStart = now.subtract(const Duration(days: 14));

    // Seven-day windows power the change labels beside each live metric.

    // Count users.
    final currentUsers = _countDocumentsBetween(
      data.users,
      start: currentStart,
      end: now,
    );
    final previousUsers = _countDocumentsBetween(
      data.users,
      start: previousStart,
      end: currentStart,
    );

    // Count recipes.
    final currentRecipes = _countDocumentsBetween(
      data.recipes,
      start: currentStart,
      end: now,
    );
    final previousRecipes = _countDocumentsBetween(
      data.recipes,
      start: previousStart,
      end: currentStart,
    );

    // Count feedback.
    final currentFeedback = _countDocumentsBetween(
      data.ratings,
      start: currentStart,
      end: now,
      fallbackTimestampField: 'updatedAt',
    );
    final previousFeedback = _countDocumentsBetween(
      data.ratings,
      start: previousStart,
      end: currentStart,
      fallbackTimestampField: 'updatedAt',
    );

    // Calculate average ratings.
    final currentAverageRating = _averageRating(data.ratings);
    final previousAverageRating = _averageRating(
      data.ratings.where((doc) {
        final date = _timestampFromData(doc.data(), primaryField: 'updatedAt');
        return date != null && date.isBefore(currentStart);
      }).toList(),
    );

    // Return metrics.
    return [
      // New Users.
      AdminMetric(
        title: 'New Users',
        value: _formatCount(currentUsers),
        change: _formatCountChange(currentUsers, previousUsers),
        note: 'vs last 7 days',
        icon: Icons.group,
        iconColor: const Color(0xFF10A84E),
        iconBackgroundColor: const Color(0xFFEAF8EF),
      ),

      // New Recipes.
      AdminMetric(
        title: 'New Recipes',
        value: _formatCount(currentRecipes),
        change: _formatCountChange(currentRecipes, previousRecipes),
        note: 'vs last 7 days',
        icon: Icons.description,
        iconColor: const Color(0xFF42A5F5),
        iconBackgroundColor: const Color(0xFFE6F4FF),
      ),

      // Feedback.
      AdminMetric(
        title: 'Feedbacks',
        value: _formatCount(currentFeedback),
        change: _formatCountChange(currentFeedback, previousFeedback),
        note: 'vs last 7 days',
        icon: Icons.chat_bubble_outline,
        iconColor: const Color(0xFFFFA726),
        iconBackgroundColor: const Color(0xFFFFF3E0),
      ),

      // Average Rating.
      AdminMetric(
        title: 'Avg. Rating',
        value: currentAverageRating.toStringAsFixed(1),
        change: _formatRatingChange(
          currentAverageRating,
          previousAverageRating,
        ),
        note: 'all feedback',
        icon: Icons.star,
        iconColor: const Color(0xFFB15CFF),
        iconBackgroundColor: const Color(0xFFF3E8FF),
      ),
    ];
  }

  // =========================================================================
  // PENDING REVIEWS
  // =========================================================================

  /// Loads pending reviews from help tickets.
  Future<List<AdminPendingReview>> _loadPendingReviews() async {
    // Query help tickets sorted by creation date.
    final snapshot = await _helpTicketsCollection
        .orderBy('createdAt', descending: true)
        .limit(6)
        .get()
        .timeout(const Duration(seconds: 8));

    // Filter for open tickets.
    final openDocs = snapshot.docs
        .where((doc) {
      final data = doc.data();
      final status = _cleanText(data['status']).toLowerCase();
      final replied = data['replied'] == true;

      return !replied && status != 'closed' && status != 'replied';
    })
        .take(2);

    // Build review items.
    final reviews = <AdminPendingReview>[];

    // Latest unresolved help tickets become pending admin review cards.
    for (final doc in openDocs) {
      final data = doc.data();
      final uid = _cleanText(data['uid']);
      final userName = await _userName(uid);
      final createdAt = _timestampFromData(data) ?? DateTime.now();

      reviews.add(
        AdminPendingReview(
          initials: _initials(userName),
          userName: userName,
          title: _reviewTitle(data),
          timeAgo: _timeAgo(createdAt),
          badge: _badgeFor(createdAt),
        ),
      );
    }

    return reviews;
  }

  // =========================================================================
  // FEEDBACK ITEMS
  // =========================================================================

  /// Loads feedback items from ratings.
  Future<List<AdminFeedbackItem>> _loadFeedbackItems() async {
    // Query ratings sorted by update date.
    final snapshot = await _ratingsCollection
        .orderBy('updatedAt', descending: true)
        .limit(2)
        .get()
        .timeout(const Duration(seconds: 8));

    // Build feedback items.
    final feedbackItems = <AdminFeedbackItem>[];

    // Latest app rating feedback documents populate the feedback section.
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final uid = _cleanText(data['uid']).isEmpty
          ? doc.id
          : _cleanText(data['uid']);
      final userName = await _userName(uid);
      final updatedAt =
          _timestampFromData(data, primaryField: 'updatedAt') ?? DateTime.now();

      feedbackItems.add(
        AdminFeedbackItem(
          initials: _initials(userName),
          userName: userName,
          rating: _doubleValue(data['stars']),
          comment: _cleanText(data['comment']).isEmpty
              ? 'No written feedback'
              : _cleanText(data['comment']),
          timeAgo: _timeAgo(updatedAt),
        ),
      );
    }

    return feedbackItems;
  }

  // =========================================================================
  // COLLECTION REFERENCES
  // =========================================================================

  /// Reference to the help tickets collection.
  CollectionReference<Map<String, dynamic>> get _helpTicketsCollection =>
      firestore
          .collection('support_center')
          .doc('help_tickets')
          .collection('items');

  /// Reference to the ratings collection.
  CollectionReference<Map<String, dynamic>> get _ratingsCollection => firestore
      .collection('support_center')
      .doc('app_rating_feedback')
      .collection('items');

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Counts documents between two dates.
  int _countDocumentsBetween(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
        required DateTime start,
        required DateTime end,
        String fallbackTimestampField = 'createdAt',
      }) {
    return docs.where((doc) {
      final data = doc.data();
      final date = _timestampFromData(
        data,
        primaryField: 'createdAt',
        fallbackField: fallbackTimestampField,
      );

      return date != null && !date.isBefore(start) && date.isBefore(end);
    }).length;
  }

  /// Calculates the average rating from documents.
  double _averageRating(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    // Extract valid ratings.
    final ratings = docs
        .map((doc) => _doubleValue(doc.data()['stars']))
        .where((rating) => rating > 0)
        .toList();

    // Return 0 if no ratings.
    if (ratings.isEmpty) return 0;

    // Calculate average.
    final total = ratings.fold<double>(
      0,
          (runningTotal, rating) => runningTotal + rating,
    );
    return total / ratings.length;
  }

  /// Extracts a timestamp from document data.
  DateTime? _timestampFromData(
      Map<String, dynamic> data, {
        String primaryField = 'createdAt',
        String fallbackField = 'updatedAt',
      }) {
    // Try primary field.
    final primary = data[primaryField];
    if (primary is Timestamp) return primary.toDate();

    // Try fallback field.
    final fallback = data[fallbackField];
    if (fallback is Timestamp) return fallback.toDate();

    return null;
  }

  /// Gets a user's display name.
  Future<String> _userName(String uid) async {
    // Return default for empty UID.
    if (uid.isEmpty) return 'Unknown User';

    // Get user document.
    final snapshot = await firestore.collection('users').doc(uid).get();
    final data = snapshot.data();

    // Return default if no data.
    if (data == null) return 'Unknown User';

    // Try full name.
    final name = _cleanText(data['name']);
    if (name.isNotEmpty) return name;

    // Try first + last name.
    final firstName = _cleanText(data['firstName']);
    final lastName = _cleanText(data['lastName']);
    final joinedName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');

    return joinedName.isEmpty ? 'Unknown User' : joinedName;
  }

  /// Builds a review title from data.
  String _reviewTitle(Map<String, dynamic> data) {
    final message = _cleanText(data['message']);
    if (message.isEmpty) return 'Help Center Ticket';
    if (message.length <= 34) return message;
    return '${message.substring(0, 34)}...';
  }

  /// Returns a badge label for a date.
  String _badgeFor(DateTime date) {
    final age = DateTime.now().difference(date);
    return age.inHours < 24 ? 'New' : 'Open';
  }

  /// Formats a date as a time ago string.
  String _timeAgo(DateTime date) {
    final age = DateTime.now().difference(date);

    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes} min ago';
    if (age.inHours < 24) return '${age.inHours} hours ago';
    if (age.inDays < 7) return '${age.inDays} days ago';

    final weeks = age.inDays ~/ 7;
    return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  }

  /// Gets initials from a name.
  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  /// Formats a count with k suffix.
  String _formatCount(int count) {
    if (count < 1000) return count.toString();

    final thousands = count / 1000;
    return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
  }

  /// Formats a count change as percentage.
  String _formatCountChange(int current, int previous) {
    if (previous == 0) return current == 0 ? '0%' : '+$current';

    final percent = ((current - previous) / previous * 100).round();
    return percent >= 0 ? '+$percent%' : '$percent%';
  }

  /// Formats a rating change.
  String _formatRatingChange(double current, double previous) {
    if (previous <= 0) {
      return current <= 0 ? '0.0' : '+${current.toStringAsFixed(1)}';
    }

    final change = current - previous;
    final formatted = change.toStringAsFixed(1);
    return change >= 0 ? '+$formatted' : formatted;
  }

  /// Converts a value to a double.
  double _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Cleans text by trimming and converting to string.
  String _cleanText(Object? value) => value?.toString().trim() ?? '';

  // =========================================================================
  // QUICK ACCESS ITEMS
  // =========================================================================

  /// List of quick access items for admin.
  static const List<AdminQuickAccessItem> _quickAccessItems = [
    AdminQuickAccessItem(
      title: 'Manage Content',
      description: 'Recipes, Categories',
      icon: Icons.article,
    ),

    AdminQuickAccessItem(
      title: 'View Stats',
      description: 'Analytics & Reports',
      icon: Icons.bar_chart,
    ),

    AdminQuickAccessItem(
      title: 'Manage Feedback',
      description: 'Reviews & Reports',
      icon: Icons.chat,
    ),

    AdminQuickAccessItem(
      title: 'Settings',
      description: 'App & System Settings',
      icon: Icons.settings,
    ),
  ];
}

/// Internal data class for metric data.
class _AdminMetricData {
  /// User documents.
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> users;

  /// Recipe documents.
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> recipes;

  /// Rating documents.
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> ratings;

  /// Creates a new admin metric data instance.
  const _AdminMetricData({
    required this.users,
    required this.recipes,
    required this.ratings,
  });
}