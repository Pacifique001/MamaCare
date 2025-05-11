import 'package:flutter/material.dart';
import 'package:mama_care/utils/text_styles.dart';

class NurseAssignmentHeader extends StatelessWidget {
  final int totalAssignments;
  final VoidCallback? onFilterPressed;

  const NurseAssignmentHeader({
    super.key,
    required this.totalAssignments,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Assigned Nurses ($totalAssignments)", // Updated label
            style: TextStyles.title,
          ),
          if (onFilterPressed != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: "Filter Nurses",
              onPressed: onFilterPressed,
            ),
        ],
      ),
    );
  }
}