import '../../../../core/constants/app_assets.dart';
import 'package:activ_user_app/features/onboarding/model/onboarding_model.dart';

class OnboardingData {
  static const List<OnboardingModel> items = [
    OnboardingModel(
      imagePath: AppAssets.onboarding1,
      title: 'Discover Your\nNext Activity',
      subtitle:
          'Explore sports and fitness venues near you. Find the perfect place to play, train, and move.',
    ),
    OnboardingModel(
      imagePath: AppAssets.onboarding2,
      title: 'Book in Seconds',
      subtitle:
          'Choose your venue, select your slot, and confirm your booking effortlessly.',
    ),
    OnboardingModel(
      imagePath: AppAssets.onboarding3,
      title: 'Stay Active',
      subtitle:
          'Build your streak by showing up, playing more, and making every booking count.',
    ),
  ];
}
