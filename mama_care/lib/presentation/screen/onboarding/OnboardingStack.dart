import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/onboarding_viewmodel.dart';

class OnboardingStack extends StatelessWidget {
  final int index;

  const OnboardingStack({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OnBoardingViewModel>(context);
    final onboardingSlide = viewModel.slides[index];

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 60.w,
              child: SvgPicture.asset(
                onboardingSlide.image,
                height: MediaQuery.of(context).size.height / 2,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}