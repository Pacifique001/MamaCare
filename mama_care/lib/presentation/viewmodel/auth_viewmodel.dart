import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

@injectable
class AuthViewModel extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final Logger _logger;
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  UserModel? _localUser;
  User? _firebaseUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;
  StreamSubscription<User?>? _authStateSubscription;

  String? _verificationId;
  int? _forceResendingToken;
  String? _pendingPhoneNumber;

  AuthViewModel(
    this._databaseHelper,
    this._firebaseMessaging,
    this._auth,
    this._googleSignIn,
    this._logger,
    this._firestore,
    this._uuid,
  ) {
    _authStateSubscription = _auth.authStateChanges().listen(
      _onAuthStateChanged,
      onError: (error, stackTrace) {
        _logger.e(
          "Error in authStateChanges stream",
          error: error,
          stackTrace: stackTrace,
        );
        _handleAuthError(
          AuthException("Authentication listener error.", cause: error),
        );
      },
    );
    _logger.i('AuthViewModel initialized and listening to auth state changes.');
  }

  UserModel? get localUser => _localUser;
  User? get currentUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null && _localUser != null;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserRole get userRole => _localUser?.role ?? UserRole.unknown;
  List<String> get userPermissions => _localUser?.permissions ?? [];
  String? get verificationId => _verificationId;

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value || _isDisposed) return;
    _isLoading = value;
    _logger.d('Auth loading state changed: $_isLoading');
    _safeNotifyListeners();
  }

  void _setError(String? message, {Object? error, StackTrace? stackTrace}) {
    if (_errorMessage == message || _isDisposed) return;
    _errorMessage = message;
    if (message != null) {
      _logger.e(
        "AuthViewModel Error set: $message",
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      _logger.d("AuthViewModel Error cleared.");
    }
    _safeNotifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  Map<String, dynamic> _handleAuthError(
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    String message;
    int? statusCode;
    String? errorCode;
    Object? originalError = error;

    _verificationId = null;
    _forceResendingToken = null;
    _pendingPhoneNumber = null;

    if (error is AuthException) {
      message = error.message;
      errorCode = error.code;
      originalError = error.cause ?? error;
      _logger.w(
        "AuthException Handled: ${error.message} (Code: ${error.code})",
        error: originalError,
        stackTrace: stackTrace,
      );
    } else if (error is FirebaseAuthException) {
      message = _parseFirebaseError(error);
      errorCode = error.code;
      _logger.w(
        'FirebaseAuthException Handled: ${error.code} - $message',
        error: error,
        stackTrace: stackTrace,
      );
    } else if (error is ArgumentError) {
      message = error.message ?? 'Invalid argument provided.';
      _logger.w(
        'ArgumentError Handled: $message',
        error: error,
        stackTrace: stackTrace ?? error.stackTrace,
      );
    } else if (error is ApiException) {
      message = error.message;
      statusCode = error.statusCode;
      originalError = error.cause ?? error;
      _logger.e(
        'ApiException Handled: $message (Code: $statusCode)',
        error: originalError,
        stackTrace: error.stackTrace ?? stackTrace,
      );
    } else if (error is DataProcessingException) {
      message = error.message;
      originalError = error.cause ?? error;
      _logger.e(
        'DataProcessingException Handled: $message',
        error: originalError,
        stackTrace: error.stackTrace ?? stackTrace,
      );
    } else if (error is GeneralAppException) {
      // Handle the concrete general exception
      message = error.message;
      originalError = error.cause ?? error;
      _logger.e(
        'GeneralAppException Handled: $message',
        error: originalError,
        stackTrace: error.stackTrace ?? stackTrace,
      );
    } else if (error is AppException) {
      // Keep catch-all for other potential concrete AppExceptions
      message = error.message;
      originalError = error.cause ?? error;
      _logger.e(
        'AppException Handled: $message',
        error: originalError,
        stackTrace: error.stackTrace ?? stackTrace,
      );
    } else {
      message = 'An unexpected error occurred during authentication.';
      _logger.e(
        'Unhandled Auth Error Handled',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _setError(message, error: originalError, stackTrace: stackTrace);

    return {
      'status': 'error',
      'message': message,
      'code': errorCode,
      'statusCode': statusCode,
    };
  }

  String _parseFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-phone-number':
        return 'The provided phone number is not valid. Use E.164 format (e.g., +11234567890).';
      case 'invalid-verification-code':
        return 'The verification code entered is incorrect.';
      case 'invalid-verification-id':
        return 'The verification process is invalid or expired. Please try sending the code again.';
      case 'session-expired':
        return 'The verification code has expired. Please request a new one.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'missing-phone-number':
        return 'Phone number is missing.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'missing-verification-code':
        return 'The verification code is missing.';
      case 'requires-recent-login':
        return 'This action requires you to sign in again for security. Please log out and log back in.';
      default:
        _logger.e("Unknown FirebaseAuthException code: ${e.code}", error: e);
        return 'Authentication failed (Code: ${e.code}).';
    }
  }

  Map<String, dynamic> _authSuccessResponse(UserModel user) {
    return {
      'status': 'success',
      'user': user.toJson(),
      'role': userRoleToString(user.role),
      'message': 'Authentication successful',
    };
  }

  List<String> _getDefaultPermissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return [
          'view_profile',
          'view_appointments',
          'request_appointment',
          'view_articles',
          'view_videos',
          'view_timeline',
          'view_calendar',
        ];
      case UserRole.nurse:
        return [
          'view_profile',
          'view_assigned_patients',
          'manage_own_appointments',
          'edit_patient_notes',
          'view_articles',
          'view_videos',
        ];
      case UserRole.doctor:
        return [
          'view_profile',
          'view_all_patients',
          'manage_appointments',
          'assign_nurse',
          'manage_nurses',
          'view_reports',
          'edit_articles',
          'edit_videos',
        ];
      case UserRole.admin:
        return [
          'manage_users',
          'manage_roles',
          'manage_content',
          'view_all_data',
          'configure_settings',
        ];
      default:
        return [];
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (_isDisposed) return;
    _logger.i(
      'Auth state changed. Firebase user: ${firebaseUser?.uid ?? 'null'}',
    );
    _setLoading(true);
    _firebaseUser = firebaseUser;

    if (firebaseUser != null) {
      try {
        _verificationId = null;
        _forceResendingToken = null;
        _localUser = await _fetchOrInitializeUserAppData(firebaseUser);
        if (_localUser != null) {
          await _updateUserSession(firebaseUser.uid, _localUser!.id);
          clearError();
          _logger.i(
            "User ${firebaseUser.uid} (${_localUser!.role.name}) authenticated and synced from Firestore.",
          );
        } else {
          _logger.e(
            "Critical Error: _localUser is null after Firestore fetch/init for ${firebaseUser.uid}.",
          );
          throw AuthException(
            "Failed to load user profile after login.",
            code: "firestore-sync-failed",
          );
        }
      } catch (e, stackTrace) {
        _logger.e(
          'Error processing logged-in auth state change',
          error: e,
          stackTrace: stackTrace,
        );
        _handleAuthError(e, stackTrace);
        _localUser = null;
        await logout();
      }
    } else {
      _localUser = null;
      _verificationId = null;
      _forceResendingToken = null;
      _pendingPhoneNumber = null;
      clearError();
      _logger.i("User logged out, local state cleared.");
    }
    _setLoading(false);
  }

  Future<UserModel?> _fetchOrInitializeUserAppData(User firebaseUser) async {
    _logger.d(
      "Fetching/Initializing Firestore app data for user ${firebaseUser.uid}",
    );
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    try {
      final docSnapshot = await docRef.get(
        const GetOptions(source: Source.serverAndCache),
      );
      UserModel userAppData;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (docSnapshot.exists && docSnapshot.data() != null) {
        _logger.d(
          "Firestore document found for ${firebaseUser.uid}. Parsing...",
        );
        userAppData = UserModel.fromMap({
          ...docSnapshot.data()!,
          'id': docSnapshot.id,
          'firebaseId': firebaseUser.uid,
        });
        _logger.d("Parsed Firestore data: Role=${userAppData.role.name}");

        final String? authName = firebaseUser.displayName?.trim();
        final String? authPhotoUrl = firebaseUser.photoURL;
        final String? authPhoneNumber = firebaseUser.phoneNumber;
        final bool authVerified = firebaseUser.emailVerified;
        final String firestoreName = userAppData.name;
        final String? firestorePhotoUrl = userAppData.profileImageUrl;
        final String? firestorePhoneNumber = userAppData.phoneNumber;
        final bool firestoreVerified = userAppData.verified;
        final String finalName =
            (authName != null && authName.isNotEmpty)
                ? authName
                : firestoreName;
        final String? finalPhotoUrl =
            (authPhotoUrl != null && authPhotoUrl.isNotEmpty)
                ? authPhotoUrl
                : firestorePhotoUrl;
        final String? finalPhoneNumber =
            (authPhoneNumber != null && authPhoneNumber.isNotEmpty)
                ? authPhoneNumber
                : firestorePhoneNumber;
        final bool finalVerified = authVerified;

        bool needsFirestoreUpdate = false;
        Map<String, dynamic> firestoreUpdateData = {
          'lastLogin': FieldValue.serverTimestamp(),
        };
        if (finalName != firestoreName) {
          firestoreUpdateData['name'] = finalName;
          needsFirestoreUpdate = true;
        }
        if (finalPhotoUrl != firestorePhotoUrl) {
          firestoreUpdateData['profileImageUrl'] = finalPhotoUrl;
          needsFirestoreUpdate = true;
        }
        if (finalPhoneNumber != firestorePhoneNumber) {
          firestoreUpdateData['phoneNumber'] = finalPhoneNumber;
          needsFirestoreUpdate = true;
        }
        if (finalVerified != firestoreVerified) {
          firestoreUpdateData['verified'] = finalVerified;
          needsFirestoreUpdate = true;
        }

        userAppData = userAppData.copyWith(
          name: finalName,
          profileImageUrl: finalPhotoUrl,
          phoneNumber: finalPhoneNumber,
          verified: finalVerified,
          lastLogin: now,
        );

        if (needsFirestoreUpdate) {
          _logger.d(
            "Updating existing user data in Firestore (merge specific fields).",
          );
          await docRef.set(firestoreUpdateData, SetOptions(merge: true));
        } else {
          _logger.d(
            "Firestore data up-to-date with Auth state, only updating lastLogin.",
          );
          await docRef.set({
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else {
        _logger.i(
          "Firestore document NOT found for ${firebaseUser.uid}. Creating new user data.",
        );
        final initialRole = UserRole.patient;
        userAppData = UserModel(
          id: firebaseUser.uid,
          firebaseId: firebaseUser.uid,
          email: firebaseUser.email?.trim().toLowerCase() ?? '',
          name: firebaseUser.displayName?.trim() ?? 'New User',
          phoneNumber: firebaseUser.phoneNumber?.trim(),
          profileImageUrl: firebaseUser.photoURL,
          verified: firebaseUser.emailVerified,
          createdAt: now,
          lastLogin: now,
          role: initialRole,
          permissions: _getDefaultPermissionsForRole(initialRole),
          password: null,
          syncStatus: 0,
          lastSynced: now,
        );
        _logger.d(
          "Creating initial Firestore document for new user ${firebaseUser.uid}",
        );
        await docRef.set(userAppData.toFirestoreMap());
      }
      _logger.d(
        "User data fetched/initialized from Firestore for ${userAppData.id}. Local state updated.",
      );
      return userAppData;
    } on FirebaseException catch (e, s) {
      _logger.e(
        "Firestore error fetching/initializing user data",
        error: e,
        stackTrace: s,
      );
      throw ApiException(
        "Failed to load profile from cloud.",
        cause: e,
        statusCode: e.code.hashCode,
      );
    } catch (e, s) {
      _logger.e(
        "Error processing user app data from Firestore",
        error: e,
        stackTrace: s,
      );
      throw DataProcessingException(
        "Failed to process user profile.",
        cause: e,
      );
    }
  }

  Future<void> _updateUserSession(
    String firebaseUid,
    String localUserId,
  ) async {
    _logger.d(
      'Updating session info for user: $localUserId (Firebase: $firebaseUid)',
    );
    try {
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        await _saveAndSyncFcmToken(fcmToken, localUserId, firebaseUid);
      } else {
        _logger.w("Failed to get FCM token for session update.");
      }
      _logger.i(
        'User session components (FCM) updated successfully for $localUserId.',
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to update user session components for $localUserId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveAndSyncFcmToken(
    String token,
    String localUserId,
    String firebaseUid,
  ) async {
    _logger.d("Saving/syncing FCM token for user $localUserId / $firebaseUid");

    // First try to update the token in Firestore
    bool firestoreSuccess = await _updateUserFCMTokenInFirestore(
      firebaseUid,
      token,
    );

    // Only try to save locally if Firestore update was successful
    if (firestoreSuccess) {
      try {
        // Check if the user exists in the local database first
        bool userExists = await _databaseHelper.checkUserExists(localUserId);

        if (!userExists) {
          _logger.w(
            "User $localUserId does not exist in local database. Creating local user record first.",
          );

          // Get current user data from memory or fetch from Firestore if needed
          late UserModel userData;
          if (_localUser != null && _localUser!.id == localUserId) {
            userData = _localUser!;
          } else {
            // Fetch user data from Firestore
            final docSnapshot =
                await _firestore.collection('users').doc(firebaseUid).get();
            if (docSnapshot.exists && docSnapshot.data() != null) {
              // Ensure the document ID is properly set and preserved
              Map<String, dynamic> userMap = {
                ...docSnapshot.data()!,
                'id': firebaseUid, // Explicitly set the ID properly
                'firebaseId': firebaseUid,
              };
              _logger.d("Creating UserModel with data: $userMap");
              userData = UserModel.fromMap(userMap);
            } else {
              _logger.e(
                "Cannot save FCM token locally: User does not exist in Firestore",
              );
              return;
            }
          }

          // Save user to local database first using upsertUser
          try {
            // Ensure the ID is explicitly preserved when converting to JSON
            Map<String, dynamic> userJson = userData.toSqliteMap();
            // Double-check that ID is included in the JSON
            if (!userJson.containsKey('id') ||
                userJson['id'] == null ||
                userJson['id'].toString().isEmpty) {
              _logger.w("Adding missing ID to user JSON: $firebaseUid");
              userJson['id'] = firebaseUid;
            }

            _logger.d("Upserting user with JSON: $userJson");
            await _databaseHelper.upsertUser(userJson);
            _logger.d(
              "Created local user record for $localUserId before saving FCM token",
            );
          } catch (userSaveError, userSaveStack) {
            _logger.e(
              "Failed to create local user record for FCM token",
              error: userSaveError,
              stackTrace: userSaveStack,
            );
            return; // Exit early as we can't save the token without a user
          }
        }

        // Now attempt to save the FCM token
        await _databaseHelper.saveFcmToken(token, localUserId);
        _logger.d("FCM token saved locally.");
      } catch (e, stackTrace) {
        _logger.w(
          "Error saving FCM token to local database. Will continue with session.",
          error: e,
          stackTrace: stackTrace,
        );
        // Don't rethrow - we can still function without local token storage
      }
    }

    _logger.d("FCM token sync process completed.");
  }

  Future<bool> _updateUserFCMTokenInFirestore(String uid, String token) async {
    try {
      _logger.d("AuthVM: Updating FCM token in Firestore for user $uid");

      // First, get the current document
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> existingTokens =
            data.containsKey('fcmTokens')
                ? List<dynamic>.from(data['fcmTokens'] ?? [])
                : [];

        // Check if token already exists to avoid duplicates
        if (!existingTokens.contains(token)) {
          // Add the new token
          existingTokens.add(token);

          // Clean up any old/invalid tokens periodically
          // This helps address the unregistered token errors we're seeing
          if (existingTokens.length > 5) {
            // Keep only the most recent 5 tokens, assuming newer ones are more likely valid
            existingTokens = existingTokens.sublist(existingTokens.length - 5);
          }

          // Update with the cleaned token list
          await _firestore.collection('users').doc(uid).set({
            'fcmTokens': existingTokens,
            'fcmTokenLastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          _logger.d("AuthVM: Firestore FCM token updated for user $uid");
        } else {
          _logger.d(
            "AuthVM: Token already exists in Firestore, no update needed",
          );
        }
      } else {
        // Document doesn't exist yet, create it with the token
        await _firestore.collection('users').doc(uid).set({
          'fcmTokens': [token],
          'fcmTokenLastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _logger.d("AuthVM: Created new user document with FCM token");
      }

      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'AuthVM: Error updating FCM token in Firestore for user $uid',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String password,
  ) async {
    clearError();
    _setLoading(true);
    try {
      if (!_validateEmail(email)) throw ArgumentError('Invalid email format');
      if (password.isEmpty) throw ArgumentError('Password cannot be empty');
      _logger.i('AuthVM: Attempting Firebase login for: $email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _logger.i(
        'AuthVM: Firebase sign-in successful (listener will handle state async)',
      );
      bool userStateReady = await _waitForAuthenticationState(
        identifier: email,
        isPhone: false,
      );
      if (!userStateReady) {
        _logger.w(
          "Authentication state wait failed or timed out for $email. Final Error: $_errorMessage",
        );
        await logout();
        return _handleAuthError(
          AuthException(
            _errorMessage ??
                "Login failed: Timed out waiting for user data sync.",
            code: "wait-timeout",
          ),
        );
      }
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setLoading(false);
        return _handleAuthError(
          AuthException("Login failed unexpectedly after initial success."),
        );
      }
      await currentUser.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        _setLoading(false);
        return _handleAuthError(
          AuthException("User session lost after checking verification."),
        );
      }
      if (!refreshedUser.emailVerified) {
        _logger.w(
          "Login successful but email not verified for $email (checked after wait).",
        );
        _setError(
          "Please verify your email address. Check your inbox for a link.",
        );
        await logout();
        _setLoading(false);
        return {
          'status': 'error',
          'message': _errorMessage,
          'code': 'email-not-verified',
        };
      }
      _logger.i("User $email logged in and email is verified.");
      _setLoading(false);
      if (_localUser == null) {
        return _handleAuthError(
          AuthException("User data inconsistency after successful login."),
        );
      }
      return _authSuccessResponse(_localUser!);
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _handleAuthError(e);
    } catch (e, stackTrace) {
      _logger.e(
        'Email login process failed unexpectedly',
        error: e,
        stackTrace: stackTrace,
      );
      _setLoading(false);
      return _handleAuthError(
        e is AppException
            ? e
            : AuthException(
              "Login failed due to an unexpected error.",
              cause: e,
            ),
        stackTrace,
      );
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    clearError();
    _setLoading(true);
    try {
      _logger.i('AuthVM: Attempting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w('AuthVM: Google Sign-In cancelled by user.');
        _setLoading(false);
        return {'status': 'cancelled', 'message': 'Sign in cancelled'};
      }
      _logger.d('AuthVM: Google User obtained: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      _logger.i('AuthVM: Signing into Firebase with Google credential...');
      await _auth.signInWithCredential(credential);
      _logger.i(
        'AuthVM: Firebase Google sign-in successful (listener will handle state)',
      );
      bool userStateReady = await _waitForAuthenticationState(
        identifier: googleUser.email!,
        isPhone: false,
      );
      if (!userStateReady) {
        _setLoading(false);
        await _googleSignIn.signOut().catchError((_) {});
        return _handleAuthError(
          _errorMessage ??
              AuthException(
                "Google Sign-In completed but failed to sync user data.",
              ),
        );
      }
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setLoading(false);
        await _googleSignIn.signOut().catchError((_) {});
        return _handleAuthError(
          AuthException("User session lost after Google Sign-In."),
        );
      }
      _logger.i("User ${googleUser.email} signed in via Google successfully.");
      _setLoading(false);
      if (_localUser == null) {
        await _googleSignIn.signOut().catchError((_) {});
        return _handleAuthError(
          AuthException("User data inconsistency after Google sign-in."),
        );
      }
      return _authSuccessResponse(_localUser!);
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuthException during Google Sign-In', error: e);
      await _googleSignIn.signOut().catchError((_) {});
      _setLoading(false);
      return _handleAuthError(e);
    } catch (e, stackTrace) {
      _logger.e(
        'Google Sign-In process failed unexpectedly',
        error: e,
        stackTrace: stackTrace,
      );
      await _googleSignIn.signOut().catchError((_) {});
      _setLoading(false);
      return _handleAuthError(
        e is AppException
            ? e
            : AuthException("Google Sign-In failed.", cause: e),
        stackTrace,
      );
    }
  }

  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? profileImageUrl,
    UserRole initialRole = UserRole.patient,
  }) async {
    clearError();
    _setLoading(true);
    User? tempFirebaseUser;
    try {
      if (!_validateEmail(email)) throw ArgumentError('Invalid email format');
      if (!_validatePassword(password))
        throw ArgumentError('Password does not meet requirements.');
      if (name.trim().isEmpty) throw ArgumentError('Name cannot be empty');
      _logger.i(
        'AuthVM: Attempting Firebase account creation for: $email with role: ${initialRole.name}',
      );
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      tempFirebaseUser = userCredential.user;
      if (tempFirebaseUser == null) {
        throw AuthException('Firebase user creation failed unexpectedly.');
      }
      final firebaseUser = tempFirebaseUser!;
      _logger.i('AuthVM: Firebase account created: ${firebaseUser.uid}');
      try {
        await firebaseUser.updateDisplayName(name.trim());
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          await firebaseUser.updatePhotoURL(profileImageUrl);
        }
        _logger.d("Updated Firebase profile for ${firebaseUser.uid}");
      } catch (e) {
        _logger.w(
          'AuthVM: Non-fatal error updating Firebase profile',
          error: e,
        );
      }
      _logger.d(
        "AuthVM: Creating initial Firestore document for user ${firebaseUser.uid}",
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final userData = UserModel(
        id: firebaseUser.uid,
        firebaseId: firebaseUser.uid,
        email: email.trim().toLowerCase(),
        name: name.trim(),
        phoneNumber:
            phoneNumber?.trim().isEmpty ?? true ? null : phoneNumber!.trim(),
        profileImageUrl: profileImageUrl ?? firebaseUser.photoURL,
        verified: firebaseUser.emailVerified,
        createdAt: now,
        lastLogin: null,
        role: initialRole,
        permissions: _getDefaultPermissionsForRole(initialRole),
        password: null,
        syncStatus: 0,
        lastSynced: now,
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userData.toFirestoreMap());
      _logger.i(
        "AuthVM: Firestore document created for ${firebaseUser.uid} with role ${initialRole.name}",
      );
      try {
        await firebaseUser.sendEmailVerification();
        _logger.i("AuthVM: Verification email sent to $email.");
      } catch (e) {
        _logger.w(
          "AuthVM: Failed to send verification email to $email.",
          error: e,
        );
      }
      _setLoading(false);
      return {
        'status': 'success_needs_verification',
        'message':
            'Signup successful! Please check your email ($email) for a verification link.',
        'userId': firebaseUser.uid,
      };
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _handleAuthError(e);
    } catch (e, stackTrace) {
      _logger.e(
        'Sign up process failed after Firebase Auth creation',
        error: e,
        stackTrace: stackTrace,
      );
      _setLoading(false);
      if (tempFirebaseUser != null) {
        _logger.w(
          "Attempting to delete orphaned Firebase Auth user ${tempFirebaseUser.uid} due to error: $e",
        );
        await tempFirebaseUser.delete().catchError((delErr, delStack) {
          _logger.e(
            "Failed to delete orphaned auth user ${tempFirebaseUser!.uid}",
            error: delErr,
            stackTrace: delStack,
          );
        });
      }
      return _handleAuthError(
        e is AppException
            ? e
            : AuthException("Signup failed during data setup.", cause: e),
        stackTrace,
      );
    }
  }

  Future<Map<String, dynamic>> sendOtpToPhone(String phoneNumber) async {
    clearError();
    if (!validatePhoneNumber(phoneNumber)) {
      return _handleAuthError(
        ArgumentError(
          'Invalid phone number format. Use E.164 format (e.g., +11234567890).',
        ),
      );
    }
    _setLoading(true);
    _pendingPhoneNumber = phoneNumber;
    _verificationId = null;
    _forceResendingToken = null;
    _logger.i("Attempting to send OTP to $phoneNumber");
    Completer<Map<String, dynamic>> completer = Completer();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _logger.i(
            "Phone auth verification completed automatically for $phoneNumber.",
          );
          _setLoading(true);
          try {
            await _auth.signInWithCredential(credential);
            _logger.d(
              "Auto-verification: signInWithCredential successful. Listener will handle final state.",
            );
            if (!completer.isCompleted)
              completer.complete({
                'status': 'pending_auth_state',
                'message': 'Auto-verification complete, finalizing login...',
              });
          } on FirebaseAuthException catch (e) {
            _logger.e("Auto-verification: Error signing in", error: e);
            if (!completer.isCompleted) completer.complete(_handleAuthError(e));
            _setLoading(false);
          } catch (e, s) {
            _logger.e(
              "Auto-verification: Unexpected error signing in",
              error: e,
              stackTrace: s,
            );
            if (!completer.isCompleted)
              completer.complete(
                _handleAuthError(
                  AuthException("Auto verification sign in failed.", cause: e),
                  s,
                ),
              );
            _setLoading(false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _logger.e(
            "Phone auth verification failed for $phoneNumber: ${e.code} - ${e.message}",
          );
          if (!completer.isCompleted) completer.complete(_handleAuthError(e));
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _logger.i(
            "OTP code sent successfully to $phoneNumber. Verification ID: $verificationId",
          );
          _verificationId = verificationId;
          _forceResendingToken = resendToken;
          _pendingPhoneNumber = phoneNumber;
          _setLoading(false);
          _safeNotifyListeners();
          if (!completer.isCompleted)
            completer.complete({
              'status': 'code_sent',
              'message': 'OTP sent successfully.',
            });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logger.w(
            "Phone auth auto-retrieval timed out for $phoneNumber. Verification ID: $verificationId",
          );
          if (_verificationId == null) {
            _verificationId = verificationId;
            _pendingPhoneNumber = phoneNumber;
            _safeNotifyListeners();
          }
          if (_isLoading) _setLoading(false);
        },
        timeout: const Duration(seconds: 60),
      );
      return completer.future;
    } catch (e, stackTrace) {
      _logger.e(
        "Error initiating phone verification for $phoneNumber",
        error: e,
        stackTrace: stackTrace,
      );
      final errorResult = _handleAuthError(
        AuthException("Failed to start phone verification.", cause: e),
        stackTrace,
      );
      _setLoading(false);
      if (!completer.isCompleted) completer.complete(errorResult);
      return errorResult;
    }
  }

  Future<Map<String, dynamic>> verifySmsCodeAndSignIn(String smsCode) async {
    try {
      if (_verificationId == null) {
        return {
          'status': 'error',
          'message':
              'No verification in progress. Please restart verification.',
        };
      }
      _setLoading(true);
      notifyListeners();
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        if (isNewUser) {
          await user.updateDisplayName(user.phoneNumber ?? "New User");
          await _firestore.collection('users').doc(user.uid).set({
            'phoneNumber': user.phoneNumber,
            'role': 'patient',
            'createdAt': FieldValue.serverTimestamp(),
            'firebaseId': user.uid,
            'name': user.phoneNumber ?? 'New User',
            'email': null,
            'profileImageUrl': null,
            'verified': false,
            'permissions': _getDefaultPermissionsForRole(UserRole.patient),
            'lastLogin': FieldValue.serverTimestamp(),
          });
          _logger.i(
            "Created Firestore document for new phone user: ${user.uid}",
          );
        }
        bool userStateReady = await _waitForAuthenticationState(
          identifier: user.phoneNumber!,
          isPhone: true,
        );
        _setLoading(false);
        if (!userStateReady) {
          await logout();
          return _handleAuthError(
            AuthException(
              _errorMessage ??
                  "Phone Sign-In completed but failed to sync user data.",
            ),
          );
        }
        if (_localUser == null) {
          return _handleAuthError(
            AuthException("User data inconsistency after phone sign-in."),
          );
        }
        return {
          'status': 'success',
          'message': 'Phone verification successful',
          'role': userRoleToString(_localUser!.role),
        };
      } else {
        _errorMessage = 'Failed to sign in after verification';
        _isLoading = false;
        notifyListeners();
        return {'status': 'error', 'message': _errorMessage};
      }
    } catch (e) {
      _errorMessage = 'Verification failed: ${e.toString()}';
      _logger.e(_errorMessage!);
      _isLoading = false;
      notifyListeners();
      return {'status': 'error', 'message': _errorMessage};
    }
  }

  Future<Map<String, dynamic>> resendOtpCode() async {
    if (_pendingPhoneNumber == null) {
      return {
        'status': 'error',
        'message': 'No phone number to resend code to',
      };
    }
    return await sendOtpToPhone(_pendingPhoneNumber!);
  }

  Future<void> logout() async {
    _logger.i('AuthVM: Attempting logout...');
    if (_isDisposed) {
      _logger.w("Logout called on disposed AuthViewModel.");
      return;
    }
    _setLoading(true);
    clearError();
    final String? wasLoggedInUser = _firebaseUser?.uid;
    try {
      _verificationId = null;
      _forceResendingToken = null;
      _pendingPhoneNumber = null;
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        _logger.d('AuthVM: Signed out from Google.');
      }
      await _auth.signOut();
      _logger.i('AuthVM: Firebase sign out requested successfully.');
    } catch (e, stackTrace) {
      _logger.e('AuthVM: Logout failed', error: e, stackTrace: stackTrace);
      _localUser = null;
      _firebaseUser = null;
      _setError(
        "Logout failed. Please try again.",
        error: e,
        stackTrace: stackTrace,
      );
      _setLoading(false);
    } finally {
      if (_isLoading && _firebaseUser == null && wasLoggedInUser != null) {
        _logger.w(
          "AuthVM: Forcing loading state false after logout processed or failed.",
        );
        _setLoading(false);
      }
    }
  }

  Future<bool> checkEmailVerificationStatus() async {
    final userToCheck = _auth.currentUser;
    if (userToCheck == null || userToCheck.email == null) {
      _logger.w(
        "Cannot check email verification: No user logged in or user has no email.",
      );
      return false;
    }
    _logger.d("Checking email verification status for ${userToCheck.email}...");
    _setLoading(true);
    clearError();
    try {
      await userToCheck.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        _logger.w("User became null after reload during verification check.");
        _handleAuthError(
          AuthException("Session lost during verification check."),
        );
        return false;
      }
      bool isNowVerified = refreshedUser.emailVerified;
      _logger.i("Checked email verification status: $isNowVerified");
      if (isNowVerified && _localUser?.verified != true) {
        _logger.i("Email newly verified, forcing user data refresh...");
        await _forceRefreshCurrentUser();
        await Future.delayed(const Duration(milliseconds: 200));
        isNowVerified = _localUser?.verified ?? isNowVerified;
      }
      return isNowVerified;
    } catch (e, s) {
      _logger.e(
        "Error reloading user for verification check",
        error: e,
        stackTrace: s,
      );
      _handleAuthError(
        AuthException("Could not check verification status.", cause: e),
        s,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> resendVerificationEmail() async {
    final userToSendTo = _auth.currentUser;
    if (userToSendTo == null) {
      return _handleAuthError(
        AuthException(
          "Not logged in. Cannot resend verification email.",
          code: "no-user",
        ),
      );
    }
    if (userToSendTo.email == null) {
      return _handleAuthError(
        AuthException(
          "No email address associated with this account.",
          code: 'no-email',
        ),
      );
    }
    if (userToSendTo.emailVerified) {
      return {'status': 'no_action', 'message': 'Email is already verified.'};
    }
    _logger.i("Resending verification email to ${userToSendTo.email}");
    clearError();
    _setLoading(true);
    try {
      await userToSendTo.sendEmailVerification();
      _setLoading(false);
      return {
        'status': 'success',
        'message':
            'Verification email sent successfully to ${userToSendTo.email}. Please check your inbox (and spam folder).',
      };
    } catch (e, s) {
      _setLoading(false);
      if (e is FirebaseAuthException && e.code == 'too-many-requests') {
        return _handleAuthError(
          AuthException(
            "Too many requests. Please wait before trying to resend the email.",
            code: e.code,
            cause: e,
          ),
          s,
        );
      }
      return _handleAuthError(
        AuthException("Failed to resend verification email.", cause: e),
        s,
      );
    }
  }

  Future<void> _forceRefreshCurrentUser() async {
    final userToRefresh = _auth.currentUser;
    if (userToRefresh != null) {
      _logger.d(
        "Forcing refresh of current user data by re-triggering listener...",
      );
      await _onAuthStateChanged(userToRefresh);
    } else {
      _logger.w(
        "Cannot force refresh, no current user in FirebaseAuth instance.",
      );
    }
  }

  bool _validateEmail(String email) =>
      email.isNotEmpty &&
      RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)+$",
        caseSensitive: false,
      ).hasMatch(email.trim());

  bool _validatePassword(String password) {
    if (password.length < 8) return false;
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasLetter && hasNumber;
  }

  bool validatePhoneNumber(String phoneNumber) =>
      RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phoneNumber.trim());

  Future<String?> getSavedEmail() async {
    try {
      return await _databaseHelper.getPreference('saved_email');
    } catch (e, s) {
      _logger.e("Failed to get saved email from DB", error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> saveEmail(String email) async {
    if (_validateEmail(email)) {
      try {
        await _databaseHelper.savePreference('saved_email', email.trim());
        _logger.d("Saved email preference locally.");
      } catch (e, s) {
        _logger.e("Failed to save email to DB", error: e, stackTrace: s);
      }
    }
  }

  Future<void> updateNursePermissions(
    String nurseUserId,
    List<String> newPermissions,
  ) async {
    _logger.i("Attempting to update permissions for nurse $nurseUserId");
    if (userRole != UserRole.doctor && userRole != UserRole.admin) {
      _setError(
        "Permission Denied: Only doctors or admins can update nurse permissions.",
      );
      return;
    }
    if (_localUser == null) {
      _setError("Cannot perform action: Current user data not loaded.");
      return;
    }
    _setLoading(true);
    clearError();
    try {
      final nurseDocRef = _firestore.collection('users').doc(nurseUserId);
      await nurseDocRef.update({'permissions': newPermissions});
      _logger.i(
        "Successfully updated permissions for nurse $nurseUserId in Firestore.",
      );
      _setLoading(false);
    } on FirebaseException catch (e, s) {
      _logger.e(
        "Firestore error updating nurse permissions",
        error: e,
        stackTrace: s,
      );
      _setLoading(false);
      _handleAuthError(
        ApiException(
          "Failed to update nurse permissions.",
          cause: e,
          statusCode: e.code.hashCode,
        ),
        s,
      );
    } catch (e, s) {
      _logger.e(
        "Unexpected error updating nurse permissions",
        error: e,
        stackTrace: s,
      );
      _setLoading(false);
      _handleAuthError(
        GeneralAppException("Could not update permissions.", cause: e),
        s,
      ); // Use GeneralAppException
    }
  }

  Future<bool> _waitForAuthenticationState({
    required String identifier,
    required bool isPhone,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (identifier.isEmpty) {
      _logger.e("Empty identifier provided to _waitForAuthenticationState");
      return false;
    }
    final String cleanIdentifier =
        isPhone ? identifier.trim() : identifier.trim().toLowerCase();
    _logger.d(
      "Waiting for auth state listener for $cleanIdentifier (isPhone: $isPhone)...",
    );
    if (isAuthenticated && !_isLoading) {
      bool idMatch =
          isPhone
              ? (_localUser?.phoneNumber == cleanIdentifier)
              : (_localUser?.email?.toLowerCase() == cleanIdentifier);
      if (idMatch) {
        _logger.d("Already authenticated: $cleanIdentifier.");
        return true;
      } else {
        _logger.d(
          "Already authenticated but with different identifier. Expected: $cleanIdentifier, Got: ${isPhone ? _localUser?.phoneNumber : _localUser?.email}",
        );
      }
    }
    bool listenerRemoved = false;
    bool timerCancelled = false;
    final Completer<bool> completer = Completer<bool>();
    Timer? timer;
    VoidCallback? listener;
    StreamSubscription<User?>? authStateSubscription;
    void safeComplete(bool result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    void cleanup() {
      if (!listenerRemoved && listener != null) {
        removeListener(listener);
        listenerRemoved = true;
      }
      if (!timerCancelled && timer != null) {
        timer.cancel();
        timerCancelled = true;
      }
      authStateSubscription?.cancel();
    }

    authStateSubscription = _auth.authStateChanges().listen(
      (User? firebaseUser) {
        if (listenerRemoved) return;
        _logger.d(
          "Firebase auth state changed directly: ${firebaseUser?.uid ?? 'null'}",
        );
        if (firebaseUser != null) {
          String? userIdentifier =
              isPhone
                  ? firebaseUser.phoneNumber
                  : firebaseUser.email?.toLowerCase();
          _logger.d(
            "Firebase auth state shows user with identifier: $userIdentifier",
          );
          if (userIdentifier == cleanIdentifier) {
            _logger.d(
              "Firebase auth state matches expected identifier: $cleanIdentifier",
            );
            if (_firebaseUser?.uid != firebaseUser.uid || _localUser == null) {
              _firebaseUser = firebaseUser;
              _updateLocalUserData(firebaseUser);
            }
          }
        }
      },
      onError: (error) {
        _logger.e("Firebase auth state stream error: $error");
        _setError("Authentication error: ${error.toString()}");
        cleanup();
        safeComplete(false);
      },
    );
    final User? currentFirebaseUser = _auth.currentUser;
    if (currentFirebaseUser != null) {
      _logger.d(
        "Current Firebase user at wait start: ${currentFirebaseUser.uid}",
      );
      String? firebaseIdentifier =
          isPhone
              ? currentFirebaseUser.phoneNumber
              : currentFirebaseUser.email?.toLowerCase();
      _logger.d(
        "Current Firebase identifier: $firebaseIdentifier vs expected: $cleanIdentifier",
      );
    }
    listener = () {
      if (listenerRemoved) return;
      _logger.d(
        "ViewModel state changed. Authenticated: $isAuthenticated, Error: $_errorMessage",
      );
      if (_errorMessage != null) {
        _logger.w("Listener error detected while waiting: $_errorMessage");
        cleanup();
        safeComplete(false);
      } else if (isAuthenticated && _localUser != null) {
        bool idMatch =
            isPhone
                ? (_localUser!.phoneNumber == cleanIdentifier)
                : (_localUser!.email?.toLowerCase() == cleanIdentifier);
        _logger.d(
          "Checking identity match: expected=$cleanIdentifier, actual=${isPhone ? _localUser!.phoneNumber : _localUser!.email}",
        );
        if (idMatch) {
          _logger.d(
            "Auth state listener updated successfully for $cleanIdentifier.",
          );
          cleanup();
          safeComplete(true);
        } else {
          _logger.d(
            "Auth state changed, identifier mismatch while waiting. Expected: $cleanIdentifier, Got: ${isPhone ? _localUser?.phoneNumber : _localUser?.email}",
          );
        }
      } else if (!isAuthenticated && _firebaseUser == null) {
        _logger.d(
          "Auth state changed to unauthenticated while waiting for $cleanIdentifier.",
        );
        cleanup();
        safeComplete(false);
      } else {
        _logger.d(
          "Auth state indeterminate. Authenticated: $isAuthenticated, Firebase user: ${_firebaseUser?.uid ?? 'null'}, Local user: ${_localUser != null}",
        );
      }
    };
    addListener(listener);
    if (isAuthenticated && _localUser != null) {
      bool idMatch =
          isPhone
              ? (_localUser!.phoneNumber == cleanIdentifier)
              : (_localUser!.email?.toLowerCase() == cleanIdentifier);
      if (idMatch) {
        _logger.d(
          "Immediate check found user already authenticated: $cleanIdentifier",
        );
        cleanup();
        return true;
      }
    }
    final int checkIntervals = 4;
    final Duration intervalDuration = Duration(
      milliseconds: timeout.inMilliseconds ~/ checkIntervals,
    );
    int checkCount = 0;
    timer = Timer.periodic(intervalDuration, (Timer t) {
      if (timerCancelled) return;
      checkCount++;
      final User? currentUser = _auth.currentUser;
      _logger.d(
        "Timer check $checkCount/$checkIntervals - Firebase user: ${currentUser?.uid ?? 'null'}",
      );
      if (currentUser != null) {
        String? timerCheckIdentifier =
            isPhone
                ? currentUser.phoneNumber
                : currentUser.email?.toLowerCase();
        _logger.d(
          "Timer check - Firebase identifier: $timerCheckIdentifier vs expected: $cleanIdentifier",
        );
        if (timerCheckIdentifier == cleanIdentifier) {
          _logger.d(
            "Timer check found matching Firebase user - forcing update",
          );
          if (_firebaseUser?.uid != currentUser.uid) {
            _firebaseUser = currentUser;
            _updateLocalUserData(currentUser);
          }
        }
      }
      if (checkCount >= checkIntervals) {
        _logger.e("Timed out waiting for auth state for $cleanIdentifier");
        _setError("Login failed: Timed out waiting for user data sync.");
        cleanup();
        safeComplete(false);
      }
    });
    try {
      final result = await completer.future;
      _logger.d(
        "Finished waiting for auth state for $cleanIdentifier. Success: $result. Final Error: $_errorMessage",
      );
      cleanup();
      return result;
    } catch (e) {
      _logger.e("Error during completer wait: $e");
      cleanup();
      if (_errorMessage == null) {
        _setError(
          "An unexpected error occurred during authentication wait.",
          error: "wait-error",
        );
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> checkEmailVerification() async {
    _logger.i("Checking email verification status");
    clearError();
    try {
      bool isVerified = await checkEmailVerificationStatus();
      if (isVerified) {
        _logger.i("Email verification confirmed");
        return {
          'status': 'verified',
          'message': 'Email verification confirmed.',
        };
      } else {
        final user = _auth.currentUser;
        if (user == null) {
          return {
            'status': 'error',
            'message': 'No active user session to check.',
          };
        } else {
          return {
            'status': 'pending',
            'message': 'Email verification still pending.',
          };
        }
      }
    } catch (e, stackTrace) {
      final errorMsg = "Failed to check email verification status";
      _logger.e(errorMsg, error: e, stackTrace: stackTrace);
      _setError(errorMsg);
      return {
        'status': 'error',
        'message': 'Error checking verification: ${e.toString()}',
      };
    }
  }

  void _updateLocalUserData(User? firebaseUser) {
    if (firebaseUser == null) {
      _localUser = null;
      _logger.d("Local user data cleared (null Firebase user)");
      notifyListeners();
      return;
    }
    _fetchOrInitializeUserAppData(firebaseUser)
        .then((userModel) {
          if (userModel != null) {
            _localUser = userModel;
            _logger.d(
              "Local user data updated/refreshed from Firestore for Firebase user: ${firebaseUser.uid}",
            );
          } else {
            _logger.e(
              "Failed to update local user data after Firebase user update.",
            );
            _localUser = null;
          }
          notifyListeners();
        })
        .catchError((e, s) {
          _logger.e(
            "Error during forced local user data update",
            error: e,
            stackTrace: s,
          );
          _localUser = null;
          notifyListeners();
          _handleAuthError(e, s);
        });
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String email,
    String? phoneNumber,
    String? localImageFilePath,
  }) async {
    clearError();
    if (_localUser == null || _firebaseUser == null) {
      return _handleAuthError(AuthException("Not logged in.", code: "no-user"));
    }
    _setLoading(true);
    _logger.i("Updating profile for user: ${_localUser!.id}");
    bool emailChanged =
        email.trim().toLowerCase() != _firebaseUser!.email?.toLowerCase();
    if (emailChanged) {
      _logger.w("Email change requested. Handling requires re-authentication.");
    }
    String? finalProfileImageUrl = _localUser!.profileImageUrl;
    String? uploadedImageUrl;
    try {
      if (localImageFilePath != null && localImageFilePath.isNotEmpty) {
        _logger.d("Image path provided: $localImageFilePath. Uploading...");
        try {
          File imageFile = File(localImageFilePath);
          if (!await imageFile.exists())
            throw FileSystemException(
              "Image file not found",
              localImageFilePath,
            );
          String filePath =
              'profile_images/${_localUser!.id}/${DateTime.now().millisecondsSinceEpoch}_profile.jpg';
          FirebaseStorage storage = FirebaseStorage.instance;
          final metadata = SettableMetadata(contentType: 'image/jpeg');
          UploadTask uploadTask = storage
              .ref(filePath)
              .putFile(imageFile, metadata);
          TaskSnapshot snapshot = await uploadTask;
          uploadedImageUrl = await snapshot.ref.getDownloadURL();
          _logger.i("Image uploaded successfully, URL: $uploadedImageUrl");
          if (_localUser!.profileImageUrl != null &&
              _localUser!.profileImageUrl!.contains(
                'profile_images/${_localUser!.id}',
              ) &&
              _localUser!.profileImageUrl != uploadedImageUrl) {
            try {
              await storage.refFromURL(_localUser!.profileImageUrl!).delete();
              _logger.d("Deleted old profile image.");
            } catch (e) {
              _logger.w("Failed to delete old profile image", error: e);
            }
          }
          finalProfileImageUrl = uploadedImageUrl;
        } catch (e, s) {
          _logger.e("Failed to upload profile image", error: e, stackTrace: s);
          _setError(
            "Failed to upload profile image: ${e.toString()}",
            error: e,
            stackTrace: s,
          );
        }
      }
      Map<String, dynamic> firestoreUpdateData = {
        'name': name.trim(),
        'phoneNumber':
            phoneNumber?.trim().isEmpty ?? true ? null : phoneNumber!.trim(),
        'profileImageUrl': finalProfileImageUrl,
        'profileLastUpdated': FieldValue.serverTimestamp(),
      };
      if (emailChanged) {
        firestoreUpdateData['email'] = email.trim().toLowerCase();
      }
      _logger.d("Updating Firestore document for ${_firebaseUser!.uid}");
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .set(firestoreUpdateData, SetOptions(merge: true));
      _logger.d("Firestore document updated.");
      bool authProfileUpdated = false;
      try {
        if (_firebaseUser!.displayName != name.trim() ||
            _firebaseUser!.photoURL != finalProfileImageUrl) {
          await _firebaseUser!.updateDisplayName(name.trim());
          if (finalProfileImageUrl != null) {
            await _firebaseUser!.updatePhotoURL(finalProfileImageUrl);
          } else {
            await _firebaseUser!.updatePhotoURL(null);
          }
          await _firebaseUser!.reload();
          _firebaseUser = _auth.currentUser;
          authProfileUpdated = true;
          _logger.d("Firebase Auth profile updated (name/photo).");
        }
      } catch (e, s) {
        _logger.w(
          "Failed to update Firebase Auth profile (name/photo)",
          error: e,
          stackTrace: s,
        );
      }
      final updatedDoc =
          await _firestore.collection('users').doc(_firebaseUser!.uid).get();
      if (updatedDoc.exists && updatedDoc.data() != null) {
        _localUser = UserModel.fromMap({
          ...updatedDoc.data()!,
          'id': updatedDoc.id,
          'firebaseId': _firebaseUser!.uid,
        });
        _logger.i("Refreshed local user state from Firestore after update.");
      } else {
        _logger.e(
          "Firestore document disappeared after profile update for ${_firebaseUser!.uid}",
        );
        _localUser = null;
        throw DataProcessingException("User data lost after update.");
      }
      _logger.i("User profile update successful for ${_localUser!.id}");
      _setLoading(false);
      clearError();
      _safeNotifyListeners();
      return {'status': 'success', 'message': 'Profile updated successfully.'};
    } on FirebaseException catch (e, s) {
      _setLoading(false);
      _logger.e(
        "Firestore/Auth error updating profile",
        error: e,
        stackTrace: s,
      );
      return _handleAuthError(
        ApiException(
          "Failed to save profile changes.",
          cause: e,
          statusCode: e.code.hashCode,
        ),
        s,
      );
    } catch (e, s) {
      _setLoading(false);
      _logger.e("Unexpected error updating profile", error: e, stackTrace: s);
      return _handleAuthError(
        GeneralAppException("Could not update profile.", cause: e),
        s,
      ); // Use GeneralAppException
    }
  }

  @override
  void dispose() {
    _logger.i("Disposing AuthViewModel.");
    _isDisposed = true;
    _authStateSubscription?.cancel();
    super.dispose();
  }

  String userRoleToString(UserRole role) => role.name;
}

UserRole stringToUserRole(String? roleString) {
  if (roleString == null) return UserRole.unknown;
  return UserRole.values.firstWhereOrNull(
        (e) => e.name.toLowerCase() == roleString.toLowerCase().trim(),
      ) ??
      UserRole.unknown;
}
