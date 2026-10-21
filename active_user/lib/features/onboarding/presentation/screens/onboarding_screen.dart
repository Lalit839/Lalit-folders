import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/routes/app_routes.dart';
import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:activ_user_app/features/onboarding/data/onboarding_data.dart';
import 'package:activ_user_app/features/onboarding/presentation/widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentIndex < OnboardingData.items.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() async {
    // Set onboarding completed
    await SharedPrefService.setOnboardingCompleted(true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = OnboardingData.items;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (_currentIndex < slides.length - 1) {
                _progressController.forward(from: 0.0);
              } else {
                _progressController.value = 1.0;
              }
            },
            itemCount: slides.length,
            itemBuilder: (context, index) {
              return OnboardingPage(model: slides[index]);
            },
          ),

          // Bottom Controls Overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 40, // SafeArea equivalent padding
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.bottomCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicators (horizontal lines)
                  Row(
                    children: List.generate(slides.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.only(
                          right: index == slides.length - 1 ? 0 : 8,
                        ),
                        height: 5,
                        width: isActive ? 32 : 12,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.textPrimary.withValues(alpha: 0.3)
                              : AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: isActive
                            ? AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: _progressController.value,
                                      child: Container(
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : null,
                      );
                    }),
                  ),
                  const SizedBox(
                    height: 16,
                  ), // Spacing between indicators and title
                  // Animated Text Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      key: ValueKey(_currentIndex),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bold(
                            slides[_currentIndex].title,
                            color: AppColors.textPrimary,
                            fontSize: 36,
                          ),
                          const SizedBox(height: 8),
                          AppText(
                            slides[_currentIndex].subtitle,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Button - Only show on last slide with spacing
                  if (_currentIndex == slides.length - 1) ...[
                    const SizedBox(height: 40),
                    AppButton(
                      title: AppStrings.getStarted,
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.black,
                      suffixIcon: const AppSvg(
                        AppAssets.thickArrowRight,
                        color: AppColors.black,
                        height: 24,
                        width: 24,
                      ),
                      borderRadius: 48,
                      onTap: _onNextPressed,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
