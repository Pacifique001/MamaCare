import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart'; // Import Logger
// Removed Mailer imports - SMTP handled by backend
// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server/gmail.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/data/repositories/login_repository.dart'; // Assuming interface path
// Import UserModel if needed for mapping
import 'package:mama_care/core/error/exceptions.dart'; // Import custom exceptions

@Injectable(as: LoginRepository)
class LoginRepositoryImpl implements LoginRepository {
  final DatabaseHelper
  _databaseHelper; // Keep for potential local checks if needed
  final FirebaseAuth _firebaseAuth; // Inject
  final GoogleSignIn _googleSignIn; // Inject
  final FirebaseMessaging _firebaseMessaging; // Inject
  final FirebaseFirestore _firestore; // Inject
  final Logger _logger; // Inject

  // --- REMOVED SMTP Credentials ---
  // String _smtpUsername = '...'; // REMOVED
  // String _smtpPassword = '...'; // REMOVED

  // Updated constructor with injected dependencies
  LoginRepositoryImpl(
    this._databaseHelper,
    this._firebaseMessaging,
    this._firebaseAuth,
    this._googleSignIn,
    this._firestore,
    this._logger,
  );

  // Removed _initializeEmailCredentials

  @override
  Future<UserCredential> login(String email, String password) async {
    _logger.i("Repository: Attempting Firebase login for $email");
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update FCM token in Firestore after successful login
      if (userCredential.user != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _updateUserFCMTokenInFirestore(userCredential.user!.uid, token);
        } else {
          _logger.w(
            "Could not get FCM token after login for user ${userCredential.user!.uid}",
          );
        }
        // Local DB update (last login, user data sync) should be handled
        // by AuthViewModel listening to auth state changes.
        // Avoid direct DB updates here to prevent race conditions/redundancy.
      } else {
        // Should not happen if signInWithEmailAndPassword succeeded without error
        _logger.e("Firebase login succeeded but UserCredential.user is null!");
        throw AuthException(
          "Login failed: User data unavailable after successful authentication.",
        );
      }

      _logger.i("Repository: Firebase login successful for $email");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.w(
        "Repository: Firebase login failed for $email. Code: ${e.code}",
      );
      // Re-throw a more specific custom exception or let ViewModel handle FirebaseAuthException
      throw AuthException(_parseFirebaseErrorMsg(e.code, "Login failed"));
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected login error for $email",
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException(
        "An unexpected error occurred during login.",
      ); // Generic error
    }
  }

  @override
  Future<UserCredential> googleLogin() async {
    _logger.i("Repository: Attempting Google Sign-In");
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w("Repository: Google Sign-In cancelled by user.");
        throw AuthException("Google Sign-In cancelled."); // Specific exception
      }
      _logger.d("Repository: Google user obtained: ${googleUser.email}");

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      _logger.i("Repository: Signing into Firebase with Google credential...");
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Update FCM token in Firestore
      if (userCredential.user != null) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _updateUserFCMTokenInFirestore(userCredential.user!.uid, token);
        }
        // Local DB sync handled by AuthViewModel listener
      } else {
        _logger.e(
          "Firebase Google Sign-In succeeded but UserCredential.user is null!",
        );
        // Sign out from google in case of partial failure
        await _googleSignIn.signOut().catchError(
          (err) => _logger.e("Error signing out Google on failure", error: err),
        );
        throw AuthException(
          "Google Sign-In failed: User data unavailable after successful authentication.",
        );
      }

      _logger.i(
        "Repository: Firebase Google Sign-In successful for ${googleUser.email}",
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.w("Repository: Firebase Google Sign-In failed. Code: ${e.code}");
      await _googleSignIn.signOut().catchError(
        (err) => _logger.e("Error signing out Google on failure", error: err),
      );
      throw AuthException(
        _parseFirebaseErrorMsg(e.code, "Google Sign-In failed"),
      );
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected Google Sign-In error",
        error: e,
        stackTrace: stackTrace,
      );
      await _googleSignIn.signOut().catchError(
        (err) => _logger.e("Error signing out Google on failure", error: err),
      );
      if (e is AuthException) rethrow; // Don't wrap cancellation error
      throw AuthException(
        "An unexpected error occurred during Google Sign-In.",
      );
    }
  }

  /// Updates the FCM token specifically in Firestore for backend use.
  Future<void> _updateUserFCMTokenInFirestore(String uid, String token) async {
    try {
      _logger.d("Repository: Updating FCM token in Firestore for user $uid");
      // Use a subcollection or a field on the user document based on your Firestore structure
      // Example: Updating a field on the main user document
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token, // Or maybe an array 'fcmTokens' if multiple devices
        'fcmTokenLastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge to avoid overwriting other fields
      _logger.d(
        "Repository: Firestore FCM token updated successfully for user $uid",
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Repository: Error updating FCM token in Firestore for user $uid',
        error: e,
        stackTrace: stackTrace,
      );
      // Non-fatal error, maybe retry later? Don't throw to block login/signup.
    }
  }

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    String? phoneNumber, // Pass optional fields as nullable
    String? profileImageUrl,
  }) async {
    _logger.i("Repository: Attempting Firebase signup for $email");
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.d(
        "Repository: Firebase user created: ${userCredential.user?.uid}",
      );

      // Update Firebase profile immediately after creation
      if (userCredential.user != null) {
        User firebaseUser = userCredential.user!;
        try {
          _logger.d(
            "Repository: Updating Firebase profile for ${firebaseUser.uid}",
          );
          await firebaseUser.updateDisplayName(name);
          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            await firebaseUser.updatePhotoURL(profileImageUrl);
          }
          // Phone number requires verification - handle separately if needed
        } catch (e, stackTrace) {
          _logger.w(
            "Repository: Failed to update Firebase profile after signup",
            error: e,
            stackTrace: stackTrace,
          );
          // Non-fatal, continue
        }

        // Update FCM token in Firestore
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _updateUserFCMTokenInFirestore(firebaseUser.uid, token);
        }

        // Subscribe to general topic
        await _firebaseMessaging
            .subscribeToTopic('general')
            .catchError(
              (e) =>
                  _logger.e("Failed to subscribe to topic 'general'", error: e),
            );

        // Local DB user creation should be handled by AuthViewModel listener
        // Avoid direct DB write here.
      } else {
        _logger.e("Firebase signup succeeded but UserCredential.user is null!");
        throw AuthException(
          "Signup failed: User data unavailable after successful creation.",
        );
      }

      _logger.i("Repository: Firebase signup successful for $email");
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.w(
        "Repository: Firebase signup failed for $email. Code: ${e.code}",
      );
      throw AuthException(_parseFirebaseErrorMsg(e.code, "Sign-up failed"));
    } catch (e, stackTrace) {
      _logger.e(
        "Repository: Unexpected sign-up error for $email",
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException("An unexpected error occurred during sign-up.");
    }
  }

  @override
  Future<void> logout() async {
    _logger.i("Repository: Attempting logout");
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Unsubscribe from topics on logout if needed
        await _firebaseMessaging
            .unsubscribeFromTopic('general')
            .catchError(
              (e) => _logger.e(
                "Error unsubscribing from topic 'general' on logout",
                error: e,
              ),
            );
        // Optionally clear FCM token from Firestore (or let backend handle inactive tokens)
        // await _updateUserFCMTokenInFirestore(user.uid, null); // Example: setting to null
      }
      // Sign out from Firebase (triggers AuthViewModel listener)
      await _firebaseAuth.signOut();
      _logger.d("Repository: Signed out from Firebase.");

      // Sign out from Google if previously signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        _logger.d("Repository: Signed out from Google.");
      }
      _logger.i("Repository: Logout successful.");
    } catch (e, stackTrace) {
      _logger.e("Repository: Logout error", error: e, stackTrace: stackTrace);
      throw AuthException("Logout failed: ${e.toString()}");
    }
  }

  // --- OTP Methods (Removed/Backend Responsibility) ---
  @override
  Future<void> sendEmailOTP(String email) async {
    _logger.e(
      "Repository: sendEmailOTP called on client-side. This MUST be handled by the backend for security.",
    );
    throw UnimplementedError(
      "OTP sending must be performed by a secure backend service.",
    );
    // --- REMOVED SMTP and local OTP storage logic ---
  }

  @override
  Future<bool> verifyEmailOTP(String email, String otp) async {
    _logger.e(
      "Repository: verifyEmailOTP called on client-side. This MUST be handled by the backend for security.",
    );
    throw UnimplementedError(
      "OTP verification must be performed by a secure backend service.",
    );
    // --- REMOVED local OTP verification logic ---
  }

  // --- User Data Saving (Likely Redundant) ---
  // This responsibility should primarily lie with AuthViewModel syncing based on Firebase state
  @override
  Future<void> saveUserToLocalDatabase(Map<String, dynamic> userData) async {
    _logger.w(
      "Repository: saveUserToLocalDatabase called. This is likely redundant if AuthViewModel handles local user sync.",
    );
    // If absolutely needed for some specific reason:
    // try {
    //   await _databaseHelper.upsertUser(userData);
    // } catch (e, stackTrace) {
    //   _logger.e('Repository: Error saving user explicitly to local database', error: e, stackTrace: stackTrace);
    //   throw DatabaseException('Failed to save user data locally.');
    // }
  }

  // --- Helper to Parse Firebase Errors (Consistent with AuthViewModel) ---
  String _parseFirebaseErrorMsg(String errorCode, String defaultPrefix) {
    switch (errorCode) {
      case 'user-not-found':
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
        return 'The password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return '$defaultPrefix: An unknown error occurred ($errorCode).';
    }
  }
}
