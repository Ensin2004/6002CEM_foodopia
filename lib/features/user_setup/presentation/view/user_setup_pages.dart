import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/user_setup_option.dart';
import '../viewmodel/user_setup_viewmodel.dart';
import '../widgets/user_setup_choice_chip.dart';
import '../widgets/user_setup_scaffold.dart';
import '../widgets/user_setup_search_field.dart';

class UserSetupDietPage extends StatelessWidget {
  final UserSetupArgs args;

  const UserSetupDietPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return _UserSetupProvider(
      args: args,
      optionCategoryIds: const ['meal_preferences'],
      child: _DietView(args: args),
    );
  }
}

class UserSetupAllergiesPage extends StatelessWidget {
  final UserSetupArgs args;

  const UserSetupAllergiesPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return _UserSetupProvider(
      args: args,
      optionCategoryIds: const ['allergies'],
      child: _AllergiesView(args: args),
    );
  }
}

class UserSetupDislikesPage extends StatelessWidget {
  final UserSetupArgs args;

  const UserSetupDislikesPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return _UserSetupProvider(
      args: args,
      optionCategoryIds: const ['dislikes'],
      child: _DislikesView(args: args),
    );
  }
}

class UserSetupCaloriesPage extends StatelessWidget {
  final UserSetupArgs args;

  const UserSetupCaloriesPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return _UserSetupProvider(
      args: args,
      child: _CaloriesView(args: args),
    );
  }
}

class UserSetupNotificationPage extends StatelessWidget {
  final UserSetupArgs args;

  const UserSetupNotificationPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return _UserSetupProvider(
      args: args,
      child: _NotificationView(args: args),
    );
  }
}

class _UserSetupProvider extends StatelessWidget {
  final UserSetupArgs args;
  final List<String> optionCategoryIds;
  final Widget child;

  const _UserSetupProvider({
    required this.args,
    this.optionCategoryIds = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserSetupViewModel(
        uid: args.uid,
        getOptionsUseCase: sl(),
        searchFoodsUseCase: sl(),
        getPreferencesUseCase: sl(),
        savePreferencesUseCase: sl(),
      )..load(optionCategoryIds: optionCategoryIds),
      child: child,
    );
  }
}

class _DietView extends StatelessWidget {
  final UserSetupArgs args;

  const _DietView({required this.args});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserSetupViewModel>();
    _handleNavigation(context, viewModel, args);

    if (viewModel.isLoading) return const LoadingDialog();

    final options = viewModel.dietOptions;
    return UserSetupScaffold(
      step: 1,
      title: 'Pick your diet',
      buttonText: args.isSettingsMode ? 'Save' : 'Continue',
      showProgress: !args.isSettingsMode,
      isSaving: viewModel.isSaving,
      onContinue: args.isSettingsMode
          ? viewModel.saveDietFromSettings
          : viewModel.saveDiet,
      child: _OptionList(
        options: options,
        emptyText: 'No diet options yet',
        selectedValues: {
          viewModel.preferences.diet ?? UserSetupViewModel.noDietValue,
        },
        onSelected: viewModel.selectDiet,
        fullWidth: true,
      ),
    );
  }
}

class _AllergiesView extends StatefulWidget {
  final UserSetupArgs args;

  const _AllergiesView({required this.args});

  @override
  State<_AllergiesView> createState() => _AllergiesViewState();
}

class _AllergiesViewState extends State<_AllergiesView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserSetupViewModel>();
    _handleNavigation(context, viewModel, widget.args);

    if (viewModel.isLoading) return const LoadingDialog();

    return UserSetupScaffold(
      step: 2,
      title: 'Any allergies?',
      buttonText: widget.args.isSettingsMode ? 'Save' : 'Continue',
      showProgress: !widget.args.isSettingsMode,
      isSaving: viewModel.isSaving,
      onContinue: widget.args.isSettingsMode
          ? viewModel.saveAllergiesFromSettings
          : viewModel.saveAllergies,
      onBack: widget.args.isSettingsMode
          ? null
          : () => context.go(AppRouter.setupDiet, extra: widget.args),
      child: Column(
        children: [
          UserSetupSearchField(
            controller: _searchController,
            hintText: 'Search allergies ...',
            onChanged: viewModel.search,
            onClear: () {
              _searchController.clear();
              viewModel.clearSearch();
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _SearchableOptionSections(
              defaultOptions: viewModel.allergyOptions,
              searchOptions: viewModel.searchResults,
              isSearching: viewModel.isSearching,
              searchQuery: _searchController.text,
              emptyDefaultText: 'No allergy defaults yet',
              emptySearchText: 'No allergy results found',
              selectedValues: viewModel.preferences.allergies.toSet(),
              onSelected: viewModel.toggleAllergy,
            ),
          ),
        ],
      ),
    );
  }
}

class _DislikesView extends StatefulWidget {
  final UserSetupArgs args;

  const _DislikesView({required this.args});

  @override
  State<_DislikesView> createState() => _DislikesViewState();
}

class _DislikesViewState extends State<_DislikesView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserSetupViewModel>();
    _handleNavigation(context, viewModel, widget.args);

    if (viewModel.isLoading) return const LoadingDialog();

    return UserSetupScaffold(
      step: 3,
      title: 'How about dislikes?',
      buttonText: widget.args.isSettingsMode ? 'Save' : 'Continue',
      showProgress: !widget.args.isSettingsMode,
      isSaving: viewModel.isSaving,
      onContinue: widget.args.isSettingsMode
          ? viewModel.saveDislikesFromSettings
          : viewModel.saveDislikes,
      onBack: widget.args.isSettingsMode
          ? null
          : () => context.go(AppRouter.setupAllergies, extra: widget.args),
      child: Column(
        children: [
          UserSetupSearchField(
            controller: _searchController,
            hintText: 'Search dislikes ...',
            onChanged: viewModel.search,
            onClear: () {
              _searchController.clear();
              viewModel.clearSearch();
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _SearchableOptionSections(
              defaultOptions: viewModel.dislikeOptions,
              searchOptions: viewModel.searchResults,
              isSearching: viewModel.isSearching,
              searchQuery: _searchController.text,
              emptyDefaultText: 'No dislike defaults yet',
              emptySearchText: 'No dislike results found',
              selectedValues: viewModel.preferences.dislikes.toSet(),
              onSelected: viewModel.toggleDislike,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesView extends StatefulWidget {
  final UserSetupArgs args;

  const _CaloriesView({required this.args});

  @override
  State<_CaloriesView> createState() => _CaloriesViewState();
}

class _CaloriesViewState extends State<_CaloriesView> {
  late final TextEditingController _calorieController;

  @override
  void initState() {
    super.initState();
    _calorieController = TextEditingController();
  }

  @override
  void dispose() {
    _calorieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserSetupViewModel>();
    _handleNavigation(context, viewModel, widget.args);

    if (viewModel.isLoading) return const LoadingDialog();

    final target = viewModel.preferences.targetCalories;
    if (_calorieController.text.isEmpty && target != null) {
      _calorieController.text = target.toString();
    }

    return UserSetupScaffold(
      step: 4,
      title: 'Set Your Daily Target Calories',
      buttonText: widget.args.isSettingsMode ? 'Save' : 'Continue',
      showProgress: !widget.args.isSettingsMode,
      isSaving: viewModel.isSaving,
      onContinue: widget.args.isSettingsMode
          ? viewModel.saveCaloriesFromSettings
          : viewModel.saveCalories,
      onBack: widget.args.isSettingsMode
          ? null
          : () => context.go(AppRouter.setupDislikes, extra: widget.args),
      child: ListView(
        children: [
          _SetupSwitchTile(
            title: 'No target',
            subtitle: 'Skip daily calorie targeting for now',
            value: !viewModel.preferences.calorieTargetEnabled,
            onChanged: (value) {
              viewModel.setCalorieTargetEnabled(!value);
              if (value) _calorieController.clear();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _calorieController,
            enabled: viewModel.preferences.calorieTargetEnabled,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Daily target',
              hintText: 'e.g. 2000',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              viewModel.setTargetCalories(int.tryParse(value.trim()));
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            children: [
              UserSetupChoiceChip(
                label: 'kcal',
                selected: viewModel.preferences.calorieUnit == 'kcal',
                onTap: () => viewModel.setCalorieUnit('kcal'),
              ),
              UserSetupChoiceChip(
                label: 'kJ',
                selected: viewModel.preferences.calorieUnit == 'kJ',
                onTap: () => viewModel.setCalorieUnit('kJ'),
              ),
            ],
          ),
          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              viewModel.errorMessage!,
              style: context.text.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationView extends StatelessWidget {
  final UserSetupArgs args;

  const _NotificationView({required this.args});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserSetupViewModel>();
    _handleNavigation(context, viewModel, args);

    if (viewModel.isLoading) return const LoadingDialog();

    return UserSetupScaffold(
      step: 5,
      title: 'Set Notification',
      buttonText: 'Done',
      isSaving: viewModel.isSaving,
      onContinue: viewModel.complete,
      onBack: () => context.go(AppRouter.setupCalories, extra: args),
      child: ListView(
        children: [
          _SetupSwitchTile(
            title: 'Enable notifications',
            subtitle: 'Use the same notification settings as your profile',
            value: viewModel.preferences.notificationsEnabled,
            onChanged: (value) {
              viewModel.setNotificationsEnabled(value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _NotificationToggle(
            title: 'New Follower Notification',
            subtitle: 'Get a notification for new follower',
            value: viewModel.notificationValue('new_follower_notification'),
            enabled: viewModel.preferences.notificationsEnabled,
            onChanged: (value) => viewModel.setNotificationValue(
              'new_follower_notification',
              value,
            ),
          ),
          _NotificationToggle(
            title: 'New Rating Notification',
            subtitle: 'Receive a notification when your recipe is rated',
            value: viewModel.notificationValue('new_rating_notification'),
            enabled: viewModel.preferences.notificationsEnabled,
            onChanged: (value) => viewModel.setNotificationValue(
              'new_rating_notification',
              value,
            ),
          ),
          _NotificationToggle(
            title: 'New Comment Notification',
            subtitle: 'Receive a notification when your recipe has comment',
            value: viewModel.notificationValue('new_comment_notification'),
            enabled: viewModel.preferences.notificationsEnabled,
            onChanged: (value) => viewModel.setNotificationValue(
              'new_comment_notification',
              value,
            ),
          ),
          _NotificationToggle(
            title: 'New Recipe Notification',
            subtitle: 'Receive a notification when followed creator posts',
            value: viewModel.notificationValue('new_recipe_notification'),
            enabled: viewModel.preferences.notificationsEnabled,
            onChanged: (value) => viewModel.setNotificationValue(
              'new_recipe_notification',
              value,
            ),
          ),
          _NotificationToggle(
            title: 'New Reply Notification',
            subtitle: 'Receive a notification when someone replies you',
            value: viewModel.notificationValue('new_reply_notification'),
            enabled: viewModel.preferences.notificationsEnabled,
            onChanged: (value) => viewModel.setNotificationValue(
              'new_reply_notification',
              value,
            ),
          ),
          _NotificationToggle(
            title: 'Plan Reminder',
            subtitle: 'Get a reminder when you forget to plan your meal',
            value: viewModel.notificationValue('plan_reminder_notification'),
            enabled: viewModel.preferences.notificationsEnabled,
            onChanged: (value) => viewModel.setNotificationValue(
              'plan_reminder_notification',
              value,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: context.text.bodyLarge),
      subtitle: Text(subtitle, style: context.text.bodySmall),
      value: enabled && value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _SetupSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SetupSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SearchableOptionSections extends StatelessWidget {
  final List<UserSetupOption> defaultOptions;
  final List<UserSetupOption> searchOptions;
  final bool isSearching;
  final String searchQuery;
  final String emptyDefaultText;
  final String emptySearchText;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelected;

  const _SearchableOptionSections({
    required this.defaultOptions,
    required this.searchOptions,
    required this.isSearching,
    required this.searchQuery,
    required this.emptyDefaultText,
    required this.emptySearchText,
    required this.selectedValues,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _OptionSection(
          title: 'Default options',
          options: defaultOptions,
          emptyText: emptyDefaultText,
          selectedValues: selectedValues,
          onSelected: onSelected,
        ),
        if (searchQuery.trim().length >= 2) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Search results', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _OptionWrap(
              options: searchOptions,
              emptyText: emptySearchText,
              selectedValues: selectedValues,
              onSelected: onSelected,
            ),
        ],
      ],
    );
  }
}

class _OptionSection extends StatelessWidget {
  final String title;
  final List<UserSetupOption> options;
  final String emptyText;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelected;

  const _OptionSection({
    required this.title,
    required this.options,
    required this.emptyText,
    required this.selectedValues,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _OptionWrap(
          options: options,
          emptyText: emptyText,
          selectedValues: selectedValues,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _OptionWrap extends StatelessWidget {
  final List<UserSetupOption> options;
  final String emptyText;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelected;

  const _OptionWrap({
    required this.options,
    required this.emptyText,
    required this.selectedValues,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(emptyText, style: context.text.bodyMedium),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final option in options)
          UserSetupChoiceChip(
            label: option.name,
            selected: selectedValues.contains(option.name),
            onTap: () => onSelected(option.name),
          ),
      ],
    );
  }
}

class _OptionList extends StatelessWidget {
  final List<UserSetupOption> options;
  final String emptyText;
  final Set<String> selectedValues;
  final ValueChanged<String> onSelected;
  final bool fullWidth;

  const _OptionList({
    required this.options,
    required this.emptyText,
    required this.selectedValues,
    required this.onSelected,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', width: 150),
            const SizedBox(height: AppSpacing.md),
            Text(emptyText, style: context.text.bodyMedium),
          ],
        ),
      );
    }

    if (fullWidth) {
      return ListView.separated(
        itemBuilder: (context, index) {
          final option = options[index];
          return UserSetupChoiceChip(
            label: option.name,
            selected: selectedValues.contains(option.name),
            onTap: () => onSelected(option.name),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: options.length,
      );
    }

    return _OptionWrap(
      options: options,
      emptyText: emptyText,
      selectedValues: selectedValues,
      onSelected: onSelected,
    );
  }
}

void _handleNavigation(
  BuildContext context,
  UserSetupViewModel viewModel,
  UserSetupArgs args,
) {
  final event = viewModel.navigationEvent;
  if (event == null) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    switch (event) {
      case UserSetupNavigationEvent.goToAllergies:
        context.go(AppRouter.setupAllergies, extra: args);
        break;
      case UserSetupNavigationEvent.goToDislikes:
        context.go(AppRouter.setupDislikes, extra: args);
        break;
      case UserSetupNavigationEvent.goToCalories:
        context.go(AppRouter.setupCalories, extra: args);
        break;
      case UserSetupNavigationEvent.goToNotifications:
        context.go(AppRouter.setupNotifications, extra: args);
        break;
      case UserSetupNavigationEvent.goToHome:
        final user = args.user;
        context.go(
          AppRouter.home,
          extra: user == null
              ? null
              : HomeArgs(user: user, role: args.role ?? user.role.name),
        );
        break;
      case UserSetupNavigationEvent.closeSettings:
        if (context.canPop()) context.pop();
        break;
    }
  });
}
