// lib/presentation/screen/phone_auth_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/presentation/widgets/custom_button.dart'; // Assuming these exist
import 'package:mama_care/presentation/widgets/custom_text_field.dart'; // Assuming these exist
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart'; // Assuming these exist
import 'package:mama_care/presentation/view/otp_verification_view.dart'; // Assuming this is your OTP screen
import 'package:mama_care/utils/app_colors.dart'; // Assuming these exist
import 'package:mama_care/utils/text_styles.dart'; // Assuming these exist
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart'; // Assuming locator setup is correct

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final Logger _logger = locator<Logger>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // --- Helper to show snackbar errors ---
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

  // --- Function to initiate OTP sending ---
  Future<void> _initiateOtpSend(AuthViewModel authViewModel) async {
    // 1. Validate Form
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 2. Unfocus Keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    // 3. Get Phone Number
    final phoneNumber = _phoneController.text.trim();
    _logger.i("Initiating phone verification for: $phoneNumber");

    // 4. Call ViewModel Method (Using the correct name: sendOtpToPhone)
    final result = await authViewModel.sendOtpToPhone(phoneNumber);

    // 5. Handle Result (Check mount status AFTER await)
    if (!mounted) return;

    // --- Interpret the result ---
    final status = result['status'];
    final message = result['message'] as String?;

    if (status == 'code_sent') {
      // --- Success: Navigate to OTP screen ---
      _logger.i(
        "Phone verification initiated (code sent), navigating to OTP screen",
      );
      authViewModel.clearError(); // Clear any previous errors before navigating
      Navigator.push(
        context,
        MaterialPageRoute(
          // Pass phone number for display/resend reference if needed
          builder: (context) => OtpInputScreen(phoneNumber: phoneNumber),
        ),
      );
    } else if (status == 'pending_auth_state') {
      // --- Auto-verification Completed (Rare but possible) ---
      _logger.i("Auto-verification complete, awaiting final auth state...");
      // Optionally show info message or let listener handle navigation
    } else if (status == 'error') {
      // --- Error Sending OTP ---
      _logger.w("Failed to start phone verification: $message");
      _showErrorSnackbar(message ?? 'Failed to send verification code.');
    } else {
      // --- Unexpected status ---
      _logger.e("Unexpected status from sendOtpToPhone: $status");
      _showErrorSnackbar('An unexpected error occurred.');
    }
  }

  // --- Phone Number Validation ---
  String? _validatePhone(String? value) {
    // Get ViewModel instance to access validation logic
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    // Use the ViewModel's validation logic
    if (!viewModel.validatePhoneNumber(value.trim())) {
      return 'Use E.164 format (e.g., +11234567890)';
    }
    return null; // Valid
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react to ViewModel changes (isLoading, errorMessage)
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Scaffold(
          appBar: const MamaCareAppBar(
            title: "Phone Authentication",
          ), // Assuming this exists
          body: SafeArea(
            child: Stack(
              // Stack for loading overlay
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center content vertically
                      children: [
                        const Spacer(flex: 1), // Add space at top
                        Text(
                          "Enter Your Phone Number",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ), // Use theme
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "We'll send a verification code to authenticate your account.",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ), // Use theme
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Phone Input Field
                        CustomTextField(
                          // Assuming this exists
                          controller: _phoneController,
                          hint: "e.g., +25078 or +25079", // Example format
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.phone_android,
                            color: AppColors.primaryLight,
                          ),
                          validator: _validatePhone, // Use updated validation
                          onFieldSubmitted: (_) {
                            // Allow submitting form via keyboard
                            if (!authViewModel.isLoading) {
                              _initiateOtpSend(authViewModel);
                            }
                          },
                        ),
                        const SizedBox(height: 32),

                        // Continue Button
                        CustomButton(
                          // Assuming this exists
                          label: "Send Verification Code",
                          // Disable button when loading
                          onPressed:
                              authViewModel.isLoading
                                  ? null
                                  : () => _initiateOtpSend(authViewModel),
                          backgroundColor: AppColors.primary,
                          textStyle:
                              TextStyles.buttonText, // Assuming this exists
                        ),
                        const Spacer(flex: 2), // Add space at bottom
                      ],
                    ),
                  ),
                ),

                // Loading Overlay (Simpler implementation)
                if (authViewModel.isLoading)
                  Container(
                    color: Colors.black.withOpacity(
                      0.5,
                    ), // Semi-transparent overlay
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
