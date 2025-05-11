// TODO Implement this library.
// lib/presentation/widgets/loading_overlay.dart

import 'package:flutter/material.dart';
import 'package:mama_care/utils/app_colors.dart'; // Optional: For theme color
import 'package:mama_care/utils/text_styles.dart'; // Optional: For text styles

/// A widget that displays a semi-transparent overlay with a loading indicator
/// and an optional message. Typically used within a Stack.
class LoadingOverlay extends StatelessWidget {
  /// The message to display below the loading indicator.
  final String? message;

  /// Creates a loading overlay.
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme

    return Stack(
      children: [
        // --- Semi-Transparent Modal Barrier ---
        // Covers the entire screen behind the loading indicator area.
        // Prevents interaction with the UI underneath while loading.
        Positioned.fill(
          child: ModalBarrier(
            dismissible: false, // Prevent dismissing by tapping outside
            // Use a subtle overlay color, adjust opacity as needed
            color: Colors.black.withOpacity(0.3),
          ),
        ),

        // --- Centered Loading Box ---
        Center(
          child: Material(
            // Use Material for elevation and shape if desired
            elevation: 8.0, // Add some shadow
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
            color: theme.dialogBackgroundColor, // Use theme's dialog background
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Fit content size
                children: [
                  // --- Circular Progress Indicator ---
                  CircularProgressIndicator(
                    // Use theme's primary color or your app's primary color
                    color:
                        theme.progressIndicatorTheme.color ?? AppColors.primary,
                    strokeWidth: 4.0, // Adjust thickness
                  ),

                  // --- Optional Loading Message ---
                  if (message != null && message!.isNotEmpty) ...[
                    const SizedBox(height: 20), // Spacing
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      // Use theme's bodyMedium style or your custom style
                      style: theme.textTheme.bodyMedium ?? TextStyles.body,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
