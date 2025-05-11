// lib/presentation/screen/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/view/calendar_view.dart';
import 'package:mama_care/domain/usecases/calendar_use_case.dart';
import 'package:mama_care/presentation/viewmodel/calendar_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/navigation/router.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => CalendarViewModel(
            locator<CalendarUseCase>(),
            locator<AuthViewModel>(),
          ),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: const CalendarView(),
        floatingActionButton: _buildAddNoteButton(),
      ),
    );
  }

  /// Builds the app bar with actions for calendar navigation
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Pregnancy Calendar'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 1,
      actions: [_buildGoToTodayButton(), _buildScheduleAppointmentButton()],
    );
  }

  /// Button to return to today's date
  Widget _buildGoToTodayButton() {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(Icons.today),
          tooltip: "Go to Today",
          onPressed: () => context.read<CalendarViewModel>().goToToday(),
        );
      },
    );
  }

  /// Button to schedule a new appointment
  Widget _buildScheduleAppointmentButton() {
    return Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(Icons.add_alarm_outlined),
          tooltip: "Schedule Appointment",
          onPressed: () {
            Navigator.pushNamed(context, NavigationRoutes.addAppointment);
          },
        );
      },
    );
  }

  /// FAB for adding a note to the selected day
  Widget _buildAddNoteButton() {
    return Builder(
      builder: (context) {
        return FloatingActionButton(
          onPressed: () => _showAddNoteDialog(context),
          tooltip: 'Add Note for Selected Day',
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.note_add_outlined, color: Colors.black87),
        );
      },
    );
  }

  /// Shows dialog to add a note to the selected day
  void _showAddNoteDialog(BuildContext context) {
    final vm = context.read<CalendarViewModel>();
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.uid ?? authVm.localUser?.id;
    final noteController = TextEditingController();

    // Check if user is logged in
    if (userId == null) {
      _showUserNotLoggedInMessage(context);
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) =>
              _buildNoteDialog(dialogContext, vm, userId, noteController),
    ).then((_) => noteController.dispose());
  }

  /// Shows a message when the user is not logged in
  void _showUserNotLoggedInMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please log in to add notes."),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Builds the note dialog widget
  Widget _buildNoteDialog(
    BuildContext dialogContext,
    CalendarViewModel vm,
    String userId,
    TextEditingController noteController,
  ) {
    return AlertDialog(
      title: Text('Add Note for ${DateFormat.yMd().format(vm.selectedDate)}'),
      content: _buildNoteTextField(noteController),
      actions: <Widget>[
        _buildCancelButton(dialogContext),
        _buildSaveButton(dialogContext, vm, userId, noteController),
      ],
    );
  }

  /// Builds the text field for entering a note
  Widget _buildNoteTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: "Enter your note...",
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.sentences,
      minLines: 1,
      maxLines: 4,
    );
  }

  /// Builds the cancel button for the note dialog
  Widget _buildCancelButton(BuildContext dialogContext) {
    return TextButton(
      child: const Text('Cancel'),
      onPressed: () => Navigator.pop(dialogContext),
    );
  }

  /// Builds the save button for the note dialog
  Widget _buildSaveButton(
    BuildContext dialogContext,
    CalendarViewModel vm,
    String userId,
    TextEditingController noteController,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
      child: const Text('Save Note', style: TextStyle(color: Colors.white)),
      onPressed:
          () => _handleNoteSave(dialogContext, vm, userId, noteController),
    );
  }

  /// Handles saving a note
  void _handleNoteSave(
    BuildContext dialogContext,
    CalendarViewModel vm,
    String userId,
    TextEditingController noteController,
  ) {
    final noteText = noteController.text.trim();
    if (noteText.isNotEmpty) {
      vm.addNote(noteText, userId);
      Navigator.pop(dialogContext);
    } else {
      _showEmptyNoteError(dialogContext);
    }
  }

  /// Shows an error when the note is empty
  void _showEmptyNoteError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Note cannot be empty."),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
