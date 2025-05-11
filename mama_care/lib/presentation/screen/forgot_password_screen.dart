// lib/presentation/screen/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
// Add other necessary imports (ViewModel, widgets, utils)

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  // TODO: Add ForgotPasswordViewModel if needed

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetLink() {
     if (!(_formKey.currentState?.validate() ?? false)) return;
     final email = _emailController.text.trim();
     // TODO: Call ViewModel method to send reset link (e.g., using FirebaseAuth.sendPasswordResetEmail or backend call)
     print("Send password reset link for: $email");
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("If an account exists for $email, a password reset link has been sent.")),
      );
      // Optionally navigate back or show confirmation
      // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Wrap with Provider if using ViewModel
    return Scaffold(
      appBar: const MamaCareAppBar(title: "Reset Password"),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                 "Enter your email address below and we'll send you a link to reset your password.",
                 textAlign: TextAlign.center,
                 style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField( // Using standard TextFormField here, replace with CustomTextField if preferred
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                   labelText: "Email Address",
                   hintText: "Enter your registered email",
                   prefixIcon: Icon(Icons.email_outlined),
                 ),
                 validator: (value) {
                   if (value == null || value.trim().isEmpty) return 'Please enter your email';
                   final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                   if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email address';
                   return null;
                 },
              ),
              const SizedBox(height: 30),
               ElevatedButton( // Using standard ElevatedButton, replace with CustomButton if preferred
                 onPressed: _handleSendResetLink,
                 child: const Text("Send Reset Link"),
               )
            ],
          ),
        ),
      ),
    );
  }
}