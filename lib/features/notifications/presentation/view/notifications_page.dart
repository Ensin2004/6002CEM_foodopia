import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/usecases/get_notification_preferences_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../domain/usecases/schedule_plan_reminder_usecase.dart';
import '../../domain/usecases/update_notification_preference_usecase.dart';
import '../viewmodel/notifications_viewmodel.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsViewModel(
        getNotificationsUseCase: sl<GetNotificationsUseCase>(),
        getPreferencesUseCase: sl<GetNotificationPreferencesUseCase>(),
        markAsReadUseCase: sl<MarkNotificationAsReadUseCase>(),
        markAllAsReadUseCase: sl<MarkAllNotificationsAsReadUseCase>(),
        updatePreferenceUseCase: sl<UpdateNotificationPreferenceUseCase>(),
        schedulePlanReminderUseCase: sl<SchedulePlanReminderUseCase>(),
      ),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();

    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final message = viewModel.errorMessage;
        if (message == null || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
        context.read<NotificationsViewModel>().clearError();
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Notification',
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<_NotificationMenuAction>(
            icon: const Icon(Icons.more_horiz),
            offset: const Offset(0, 40),
            onSelected: (action) => _handleMenuAction(
              context: context,
              viewModel: viewModel,
              action: action,
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _NotificationMenuAction.markAllAsRead,
                child: _NotificationMenuItem(
                  icon: Icons.done_all,
                  label: 'Mark all as read',
                ),
              ),
            ],
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : viewModel.notifications.isEmpty
          ? const NotificationEmptyState()
          : RefreshIndicator(
              onRefresh: viewModel.load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: viewModel.notifications.length,
                itemBuilder: (context, index) {
                  final notification = viewModel.notifications[index];
                  return NotificationTile(
                    notification: notification,
                    onTap: () => viewModel.markAsRead(notification.id),
                  );
                },
              ),
            ),
    );
  }

  void _handleMenuAction({
    required BuildContext context,
    required NotificationsViewModel viewModel,
    required _NotificationMenuAction action,
  }) {
    switch (action) {
      case _NotificationMenuAction.markAllAsRead:
        viewModel.markAllAsRead();
        break;
    }
  }
}

enum _NotificationMenuAction { markAllAsRead }

class _NotificationMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NotificationMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 14),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
