import 'package:flutter/material.dart';
import 'package:foodopia/core/theme/app_colors.dart';
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

// =============================================================================
// PAGE WIDGETS
// =============================================================================

/// Page for selecting diet preferences during user setup.
class UserSetupDietPage extends StatelessWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new diet page instance.
  const UserSetupDietPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    // Provide the view model with diet options.
    return _UserSetupProvider(
      args: args,
      optionCategoryIds: const ['meal_preferences'],
      child: _DietView(args: args),
    );
  }
}

/// Page for selecting allergies during user setup.
class UserSetupAllergiesPage extends StatelessWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new allergies page instance.
  const UserSetupAllergiesPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    // Provide the view model with allergy options.
    return _UserSetupProvider(
      args: args,
      optionCategoryIds: const ['allergies'],
      child: _AllergiesView(args: args),
    );
  }
}

/// Page for selecting dislikes during user setup.
class UserSetupDislikesPage extends StatelessWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new dislikes page instance.
  const UserSetupDislikesPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    // Provide the view model with dislike options.
    return _UserSetupProvider(
      args: args,
      optionCategoryIds: const ['dislikes'],
      child: _DislikesView(args: args),
    );
  }
}

/// Page for setting calorie targets during user setup.
class UserSetupCaloriesPage extends StatelessWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new calories page instance.
  const UserSetupCaloriesPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    // Provide the view model.
    return _UserSetupProvider(
      args: args,
      child: _CaloriesView(args: args),
    );
  }
}

/// Page for configuring notifications during user setup.
class UserSetupNotificationPage extends StatelessWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new notification page instance.
  const UserSetupNotificationPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    // Provide the view model.
    return _UserSetupProvider(
      args: args,
      child: _NotificationView(args: args),
    );
  }
}

// =============================================================================
// PROVIDER WRAPPER
// =============================================================================

/// Provider wrapper for user setup pages.
/// Creates and provides the view model with dependencies.
class _UserSetupProvider extends StatelessWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Category IDs for loading admin options.
  final List<String> optionCategoryIds;

  /// Child widget.
  final Widget child;

  /// Creates a new user setup provider instance.
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
        getNotificationPreferencesUseCase: sl(),
        updateNotificationPreferenceUseCase: sl(),
      )..load(optionCategoryIds: optionCategoryIds),
      child: child,
    );
  }
}

// =============================================================================
// DIET VIEW
// =============================================================================

/// View for the diet selection page.
class _DietView extends StatelessWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new diet view instance.
  const _DietView({required this.args});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<UserSetupViewModel>();

    // Handle navigation events.
    _handleNavigation(context, viewModel, args);

    // Show loading state.
    if (viewModel.isLoading) return const _UserSetupPageLoading();

    // Get diet options.
    final options = viewModel.dietOptions;

    return UserSetupScaffold(
      step: 1,
      title: 'Pick your meal preferences',
      buttonText: args.isSettingsMode ? 'Save' : 'Continue',
      showProgress: !args.isSettingsMode,
      isSaving: viewModel.isSaving,
      onContinue: args.isSettingsMode
          ? viewModel.saveDietFromSettings
          : viewModel.saveDiet,
      child: ListView(
        children: [
          _OptionSection(
            title: 'Default options',
            options: options,
            emptyText: 'No diet options yet',
            selectedValues: viewModel.preferences.diets.toSet(),
            onSelected: viewModel.toggleDiet,
            onClearAll: viewModel.clearDiet,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ALLERGIES VIEW
// =============================================================================

/// View for the allergies selection page.
class _AllergiesView extends StatefulWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new allergies view instance.
  const _AllergiesView({required this.args});

  @override
  State<_AllergiesView> createState() => _AllergiesViewState();
}

/// State for the allergies view.
class _AllergiesViewState extends State<_AllergiesView> {
  /// Controller for the search field.
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<UserSetupViewModel>();

    // Handle navigation events.
    _handleNavigation(context, viewModel, widget.args);

    // Show loading state.
    if (viewModel.isLoading) return const _UserSetupPageLoading();

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
          // Search field.
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

          // Options sections.
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
              onClearAll: viewModel.clearAllergies,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DISLIKES VIEW
// =============================================================================

/// View for the dislikes selection page.
class _DislikesView extends StatefulWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new dislikes view instance.
  const _DislikesView({required this.args});

  @override
  State<_DislikesView> createState() => _DislikesViewState();
}

/// State for the dislikes view.
class _DislikesViewState extends State<_DislikesView> {
  /// Controller for the search field.
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<UserSetupViewModel>();

    // Handle navigation events.
    _handleNavigation(context, viewModel, widget.args);

    // Show loading state.
    if (viewModel.isLoading) return const _UserSetupPageLoading();

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
          // Search field.
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

          // Options sections.
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
              onClearAll: viewModel.clearDislikes,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CALORIES VIEW
// =============================================================================

/// View for the calorie target setup page.
class _CaloriesView extends StatefulWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new calories view instance.
  const _CaloriesView({required this.args});

  @override
  State<_CaloriesView> createState() => _CaloriesViewState();
}

/// State for the calories view.
class _CaloriesViewState extends State<_CaloriesView> {
  /// Controller for the calorie input field.
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
    // Watch the view model for state changes.
    final viewModel = context.watch<UserSetupViewModel>();

    // Handle navigation events.
    _handleNavigation(context, viewModel, widget.args);

    // Show loading state.
    if (viewModel.isLoading) return const _UserSetupPageLoading();

    // Set initial calorie value.
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
          // Skip target switch.
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

          // Calorie input field.
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

          // Calorie unit selection.
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

          // Error message.
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

// =============================================================================
// NOTIFICATION VIEW
// =============================================================================

/// View for the notification setup page.
class _NotificationView extends StatelessWidget {
  /// Arguments passed to the page.
  final UserSetupArgs args;

  /// Creates a new notification view instance.
  const _NotificationView({required this.args});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<UserSetupViewModel>();

    // Handle navigation events.
    _handleNavigation(context, viewModel, args);

    // Show loading state.
    if (viewModel.isLoading) return const _UserSetupPageLoading();

    return UserSetupScaffold(
      step: 5,
      title: 'Set Notification',
      buttonText: 'Done',
      isSaving: viewModel.isSaving,
      onContinue: viewModel.complete,
      onBack: () => context.go(AppRouter.setupCalories, extra: args),
      child: ListView(
        children: [
          // Master notification switch.
          _SetupSwitchTile(
            title: 'Enable notifications',
            subtitle: 'Turn off to close all notification pop-ups',
            value: viewModel.preferences.notificationsEnabled,
            onChanged: (value) {
              viewModel.setNotificationsEnabled(value);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Notification toggles.
          for (final item in viewModel.notificationPreferences)
            _NotificationToggle(
              title: item.title,
              subtitle: item.description,
              value: viewModel.notificationValue(item.id),
              enabled: viewModel.preferences.notificationsEnabled,
              onChanged: (value) =>
                  viewModel.toggleNotificationValue(item.id, value),
            ),

          // New Comment Notification toggle.
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

          // New Recipe Notification toggle.
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

          // New Reply Notification toggle.
          _NotificationToggle(
            title: 'New Reply Notification',
            subtitle: 'Receive a notification when someone replies you',
            value: viewModel.notificationValue('new_reply_notification'),
            enabled: viewModel.preferences.notificationsEnabled,
            onChanged: (value) =>
                viewModel.setNotificationValue('new_reply_notification', value),
          ),

          // Plan Reminder Notification toggle.
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

          // Error message.
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

// =============================================================================
// REUSABLE WIDGETS
// =============================================================================

/// Notification toggle list tile.
class _NotificationToggle extends StatelessWidget {
  /// Title of the notification.
  final String title;

  /// Subtitle description.
  final String subtitle;

  /// Whether the toggle is active.
  final bool value;

  /// Whether the toggle is enabled.
  final bool enabled;

  /// Callback when the toggle changes.
  final ValueChanged<bool> onChanged;

  /// Creates a new notification toggle instance.
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

/// Loading state for user setup pages.
class _UserSetupPageLoading extends StatelessWidget {
  /// Creates a new user setup page loading instance.
  const _UserSetupPageLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingDialog(message: "Loading...", inline: true),
    );
  }
}

/// Switch tile with custom styling.
class _SetupSwitchTile extends StatelessWidget {
  /// Title text.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Switch value.
  final bool value;

  /// Callback when switch changes.
  final ValueChanged<bool> onChanged;

  /// Creates a new setup switch tile instance.
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

/// Searchable option sections with default and search results.
class _SearchableOptionSections extends StatelessWidget {
  /// Default options from admin configuration.
  final List<UserSetupOption> defaultOptions;

  /// Search results.
  final List<UserSetupOption> searchOptions;

  /// Whether search is in progress.
  final bool isSearching;

  /// Current search query.
  final String searchQuery;

  /// Empty state text for defaults.
  final String emptyDefaultText;

  /// Empty state text for search results.
  final String emptySearchText;

  /// Set of selected values.
  final Set<String> selectedValues;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Callback to clear all selections.
  final VoidCallback? onClearAll;

  /// Creates a new searchable option sections instance.
  const _SearchableOptionSections({
    required this.defaultOptions,
    required this.searchOptions,
    required this.isSearching,
    required this.searchQuery,
    required this.emptyDefaultText,
    required this.emptySearchText,
    required this.selectedValues,
    required this.onSelected,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Default options section.
        _OptionSection(
          title: 'Default options',
          options: defaultOptions,
          emptyText: emptyDefaultText,
          selectedValues: selectedValues,
          onSelected: onSelected,
          onClearAll: onClearAll,
        ),

        // Search results section.
        if (searchQuery.trim().length >= 2) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Search results', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          // Show loading or results.
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

/// Option section with title and chips.
class _OptionSection extends StatelessWidget {
  /// Section title.
  final String title;

  /// List of options.
  final List<UserSetupOption> options;

  /// Empty state text.
  final String emptyText;

  /// Set of selected values.
  final Set<String> selectedValues;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Callback to clear all selections.
  final VoidCallback? onClearAll;

  /// Whether to display in full width mode.
  final bool fullWidth;

  /// Creates a new option section instance.
  const _OptionSection({
    required this.title,
    required this.options,
    required this.emptyText,
    required this.selectedValues,
    required this.onSelected,
    this.onClearAll,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: context.text.titleMedium)),
            if (onClearAll != null)
              TextButton(onPressed: onClearAll, child: const Text('Clear all')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Options wrapper.
        _OptionWrap(
          options: options,
          emptyText: emptyText,
          selectedValues: selectedValues,
          onSelected: onSelected,
          fullWidth: fullWidth,
        ),
      ],
    );
  }
}

/// Wrapper for option chips.
class _OptionWrap extends StatelessWidget {
  /// List of options.
  final List<UserSetupOption> options;

  /// Empty state text.
  final String emptyText;

  /// Set of selected values.
  final Set<String> selectedValues;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Whether to display in full width mode.
  final bool fullWidth;

  /// Creates a new option wrap instance.
  const _OptionWrap({
    required this.options,
    required this.emptyText,
    required this.selectedValues,
    required this.onSelected,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show empty state.
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(emptyText, style: context.text.bodyMedium),
      );
    }

    // Full width list mode.
    if (fullWidth) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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

    // Wrap layout for chips.
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

// =============================================================================
// NAVIGATION HELPER
// =============================================================================

/// Handles navigation events from the view model.
void _handleNavigation(
  BuildContext context,
  UserSetupViewModel viewModel,
  UserSetupArgs args,
) {
  // Get the navigation event.
  final event = viewModel.navigationEvent;

  // Return if no event.
  if (event == null) return;

  // Execute navigation after the frame.
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
