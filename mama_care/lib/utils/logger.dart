// lib/utils/logger.dart
import 'dart:io'; // Import dart:io for File operations
import 'package:flutter/foundation.dart'; // For kDebugMode and debugPrint
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
// Removed: import 'package:provider/provider.dart'; // Not used here
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // <-- CORRECT IMPORT

/// A custom logger class for handling console, file, and Crashlytics logging.
/// Uses the standard 'logging' package.
class AppLogger {
  // Singleton pattern
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  // Logger instance from 'logging' package
  final Logger _logger = Logger.root; // Use Logger.root for global config

  // File logging configuration
  static const String _logFileName = 'app_logs.log'; // Base log file name
  static const int _maxLogFiles = 5; // Keep current + 4 old logs
  static const int _maxFileSize = 1024 * 1024 * 2; // 2MB per file

  // Flag to prevent multiple initializations
  static bool _isInitialized = false;

  AppLogger._internal() {
    // Initialization should happen only once
    if (!_isInitialized) {
      _initLogging();
      _isInitialized = true;
    }
  }

  /// Initializes the logging setup (levels, listeners).
  void _initLogging() {
    // Set the desired logging level. Messages below this level won't be processed.
    // Level.ALL logs everything, Level.INFO is common for production.
    _logger.level = kDebugMode ? Level.ALL : Level.INFO; // Log more in debug mode

    // Clear existing listeners to avoid duplicates if init is called multiple times
    _logger.clearListeners();

    // Listen to all log records
    _logger.onRecord.listen((record) {
      // Log differently based on environment
      if (kDebugMode) {
        // Log detailed message to console in debug mode
        _logToConsole(record);
      } else {
        // Log simpler message to console in production
        _logToProdConsole(record);
      }
      // Log to file in both modes (consider disabling in production if not needed)
      _logToFile(record);
      // Log severe errors and warnings to Crashlytics
      _logToCrashlytics(record);
    });

    _logger.info("AppLogger Initialized (Level: ${_logger.level.name})");
  }

  /// Formats the log message for detailed console/file output.
  String _formatMessage(LogRecord record) {
    return '[${record.level.name}] '
        '${record.time.toIso8601String()} '
        '${record.loggerName}: ' // Include logger name if using hierarchical loggers
        '${record.message}'
        '${record.error != null ? '\nError: ${record.error}' : ''}' // Error on new line
        '${record.stackTrace != null ? '\nStacktrace:\n${record.stackTrace}' : ''}'; // Stack trace on new line
  }

  /// Logs formatted message to the debug console.
  void _logToConsole(LogRecord record) {
    // Using debugPrint to avoid truncation on some platforms
    debugPrint(_formatMessage(record));
  }

   /// Logs simpler message to console (for production).
   void _logToProdConsole(LogRecord record) {
     debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}${record.error != null ? ' - Error: ${record.error}' : ''}');
   }


  /// Logs formatted message to a rotating file asynchronously.
  Future<void> _logToFile(LogRecord record) async {
    // Avoid file logging on platforms where it might not make sense (e.g., web)
    if (kIsWeb) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$_logFileName';
      final logFile = File(filePath);

      // Check file size and rotate if necessary before writing
      if (await logFile.exists() && await logFile.length() > _maxFileSize) {
        await _rotateLogs(directory, _logFileName);
      }

      // Append the formatted log record
      await logFile.writeAsString(
        '${_formatMessage(record)}\n',
        mode: FileMode.append, // Append to the file
        flush: true, // Ensure it's written immediately (optional)
      );
    } catch (e) {
      // Avoid infinite loops if logging the error itself fails
      debugPrint('[AppLogger] Failed to write log to file: $e');
    }
  }

  /// Rotates log files, keeping a specified number of backups.
  Future<void> _rotateLogs(Directory directory, String baseFileName) async {
     debugPrint('[AppLogger] Rotating log files...');
     // Rename current log file (e.g., app_logs.log -> app_logs.log.1)
     // Shift existing backups (log.1 -> log.2, etc.)
     // Delete the oldest log file if maxLogFiles is exceeded
     try {
        for (int i = _maxLogFiles - 1; i >= 0; i--) {
            final currentPath = (i == 0) ? baseFileName : '$baseFileName.$i';
            final File currentFile = File('${directory.path}/$currentPath');

            if (await currentFile.exists()) {
               if (i == _maxLogFiles - 1) {
                  // Delete the oldest file
                   await currentFile.delete();
                    debugPrint('[AppLogger] Deleted oldest log: ${currentFile.path}');
               } else {
                  // Rename to the next number
                  final nextPath = '$baseFileName.${i + 1}';
                  await currentFile.rename('${directory.path}/$nextPath');
                   debugPrint('[AppLogger] Renamed ${currentFile.path} to $nextPath');
               }
            }
        }
         debugPrint('[AppLogger] Log rotation finished.');
     } catch (e) {
         debugPrint('[AppLogger] Log rotation failed: $e');
     }
  }


  /// Logs errors/severe messages and their stack traces to Firebase Crashlytics.
  void _logToCrashlytics(LogRecord record) {
    // Log only WARNING or SEVERE level messages to Crashlytics
    // Also check if error is not null to avoid logging simple messages as errors
    if (record.level >= Level.WARNING && record.error != null) {
       debugPrint('[AppLogger] Logging to Crashlytics: ${record.level.name} - ${record.message}');
      FirebaseCrashlytics.instance.recordError(
        record.error, // The actual error/exception object
        record.stackTrace,
        reason: 'AppLog [${record.level.name}]: ${record.message}', // Add context
        fatal: record.level >= Level.SEVERE, // Mark SEVERE logs as fatal crashes
      );
    } else if (record.level >= Level.INFO) {
        // Log non-fatal messages as custom logs in Crashlytics for context
         FirebaseCrashlytics.instance.log(
           '[${record.level.name}] ${record.loggerName}: ${record.message}'
         );
    }
  }

  // --- Public Static Logging Methods ---
  // Provide convenient static methods to log from anywhere in the app.
  // These use the root logger instance internally.

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // Use the root logger configured in _initLogging
    Logger.root.severe(message, error, stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    Logger.root.warning(message, error, stackTrace);
  }

  static void info(String message) {
    Logger.root.info(message);
  }

  static void debug(String message) {
    // FINE level is often used for debug messages
    Logger.root.fine(message);
  }

   static void verbose(String message) {
    // FINEST level for very detailed logs
    Logger.root.finest(message);
  }

  // --- Utility Method ---

  /// Retrieves the content of the current log file.
  static Future<String> getLogs() async {
    if (kIsWeb) return 'File logging not available on web.';
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/$_logFileName');
      if (await logFile.exists()) {
         return await logFile.readAsString();
      } else {
         return 'Log file does not exist yet.';
      }
    } catch (e) {
      debugPrint('[AppLogger] Failed to read logs from file: $e');
      return 'Error reading logs: $e';
    }
  }

   /// Call this method once during app initialization (e.g., in main.dart).
   static void initialize() {
     // This will create the singleton instance and run _initLogging if not already done.
     AppLogger();
   }
}