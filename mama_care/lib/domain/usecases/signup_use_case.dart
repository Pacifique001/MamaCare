import 'package:injectable/injectable.dart';
import 'package:mama_care/data/repositories/signup_repository.dart';
import 'package:mama_care/domain/entities/user_model.dart';

@injectable
class SignupUseCase {
  final SignupRepository _signupRepository;

  SignupUseCase(this._signupRepository);

  Future<void> signup(UserModel user) async {
    await _signupRepository.signup(user);
  }
} 