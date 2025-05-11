// lib/core/error/exceptions.dart

import 'package:flutter/foundation.dart'; // For @immutable

/// Base class for all custom exceptions in the application.
/// Designed to provide more context than standard [Exception].
@immutable // Exceptions should generally be immutable
abstract class AppException implements Exception {
  /// A user-friendly or developer-friendly message describing the error.
  final String message;

  /// The original error/exception that caused this AppException, if any.
  /// Useful for logging and debugging the root cause.
  final Object? cause;

  /// The stack trace associated with the original error, if available.
  final StackTrace? stackTrace;

  const AppException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() {
    // Provide a clear representation including the runtime type.
    // Including the cause can be very helpful for debugging.
    String result = '$runtimeType: $message';
    if (cause != null) {
      result += '\nCause: $cause';
    }
    // Stack trace is usually logged separately, not included in toString by default.
    return result;
  }
}

// ==========================================================================
// --- Specific Application Exception Types ---
// ==========================================================================

// --- Authentication & Authorization ---

/// Exception related to authentication operations (login, signup, token refresh)
/// or authorization/permission issues.
/// 
class GeneralAppException extends AppException {
  GeneralAppException(super.message, {super.cause, super.stackTrace});
}

class AuthException extends AppException {
  /// Specific error code from the authentication provider (e.g., FirebaseAuth code).
  final String? code;

  const AuthException(
    super.message, {
    this.code, // Firebase error code, OAuth error code, etc.
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'AuthException: $message${code != null ? " (Code: $code)" : ""}';
}

/// Exception specifically for user cancellation during an auth flow (e.g., closing Google Sign-In).
class AuthCancelledException extends AuthException {
  // Constructor now only passes message, cause, stackTrace up to AuthException
  const AuthCancelledException(super.message, {super.cause, super.stackTrace});

  // The type itself signifies cancellation. Add specific properties if needed.
  // final bool isCancelled = true; // You could add this field if needed elsewhere

  @override
  String toString() => 'AuthCancelledException: $message (Cancelled by user)';
}

// --- Data Persistence & Access ---

/// Exception related to local database operations (SQLite errors, constraint violations).
class DatabaseException extends AppException {
  /// Optional identifier for the item involved in the DB operation.
  final String? itemIdentifier;

  const DatabaseException(
    super.message, {
    this.itemIdentifier,
    super.cause, // Often an sqflite DatabaseException
    super.stackTrace,
  });

  @override
  String toString() =>
      'DatabaseException: $message${itemIdentifier != null ? " (Item: $itemIdentifier)" : ""}';
}

/// Exception related to network operations (connectivity loss, DNS errors, timeouts *before* response).
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.cause, // Often a SocketException or TimeoutException from Dio/http
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception related to API calls resulting in non-successful HTTP status codes (e.g., 4xx, 5xx)
/// or specific errors returned in the API response body.
class ApiException extends AppException {
  /// HTTP status code from the API response, if available.
  final int? statusCode;

  const ApiException(
    super.message, {
    this.statusCode,
    super.cause, // Often a DioException containing the Response object
    super.stackTrace,
  });

  @override
  String toString() {
    String result = 'ApiException: $message';
    if (statusCode != null) {
      result += ' (Status Code: $statusCode)';
    }
    return result;
  }
}

/// Exception thrown when expected data is not found (e.g., query returns null/empty, 404 from API).
class DataNotFoundException extends AppException {
  // <<< ADDED
  /// Optional identifier of the resource that was not found.
  final String? resourceIdentifier;

  const DataNotFoundException(
    String message, {
    this.resourceIdentifier,
    super.cause,
    super.stackTrace,
  }) : super(
         "$message${resourceIdentifier != null ? ' [ID: $resourceIdentifier]' : ''}",
       ); // Auto-append ID

  @override
  String toString() => message; // Message already includes details
}

/// Exception for errors during data parsing, serialization, deserialization, or transformation.
class DataProcessingException extends AppException {
  const DataProcessingException(
    super.message, {
    super.cause, // e.g., FormatException, TypeError
    super.stackTrace,
  });

  @override
  String toString() => 'DataProcessingException: $message';
}

// --- Business Logic & Domain ---

/// General exception originating from the domain or use case layer, often wrapping lower-level exceptions.
class DomainException extends AppException {
  // <<< ADDED
  const DomainException(super.message, {super.cause, super.stackTrace});

  @override
  String toString() => 'DomainException: $message';
}

/// Exception thrown when an operation is attempted in an invalid state or violates business rules.
/// (e.g., trying to cancel a completed appointment).
class InvalidOperationException extends AppException {
  // <<< ADDED
  const InvalidOperationException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'InvalidOperationException: $message';
}

/// Exception for invalid arguments passed to methods (distinct from user input validation).
class InvalidArgumentException extends AppException {
  // <<< ADDED (or use core ArgumentError)
  final String? argumentName;

  const InvalidArgumentException(
    String message, {
    this.argumentName,
    super.cause,
    super.stackTrace,
  }) : super(
         "$message${argumentName != null ? ' (Argument: $argumentName)' : ''}",
       );

  @override
  String toString() => message;
}

// --- Other Application Exceptions ---

/// Exception related to caching operations specifically (if distinct from DatabaseException).
class CacheException extends AppException {
  const CacheException(super.message, {super.cause, super.stackTrace});

  @override
  String toString() => 'CacheException: $message';
}

/// Exception related to application configuration errors.
class ConfigurationException extends AppException {
  const ConfigurationException(super.message, {super.cause, super.stackTrace});

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Exception for features explicitly marked as not yet implemented.
class UnimplementedFeatureException extends AppException {
  const UnimplementedFeatureException(String featureName)
    : super("Feature not implemented yet: $featureName");

  @override
  String toString() => 'UnimplementedFeatureException: $message';
}

// --- Usage Examples in Comments (Keep or Remove) ---
/*
// LoginRepositoryImpl:
// throw AuthException("Login failed: ${_parseFirebaseError(e.code)}", code: e.code, cause: e, stackTrace: stackTrace);
// throw AuthCancelledException("Google Sign-In cancelled by user.");
// throw AuthException("An unexpected error occurred during login.", cause: e, stackTrace: stackTrace);

// NotificationRepositoryImpl:
// throw DatabaseException("Failed to save notification.", cause: e, stackTrace: stackTrace);
// throw DatabaseException("Failed to load notifications.", cause: e, stackTrace: stackTrace);

// Appointment UseCase (Example):
// if (patient == null) throw DataNotFoundException("Patient not found", resourceIdentifier: patientId);
// if (appointment.status == AppointmentStatus.completed) throw InvalidOperationException("Cannot cancel completed appointment.");

// Repository Example:
// if (docSnapshot.exists) { ... } else { throw DataNotFoundException("Appointment not found", resourceIdentifier: appointmentId); }
// on FirebaseException catch(e) { throw ApiException("Firestore error", cause:e); }
// catch(e) { throw DataProcessingException("Failed parsing data", cause:e); }
*/
