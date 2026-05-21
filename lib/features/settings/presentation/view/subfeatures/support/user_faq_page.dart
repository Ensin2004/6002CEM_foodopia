// Builds the user faq screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../domain/entities/faq_item.dart';
import '../../../../domain/usecases/support/faq/get_user_faq_items_usecase.dart';
import '../../../viewmodel/support/user_faq_viewmodel.dart';

/// Defines behavior for user faq page.
class UserFaqPage extends StatelessWidget {
  /// Creates a user faq page instance.
  const UserFaqPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => UserFaqViewModel(
        getUserFaqItemsUseCase: sl<GetUserFaqItemsUseCase>(),
      ),
      child: const _UserFaqPageView(),
    );
  }
}

/// Defines behavior for user faq page view.
class _UserFaqPageView extends StatelessWidget {
  /// Handles the user faq page view operation.
  const _UserFaqPageView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserFaqViewModel>();

    /// Handles the scaffold operation.
    return Scaffold(
      appBar: const CustomAppBar(title: 'FAQs', centerTitle: true),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : viewModel.items.isEmpty
          ? const Center(child: Text('No FAQs available yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: viewModel.items.length,
        itemBuilder: (context, index) {
          final item = viewModel.items[index];
          /// Handles the build faq item operation.
          return _buildFaqItem(context, item);
        },
      ),
    );
  }

  /// Handles the build faq item operation.
  Widget _buildFaqItem(BuildContext context, FaqItem item) {
    /// Handles the container operation.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1),
        color: Theme.of(context).cardColor,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Text(
            item.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          children: [
            /// Creates a align instance.
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.answer,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
