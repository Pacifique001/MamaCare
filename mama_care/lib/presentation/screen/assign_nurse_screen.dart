// lib/presentation/screen/assign_nurse_screen.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
//import 'package:mama_care/domain/entities/nurse.dart'; // Import correct entity
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/viewmodel/assign_nurse_viewmodel.dart'; // Import ViewModel
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/presentation/widgets/custom_button.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:provider/provider.dart';
//import 'package:mama_care/core/error/exceptions.dart'; // Import custom exceptions

class AssignNurseScreen extends StatefulWidget {
  final String? contextId; // e.g., appointmentId or patientId

  const AssignNurseScreen({super.key, this.contextId});

  @override
  State<AssignNurseScreen> createState() => _AssignNurseScreenState();
}

class _AssignNurseScreenState extends State<AssignNurseScreen> {
  final Logger _logger = locator<Logger>();

  @override
  void initState() {
    super.initState();
    // Load data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use context.read here because it's outside the build method
      context.read<AssignNurseViewModel>().loadAvailableNurses(widget.contextId);
    });
    _logger.i("AssignNurseScreen initialized for context ID: ${widget.contextId ?? 'None'}");
  }

  // Removed placeholder data and local state (_availableNurses, _isLoading, _error, _selectedNurseId)
  // Removed _loadDummyData

  Future<void> _handleAssignNurse(AssignNurseViewModel viewModel) async {
    // Selected nurse ID is now managed by the ViewModel
    if (viewModel.selectedNurseId == null) {
      _showSnackbar("Please select a nurse to assign.", isError: true);
      return;
    }
    if (widget.contextId == null) {
      _showSnackbar("Cannot assign nurse: Context ID (appointment/patient) is missing.", isError: true);
      return;
    }

    _logger.i("Attempting to assign Nurse ID: ${viewModel.selectedNurseId} to Context ID: ${widget.contextId}");

    // --- Call ViewModel to perform the assignment ---
    bool success = await viewModel.assignSelectedNurseToContext(widget.contextId!);

    if (!mounted) return;

    if (success) {
      _showSnackbar("Nurse assigned successfully!", isError: false);
      Navigator.pop(context); // Go back after successful assignment
    } else {
      // Error message is now handled by the ViewModel's error state
      _showSnackbar(viewModel.error ?? "Failed to assign nurse.", isError: true);
    }
  }

  // --- Snackbar Helper ---
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use context.watch here to rebuild the UI when ViewModel state changes
    final viewModel = context.watch<AssignNurseViewModel>();

    return Scaffold(
      appBar: const MamaCareAppBar(title: "Assign Nurse"),
      body: Stack( // Keep Stack for loading overlay
        children: [
          Column(
            children: [
              // TODO: Add search/filter bar if needed
              // Padding( ... SearchBar ... ),
              Expanded(
                // Pass the ViewModel to the list builder
                child: _buildNurseList(context, viewModel),
              ),
              // Assign Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomButton(
                  label: "Assign Selected Nurse",
                  // Enable button based on ViewModel state
                  onPressed: (viewModel.selectedNurseId != null && !viewModel.isLoading)
                      ? () => _handleAssignNurse(viewModel) // Pass VM instance
                      : null,
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          // Loading Overlay based on ViewModel state
          if (viewModel.isLoading)
             const Opacity(opacity: 0.6, child: ModalBarrier(dismissible: false, color: Colors.black)),
          if (viewModel.isLoading)
             const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }

  // --- Build Nurse List using ViewModel data ---
  Widget _buildNurseList(BuildContext context, AssignNurseViewModel viewModel) {
    // Use ViewModel state for loading, error, and data
    if (viewModel.isLoading && viewModel.availableNurses.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (viewModel.error != null && viewModel.availableNurses.isEmpty) {
      // Display error message from ViewModel
      return Center(
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
               SizedBox(height: 10),
               Text("Error Loading Nurses", style: TextStyles.title.copyWith(color: Colors.redAccent)),
               SizedBox(height: 5),
               Text(viewModel.error!, style: TextStyles.bodyGrey, textAlign: TextAlign.center),
               SizedBox(height: 15),
               // Add retry button if desired
               ElevatedButton(onPressed: () => viewModel.loadAvailableNurses(widget.contextId), child: Text("Retry"))
             ],
           ),
         ),
      );
    }
    if (viewModel.availableNurses.isEmpty) {
      return Center(child: Text("No available nurses found.", style: TextStyles.bodyGrey));
    }

    // Display list from ViewModel
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0), // Adjust padding
      itemCount: viewModel.availableNurses.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 16, endIndent: 16), // Thinner divider
      itemBuilder: (context, index) {
        final nurse = viewModel.availableNurses[index];
        // Use ViewModel's selectedNurseId for groupValue
        final bool isSelected = nurse.id == viewModel.selectedNurseId;
        // Capacity check remains the same
        final bool canAssign = nurse.currentPatientLoad < 5; // Example capacity

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adjust padding
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (nurse.imageUrl != null && nurse.imageUrl!.isNotEmpty)
                ? NetworkImage(nurse.imageUrl!)
                : Image.asset(AssetsHelper.stretching).image,
            child: (nurse.imageUrl == null || nurse.imageUrl!.isEmpty)
                 ? const Icon(Icons.person_outline, size: 28, color: Colors.grey) : null,
          ),
          title: Text(nurse.name, style: TextStyles.titleCard.copyWith(color: AppColors.textDark)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               if (nurse.specialty != null && nurse.specialty!.isNotEmpty)
                 Padding( // Add padding for specialty
                   padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                   child: Text(nurse.specialty!, style: TextStyles.small.copyWith(color: AppColors.primary)),
                 ),
               Text(
                 "Patients: ${nurse.currentPatientLoad}${canAssign ? '' : ' (Max Capacity)'}", // Clearer label
                 style: TextStyles.smallGrey.copyWith(
                   color: canAssign ? AppColors.textGrey : Colors.orange.shade800, // Use stronger warning color
                   fontStyle: canAssign ? FontStyle.normal : FontStyle.italic,
                 )
               ),
            ],
          ),
          trailing: Radio<String>(
            value: nurse.id,
            groupValue: viewModel.selectedNurseId, // Use ViewModel state
            onChanged: canAssign
              // Call ViewModel method to update selection
              ? (String? value) => viewModel.selectNurse(value)
              : null, // Disable radio if cannot assign
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap area
          ),
          tileColor: isSelected ? AppColors.primary.withOpacity(0.08) : null,
          onTap: canAssign
             // Call ViewModel method to update selection on tap
             ? () => viewModel.selectNurse(nurse.id)
             : () => _showSnackbar("Nurse ${nurse.name} is at maximum capacity.", isError: true),
        );
      },
    );
  }
}