// lib/presentation/widgets/nurse_assignment_card.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/nurse.dart'; // <-- Import the Nurse entity
import 'package:mama_care/navigation/navigation_service.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:mama_care/injection.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Use cached_network_image

class NurseAssignmentCard extends StatelessWidget {
  // --- ACCEPT NURSE ENTITY ---
  final Nurse nurse; // Changed from NurseAssignment

  final Logger _logger = locator<Logger>();

  NurseAssignmentCard({
    super.key,
    required this.nurse, required Null Function() onTap, // Changed parameter name
  });

  @override
  Widget build(BuildContext context) {
    // --- Extract data from Nurse entity ---
    final nurseName = nurse.name; // Use direct field access
    final nurseSpecialty = nurse.specialty;
    final nurseImageUrl = nurse.imageUrl;
    final patientCount = nurse.currentPatientLoad; // Use direct field access
    final bool hasImage = nurseImageUrl != null && nurseImageUrl.isNotEmpty;
    final bool isAtCapacity = patientCount >= 5; // Example capacity check

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // --- Navigate using nurse.id ---
        onTap: () => _navigateToNurseDetails(nurse.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Nurse Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: hasImage
                    ? CachedNetworkImageProvider(nurseImageUrl)
                    : Image.asset(AssetsHelper.stretching).image,
                child: !hasImage
                    ? const Icon(Icons.person_outline, size: 30, color: AppColors.textGrey)
                    : null,
              ),
              const SizedBox(width: 12),
              // Nurse Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nurseName, // Use nurse.name
                      style: TextStyles.titleCard.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (nurseSpecialty != null && nurseSpecialty.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                         nurseSpecialty,
                         style: TextStyles.small.copyWith(color: AppColors.primary),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      // Use nurse.currentPatientLoad
                      '$patientCount Patient${patientCount == 1 ? '' : 's'}${isAtCapacity ? ' (Max)' : ''}',
                      style: TextStyles.smallGrey.copyWith(
                         color: isAtCapacity ? Colors.orange.shade800 : null,
                         fontStyle: isAtCapacity ? FontStyle.italic : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Button (More Options)
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                tooltip: 'Nurse Options',
                // --- Pass nurse object to options menu ---
                onPressed: () => _showOptionsMenu(context, nurse),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Navigation Helpers ---
  void _navigateToNurseDetails(String nurseId) {
     _logger.i("Navigating to Nurse Details for ID: $nurseId");
     NavigationService.navigateTo(NavigationRoutes.nurseDetail, arguments: nurseId);
  }

   void _navigateToAssignmentManagement(String nurseId) {
      _logger.i("Navigating to Assignment Management for Nurse ID: $nurseId");
     NavigationService.navigateTo(NavigationRoutes.nurseAssignmentManagement, arguments: nurseId);
   }


  // --- Options Menu ---
  // --- Accepts Nurse object now ---
  void _showOptionsMenu(BuildContext context, Nurse nurse) {
     showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder( borderRadius: BorderRadius.vertical(top: Radius.circular(20)), ),
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility_outlined, color: AppColors.textDark),
                title: Text('View Profile', style: TextStyles.body),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToNurseDetails(nurse.id); // Use nurse.id
                },
              ),
               ListTile(
                leading: const Icon(Icons.assignment_ind_outlined, color: AppColors.textDark),
                title: Text('Manage Patient Assignments', style: TextStyles.body),
                onTap: () {
                   Navigator.pop(ctx);
                   _navigateToAssignmentManagement(nurse.id); // Use nurse.id
                },
              ),
               const Divider(height: 1, indent: 16, endIndent: 16),
               ListTile(
                 leading: const Icon(Icons.cancel_outlined, color: Colors.grey),
                 title: Text('Cancel', style: TextStyles.bodyGrey),
                 onTap: () => Navigator.pop(ctx),
               ),
            ],
          ),
        ),
     );
  }
}