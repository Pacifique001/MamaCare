// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:mama_care/domain/entities/user_model.dart';
//import 'package:injectable/injectable.dart';

@factoryMethod
abstract class UserRepository {
  Future<UserModel> getUserById(String patientId);
}
