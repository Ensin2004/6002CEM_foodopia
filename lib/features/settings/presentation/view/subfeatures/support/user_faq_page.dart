import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';
import '../../../../domain/entities/faq_item.dart';
import '../../../../domain/usecases/get_user_faq_items_usecase.dart';
import '../../../viewmodel/support/user_faq_viewmodel.dart';

class UserFaqPage extends StatelessWidget {
  const UserFaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserFaqViewModel(
        getUserFaqItemsUseCase: sl<GetUserFaqItemsUseCase>(),
      ),
      child: const _UserFaqPageView(),
    );
  }
}

class _UserFaqPageView extends StatelessWidget {
  const _UserFaqPageView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserFaqViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'FAQs', centerTitle: true),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.items.isEmpty
          ? const Center(child: Text('No FAQs available yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: viewModel.items.length,
        itemBuilder: (context, index) {
          final item = viewModel.items[index];
          return _buildFaqItem(context, item);
        },
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, FaqItem item) {
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