// lib/presentation/screen/otp_input_screen.dart

import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart'; // Assuming locator for Logger
// import 'package:mama_care/navigation/router.dart'; // Navigation handled by AuthViewModel listener now
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // Import AuthViewModel
import 'package:mama_care/presentation/widgets/custom_button.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart'; // Assuming shared AppBar
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:pin_code_fields/pin_code_fields.dart'; // Using package for OTP fields
import 'package:provider/provider.dart'; // Import Provider
import 'package:sizer/sizer.dart'; // Assuming Sizer is used in TextStyles

class OtpInputScreen extends StatefulWidget {
  // Only requires the phone number for display purposes.
  // The verification process state (verificationId, etc.) is managed by AuthViewModel.
  final String phoneNumber;

  const OtpInputScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpInputScreen> createState() => _OtpInputScreenState();
}

class _OtpInputScreenState extends State<OtpInputScreen> {
  final _otpController = TextEditingController();
  StreamController<ErrorAnimationType>? _errorController;
  final Logger _logger = locator<Logger>();

  // Resend Timer logic
  Timer? _resendTimer;
  int _resendCooldown = 60; // Cooldown duration in seconds
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>.broadcast();
    // Log the phone number this screen is intended for.
    // The verification process should have already been initiated before navigating here.
    _logger.i("OtpInputScreen initialized for ${widget.phoneNumber}");
    // Start the cooldown timer immediately when the screen loads
    _startResendTimer();

    // Add a listener to clear the OTP field if an error occurs from the ViewModel
    // This ensures if verification fails (e.g., invalid code), the field clears.
    // We need to use context.read inside initState callbacks or addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
           context.read<AuthViewModel>().addListener(_handleViewModelErrors);
       }
    });
  }

  @override
  void dispose() {
    // Remove the listener when the widget is disposed
     if (mounted) {
        context.read<AuthViewModel>().removeListener(_handleViewModelErrors);
     }
    _otpController.dispose();
    _errorController?.close();
    _resendTimer?.cancel();
    super.dispose();
  }

  // Listener to react to errors set in the ViewModel
  void _handleViewModelErrors() {
     final authViewModel = context.read<AuthViewModel>();
      // Check if an error exists and the controller has text
      if (authViewModel.errorMessage != null && _otpController.text.isNotEmpty && mounted) {
          _logger.d("ViewModel error detected, clearing OTP field.");
          _otpController.clear();
          _errorController?.add(ErrorAnimationType.shake);
      }
  }


  /// Starts or restarts the resend cooldown timer.
  void _startResendTimer() {
    _canResend = false; // Disable resend initially
    _resendCooldown = 60; // Reset duration
    _resendTimer?.cancel(); // Cancel existing timer

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 0) {
        // When cooldown finishes, enable resend and stop timer
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        // Decrement timer and update UI
        setState(() => _resendCooldown--);
      }
    });
    // Update UI immediately if timer starts (e.g., to show initial cooldown)
    if (mounted) setState(() {});
  }

  /// Verifies the entered OTP code using the AuthViewModel.
  Future<void> _verifyOtp() async {
    FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
    final enteredOtp = _otpController.text.trim();

    // Validate OTP length
    if (enteredOtp.length != 6) {
      _errorController?.add(ErrorAnimationType.shake); // Trigger error animation
      _showErrorSnackbar("Please enter the complete 6-digit code.");
      return;
    }

    _logger.i("Verifying SMS code: $enteredOtp for Phone: ${widget.phoneNumber}");
    // Use context.read for one-time action
    final authViewModel = context.read<AuthViewModel>();

    // Clear previous errors before attempting verification
    authViewModel.clearError();

    // Call ViewModel to verify the code and sign in.
    // The ViewModel internally uses its stored _verificationId.
    final result = await authViewModel.verifySmsCodeAndSignIn(enteredOtp);

    if (!mounted) return; // Check if widget is still in the tree

    // The ViewModel's authStateChanges listener handles successful navigation automatically.
    // We only need to handle explicit errors returned by the verifySmsCodeAndSignIn method itself.
    if (result['status'] == 'error') {
        _logger.w("SMS code verification failed: ${result['message']}");
        // The _handleViewModelErrors listener might also catch this, but direct feedback is good too.
        _errorController?.add(ErrorAnimationType.shake); // Shake animation on error
        // Don't necessarily clear field here, let listener handle it based on ViewModel state change
        _showErrorSnackbar(result['message'] ?? "Invalid or expired code.");
    }
    // On success, no explicit navigation needed here; AuthViewModel listener drives it.
    // If successful, the auth state changes, _onAuthStateChanged runs, potentially navigates.
  }

   /// Requests the AuthViewModel to resend the OTP code using its internal state.
   Future<void> _resendOtp() async {
     if (!_canResend) return; // Only allow resend when timer is up
     FocusManager.instance.primaryFocus?.unfocus();
     _logger.i("Requesting OTP resend for phone stored in ViewModel: ${widget.phoneNumber}"); // Log displayed number
     final authViewModel = context.read<AuthViewModel>();

     // Clear previous errors before attempting resend
     authViewModel.clearError();

     // Call ViewModel method to trigger resend. ViewModel uses its internally stored
     // _pendingPhoneNumber and _forceResendingToken.
     final result = await authViewModel.resendOtpCode(); // No argument needed

     if (!mounted) return;

     // Check the result of *initiating* the resend request
     if (result['status'] == 'error') {
         // Error *starting* the resend (e.g., no pending number in VM)
         _logger.w("Failed to initiate OTP resend: ${result['message']}");
         _showErrorSnackbar(result['message'] ?? "Failed to request code resend.");
         // Optionally restart timer even on initiation failure to prevent spam
         _startResendTimer();
     } else {
          // Assume initiation was successful (status is likely 'pending')
          // The actual success/failure of SMS sending will be handled by callbacks in ViewModel,
          // which might set authViewModel.errorMessage if needed.
          _logger.i("OTP resend request initiated successfully.");
          _showSuccessSnackbar("Requesting a new code for ${widget.phoneNumber}.");
          _startResendTimer(); // Restart the cooldown timer
     }
   }

  // --- Snackbar Helpers ---
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(16.0), // Add margin for floating
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
   if (!mounted) return;
   ScaffoldMessenger.of(context).removeCurrentSnackBar();
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text(message),
       backgroundColor: Colors.green,
       behavior: SnackBarBehavior.floating,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
       margin: const EdgeInsets.all(16.0),
     ),
   );
 }

  @override
  Widget build(BuildContext context) {
     // Watch AuthViewModel for isLoading state and errorMessage changes
     final authViewModel = context.watch<AuthViewModel>();

    // If an error message appears in the ViewModel, show it in a snackbar
    // (This handles errors set asynchronously by callbacks like verificationFailed)
    // Use a listener in build might cause multiple snackbars, handle via listener in initState instead.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (authViewModel.errorMessage != null && mounted) {
    //      _showErrorSnackbar(authViewModel.errorMessage!);
    //      // Consider clearing the error in VM after showing it? Or let user action clear it.
    //      // authViewModel.clearError();
    //   }
    // });


    return Scaffold(
      appBar: const MamaCareAppBar(title: "Verify Phone Number"),
      body: Stack(
        children: [
          SafeArea( // Ensure content is within safe area
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Header Text
                    Text("Enter Verification Code", style: TextStyles.headline2, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Enter the 6-digit code sent via SMS to\n${widget.phoneNumber}", // Display target phone number
                        style: TextStyles.bodyGrey,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // OTP Input Field using pin_code_fields package
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0), // Adjust padding for OTP field
                      child: PinCodeTextField(
                        appContext: context,
                        length: 6, // Standard OTP length
                        obscureText: false,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box, // Or .underline, .circle
                          borderRadius: BorderRadius.circular(10),
                          fieldHeight: 55,
                          fieldWidth: 45, // Adjust width based on screen size if needed
                          activeFillColor: Colors.white, // Background when active/filled
                          inactiveFillColor: Colors.grey.shade100, // Background when inactive
                          selectedFillColor: Colors.white, // Background when selected
                          activeColor: AppColors.primary, // Border color when active
                          inactiveColor: Colors.grey.shade300, // Border color when inactive
                          selectedColor: AppColors.primaryLight, // Border color when selected
                           borderWidth: 1,
                        ),
                        animationDuration: const Duration(milliseconds: 300),
                        backgroundColor: Colors.transparent, // Let parent handle background
                        enableActiveFill: true, // Enable fill colors
                        errorAnimationController: _errorController, // Controller for shake animation
                        controller: _otpController, // Controller for text value
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Allow only numbers
                        onCompleted: (v) {
                          // Auto-submit when 6 digits are entered, if not loading
                          if (!authViewModel.isLoading) {
                             _logger.d("OTP field completed");
                             _verifyOtp();
                          }
                        },
                        onChanged: (value) {
                          // Clear ViewModel error state when user starts typing
                          if (authViewModel.errorMessage != null) {
                             authViewModel.clearError();
                          }
                        },
                        beforeTextPaste: (text) {
                           _logger.d("Attempting to paste OTP: $text");
                          // Validate pasted text (must be 6 digits)
                           return text != null && text.length == 6 && int.tryParse(text) != null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    SizedBox(
                      width: double.infinity, // Make button wide
                      child: CustomButton(
                        label: "Verify Code",
                        // Disable button while loading
                        onPressed: authViewModel.isLoading ? null : _verifyOtp,
                        backgroundColor: AppColors.primary,
                        textStyle: TextStyles.buttonText,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Resend OTP Link/Button
                    Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                          Text("Didn't receive the code?", style: TextStyles.bodyGrey),
                          TextButton(
                            // Disable button during loading and during cooldown
                            onPressed: (_canResend && !authViewModel.isLoading) ? _resendOtp : null,
                            child: Text(
                               _canResend ? "Resend Code" : "Resend in $_resendCooldown s",
                               style: _canResend
                                  ? TextStyles.linkText // Active link style
                                  : TextStyles.bodyGrey.copyWith(fontSize: 13.sp, color: Colors.grey.shade500), // Disabled/cooldown style
                            ),
                          ),
                       ],
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
            ),
          ),
          // Loading Overlay (Uses ViewModel state)
          if (authViewModel.isLoading)
             const Opacity( opacity: 0.6, child: ModalBarrier(dismissible: false, color: Colors.black) ),
          if (authViewModel.isLoading)
             const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}