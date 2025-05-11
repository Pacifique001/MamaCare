import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/onboarding_viewmodel.dart';
import 'package:mama_care/presentation/screen/onboarding/on_boarding_page.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnBoardingViewModel(),
      child: const OnBoardingPage(),
    );
  }
}