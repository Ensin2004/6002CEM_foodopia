import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../domain/usecases/create_grocery_list_usecase.dart';
import '../../domain/usecases/get_add_grocery_list_plan_usecase.dart';
import '../viewmodel/grocery/add_grocery_list_viewmodel.dart';
import '../widgets/grocery/add_grocery/basic_info_step.dart';
import '../widgets/grocery/add_grocery/add_grocery_app_bar.dart';
import '../widgets/grocery/add_grocery/select_meals_step.dart';

/// Page for creating a new grocery list.
/// Provides a two-step wizard for configuring list details and selecting meals.
class AddGroceryListPage extends StatelessWidget {
  /// User ID of the current user.
  final String userId;

  /// Creates a new add grocery list page instance.
  const AddGroceryListPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => AddGroceryListViewModel(
        userId: userId,
        getPlanUseCase: sl<GetAddGroceryListPlanUseCase>(),
        createGroceryListUseCase: sl<CreateGroceryListUseCase>(),
      ),
      child: const _AddGroceryListView(),
    );
  }
}

/// Internal view for the add grocery list page.
class _AddGroceryListView extends StatefulWidget {
  /// Creates a new add grocery list view instance.
  const _AddGroceryListView();

  @override
  State<_AddGroceryListView> createState() => _AddGroceryListViewState();
}

/// State for the add grocery list view.
class _AddGroceryListViewState extends State<_AddGroceryListView> {
  /// Text controller for the list name input.
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<AddGroceryListViewModel>();

    // Show loading dialog while plan is loading.
    if (viewModel.isLoading && viewModel.plan == null) {
      return const Scaffold(
        body: LoadingDialog(inline: true, message: 'Loading grocery setup...'),
      );
    }

    // Get the plan.
    final plan = viewModel.plan;

    // Show error state if plan is null.
    if (plan == null) {
      return Scaffold(
        appBar: AddGroceryAppBar(onBack: () => context.pop()),
        body: AddGroceryErrorState(
          message: viewModel.errorMessage ?? 'Unable to load grocery setup',
          onRetry: viewModel.loadPlan,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AddGroceryAppBar(
        onBack: () {
          if (viewModel.currentStep == 2) {
            // Go back to previous step.
            context.read<AddGroceryListViewModel>().goToPreviousStep();
          } else {
            // Pop the page.
            context.pop();
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              child: AppStepProgressBar(
                totalSteps: 2,
                currentStep: viewModel.currentStep,
                labels: const ['Basic Information', 'Select Meals'],
              ),
            ),
            // Dynamic step content.
            Expanded(
              child: viewModel.currentStep == 1
                  ? AddGroceryBasicInfoStep(
                      plan: plan,
                      nameController: _nameController,
                    )
                  : const AddGrocerySelectMealsStep(),
            ),
          ],
        ),
      ),
    );
  }
}
