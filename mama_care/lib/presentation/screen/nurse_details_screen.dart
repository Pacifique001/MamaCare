// lib/presentation/screen/nurse_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
//import 'package:mama_care/domain/entities/nurse.dart'; // Import Nurse entity
import 'package:mama_care/injection.dart'; // For locator
import 'package:mama_care/presentation/viewmodel/nurse_detail_viewmodel.dart'; // Import ViewModel
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

// Screen Wrapper that provides the ViewModel
class NurseDetailScreenWrapper extends StatelessWidget {
  final String nurseId;
  const NurseDetailScreenWrapper({super.key, required this.nurseId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Create ViewModel instance using locator, passing nurseId as factoryParam
      create: (_) => locator<NurseDetailViewModel>(param1: nurseId),
      child: const NurseDetailScreen(), // The actual screen content
    );
  }
}


// The actual Screen content widget
class NurseDetailScreen extends StatelessWidget {
  const NurseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to ViewModel changes
    return Consumer<NurseDetailViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: MamaCareAppBar(
            title: viewModel.nurse?.name ?? "Nurse Profile", // Dynamic title
            // Add actions if needed (e.g., Edit for admin)
            // actions: [ IconButton(onPressed: () {}, icon: Icon(Icons.edit_outlined)) ],
          ),
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NurseDetailViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("Error: ${viewModel.error}", style: TextStyles.bodyGrey.copyWith(color: Colors.redAccent)),
        ),
      );
    }

    final nurse = viewModel.nurse; // Get the loaded nurse data
    if (nurse == null) {
      // This case might be hit if fetchNurseDetails fails but doesn't set error,
      // or if called before fetch completes (though isLoading should handle that)
      return Center(child: Text("Nurse details not available.", style: TextStyles.bodyGrey));
    }

    // --- Display Nurse Details ---
    final bool hasImage = nurse.imageUrl != null && nurse.imageUrl!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 50.sp, // Larger avatar
            backgroundColor: Colors.grey.shade200,
            backgroundImage: hasImage
                ? NetworkImage(nurse.imageUrl!)
                : Image.asset(AssetsHelper.stretching).image,
            child: !hasImage ? Icon(Icons.person, size: 60.sp, color: Colors.grey) : null,
          ),
          const SizedBox(height: 16),

          // Name
          Text(nurse.name, style: TextStyles.headline2.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),

          // Specialty
          if (nurse.specialty != null && nurse.specialty!.isNotEmpty)
            Chip(
              label: Text(nurse.specialty!),
              backgroundColor: AppColors.primaryLight.withOpacity(0.15),
              labelStyle: TextStyles.smallPrimary,
              side: BorderSide.none,
            ),
          const SizedBox(height: 24),

          // Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   _buildInfoRow(Icons.medical_services_outlined, "Specialty", nurse.specialty ?? "Not specified"),
                   const Divider(height: 20),
                   _buildInfoRow(Icons.people_alt_outlined, "Assigned Patients", "${nurse.currentPatientLoad} / 5"), // Assuming max 5
                    // Add more info rows if available (e.g., contact, experience years)
                    // const Divider(height: 20),
                    // _buildInfoRow(Icons.phone_outlined, "Contact", nurse.phoneNumber ?? "Not available"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons (Example)
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
             children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.list_alt_outlined),
                   label: Text("View Assignments"),
                   onPressed: () {
                      locator<Logger>().i("Navigate to assignments for ${nurse.id}");
                      Navigator.pushNamed(
                         context,
                         NavigationRoutes.nurseAssignmentManagement,
                         arguments: nurse.id
                      );
                   },
                ),
                // Add more actions like "Contact Nurse" if applicable
             ],
          )
        ],
      ),
    );
  }

  // Helper widget for info rows in the card
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryLight, size: 20),
        const SizedBox(width: 12),
        Text("$label:", style: TextStyles.bodyGrey),
        const Spacer(),
        Text(value, style: TextStyles.bodyBold),
      ],
    );
  }
}