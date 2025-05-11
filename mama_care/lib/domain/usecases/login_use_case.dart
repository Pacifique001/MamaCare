import 'package:injectable/injectable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mama_care/data/repositories/login_repository.dart';
import 'package:mama_care/domain/entities/user_model.dart';

@injectable
class LoginUseCase {
  final LoginRepository _loginRepository;

  LoginUseCase(this._loginRepository);

  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _loginRepository.login(email, password);
    } catch (e) {
      print("Error during login: $e");
      rethrow;
    }
  }

  Future<UserCredential?> googleLogin() async {
    try {
      return await _loginRepository.googleLogin();
    } catch (e) {
      print("Error during Google login: $e");
      rethrow;
    }
  }

  Future<void> signUp(UserModel user) async {
    try {
      await _loginRepository.signUp(
        email: user.email ?? '',
        password: user.password ?? '',
        name: user.name ?? '',
        phoneNumber: user.phoneNumber ?? '',
        profileImageUrl: user.profileImageUrl ?? '',
      );
    } catch (e) {
      print("Error during sign-up: $e");
      rethrow;
    }
  }

  Future<void> sendEmailOTP(String email) async {
    try {
      await _loginRepository.sendEmailOTP(email);
    } catch (e) {
      print("Error sending OTP: $e");
      rethrow;
    }
  }

  Future<bool> verifyEmailOTP(String email, String otp) async {
    try {
      return await _loginRepository.verifyEmailOTP(email, otp);
    } catch (e) {
      print("Error verifying OTP: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _loginRepository.logout();
    } catch (e) {
      print("Error during logout: $e");
      rethrow;
    }
  }
}