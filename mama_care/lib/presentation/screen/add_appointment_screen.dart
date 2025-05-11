// lib/presentation/screen/add_appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/injection.dart'; // For locator
import 'package:mama_care/presentation/viewmodel/add_appointment_viewmodel.dart';
import 'package:mama_care/presentation/view/add_appointment_view.dart'; // Import the View

class AddAppointmentScreen extends StatelessWidget {
  const AddAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddAppointmentViewModel>(
      // Create the ViewModel using the locator
      create: (_) => locator<AddAppointmentViewModel>(),
      // The child is the actual UI View
      child: const AddAppointmentView(),
    );
  }
}
