import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:foodopia/core/theme/theme_extension.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/navigation/navigation_events.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../../../auth/presentation/view/login_screen.dart';
import '../../../auth/presentation/view/signup_screen.dart';
import '../viewmodel/onboarding_viewmodel.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<OnboardingViewModel>(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OnboardingViewModel>().startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    context.read<OnboardingViewModel>().stopAutoPlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    // ✅ Handle successful navigation events
    final navigationEvent = vm.navigationEvent;
    if (navigationEvent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(context, navigationEvent);
      });
    }

    // ✅ Handle error messages
    final errorMessage = vm.errorMessage;
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(context, errorMessage);
        vm.clearError(); // Clear after showing
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, vm),

            Expanded(
              child: PageView.builder(
                controller: vm.pageController,
                itemCount: vm.onboardingItems.length,
                onPageChanged: vm.onPageChanged,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: vm.pageController,
                    builder: (context, child) {
                      double pageOffset = 0.0;

                      if (vm.pageController.hasClients &&
                          vm.pageController.page != null) {
                        pageOffset =
                            (vm.pageController.page! - index).toDouble();
                      }

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

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildButtons(context, vm),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, OnboardingNavigationEvent event) {
    switch (event) {
      case OnboardingNavigationEvent.goToLogin:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;
      case OnboardingNavigationEvent.goToSignup:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
        break;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OnboardingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Foodopia", style: context.text.titleLarge),

          if (vm.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
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

  Widget _buildIndicator(BuildContext context, OnboardingViewModel vm) {
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

  Widget _buildButtons(BuildContext context, OnboardingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          PrimaryButton(
            text: "GET STARTED",
            onPressed: vm.isLoading ? null : () => _handleGetStarted(context, vm),
            isLoading: vm.isLoading,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            text: "SIGN UP",
            onPressed: vm.isLoading ? null : () => _handleSignUp(context, vm),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGetStarted(BuildContext context, OnboardingViewModel vm) async {
    await vm.completeOnboarding();
  }

  Future<void> _handleSkip(BuildContext context, OnboardingViewModel vm) async {
    await vm.completeOnboarding();
  }

  Future<void> _handleSignUp(BuildContext context, OnboardingViewModel vm) async {
    vm.goToSignup();
  }
}