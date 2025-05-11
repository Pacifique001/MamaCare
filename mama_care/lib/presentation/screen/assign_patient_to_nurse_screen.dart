// lib/presentation/screen/assign_patient_to_nurse_screen.dart
import 'package:flutter/material.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';

class AssignPatientToNurseScreen extends StatelessWidget {
  final String nurseId; // Nurse to assign patient TO

  const AssignPatientToNurseScreen({super.key, required this.nurseId});

  @override
  Widget build(BuildContext context) {
     // TODO: Implement ViewModel (e.g., AssignPatientViewModel)
     // Fetch list of assignable patients (e.g., doctor's patients without a nurse)
     // Handle selection and call use case/repo to assign selected patient to this nurseId

    return Scaffold(
      appBar: MamaCareAppBar(title: "Assign Patient"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
             mainAxisSize: MainAxisSize.min,
            children: [
              Text("Assign Patient Screen", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
               Text("Assigning patient TO Nurse ID: $nurseId"),
               const SizedBox(height: 20),
               const Text("(Placeholder UI - Needs Implementation)", style: TextStyle(color: Colors.grey)),
               // TODO: Add patient list, search, selection UI
               // TODO: Add confirm button
            ],
          ),
        ),
      ),
    );
  }
}