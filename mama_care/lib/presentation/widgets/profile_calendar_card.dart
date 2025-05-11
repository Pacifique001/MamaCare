import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';

class ProfileCalendarCard extends StatelessWidget {
  final PregnancyDetails? details;

  const ProfileCalendarCard({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar(
          headerVisible: false,
          daysOfWeekVisible: false,
          focusedDay: DateTime.now(),
          firstDay: details?.startingDay ?? DateTime.now(),
          lastDay:
              details?.dueDate ?? DateTime.now().add(const Duration(days: 280)),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            defaultDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder:
                (context, day, focusedDay) => _buildDayCell(day, false),
            todayBuilder:
                (context, day, focusedDay) => _buildDayCell(day, true),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday) {
    final daysDifference = day.difference(details?.startingDay ?? day).inDays;
    return Center(
      child: Text(
        '$daysDifference',
        style: TextStyle(
          color: isToday ? Colors.white : Colors.black87,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
