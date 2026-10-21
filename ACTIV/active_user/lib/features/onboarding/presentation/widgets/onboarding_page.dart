import 'package:flutter/material.dart';
import 'package:activ_user_app/features/onboarding/model/onboarding_model.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel model;

  const OnboardingPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Image.asset(
          model.imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Dark Gradient Overlay for readability
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000), // rgba(0, 0, 0, 0) 0%
                  Color(0x33000000), // rgba(0, 0, 0, 0.2) 20.53%
                  Color(0x66000000), // rgba(0, 0, 0, 0.4) 38.76%
                  Color(0xA6000000), // rgba(0, 0, 0, 0.65) 55.91%
                  Color(0xD9000000), // rgba(0, 0, 0, 0.85) 72.51%
                  Color(0xF2000000), // rgba(0, 0, 0, 0.95) 85.3%
                  Color(0xFF000000), // #000000 100%
                ],
                stops: [0.0, 0.2053, 0.3876, 0.5591, 0.7251, 0.853, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
