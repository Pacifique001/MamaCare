// lib/presentation/view/add_appointment_view.dart
// (Ensure no ChangeNotifierProvider.create is inside this file's build method)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/user_model.dart'; // Adjust if using a specific Doctor entity
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/widgets/custom_button.dart';
import 'package:mama_care/presentation/widgets/custom_text_field.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/presentation/viewmodel/add_appointment_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class AddAppointmentView extends StatefulWidget {
  const AddAppointmentView({super.key});

  @override
  State<AddAppointmentView> createState() => _AddAppointmentViewState();
}

class _AddAppointmentViewState extends State<AddAppointmentView> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDateTime;
  String? _selectedDoctorId;

  final Logger _logger = locator<Logger>();

  @override
  void initState() {
    super.initState();
    // Load doctors when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use context.read to access the provider created by AddAppointmentScreen
      context.read<AddAppointmentViewModel>().loadAvailableDoctors();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- _pickDateTime, _saveAppointment, _showErrorSnackbar, _showSuccessSnackbar methods ---
  // (Keep the implementations from the previous step - they use context.read/watch correctly)
  Future<void> _pickDateTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now().add(const Duration(hours: 1)),
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                hourMinuteTextColor: AppColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _logger.d("Selected DateTime: $_selectedDateTime");
        });
      }
    }
  }

  Future<void> _saveAppointment() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _logger.w("Add Appointment form validation failed.");
      return;
    }
    if (_selectedDateTime == null) {
      _showErrorSnackbar("Please select a date and time.");
      return;
    }
    if (_selectedDoctorId == null || _selectedDoctorId!.isEmpty) {
      _showErrorSnackbar("Please select a doctor.");
      return;
    }

    final String reason = _reasonController.text.trim();
    final String notes = _notesController.text.trim();
    _logger.i(
      "Saving appointment - Reason: $reason, Time: $_selectedDateTime, Doctor: $_selectedDoctorId, Notes: $notes",
    );

    // Use context.read as this is an action method
    final viewModel = context.read<AddAppointmentViewModel>();
    bool success = false;

    try {
      final Appointment? createdAppointment = await viewModel.saveAppointment(
        doctorId: _selectedDoctorId!,
        reason: reason,
        dateTime: _selectedDateTime!,
        notes: notes.isEmpty ? null : notes,
      );
      if (!mounted) return;

      if (createdAppointment != null) {
        // Check if result is not null
        _showSuccessSnackbar("Appointment requested successfully!");
        // Optionally use createdAppointment details if needed
        Navigator.pop(context); // Go back after saving
      } else {
        // Show error message FROM THE VIEWMODEL
        _showErrorSnackbar(viewModel.error ?? "Failed to save appointment.");
      }
    } catch (e, s) {
      // Catch unexpected errors during the VM call itself
      _logger.e(
        "Error calling saveAppointment from View",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        _showErrorSnackbar("An unexpected error occurred: ${e.toString()}");
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    // Use Consumer to access the ViewModel provided by AddAppointmentScreen
    // and rebuild the UI when its state changes.
    return Consumer<AddAppointmentViewModel>(
      builder: (context, viewModel, child) {
        // Scaffold and UI structure remain largely the same
        return Scaffold(
          appBar: const MamaCareAppBar(title: "Request Appointment"),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Doctor Selection Dropdown ---
                      Text("Select Doctor", style: TextStyles.textFieldLabel),
                      const SizedBox(height: 8),
                      if (viewModel.isLoadingDoctors)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (viewModel.error != null &&
                          viewModel.availableDoctors.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Error loading doctors: ${viewModel.error}",
                            style: TextStyles.errorText,
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedDoctorId,
                          items:
                              viewModel.availableDoctors.map((doctor) {
                                // Use UserModel fields - adjust if you have a specific Doctor model
                                String specialty =
                                    doctor.specialty ??
                                    ''; // Assuming specialty is nullable on UserModel
                                return DropdownMenuItem<String>(
                                  value: doctor.id,
                                  child: Text(
                                    "${doctor.name}${specialty.isNotEmpty ? ' ($specialty)' : ''}",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDoctorId = value;
                            });
                            if (viewModel.error != null) viewModel.clearError();
                          },
                          decoration: InputDecoration(
                            hintText:
                                viewModel.availableDoctors.isEmpty
                                    ? 'No doctors available'
                                    : 'Choose a doctor',
                            prefixIcon: const Icon(
                              Icons.medical_services_outlined,
                              color: AppColors.primaryLight,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator:
                              (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Please select a doctor'
                                      : null,
                          isExpanded: true,
                        ),
                      const SizedBox(height: 20),

                      // Reason Field
                      Text(
                        "Reason for Appointment",
                        style: TextStyles.textFieldLabel,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _reasonController,
                        hint: "e.g., Routine Checkup, Feeling unwell",
                        validator:
                            (value) =>
                                (value?.trim().isEmpty ?? true)
                                    ? 'Please enter a reason'
                                    : null,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),

                      // Date & Time Picker
                      Text(
                        "Preferred Date and Time",
                        style: TextStyles.textFieldLabel,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDateTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDateTime == null
                                    ? 'Select Date & Time'
                                    : DateFormat(
                                      'EEE, MMM dd, yyyy  hh:mm a',
                                    ).format(_selectedDateTime!),
                                style:
                                    _selectedDateTime == null
                                        ? TextStyles.bodyGrey.copyWith(
                                          fontSize: 13.sp,
                                        )
                                        : TextStyles.body.copyWith(
                                          fontSize: 13.sp,
                                        ),
                              ),
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notes Field (Optional)
                      Text(
                        "Notes (Optional)",
                        style: TextStyles.textFieldLabel,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _notesController,
                        hint: "e.g., Any specific questions for the doctor?",
                        maxLines: 4,
                        minLines: 2,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 30),

                      // Save Button
                      CustomButton(
                        label: "Request Appointment",
                        onPressed:
                            viewModel.isLoading ? null : _saveAppointment,
                        backgroundColor: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Loading Overlay
              if (viewModel.isLoading)
                const Opacity(
                  opacity: 0.6,
                  child: ModalBarrier(dismissible: false, color: Colors.black),
                ),
              if (viewModel.isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            ],
          ),
        );
      },
    );
  }
}
