// lib/presentation/view/doctor_appointments_screen.dart

import 'package:flutter/material.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/view/doctor_appointments_view.dart';
import 'package:mama_care/presentation/viewmodel/doctor_appointments_viewmodel.dart';
import 'package:provider/provider.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => locator<DoctorAppointmentsViewModel>(),
      child: const DoctorAppointmentsView(),
    );
  }
}