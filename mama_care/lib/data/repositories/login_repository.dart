import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@factoryMethod
abstract class LoginRepository {
  // Login with email and password
  Future<UserCredential?> login(String email, String password);

  // Signup with email, password, name, phoneNumber, and profileImageUrl
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String profileImageUrl,
  });

  // Send OTP to verify email
  Future<void> sendEmailOTP(String email);

  // Verify OTP for email
  Future<bool> verifyEmailOTP(String email, String otp);

  // Google login
  Future<UserCredential?> googleLogin();

  // Logout
  Future<void> logout();

  // Save user data to local database
  Future<void> saveUserToLocalDatabase(Map<String, dynamic> userData);
}