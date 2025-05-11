import 'package:flutter/material.dart';
import 'package:mama_care/domain/entities/onboarding_entities.dart';

class OnBoardingViewModel extends ChangeNotifier {
  // State variables
  int _currentPage = 0;
  final List<OnboardingEntity> _slides = mainOnboardings;

  // Getters
  int get currentPage => _currentPage;
  List<OnboardingEntity> get slides => _slides;

  // Set current page
  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  // Go to next page
  void nextPage() {
    if (_currentPage < 4) { // Assuming 3 pages (0, 1, 2)
      _currentPage++;
      notifyListeners();
    }
  }

  // Go to previous page
  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  // Skip onboarding
  void skipOnboarding() {
    _currentPage = 2; // Go to last page
    notifyListeners();
  }

  // Complete onboarding
  void completeOnboarding() {
    // Implement any logic needed when onboarding is completed
    // For example, setting a flag in shared preferences
    notifyListeners();
  }

  // Method to update the current page
  void updateCurrentPage(int page) {
    _currentPage = page;
    notifyListeners(); // Notify listeners to update the UI
  }
}