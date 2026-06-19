import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/entities/meal_plan_dashboard.dart';

part 'meal_plan_remote_dashboard_datasource.dart';
part 'meal_plan_remote_grocery_datasource.dart';
part 'meal_plan_remote_operations_datasource.dart';
part 'meal_plan_remote_helpers.dart';

/// Shared Firestore holder for meal plan remote data source mixins.
abstract class _MealPlanRemoteDataSourceCore {
  /// Firestore instance used for all database operations.
  final FirebaseFirestore firestore;

  /// Creates the shared Firestore holder.
  const _MealPlanRemoteDataSourceCore({required this.firestore});
}

/// Remote data source implementation for meal planning operations.
///
/// Public behavior is composed from focused mixins so each file stays readable:
/// dashboard queries, grocery list operations, meal plan operations, and helpers.
class MealPlanRemoteDataSource extends _MealPlanRemoteDataSourceCore
    with
        _MealPlanRemoteDataSourceHelpers,
        _MealPlanRemoteOperationsDataSource,
        _MealPlanRemoteGroceryDataSource,
        _MealPlanRemoteDashboardDataSource {
  /// Creates a new instance with the required Firestore reference.
  const MealPlanRemoteDataSource({required super.firestore});
}
