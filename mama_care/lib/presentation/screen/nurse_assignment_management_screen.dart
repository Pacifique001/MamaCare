// lib/presentation/screen/nurse_assignment_management_screen.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/nurse.dart'; // Import Nurse
import 'package:mama_care/domain/entities/patient_summary.dart'; // Import PatientSummary
import 'package:mama_care/injection.dart'; // For locator
import 'package:mama_care/navigation/router.dart'; // For navigation
import 'package:mama_care/presentation/viewmodel/nurse_assignment_management_viewmodel.dart'; // Import ViewModel
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/utils/asset_helper.dart'; // For default avatar
import 'package:provider/provider.dart';
//import 'package:sizer/sizer.dart';

// Screen Wrapper that provides the ViewModel
class NurseAssignmentManagementScreenWrapper extends StatelessWidget {
  final String nurseId;
  const NurseAssignmentManagementScreenWrapper({super.key, required this.nurseId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => locator<NurseAssignmentManagementViewModel>(param1: nurseId),
      child: const NurseAssignmentManagementScreen(),
    );
  }
}


// The actual Screen content widget
class NurseAssignmentManagementScreen extends StatelessWidget {
  const NurseAssignmentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NurseAssignmentManagementViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: MamaCareAppBar(
            title: "Manage ${viewModel.nurseProfile?.name ?? 'Nurse'}'s Assignments",
          ),
          body: _buildBody(context, viewModel),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              locator<Logger>().i("FAB Tapped: Navigate to Assign Patient TO this nurse");
               // Navigate to a screen to select a patient *for this nurse*
               Navigator.pushNamed(
                  context,
                  NavigationRoutes.assignPatientToNurse, // Need this route
                  arguments: viewModel.nurseId // Pass nurseId to assign TO
               );
            },
            tooltip: "Assign New Patient",
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.person_add_alt),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NurseAssignmentManagementViewModel viewModel) {
    if (viewModel.isLoading && viewModel.assignedPatients.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (viewModel.error != null) {
       // Show persistent error if nurse profile failed, otherwise maybe just for list?
      return Center(
         child: Padding(
           padding: const EdgeInsets.all(20.0),
           child: Text("Error: ${viewModel.error}", style: TextStyles.bodyGrey.copyWith(color: Colors.redAccent)),
         ),
       );
    }

     if (viewModel.nurseProfile == null) {
        // Handle case where nurse profile specifically failed but maybe assignments didn't
         return Center(child: Text("Could not load nurse profile.", style: TextStyles.bodyGrey));
     }


    // --- Display Nurse Info and Assigned Patients ---
    return Column(
       children: [
          // Optional: Display a summary of the nurse at the top
          _buildNurseSummaryHeader(context, viewModel.nurseProfile!),
          const Divider(),
          // List Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Assigned Patients (${viewModel.assignedPatients.length})",
              style: TextStyles.title,
            ),
          ),
          // Patient List
          Expanded(
            child: _buildPatientList(context, viewModel),
          ),
       ],
    );
  }

  Widget _buildNurseSummaryHeader(BuildContext context, Nurse nurse) {
     final bool hasImage = nurse.imageUrl != null && nurse.imageUrl!.isNotEmpty;
     return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
           children: [
              CircleAvatar(
                 radius: 25,
                 backgroundColor: Colors.grey.shade200,
                 backgroundImage: hasImage
                     ? NetworkImage(nurse.imageUrl!)
                     : Image.asset(AssetsHelper.stretching).image,
                 child: !hasImage ? const Icon(Icons.person, size: 28, color: Colors.grey) : null,
              ),
              const SizedBox(width: 16),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(nurse.name, style: TextStyles.title),
                     if(nurse.specialty != null)
                       Text(nurse.specialty!, style: TextStyles.bodyGrey),
                  ],
              ),
               const Spacer(),
               // Display current load vs capacity
                Chip(
                  label: Text("${nurse.currentPatientLoad} / 5 Patients", style: TextStyles.small),
                  backgroundColor: nurse.currentPatientLoad >= 5 ? Colors.orange.shade100 : Colors.green.shade50,
                  side: BorderSide.none,
                  labelStyle: TextStyle(color: nurse.currentPatientLoad >= 5 ? Colors.orange.shade900 : Colors.green.shade800),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
               ),
           ],
        ),
     );
  }


   Widget _buildPatientList(BuildContext context, NurseAssignmentManagementViewModel viewModel) {
     if (viewModel.assignedPatients.isEmpty) {
        return Center(child: Text("No patients currently assigned.", style: TextStyles.bodyGrey));
     }

     return ListView.separated(
       padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
       itemCount: viewModel.assignedPatients.length,
       separatorBuilder: (_, __) => const Divider(height: 0, indent: 16, endIndent: 16),
       itemBuilder: (context, index) {
          final patient = viewModel.assignedPatients[index];
          return ListTile(
             // TODO: Add patient avatar if available in PatientSummary
             // leading: CircleAvatar(...),
             title: Text(patient.name, style: TextStyles.bodyBold),
             // TODO: Add subtitle with relevant patient info (e.g., condition, due date)
             // subtitle: Text("Due: ${DateFormat.yMd().format(patient.dueDate)}"),
             trailing: IconButton(
                icon: Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                tooltip: "Unassign Patient",
                onPressed: viewModel.isLoading // Disable button while another action is in progress
                   ? null
                   : () => _showUnassignConfirmationDialog(context, viewModel, patient),
             ),
             onTap: () {
                // TODO: Navigate to patient detail screen
                 locator<Logger>().i("Navigate to detail for patient ${patient.id}");
                // Navigator.pushNamed(context, NavigationRoutes.patientDetail, arguments: patient.id);
             },
          );
       },
     );
   }

   // --- Confirmation Dialog for Unassignment ---
   Future<void> _showUnassignConfirmationDialog(
      BuildContext context,
      NurseAssignmentManagementViewModel viewModel,
      PatientSummary patient
   ) async {
      final Logger logger = locator<Logger>();
      return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Unassign ${patient.name}?'),
            content: Text('Are you sure you want to remove ${patient.name} from ${viewModel.nurseProfile?.name ?? 'this nurse'}\'s assignments?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Confirm Unassignment'),
                onPressed: () async { // Make async for await
                  Navigator.of(dialogContext).pop(); // Dismiss dialog
                  logger.i("Confirming unassignment of patient ${patient.id} from nurse ${viewModel.nurseId}");
                  // Call VM method - show snackbar based on result
                  bool success = await viewModel.unassignPatient(patient.id);
                  if (!context.mounted) return; // Check mounted after await
                  if (success) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${patient.name} unassigned."), backgroundColor: Colors.green));
                  } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.error ?? "Failed to unassign patient."), backgroundColor: Colors.redAccent));
                  }
                },
              ),
            ],
          );
        },
      );
   }
}
