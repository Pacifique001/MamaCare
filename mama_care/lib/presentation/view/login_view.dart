// lib/presentation/view/login_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/presentation/widgets/custom_button.dart';
import 'package:mama_care/presentation/widgets/custom_text_field.dart';
import 'package:mama_care/presentation/widgets/google_auth_button.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  final Logger _logger = locator<Logger>();

  @override
  void initState() {
    super.initState();
    // Pre-fill email if saved previously (optional)
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final savedEmail = await context.read<AuthViewModel>().getSavedEmail();
    if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
      setState(() {
        _emailController.text = savedEmail;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react ONLY to isLoading state for the overlay/buttons
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Scaffold(
          resizeToAvoidBottomInset:
              true, // Prevent overflow when keyboard appears
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(
              children: [
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
                      child: _buildLoginForm(context, authViewModel),
                    ),
                  ),
                ),
                // Loading Overlay based on ViewModel state
                if (authViewModel.isLoading)
                  const Opacity(
                    opacity: 0.7,
                    child: ModalBarrier(
                      color: Colors.black,
                      dismissible: false,
                    ),
                  ),
                if (authViewModel.isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Main Login Form Structure
  Widget _buildLoginForm(BuildContext context, AuthViewModel authViewModel) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Logo/Header Section ---
          Container(
            margin: const EdgeInsets.only(bottom: 40),
            child: Center(
              child: Image.asset(
                AssetsHelper.stretching,
                height: 100,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
              ),
            ),
          ),
          Text(
            'Welcome Back!',
            style: TextStyles.headline1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Login to access your account',
            style: TextStyles.bodyGrey,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // --- Input Fields Container ---
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEmailField(context),
                const SizedBox(height: 16),
                _buildPasswordField(context),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyles.smallPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Action Buttons Container ---
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLoginButton(authViewModel),
                const SizedBox(height: 16),
                _buildSignupLink(context),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Social/Alternative Login Container ---
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: Divider(endIndent: 10)),
                    Text("OR", style: TextStyles.bodyGrey),
                    const Expanded(child: Divider(indent: 10)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGoogleLoginButton(authViewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Field Builder Methods ---
  Widget _buildFormField({
    required BuildContext context,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyles.textFieldLabel),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return _buildFormField(
      context: context,
      label: "Email Address",
      child: CustomTextField(
        controller: _emailController,
        hint: "Enter your email",
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: _validateEmail,
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: AppColors.primaryLight,
        ),
        autofillHints: const [AutofillHints.email, AutofillHints.username],
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    return _buildFormField(
      context: context,
      label: "Password",
      child: CustomTextField(
        controller: _passwordController,
        hint: "Enter your password",
        obscureText: _obscureText,
        validator: _validatePassword,
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.primaryLight,
        ),
        autofillHints: const [AutofillHints.password],
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) {
          if (!authViewModel.isLoading) {
            _handleLogin(authViewModel);
          }
        },
        suffixIcon: InkWell(
          onTap: () => setState(() => _obscureText = !_obscureText),
          child: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.primaryLight,
          ),
        ),
      ),
    );
  }

  // --- Button/Link Builder Methods ---
  Widget _buildLoginButton(AuthViewModel authViewModel) {
    return CustomButton(
      label: "Login",
      onPressed:
          authViewModel.isLoading ? null : () => _handleLogin(authViewModel),
      backgroundColor: AppColors.primary,
      textStyle: TextStyles.buttonText,
    );
  }

  Widget _buildSignupLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?", style: TextStyles.bodyGrey),
        TextButton(
          onPressed:
              () => Navigator.pushReplacementNamed(
                context,
                NavigationRoutes.signup,
              ),
          child: Text("Sign Up", style: TextStyles.linkText),
        ),
      ],
    );
  }

  Widget _buildGoogleLoginButton(AuthViewModel authViewModel) {
    return GoogleAuthButton(
      label: "Continue with Google",
      onPressed:
          authViewModel.isLoading
              ? null
              : () => _handleGoogleLogin(authViewModel),
      isLoading: authViewModel.isLoading,
    );
  } // Pass isLoading to Google button too

  // --- Validation Logic ---
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = value.contains(RegExp(r'[0-9]'));
    if (!hasLetter || !hasNumber) return 'Password needs letters and numbers';
    return null;
  }

  Widget _buildPhoneLoginButton(AuthViewModel authViewModel) {
    return CustomButton(
      label: "Continue with Phone Number",
      onPressed: authViewModel.isLoading ? null : _handlePhoneLogin,
      backgroundColor: Colors.white,
      textStyle: TextStyles.buttonText.copyWith(color: AppColors.primary),
      borderColor: AppColors.primary,
      borderWidth: 1,
      icon: const Icon(Icons.phone, color: AppColors.primary),
    );
  }

  // --- Action Handlers ---
  Future<void> _handleLogin(AuthViewModel authViewModel) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Save email for next time *before* attempting login
    await authViewModel.saveEmail(_emailController.text.trim());

    final result = await authViewModel.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (result['status'] == 'success') {
      _logger.i("Login successful. User role: ${result['role']}");
      _navigateToDashboardBasedOnRole(result['role'] as String?);
    } else {
      _showErrorSnackbar(result['message'] ?? 'Login failed.');
    }
  }

  void _handlePhoneLogin() {
    _logger.i("Phone login action triggered");
    Navigator.pushNamed(context, NavigationRoutes.phoneAuth);
  }

  Future<void> _handleGoogleLogin(AuthViewModel authViewModel) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await authViewModel.signInWithGoogle();
    if (!mounted) return;
    if (result['status'] == 'success') {
      _logger.i("Google Sign-In successful. User role: ${result['role']}");
      _navigateToDashboardBasedOnRole(result['role'] as String?);
    } else if (result['status'] != 'cancelled') {
      _showErrorSnackbar(result['message'] ?? 'Google sign-in failed.');
    }
  }

  void _handleForgotPassword() {
    _logger.i("Forgot Password action triggered.");
    // Ensure NavigationRoutes.forgotPassword exists and is handled in RouteGenerator
    Navigator.pushNamed(context, NavigationRoutes.forgotPassword);
  }

  // --- Navigation & Feedback ---
  void _navigateToDashboardBasedOnRole(String? roleString) {
    final role = userRoleFromString(roleString);
    String targetRoute;
    switch (role) {
      case UserRole.patient:
        targetRoute = NavigationRoutes.mainScreen;
        break;
      case UserRole.nurse:
        targetRoute = NavigationRoutes.nurseDashboard;
        break; // CREATE ROUTE
      case UserRole.doctor:
        targetRoute = NavigationRoutes.doctorDashboard;
        break; // CREATE ROUTE
      case UserRole.admin:
        targetRoute = NavigationRoutes.adminDashboard;
        break; // CREATE ROUTE
      case UserRole.unknown:
      default:
        _logger.e("Unknown/unhandled role after login: $role");
        _showErrorSnackbar(
          "Login successful, but couldn't determine dashboard access.",
        );
        targetRoute = NavigationRoutes.mainScreen;
        break;
    }
    _logger.i("Navigating to $targetRoute based on role $role");
    Navigator.pushReplacementNamed(
      context,
      targetRoute,
    ); // Clear login screen from stack
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
