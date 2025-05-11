
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/onboarding_viewmodel.dart';

import '../../../domain/entities/onboarding_entities.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});
  

  @override
  _OnBoardingPageState createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<OnBoardingViewModel>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: viewModel.slides.length,
                onPageChanged: viewModel.updateCurrentPage,
                itemBuilder: (context, index) {
                  return _buildOnboardingSlide(viewModel.slides[index]);
                },
              ),
            ),
            _buildPageIndicator(viewModel),
            _buildNavigationButtons(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingSlide(OnboardingEntity slide) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            slide.image,
            height: 200,
          ),
          const SizedBox(height: 20),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(OnBoardingViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        viewModel.slides.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == viewModel.currentPage ? Colors.blue : Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(OnBoardingViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: viewModel.currentPage > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            child: Text(
              'Back',
              style: TextStyle(
                color: viewModel.currentPage > 0 ? Colors.blue : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: viewModel.currentPage < viewModel.slides.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : () {
                    // Navigate to the next screen (e.g., login or dashboard)
                    Navigator.pushReplacementNamed(context, '/login');
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              viewModel.currentPage < viewModel.slides.length - 1 ? 'Next' : 'Get Started',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}