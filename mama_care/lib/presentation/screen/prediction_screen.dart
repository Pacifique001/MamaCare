import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/injection.dart'; // Assuming locator setup is correct
// Removed RiskDetectorUseCase import as it's not directly used here anymore
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/presentation/view/prediction_view.dart';
import 'package:mama_care/presentation/viewmodel/risk_detector_viewmodel.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RiskDetectorViewModel(locator<DatabaseHelper>()),
      child: const PredictionView(),
    );
  }
}
