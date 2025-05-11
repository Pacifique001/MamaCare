// lib/presentation/screen/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/view/profile_view.dart';
import 'package:mama_care/presentation/viewmodel/profile_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Import AuthViewModel
import 'package:mama_care/injection.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MultiProvider to provide both ViewModels
    return MultiProvider(
      providers: [
        // Provide ProfileViewModel (depends on AuthViewModel)
        ChangeNotifierProvider<ProfileViewModel>(
          create: (_) => ProfileViewModel(
            locator(), // ProfileUseCase
            locator(), // AuthViewModel (already a singleton)
            locator(), // Logger
          ),
        ),
        // Provide AuthViewModel (read the existing singleton instance)
        // This ensures both ProfileVM and ProfileView access the SAME AuthVM instance.
        ChangeNotifierProvider.value(
           value: locator<AuthViewModel>(),
        ),
      ],
      child:  ProfileView(), // Child is the View
    );
  }
}