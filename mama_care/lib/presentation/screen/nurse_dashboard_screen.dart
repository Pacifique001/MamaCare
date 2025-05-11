// lib/presentation/screen/nurse_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/viewmodel/nurse_dashboard_viewmodel.dart';
import 'package:mama_care/presentation/view/nurse_dashboard_view.dart'; // Import the View

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  final Logger _logger = locator<Logger>();
  late NurseDashboardViewModel _viewModel; // Hold the ViewModel instance

  @override
  void initState() {
    super.initState();
    // Create the ViewModel instance here
    _viewModel = locator<NurseDashboardViewModel>();

    // Trigger initial data load after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    // Ask the ViewModel to load its data.
    // The ViewModel should internally get the nurse's ID (e.g., from AuthViewModel or secure storage).
    _logger.d(
      "NurseDashboardScreen: Requesting initial data load via ViewModel.",
    );
    await _viewModel.loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    // Provide the created ViewModel instance to the View
    return ChangeNotifierProvider<NurseDashboardViewModel>.value(
      value: _viewModel, // Provide the existing instance
      child: const NurseDashboardView(), // The View consumes the VM
    );
  }
}
