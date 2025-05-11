// lib/presentation/view/calendar_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_care/navigation/router.dart'; // Assuming NavigationRoutes.appointmentDetail is defined
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mama_care/domain/entities/calendar_notes_model.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/presentation/viewmodel/calendar_viewmodel.dart';
import 'package:mama_care/presentation/widgets/appointment_card.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late final CalendarViewModel _vm;
  final TextEditingController _noteController = TextEditingController();
  final Logger _logger = locator<Logger>();

  @override
  void initState() {
    super.initState();
    _vm = context.read<CalendarViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure AuthViewModel is ready if userId is needed for initial load
      final authVm = context.read<AuthViewModel>();
      if (authVm.currentUser?.uid != null) {
        _vm.loadDataForSelectedDate(); // Assuming this uses the selected date and fetches relevant user data
      } else {
        // Handle case where user is not logged in yet, or subscribe to auth changes
        _logger.w("CalendarView initState: User not available for initial data load.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, vm, _) {
        // This Column is intended to fill the space given to CalendarView
        // The Expanded widget in _buildEventsList will handle the list's flexible height
        return Column(
          children: [
            _buildCalendar(vm),
            const SizedBox(height: 8),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  "Error: ${vm.error}",
                  style: TextStyle(color: Colors.red.shade700, fontSize: 10.sp),
                  textAlign: TextAlign.center,
                ),
              ),
            // Show specific loading for events list if it's loading and the list part would be empty
            if (vm.isLoading && vm.eventsForSelectedDate.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primaryLight,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                "Events for ${DateFormat.yMMMd().format(vm.selectedDate)}",
                style: TextStyles.title.copyWith(fontSize: 14.sp),
              ),
            ),
            const Divider(height: 1),
            // _buildEventsList already returns an Expanded widget, which is correct here.
            _buildEventsList(vm),
            // _buildAddNoteField(context, vm), // Uncomment if you want the add note field here
          ],
        );
      },
    );
  }

  Widget _buildCalendar(CalendarViewModel vm) {
    return TableCalendar<dynamic>(
      focusedDay: vm.focusedDate,
      selectedDayPredicate: (day) => isSameDay(vm.selectedDate, day),
      firstDay: DateTime.utc(DateTime.now().year - 2, 1, 1), // Extended range
      lastDay: DateTime.utc(DateTime.now().year + 2, 12, 31),  // Extended range
      calendarFormat: vm.calendarFormat, // Use format from VM
      onFormatChanged: (format) {
        vm.setCalendarFormat(format); // Allow VM to control format
      },
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 Weeks',
        CalendarFormat.week: 'Week',
      },
      eventLoader: (day) {
        // Filter events from the VM's pre-loaded list for the selected date
        // This eventLoader is for displaying markers on the calendar, not for the list below
        return vm.getEventsForDay(day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(vm.selectedDate, selectedDay)) {
          vm.updateSelectedDate(selectedDay, focusedDay);
        }
      },
      onPageChanged: (focusedDay) {
        vm.updateFocusedDate(focusedDay);
      },
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        titleTextStyle: TextStyles.title.copyWith(fontSize: 15.sp),
        formatButtonTextStyle: TextStyle(fontSize: 11.sp),
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryLight),
          borderRadius: BorderRadius.circular(12.0),
        ),
        leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
        rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        todayTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        markerDecoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerSize: 5.0,
        markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
        outsideDaysVisible: false,
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 11.sp, color: Colors.black54),
        weekendStyle: TextStyle(fontSize: 11.sp, color: AppColors.primary),
      ),
    );
  }

  Widget _buildEventsList(CalendarViewModel vm) {
    // Get events specifically for the currently selectedDate from the VM
    final events = vm.eventsForSelectedDate;

    // If the VM indicates it's loading these specific events (you might need a separate flag for this)
    // or if general loading is on and events are empty.
    if (vm.isLoading && events.isEmpty) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (events.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No events or notes for this day.',
              style: TextStyles.bodyGrey.copyWith(fontSize: 11.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final authViewModel = context.read<AuthViewModel>();
    final userId = authViewModel.currentUser?.uid;
    final userRole = authViewModel.userRole;

    return Expanded( // This Expanded is crucial for Strategy 2
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          if (event is CalendarNote) {
            return _buildNoteItem(event, vm);
          } else if (event is Appointment) {
            return AppointmentCard(
              appointment: event,
              userRole: userRole,
              currentUserId: userId ?? '',
              onTap: () {
                _logger.d("Tapped appointment ${event.id} from calendar");
                Navigator.pushNamed(
                  context,
                  NavigationRoutes.appointmentDetail,
                  arguments: event.id,
                );
              },
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildNoteItem(CalendarNote note, CalendarViewModel vm) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.note_alt_outlined, color: AppColors.secondary),
        title: Text(note.note, style: TextStyles.body.copyWith(fontSize: 11.sp)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
          tooltip: "Delete Note",
          iconSize: 20.sp,
          onPressed: () => _confirmDeleteNote(note, vm),
        ),
      ),
    );
  }

  void _confirmDeleteNote(CalendarNote note, CalendarViewModel vm) async {
     if (note.id == null) {
      _logger.e("Cannot delete note: Note ID is null.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Cannot delete note without an ID.")),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Note?"),
        content: const Text("Are you sure you want to delete this note?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) { // Explicitly check for true
      vm.deleteNote(note.id!);
    }
  }

  Widget _buildAddNoteField(BuildContext context, CalendarViewModel vm) {
    final authViewModel = context.watch<AuthViewModel>(); // Use watch if it might change
    final userId = authViewModel.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0), // Adjust padding
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add a note for ${DateFormat.yMd().format(vm.selectedDate)}...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              onSubmitted: (text) {
                if (userId != null && text.trim().isNotEmpty) {
                  vm.addNote(text.trim(), userId);
                  _noteController.clear();
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            iconSize: 28.sp,
            tooltip: "Save Note",
            onPressed: () {
              final noteText = _noteController.text.trim();
              if (noteText.isNotEmpty && userId != null) {
                vm.addNote(noteText, userId);
                _noteController.clear();
                FocusScope.of(context).unfocus();
              } else if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please log in to add notes.")),
                );
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Note cannot be empty.")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}