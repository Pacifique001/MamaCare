// lib/presentation/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:mama_care/presentation/screen/admin_dashboard_screen.dart';
import 'package:mama_care/presentation/screen/doctor_dashboard_screen.dart';
import 'package:mama_care/presentation/screen/mama_care_screen.dart';
import 'package:mama_care/presentation/screen/nurse_dashboard_screen.dart';
import 'package:mama_care/presentation/screen/onboarding/OnboardingScreen.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/domain/entities/user_role.dart';
// Import your screen widgets
import 'package:mama_care/presentation/screen/login_screen.dart';
import 'package:mama_care/presentation/screen/dashboard_screen.dart'; // Patient Dashboard Screen
import 'package:mama_care/presentation/screen/verification_pending_screen.dart'; // Verification Screen

/// AuthWrapper Widget
///
/// This widget acts as the main entry point after initialization.
/// It listens to the authentication state from [AuthViewModel] and
/// directs the user to the appropriate screen:
/// - Loading/Splash Screen: While initial auth state is being determined.
/// - Verification Pending Screen: If the user is signed up but hasn't verified email/phone.
/// - Login Screen: If the user is not authenticated.
/// - Role-Specific Dashboard: If the user is authenticated and verified.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch AuthViewModel for state changes (isAuthenticated, isLoading, user data)
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser; // Firebase User state
    final localUser = authViewModel.localUser; // Local synced User state

    // --- Loading State ---
    // Show a loading indicator/splash screen ONLY during the very initial check,
    // before either currentUser or localUser has had a chance to be populated
    // and while the viewModel reports it might still be loading that initial state.
    // Avoid showing loading during background syncs after initial load.
    final isInitialLoading =
        authViewModel.isLoading && currentUser == null && localUser == null;
    if (isInitialLoading) {
      // Replace with your actual Splash Screen if you have one
      return const OnboardingScreen();
      // Or a simpler version:
      //return const Scaffold(
      //   body: Center(child: CircularProgressIndicator()),
      // );
    }

    // --- Verification Pending State ---
    // Check if a Firebase user exists BUT their email is not verified.
    // This catches users immediately after email/password signup OR if they
    // somehow log in later without having verified.
    // We don't strictly need localUser here, as emailVerified comes from Firebase.
    if (currentUser != null && !currentUser.emailVerified) {
      // If user exists but email is not verified, show the pending screen.
      // Pass email and phone number (if available) for display/use.
      return VerificationPendingScreen(
        email:
            currentUser.email ?? 'your email', // Email should always exist here
        // Phone number might be null if not provided during signup or fetched yet
        phoneNumber: currentUser.phoneNumber ?? localUser?.phoneNumber,
      );
    }

    // --- Authenticated State ---
    // Check if the user is considered fully authenticated by the ViewModel.
    // This relies on isAuthenticated being true (meaning _firebaseUser and _localUser are non-null in VM).
    if (authViewModel.isAuthenticated && localUser != null) {
      // User is authenticated, local data is loaded, determine the dashboard by role.
      final userRole =
          localUser.role; // Use role from the synced localUser data

      switch (userRole) {
        case UserRole.patient:
          // Navigate to the main screen/dashboard for patients
          // Replace DashboardScreen with MamaCareScreen if that's your main patient wrapper
          return const DashboardScreen();
        case UserRole.nurse:
          return const NurseDashboardScreen();
        case UserRole.doctor:
          return const DoctorDashboardScreen();
        case UserRole.admin:
          // Ensure AdminDashboardScreen is implemented
          return const AdminDashboardScreen();
        case UserRole.unknown:
        default:
          // CRITICAL: User is authenticated but has an unknown/unhandled role.
          // This indicates a potential data issue or missing case.
          // Force logout for safety and navigate to login.
          // Use addPostFrameCallback to avoid calling logout during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Ensure context is still valid if build is somehow interrupted
            if (context.mounted) {
              Provider.of<AuthViewModel>(context, listen: false).logout();
              // Explicit navigation might be needed if logout doesn't trigger wrapper rebuild quickly enough
              // Navigator.pushNamedAndRemoveUntil(context, NavigationRoutes.login, (route) => false);
            }
          });
          // Show login screen while logout processes
          return const LoginScreen();
      }
    }
    // --- Unauthenticated State ---
    else {
      // If none of the above conditions are met (e.g., user is null, not authenticated),
      // show the LoginScreen.
      return const LoginScreen();
    }
  }
}
