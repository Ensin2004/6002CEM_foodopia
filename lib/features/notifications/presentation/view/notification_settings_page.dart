import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/usecases/get_notification_preferences_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../domain/usecases/schedule_plan_reminder_usecase.dart';
import '../../domain/usecases/update_notification_preference_usecase.dart';
import '../viewmodel/notifications_viewmodel.dart';
import '../widgets/notification_setting_tile.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

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
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationsViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Setting',
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: viewModel.isLoading
          ? const LoadingDialog()
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                itemCount: viewModel.preferences.length,
                itemBuilder: (context, index) {
                  final item = viewModel.preferences[index];
                  return NotificationSettingTile(
                    icon: _iconFor(item),
                    title: item.title,
                    description: item.description,
                    value: item.enabled,
                    onChanged: (value) =>
                        viewModel.updatePreference(item.id, value),
                  );
                },
              ),
            ),
    );
  }

  IconData _iconFor(NotificationPreference preference) {
    switch (preference.id) {
      case 'new_follower_notification':
        return Icons.group_add_outlined;
      case 'new_rating_notification':
        return Icons.info_outline;
      default:
        return Icons.notifications_none;
    }
  }
}
