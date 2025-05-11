import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Future<void> Function()? onAsyncPressed; // Changed from AsyncCallback
  final Color? color;
  final Color? textColor;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final TextStyle? textStyle;
  final bool isLoading;
  final double? loadingIndicatorSize;
  final double? loadingIndicatorStrokeWidth;
  final Color? borderColor;
  final double? borderWidth;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.onAsyncPressed,
    this.color,
    this.textColor,
    this.borderRadius = 8.0,
    this.padding,
    this.elevation,
    this.textStyle,
    this.isLoading = false,
    this.loadingIndicatorSize = 20,
    this.loadingIndicatorStrokeWidth = 2,
    this.borderColor,
    this.borderWidth,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _getOnPressed(),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: borderColor != null && borderWidth != null
              ? BorderSide(color: borderColor!, width: borderWidth!)
              : BorderSide.none,
        ),
        elevation: elevation ?? 0,
      ),
      child: _buildChild(context),
    );
  }

  VoidCallback? _getOnPressed() {
    if (isLoading) return null;
    if (onAsyncPressed != null) {
      return () async => await onAsyncPressed!();
    }
    return onPressed;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: loadingIndicatorSize,
        width: loadingIndicatorSize,
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: loadingIndicatorStrokeWidth!,
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            label,
            style: textStyle ?? Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
        ],
      );
    }
    
    return Text(
      label,
      style: textStyle ?? Theme.of(context).textTheme.labelLarge?.copyWith(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
    );
  }
}