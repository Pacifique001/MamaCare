// lib/presentation/widgets/patient_summary_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:cached_network_image/cached_network_image.dart'; // Import for network images
import 'package:mama_care/domain/entities/patient_summary.dart'; // Import the entity
import 'package:mama_care/utils/app_colors.dart';   // Assuming AppColors
import 'package:mama_care/utils/text_styles.dart';  // Assuming TextStyles
// import 'package:mama_care/utils/asset_helper.dart'; // Only needed if you have a specific asset fallback

class PatientSummaryCard extends StatelessWidget {
  final PatientSummary patient;
  final VoidCallback? onTap; // Callback when the card is tapped

  const PatientSummaryCard({
    super.key,
    required this.patient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = patient.imageUrl != null && patient.imageUrl!.isNotEmpty;
    final String initials = patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0), // Vertical spacing
      elevation: 1.5, // Subtle elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias, // Clip ripple effect
      child: InkWell( // Make the whole card tappable
        onTap: onTap, // Trigger the callback
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Adjusted padding
          child: Row(
            children: [
              // Patient Avatar using CachedNetworkImage logic
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                // Use CachedNetworkImageProvider if URL exists
                backgroundImage: hasImage ? CachedNetworkImageProvider(patient.imageUrl!) : null,
                // Show initials or icon as fallback
                child: !hasImage
                    ? Text(
                        initials,
                        style: TextStyle(
                            fontSize: 16, // Adjust size
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark.withOpacity(0.7)),
                      )
                    : null, // No child if image is loading/loaded
              ),
              const SizedBox(width: 12),

              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name, // Use patient.name from PatientSummary
                      style: TextStyles.titleCard.copyWith(color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Display Due Date if available in PatientSummary
                    if (patient.dueDate != null)
                      Row(
                        children: [
                           Icon(Icons.cake_outlined, size: 14, color: AppColors.textGrey),
                           const SizedBox(width: 4),
                           Text(
                              'Due: ${DateFormat.yMd().format(patient.dueDate!)}', // Format the date
                              style: TextStyles.smallGrey,
                           ),
                        ],
                      ),
                    // Example: Displaying Weeks Pregnant if available
                    if (patient.weeksPregnant != null)
                       Padding(
                         padding: const EdgeInsets.only(top: 3.0),
                         child: Row(
                            children: [
                               Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.textGrey),
                               const SizedBox(width: 4),
                               Text(
                                  'Week: ${patient.weeksPregnant}',
                                  style: TextStyles.smallGrey,
                               ),
                            ],
                         ),
                       ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trailing action/indicator
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}