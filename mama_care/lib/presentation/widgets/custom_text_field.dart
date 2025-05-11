import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:mama_care/utils/app_colors.dart'; // Assuming AppColors for defaults

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon; // Added
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final String? labelText;
  // Theme-based colors (less direct parameters needed)
  // final Color? borderColor;
  // final Color? focusedBorderColor;
  // final Color? errorBorderColor;
  // final Color? hintColor;
  // final Color? textColor;
  final double borderRadius;
  final List<TextInputFormatter>? inputFormatters; // Added
  final Iterable<String>? autofillHints; // Added
  final int? maxLines; // Added (default is 1)
  final int minLines; // Added
  final TextCapitalization textCapitalization; // Added
  final FocusNode? focusNode; // Added
  final TextStyle? errorStyle; // Added

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.labelText,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon, // Added
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.contentPadding,
    this.borderRadius = 12.0, // Adjusted default radius slightly
    this.inputFormatters, // Added
    this.autofillHints, // Added
    this.maxLines = 1, // Default to single line
    this.minLines = 1, // Default to single line
    this.textCapitalization = TextCapitalization.none, // Default capitalization
    this.focusNode, // Added
    this.errorStyle, // Added
    // Removed direct color parameters, rely on theme more
  });

  @override
  Widget build(BuildContext context) {
    // Get theme data for styling
    final theme = Theme.of(context);
    final colors = theme.colorScheme; // Access ColorScheme
    final inputTheme =
        theme.inputDecorationTheme; // Access InputDecorationTheme

    // Define border styles using theme or defaults
    final defaultBorderSide = BorderSide(
      color: colors.onSurface.withOpacity(0.3),
    ); // Default border
    final errorBorderSide = BorderSide(color: colors.error); // Error border
    final focusedBorderSide = BorderSide(
      color: AppColors.primary,
      width: 1.5,
    ); // Focused border (using AppColors example)

    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: inputTheme.enabledBorder?.borderSide ?? defaultBorderSide,
    );
    final enabledBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: inputTheme.enabledBorder?.borderSide ?? defaultBorderSide,
    );
    final focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: inputTheme.focusedBorder?.borderSide ?? focusedBorderSide,
    );
    final errorBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: inputTheme.errorBorder?.borderSide ?? errorBorderSide,
    );
    final focusedErrorBorderStyle = OutlineInputBorder(
      // Also style focused error state
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide:
          inputTheme.focusedErrorBorder?.borderSide ??
          errorBorderSide.copyWith(width: 1.5),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      maxLines: obscureText ? 1 : maxLines, // Force single line for passwords
      minLines: obscureText ? 1 : minLines,
      textCapitalization: textCapitalization,

      style:
          inputTheme.labelStyle ??
          theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface, // Use theme text color
          ),
      decoration: InputDecoration(
        // Icons
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        labelText: labelText,
        // Hint
        hintText: hint,
        hintStyle:
            inputTheme.hintStyle ??
            theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.5), // Use theme hint color
            ),
        // Padding
        contentPadding:
            contentPadding ??
            inputTheme.contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ), // More control
        // Borders
        border: inputTheme.border ?? borderStyle, // Prefer theme's definition
        enabledBorder: enabledBorderStyle,
        focusedBorder: focusedBorderStyle,
        errorBorder: errorBorderStyle,
        focusedErrorBorder: focusedErrorBorderStyle, // Add focused error border
        disabledBorder: enabledBorderStyle.copyWith(
          // Style for disabled state
          borderSide: BorderSide(color: colors.onSurface.withOpacity(0.2)),
        ),
        // Fill & Background (Optional, depends on design)
        filled:
            inputTheme.filled ?? false, // Check if theme wants filled fields
        fillColor:
            inputTheme.fillColor ??
            colors.surface.withOpacity(0.05), // Use theme fill color
        // Error style
        errorStyle:
            errorStyle ??
            inputTheme.errorStyle ??
            TextStyle(color: colors.error, fontSize: 12),
      ),
    );
  }
}
