import 'package:flutter/material.dart';
// Import for SVG if using SVG logo
import 'package:mama_care/utils/text_styles.dart'; // Assuming styles defined here
import 'package:mama_care/utils/app_colors.dart'; // Assuming colors defined here

class GoogleAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed; // *** CHANGED: Made onPressed nullable ***
  final bool isLoading; // Optional: To show loading indicator internally
  // Removed redundant color/style parameters, prefer Theme or defaults

  const GoogleAuthButton({
    super.key,
    required this.label,
    required this.onPressed, // Still required, but type is nullable
    this.isLoading = false, // Default to not loading
    // Removed borderColor, textColor, borderRadius, padding, elevation, iconSize, textStyle parameters
  });

  @override
  Widget build(BuildContext context) {
    // Define styles locally or get from Theme/TextStyles for consistency
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor:
          AppColors.textDark, // Text and icon color (ensure contrast)
      backgroundColor: Colors.white, // Standard Google button background
      disabledBackgroundColor: Colors.grey.shade200, // Background when disabled
      disabledForegroundColor:
          Colors.grey.shade500, // Text/icon color when disabled
      side: BorderSide(
        color: Colors.grey.shade300,
        width: 1.0,
      ), // Subtle border
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ), // Adjust padding
      minimumSize: const Size.fromHeight(48), // Consistent minimum height
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Consistent border radius
      elevation: 1, // Slight elevation
    );

    return OutlinedButton.icon(
      icon:
          isLoading
              ? Container(
                // Show spinner when loading
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textGrey,
                ), // Use neutral color for spinner
              )
              : Image.asset(
                // Assuming Google logo is an SVG asset
                'assets/images/google_icon.png', // <<<=== ADJUST PATH TO YOUR GOOGLE LOGO
                height: 20, // Consistent icon size
                width: 20,
              ),
      label: Text(
        label,
        // Use a defined text style for consistency
        style: TextStyles.bodyBold.copyWith(
          color: AppColors.textDark,
        ), // Example style
      ),
      onPressed:
          isLoading
              ? null
              : onPressed, // Pass nullable onPressed, disable based on isLoading
      style: buttonStyle, // Apply the defined style
    );
  }
}
