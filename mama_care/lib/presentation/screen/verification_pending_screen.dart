// lib/presentation/screen/verification_pending_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/presentation/widgets/custom_button.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart';
import 'package:url_launcher/url_launcher.dart';

class VerificationPendingScreen extends StatefulWidget {
  final String email;
  final String? phoneNumber;
  final String? userId;

  const VerificationPendingScreen({
    super.key,
    required this.email,
    this.phoneNumber,
    this.userId,
  });

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  static const int _verificationCheckIntervalSeconds = 5;
  static const int _resendCooldownSeconds = 60;
  static const int _redirectDelaySeconds = 2;

  final Logger _logger = locator<Logger>();
  Timer? _verificationCheckTimer;
  Timer? _cooldownTimer;
  bool _isCheckingVerification = false;
  bool _canResendEmail = true;
  int _resendCooldown = 0;
  bool _openedEmailApp = false;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    // Check every 5 seconds if the email has been verified
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: _verificationCheckIntervalSeconds),
      (_) => _checkEmailVerification(),
    );

    // Also check immediately
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final result = await authViewModel.checkEmailVerification();

      if (result['status'] == 'verified') {
        _verificationCheckTimer?.cancel();

        if (!mounted) return;

        _showSuccessAndRedirect();
      } else if (_openedEmailApp && !mounted) {
        // If user opened email app and then returned, check immediately
        _openedEmailApp = false;
        _checkEmailVerification();
      }
    } catch (e) {
      _logger.w('Error checking email verification: $e');
      _handleVerificationError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  void _showSuccessAndRedirect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified successfully! Redirecting to login.'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to login after a short delay
    Future.delayed(const Duration(seconds: _redirectDelaySeconds), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        NavigationRoutes.login,
        (route) => false,
      );
    });
  }

  void _handleVerificationError(String error) {
    // Show error only if it's a substantial error (not just "not verified yet")
    if (!mounted) return;

    if (error.contains('network') ||
        error.contains('connection') ||
        error.contains('timeout')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check verification status: $error'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _startResendCooldown() {
    setState(() {
      _canResendEmail = false;
      _resendCooldown = _resendCooldownSeconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _openEmailApp() async {
    _logger.i("Attempting to open email app.");
    final Uri emailAppUri = Uri(scheme: 'mailto');

    try {
      if (await canLaunchUrl(emailAppUri)) {
        _openedEmailApp = true;
        await launchUrl(emailAppUri);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Check your inbox for the verification link, then return here.",
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open email app."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _logger.e("Error opening email app: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open email app: $e"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _resendVerificationEmail(AuthViewModel authViewModel) async {
    _logger.i("Resend verification email requested.");
    final result = await authViewModel.resendVerificationEmail();

    if (!mounted) return;

    if (result['status'] == 'success') {
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _manuallyCheckVerification() {
    _checkEmailVerification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Checking verification status..."),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _navigateToPhoneVerification() {
    _logger.i(
      "Navigating to phone verification flow for ${widget.phoneNumber}",
    );
    Navigator.pushNamed(
      context,
      NavigationRoutes.phoneAuth,
      arguments: {
        'phoneNumber': widget.phoneNumber,
        'userId': widget.userId,
        'email': widget.email,
      },
    );
  }

  void _navigateToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      NavigationRoutes.login,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: const MamaCareAppBar(
        title: "Verify Your Account",
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderSection(),
                    _buildErrorMessage(authViewModel),
                    _buildStatusIndicator(),

                    const SizedBox(height: 20),
                    _buildOpenEmailButton(authViewModel),
                    const SizedBox(height: 15),
                    _buildResendEmailButton(authViewModel),
                    _buildVerifyNowButton(authViewModel),

                    if (widget.phoneNumber != null &&
                        widget.phoneNumber!.isNotEmpty)
                      _buildPhoneVerificationSection(authViewModel),

                    const SizedBox(height: 30),
                    _buildLoginRedirectButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Loading Overlay
            if (authViewModel.isLoading)
              const Opacity(
                opacity: 0.7,
                child: ModalBarrier(color: Colors.black, dismissible: false),
              ),
            if (authViewModel.isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: AppColors.primary,
          semanticLabel: "Email verification icon",
        ),
        const SizedBox(height: 20),
        Text(
          "Verification Required",
          style: TextStyles.headline1,
          textAlign: TextAlign.center,
          semanticsLabel: "Verification Required heading",
        ),
        const SizedBox(height: 15),
        Text(
          "We've sent a verification link to your email:",
          style: TextStyles.body,
          textAlign: TextAlign.center,
        ),
        Text(
          widget.email,
          style: TextStyles.bodyBold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "Please click the link in the email to activate your account.",
          style: TextStyles.bodyGrey,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(AuthViewModel authViewModel) {
    if (authViewModel.errorMessage?.isNotEmpty != true) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        authViewModel.errorMessage!,
        style: TextStyle(color: Colors.red.shade800),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color:
              _isCheckingVerification
                  ? Colors.blue.shade50
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isCheckingVerification)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary,
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _isCheckingVerification
                    ? "Checking verification status..."
                    : "We'll check automatically when you verify",
                style: TextStyles.smallGrey,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenEmailButton(AuthViewModel authViewModel) {
    return CustomButton(
      label: "Open Email App",
      icon: const Icon(
        Icons.outgoing_mail,
        color: AppColors.textDark,
        size: 20,
      ),
      backgroundColor: AppColors.accent,
      textStyle: TextStyles.buttonText.copyWith(color: AppColors.textDark),
      onPressed: authViewModel.isLoading ? null : _openEmailApp,
    );
  }

  Widget _buildResendEmailButton(AuthViewModel authViewModel) {
    return TextButton(
      onPressed:
          (authViewModel.isLoading || !_canResendEmail)
              ? null
              : () => _resendVerificationEmail(authViewModel),
      child: Text(
        _canResendEmail
            ? "Resend Verification Email"
            : "Resend Available in $_resendCooldown seconds",
        style: TextStyles.linkText.copyWith(
          color: _canResendEmail ? null : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildVerifyNowButton(AuthViewModel authViewModel) {
    return TextButton(
      onPressed:
          (authViewModel.isLoading || _isCheckingVerification)
              ? null
              : _manuallyCheckVerification,
      child: Text(
        "I've Clicked the Link - Check Now",
        style: TextStyles.linkText,
      ),
    );
  }

  Widget _buildPhoneVerificationSection(AuthViewModel authViewModel) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(endIndent: 10)),
            Text("OR", style: TextStyles.bodyGrey),
            const Expanded(child: Divider(indent: 10)),
          ],
        ),
        const SizedBox(height: 20),
        CustomButton(
          label: "Verify via Phone Number",
          icon: const Icon(Icons.phone_android, color: Colors.white, size: 20),
          backgroundColor: AppColors.secondary,
          textStyle: TextStyles.buttonText,
          onPressed:
              authViewModel.isLoading ? null : _navigateToPhoneVerification,
        ),
      ],
    );
  }

  Widget _buildLoginRedirectButton() {
    return TextButton(
      onPressed: _navigateToLogin,
      child: Text(
        "I've already verified / Go to Login",
        style: TextStyles.bodyGrey,
      ),
    );
  }
}
