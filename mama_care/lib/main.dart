// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/presentation/screen/error_screen.dart';
import 'package:mama_care/presentation/viewmodel/patient_appointments_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/suggested_food_viewmodel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mama_care/utils/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sizer/sizer.dart';

import 'data/local/database_helper.dart';
import 'domain/usecases/notification_use_case.dart';
import 'firebase_options.dart';
import 'injection.dart';
import 'navigation/navigation_service.dart';
import 'navigation/router.dart';
import 'presentation/viewmodel/auth_viewmodel.dart';
import 'presentation/viewmodel/doctor_dashboard_viewmodel.dart';
import 'utils/app_theme.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:intl/date_symbol_data_local.dart'; // Import for locale data init

// Use locator to get the logger instance configured via DI
final Logger _logger = locator<Logger>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _initializeApplication();
    await dotenv.load();
    runApp(const MamaCareApp());
  } catch (error, stackTrace) {
    final initLogger = Logger(printer: PrettyPrinter());
    initLogger.f(
      'Application initialization failed fatally.',
      error: error,
      stackTrace: stackTrace,
    );
    runApp(ErrorApp(error: error, stackTrace: stackTrace));
  }
}

Future<void> _initializeApplication() async {
  // Initialize Intl data
  await initializeDateFormatting();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Logger(printer: SimplePrinter()).i('Firebase initialized successfully.');
  await configureDependencies();
  _logger.i('Dependency Injection configured.');
  await _initializeDatabase();
  await _setupNotifications();
  _logger.i('Application initialization complete.');
}

Future<void> _initializeDatabase() async {
  try {
    final databaseHelper = locator<DatabaseHelper>();
    await databaseHelper.database;
    await databaseHelper.transaction((txn) async {
      await txn.insert('preferences', {
        'key': 'onboarding_completed',
        'value': '0',
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
      await txn.insert('preferences', {
        'key': 'theme',
        'value': 'system',
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
    });
    await databaseHelper.performMaintenance();
    _logger.i('Database initialized and initial preferences set.');
  } catch (e, stackTrace) {
    _logger.e(
      'Database initialization failed',
      error: e,
      stackTrace: stackTrace,
    );
    throw Exception('Failed to initialize database: ${e.toString()}');
  }
}

Future<void> _setupNotifications() async {
  try {
    await locator<NotificationUseCase>().initialize();
    _logger.i('Notifications initialized successfully.');
  } catch (e, stackTrace) {
    _logger.w('Notification setup failed', error: e, stackTrace: stackTrace);
  }
}

// Main Application Widget
class MamaCareApp extends StatelessWidget {
  const MamaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'MamaCare',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeController.themeMode,
                navigatorKey: NavigationService.navigatorKey,
                initialRoute: NavigationRoutes.splash,
                onGenerateRoute: RouteGenerator.generateRoute,
                onUnknownRoute:
                    (settings) => MaterialPageRoute(
                      builder:
                          (_) => NotFoundScreen(
                            errorMessage: 'Route Not Found',
                            errorDetails:
                                'No route defined for ${settings.name}',
                            message: '',
                          ),
                    ),
              );
            },
          );
        },
      ),
    );
  }

  List<SingleChildWidget> _buildProviders() {
    return [
      ChangeNotifierProvider<AuthViewModel>(
        create: (_) => locator<AuthViewModel>(),
      ),
      ChangeNotifierProvider<DoctorDashboardViewModel>(
        create: (_) => locator<DoctorDashboardViewModel>(),
      ),
      ChangeNotifierProvider<SuggestedFoodViewModel>(
        create: (_) => locator<SuggestedFoodViewModel>(),
      ),
      ChangeNotifierProvider<PatientAppointmentsViewModel>(
        create: (_) => locator<PatientAppointmentsViewModel>(),
      ),
      ChangeNotifierProvider<ThemeController>(
        create: (_) => locator<ThemeController>(),
      ),
    ];
  }
}

// --- Initialization Error App Widget ---
class ErrorApp extends StatelessWidget {
  final dynamic error;
  final StackTrace? stackTrace;
  const ErrorApp({super.key, required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: NotFoundScreen(
          errorMessage: 'Application Initialization Failed',
          errorDetails: '$error\n\n${stackTrace ?? ''}',
          onRetry: () {
            Logger(
              printer: SimplePrinter(),
            ).w('Retrying application initialization...');
            main(); // Call main() to restart the process
          },
          message: '',
        ),
      ),
    );
  }
}
