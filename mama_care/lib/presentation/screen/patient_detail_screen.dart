// lib/presentation/screen/patient_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
     // TODO: Implement ViewModel (e.g., PatientDetailViewModel)
     // Fetch patient details using patientId
     // Display patient info, vitals history, assigned nurse, appointments etc.

    return Scaffold(
      appBar: const MamaCareAppBar(title: "Patient Details"),
      body: Center(
        child: Padding(
           padding: const EdgeInsets.all(20.0),
          child: Column(
             mainAxisSize: MainAxisSize.min,
            children: [
              Text("Patient Detail Screen", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text("Displaying details for Patient ID:"),
               const SizedBox(height: 5),
              SelectableText(patientId, style: Theme.of(context).textTheme.titleMedium),
               const SizedBox(height: 20),
              const Text("(Placeholder UI - Needs Implementation)", style: TextStyle(color: Colors.grey)),
              // TODO: Display actual patient details
            ],
          ),
        ),
      ),
    );
  }
}