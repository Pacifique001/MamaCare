// lib/navigation/router.dart

import 'package:flutter/material.dart';
// Use package:logging or your preferred logger
import 'package:logger/logger.dart' as AppLogger; // Alias if needed
import 'package:mama_care/domain/entities/food_model.dart';
import 'package:mama_care/presentation/screen/add_appointment_screen.dart';
import 'package:mama_care/presentation/screen/appointment_detail_screen.dart';
import 'package:mama_care/presentation/screen/calendar_screen.dart';
import 'package:mama_care/presentation/screen/doctor_appointments_screen.dart';
import 'package:mama_care/presentation/screen/edit_profile_screen.dart';
// Onboarding & Auth
import 'package:mama_care/presentation/screen/onboarding/OnboardingScreen.dart';
import 'package:mama_care/presentation/screen/login_screen.dart';
import 'package:mama_care/presentation/screen/phone_auth_screen.dart';
import 'package:mama_care/presentation/screen/profile_screen.dart';
import 'package:mama_care/presentation/screen/reschedule_appointment_screen.dart';
import 'package:mama_care/presentation/screen/signup_screen.dart';
import 'package:mama_care/presentation/screen/timeline_screen.dart';
// Import your OtpInputScreen if you created it
import 'package:mama_care/presentation/screen/forgot_password_screen.dart';
import 'package:mama_care/presentation/screen/food_detail_screen.dart';
// Main Structure & Role Dashboards
import 'package:mama_care/presentation/screen/mama_care_screen.dart';
import 'package:mama_care/presentation/screen/dashboard_screen.dart';
import 'package:mama_care/presentation/screen/nurse_dashboard_screen.dart';
import 'package:mama_care/presentation/screen/admin_dashboard_screen.dart';
// Feature Screens
import 'package:mama_care/presentation/screen/article_list_screen.dart';
import 'package:mama_care/presentation/screen/article_screen.dart';
import 'package:mama_care/presentation/screen/hospital_screen.dart';
import 'package:mama_care/presentation/screen/exercise_screen.dart';
import 'package:mama_care/presentation/screen/exercise_detail_screen.dart';
import 'package:mama_care/presentation/screen/verification_pending_screen.dart';
import 'package:mama_care/presentation/screen/video_list_screen.dart';
import 'package:mama_care/presentation/screen/suggested_food_screen.dart';
import 'package:mama_care/presentation/screen/prediction_screen.dart';
import 'package:mama_care/presentation/screen/pregnancy_detail_screen.dart';
// Nurse Management Screens
import 'package:mama_care/presentation/screen/assign_nurse_screen.dart';
import 'package:mama_care/presentation/screen/nurse_details_screen.dart';
import 'package:mama_care/presentation/screen/nurse_assignment_management_screen.dart';
import 'package:mama_care/presentation/screen/assign_patient_to_nurse_screen.dart';
// Error Screen
import 'package:mama_care/presentation/screen/error_screen.dart';
import 'package:mama_care/presentation/screen/video_player_screen.dart';
import 'package:mama_care/presentation/view/otp_verification_view.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:mama_care/injection.dart'; // For locator if needed for logger

// Use your preferred logger instance
final AppLogger.Logger _logger =
    locator<AppLogger.Logger>(); // Example using GetIt

abstract class NavigationRoutes {
  // --- Keep all your route constants here ---
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String phoneOtpInput = '/phone-otp-input';
  static const String forgotPassword = '/forgot-password';
  static const String mainScreen = '/main';
  static const String nurseDashboard = '/nurse/dashboard';
  static const String doctorDashboard = '/doctor/dashboard';
  static const String adminDashboard = '/admin/dashboard';
  static const String dashboard = '/dashboard';
  static const String editScreen = '/editScreen';
  static const String calendar = '/calendar';
  static const String timeline = '/timeline';
  static const String profile = '/profile';
  static const String articleList = '/articles';
  static const String article = '/article';
  static const String map = '/map';
  static const String exercise = '/exercise';
  static const String exerciseDetail = '/exercise/detail';
  static const String food = '/food';
  static const String video_list = '/videos';
  static const String videoPlayer = '/video/player';
  static const String predictor = '/predictor';
  static const String pregnancy_detail = '/pregnancy-detail';
  static const String addAppointment = '/add-appointment';
  static const String appointmentDetail = '/appointments/detail';
  static const String rescheduleAppointment = '/appointments/reschedule';
  static const String assignNurse = '/assign-nurse';
  static const String assignPatientToNurse = '/nurses/assign-patient';
  static const String nurseDetail = '/nurses/detail';
  static const String nurseAssignmentManagement = '/nurses/assignments';
  static const String phoneAuth = '/phone-auth';
  static const String foodDetail =
      '/foodDetail'; // Keep consistent case '/food-detail' ?
  static const String nurseSchedule = '/nurse/schedule';

  static const String verificationPending =
      '/ verificationPending'; // Define nurse schedule route
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name;
    final args = settings.arguments;

    _logger.i(
      'Navigating to: $routeName ${args != null ? "with args: $args" : ""}',
    );

    if (routeName == null) {
      _logger.w('Route name is null.');
      return _errorRoute('Route name cannot be null');
    }

    try {
      switch (routeName) {
        // --- Core & Auth ---
        case NavigationRoutes.splash:
          // return _buildRoute(const SplashScreen(), settings: settings); // Use your actual splash screen
          return _buildRoute(const OnboardingScreen(), settings: settings);
        case NavigationRoutes.onboarding:
          return _buildRoute(const OnboardingScreen(), settings: settings);
        case NavigationRoutes.editScreen:
          return _buildRoute(const EditProfileScreen(), settings: settings);
        case NavigationRoutes.login:
          return _buildRoute(const LoginScreen(), settings: settings);
        case NavigationRoutes.signup:
          return _buildRoute(const SignUpScreen(), settings: settings);
        case NavigationRoutes.phoneOtpInput:
          if (args is String && args.isNotEmpty) {
            return _buildRoute(
              OtpInputScreen(phoneNumber: args),
              settings: settings,
            );
          } else {
            _logger.w('Phone number missing or invalid for route: $routeName');
            return _errorRoute(
              'Phone number is required for OTP verification.',
            );
          }
        case NavigationRoutes.phoneAuth: // Screen to INPUT phone number
          return _buildRoute(const PhoneAuthScreen(), settings: settings);

        case NavigationRoutes.forgotPassword:
          return _buildRoute(const ForgotPasswordScreen(), settings: settings);
        case NavigationRoutes.phoneAuth:
          return _buildRoute(
            PhoneAuthScreen(),
            settings: settings,
          ); // Assuming PhoneAuthScreen is correct
        case NavigationRoutes.verificationPending: // NEW CASE
          // Expects a Map with 'email' and optional 'phoneNumber'
          if (args is Map<String, dynamic> && args.containsKey('email')) {
            return _buildRoute(
              VerificationPendingScreen(
                email: args['email'] as String,
                phoneNumber: args['phoneNumber'] as String?, // Optional phone
              ),
              settings: settings,
            );
          } else {
            _logger.e(
              "Invalid arguments for verificationPending route: Expected Map with 'email'.",
            );
            return _errorRoute(
              "Required information missing for verification.",
            );
          }
        // --- Role-Based Main Screens ---
        case NavigationRoutes.mainScreen:
          return _buildRoute(const MamaCareScreen(), settings: settings);
        case NavigationRoutes.nurseDashboard:
          return _buildRoute(const NurseDashboardScreen(), settings: settings);
        case NavigationRoutes.doctorDashboard:
          return _buildRoute(
            const DoctorAppointmentsScreen(),
            settings: settings,
          );
        case NavigationRoutes.adminDashboard:
          return _buildRoute(const AdminDashboardScreen(), settings: settings);

        // --- Sections ---
        case NavigationRoutes.dashboard:
          return _buildRoute(const DashboardScreen(), settings: settings);
        case NavigationRoutes.calendar:
          return _buildRoute(const CalendarScreen(), settings: settings);
        case NavigationRoutes.timeline:
          return _buildRoute(const TimelineScreen(), settings: settings);
        case NavigationRoutes.profile:
          return _buildRoute(const ProfileScreen(), settings: settings);

        // --- Features ---
        case NavigationRoutes.articleList:
          return _buildRoute(const ArticleListScreen(), settings: settings);
        case NavigationRoutes.article:
          return _handleArticleRoute(settings);
        case NavigationRoutes.map:
          return _buildRoute(const HospitalScreen(), settings: settings);
        case NavigationRoutes.exercise:
          return _buildRoute(const ExerciseScreen(), settings: settings);
        case NavigationRoutes.exerciseDetail:
          return _handleExerciseDetailRoute(settings);
        case NavigationRoutes.video_list:
          return _buildRoute(const VideoListScreen(), settings: settings);
        case NavigationRoutes.food:
          return _buildRoute(const SuggestedFoodScreen(), settings: settings);
        case NavigationRoutes.predictor:
          return _buildRoute(const PredictionScreen(), settings: settings);
        case NavigationRoutes.pregnancy_detail:
          return _buildRoute(const PregnancyDetailScreen(), settings: settings);
        case NavigationRoutes.addAppointment:
          return _buildRoute(const AddAppointmentScreen(), settings: settings);
        case NavigationRoutes.appointmentDetail:
          if (args is String) {
            final appointmentId = args; // Argument is the Appointment ID string
            return MaterialPageRoute(
              // Navigate to the actual screen, passing the ID
              builder:
                  (_) => AppointmentDetailScreen(appointmentId: appointmentId),
              settings: settings, // Pass settings for route awareness
            );
          }
          // If args are not a String or are null
          return _errorRoute(
            'Appointment ID missing or invalid type for Detail screen',
          );
        case NavigationRoutes.rescheduleAppointment:
          if (args is String) {
            final appointmentId = args; // Argument is the Appointment ID string
            // Navigate to the actual screen, passing the ID
            return MaterialPageRoute(
              builder:
                  (_) =>
                      RescheduleAppointmentScreen(appointmentId: appointmentId),
              settings: settings, // Pass settings for route awareness
            );
          }
          // If args are not a String or are null
          return _errorRoute(
            'Appointment ID missing or invalid type for Reschedule screen',
          );

        // --- Nurse/Doctor Management ---
        case NavigationRoutes.assignNurse:
          final contextId = args as String?;
          return _buildRoute(
            AssignNurseScreen(contextId: contextId),
            settings: settings,
          );
        case NavigationRoutes.assignPatientToNurse:
          if (args is String) {
            return _buildRoute(
              AssignPatientToNurseScreen(nurseId: args),
              settings: settings,
            );
          }
          return _errorRoute('Nurse ID missing for assigning patient');
        case NavigationRoutes.nurseDetail:
          if (args is String) {
            return _buildRoute(
              NurseDetailScreenWrapper(nurseId: args),
              settings: settings,
            );
          }
          return _errorRoute('Nurse ID required for nurse details');
        case NavigationRoutes.nurseAssignmentManagement:
          if (args is String) {
            return _buildRoute(
              NurseAssignmentManagementScreenWrapper(nurseId: args),
              settings: settings,
            );
          }
          return _errorRoute('Nurse ID required for assignment management');
        case NavigationRoutes.nurseSchedule:
          // TODO: Implement Nurse Schedule Screen
          return _errorRoute('Nurse Schedule screen not implemented');

        // --- Food Detail Route ---
        case NavigationRoutes.foodDetail:
          // Check if argument is the correct type
          if (args is FoodModel) {
            // Pass the argument to the screen
            return _buildRoute(
              FoodDetailScreen(foodItem: args),
              settings: settings,
            );
          } else {
            // --- ADDED ELSE BLOCK ---
            // If argument is wrong type or null, return error route
            _logger.e(
              "Invalid arguments for foodDetail route: Expected FoodModel, got ${args?.runtimeType}",
            );
            return _errorRoute("Invalid arguments for Food Detail");
          }
        // --- END OF ADDED ELSE BLOCK ---
        case NavigationRoutes.videoPlayer: // New case
          if (args is String && args.isNotEmpty) {
            // Expect URL string
            return _buildRoute(
              VideoPlayerScreen(videoUrl: args),
              settings: settings,
            );
          } else {
            _logger.e("Video URL missing for videoPlayer route");
            return _errorRoute("Video URL is required to play.");
          }
        // --- Default Error Route ---
        default:
          _logger.w('No route defined for: $routeName');
          return _errorRoute('Route not found: $routeName');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Route generation failed for $routeName. Args: $args',
        error: e, // Pass error object
        stackTrace: stackTrace, // Pass stack trace
      );
      return _errorRoute('Failed to display the requested screen.');
    }
  }

  // --- Helper Methods ---
  // Use static consistently if these are truly static helpers
  static MaterialPageRoute<T> _buildRoute<T>(
    Widget widget, {
    RouteSettings? settings,
  }) {
    return MaterialPageRoute<T>(builder: (_) => widget, settings: settings);
  }

  static MaterialPageRoute _errorRoute(String message) {
    // Ensure NotFoundScreen exists and accepts a message
    return MaterialPageRoute(builder: (_) => NotFoundScreen(message: message));
  }

  static MaterialPageRoute _handleArticleRoute(RouteSettings settings) {
    final articleId = settings.arguments as String?;
    if (articleId == null || articleId.isEmpty) {
      _logger.w('Article ID missing or empty for route: ${settings.name}');
      return _errorRoute('Article ID is required for this route.');
    }
    // Ensure ArticleScreen exists and accepts articleId
    return _buildRoute(ArticleScreen(articleId: articleId), settings: settings);
  }

  static MaterialPageRoute _handleExerciseDetailRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    if (arguments is Map<String, dynamic>) {
      final String title = arguments['title'] as String? ?? "Exercise Detail";
      final String description =
          arguments['description'] as String? ?? "No description.";
      final String imagePath =
          arguments['image'] as String? ??
          AssetsHelper.stretching; // Ensure AssetsHelper.stretching exists

      // Ensure ExerciseDetailPage exists and accepts these parameters
      return _buildRoute(
        ExerciseDetailPage(
          title: title,
          description: description,
          image: imagePath,
        ),
        settings: settings,
      );
    } else {
      _logger.w(
        'Invalid arguments type for exercise detail: Expected Map<String, dynamic>, got ${arguments?.runtimeType}',
      );
      return _errorRoute('Invalid arguments for Exercise Detail.');
    }
  }
}
