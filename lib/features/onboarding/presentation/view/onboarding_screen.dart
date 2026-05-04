import 'dart:async';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodopia/core/theme/theme_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../viewmodel/onboarding_viewmodel.dart';
import '../widgets/onboarding_page.dart';

/// Defines behavior for onboarding screen.
class OnboardingScreen extends StatelessWidget {
  /// Creates a onboarding screen instance.
  const OnboardingScreen({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Runs the change notifier provider operation.
    return ChangeNotifierProvider(
      create: (_) => sl<OnboardingViewModel>(),
      child: const _OnboardingView(),
    );
  }
}

/// Defines behavior for onboarding view.
class _OnboardingView extends StatefulWidget {
  /// Handles the onboarding view operation.
  const _OnboardingView();

  /// Creates data for the create state operation.
  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

/// Defines behavior for onboarding view state.
class _OnboardingViewState extends State<_OnboardingView> {
  final _pageController = PageController();
  Timer? _autoPlayTimer;

  /// Initializes state before the first widget build.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAutoPlay();
      }
    });
  }

  /// Releases resources before widget removal.
  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    // Handle successful navigation events
    final navigationEvent = vm.navigationEvent;
    if (navigationEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(context, navigationEvent);
      });
    }

    // Handle error messages
    final errorMessage = vm.errorMessage;
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(context, errorMessage);
        vm.clearError(); // Clear after showing
      });
    }

    /// Handles the scaffold operation.
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, vm),

            /// Creates a expanded instance.
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: vm.onboardingItems.length,
                onPageChanged: (index) {
                  HapticFeedback.lightImpact();
                  vm.onPageChanged(index);
                },
                itemBuilder: (context, index) {
                  /// Handles the animated builder operation.
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double pageOffset = 0.0;

                      if (_pageController.hasClients &&
                          _pageController.page != null) {
                        pageOffset =
                            (_pageController.page! - index).toDouble();
                      }

                      /// Handles the onboarding page operation.
                      return OnboardingPage(
                        item: vm.onboardingItems[index],
                        pageOffset: pageOffset,
                      );
                    },
                  );
                },
              ),
            ),

            _buildIndicator(context, vm),

            /// Creates a padding instance.
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildButtons(context, vm),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles the handle navigation operation.
  void _handleNavigation(BuildContext context, OnboardingNavigationEvent event) {
    switch (event) {
      case OnboardingNavigationEvent.goToLogin:
        context.go(AppRouter.login);
        break;
      case OnboardingNavigationEvent.goToSignup:
        context.go(AppRouter.signup);
        break;
    }
  }

  /// Handles the show error snack bar operation.
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      /// Creates a snack bar instance.
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handles the build header operation.
  Widget _buildHeader(BuildContext context, OnboardingViewModel vm) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Creates a text instance.
          Text("Foodopia", style: context.text.titleLarge),

          if (vm.isLoading)
            /// Creates a sized box instance.
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            /// Creates a text button instance.
            TextButton(
              onPressed: () => _handleSkip(context, vm),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.primary,
              ),
              child: const Text("Skip"),
            ),
        ],
      ),
    );
  }

  /// Handles the build indicator operation.
  Widget _buildIndicator(BuildContext context, OnboardingViewModel vm) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: DotsIndicator(
        dotsCount: vm.onboardingItems.length,
        position: vm.currentIndex.toDouble(),
        decorator: DotsDecorator(
          activeSize: const Size(18, 8),
          size: const Size(8, 8),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          activeColor: context.colors.primary,
          color: context.colors.primary.withOpacity(0.2),
        ),
      ),
    );
  }

  /// Handles the build buttons operation.
  Widget _buildButtons(BuildContext context, OnboardingViewModel vm) {
    /// Handles the padding operation.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          /// Creates a primary button instance.
          PrimaryButton(
            text: "GET STARTED",
            onPressed: vm.isLoading ? null : () => _handleGetStarted(context, vm),
            isLoading: vm.isLoading,
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 12),
          /// Creates a secondary button instance.
          SecondaryButton(
            text: "SIGN UP",
            onPressed: vm.isLoading ? null : () => _handleSignUp(context, vm),
          ),
        ],
      ),
    );
  }

  /// Handles the handle get started operation.
  Future<void> _handleGetStarted(BuildContext context, OnboardingViewModel vm) async {
    await vm.completeOnboarding();
  }

  /// Handles the handle skip operation.
  Future<void> _handleSkip(BuildContext context, OnboardingViewModel vm) async {
    await vm.completeOnboarding();
  }

  /// Handles the handle sign up operation.
  Future<void> _handleSignUp(BuildContext context, OnboardingViewModel vm) async {
    await vm.goToSignup();
  }

  /// Handles the animate to next page operation.
  void _animateToNextPage() {
    if (!_pageController.hasClients) return;

    final vm = context.read<OnboardingViewModel>();
    _pageController.animateToPage(
      vm.nextPageIndex,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  /// Handles the start auto play operation.
  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _animateToNextPage();
    });
  }
}
