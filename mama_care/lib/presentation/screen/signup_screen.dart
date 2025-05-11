import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/view/signup_view.dart';
import 'package:mama_care/presentation/viewmodel/signup_viewmodel.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:logger/logger.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupViewModel(
        locator<AuthViewModel>(),
         locator<Logger>(),
      ),
      child: const SignUpView(),
    );
  }
}