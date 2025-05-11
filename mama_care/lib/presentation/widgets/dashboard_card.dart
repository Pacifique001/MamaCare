import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color iconColor;
  final Color cardColor;
  final double borderRadius;
  final double elevation;
  final TextStyle? textStyle;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.name,
    this.iconColor = Colors.pinkAccent,
    this.cardColor = Colors.white,
    this.borderRadius = 15.0,
    this.elevation = 0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(2.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24.sp,
            ),
            SizedBox(height: 1.h),
            Text(
              name,
              style: textStyle ?? Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
