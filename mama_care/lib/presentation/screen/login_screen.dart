import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/view/login_view.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
//import 'package:mama_care/domain/usecases/login_use_case.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:mama_care/domain/repositories/firebase_auth_repository.dart';
import 'package:mama_care/injection.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => AuthViewModel(
            //locator<LoginUseCase>(),
            locator<DatabaseHelper>(),
            locator<FirebaseMessaging>(),
            locator<FirebaseAuth>(),
            locator<GoogleSignIn>(),
            locator<Logger>(),
            locator<FirebaseFirestore>(),
            locator<Uuid>(),

            //locator<FirebaseAuthRepository>(),
          ),
      child: const Scaffold(body: LoginView()),
    );
  }
}
