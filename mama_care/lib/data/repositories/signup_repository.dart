import 'package:injectable/injectable.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/domain/entities/user_model.dart';

@injectable
class SignupRepository {
  final DatabaseHelper _databaseHelper;

  SignupRepository(this._databaseHelper);

  Future<void> signup(UserModel user) async {
    await _databaseHelper.insert('users', user.toJson());
  }
} 