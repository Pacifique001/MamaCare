import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/risk_detector_viewmodel.dart';
import 'package:mama_care/presentation/widgets/custom_button.dart'; // Assuming you have this
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart'; // Assuming you have this
import 'package:sizer/sizer.dart';
// Removed DatabaseHelper import here, as it's handled by ViewModel

class PredictionView extends StatefulWidget {
  const PredictionView({super.key});

  @override
  State<PredictionView> createState() => _PredictionViewState();
}

class _PredictionViewState extends State<PredictionView> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _sbpController = TextEditingController();
  final _dbpController = TextEditingController();
  final _bsController = TextEditingController();
  final _tempController = TextEditingController();
  final _heartRateController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers
    _ageController.dispose();
    _sbpController.dispose();
    _dbpController.dispose();
    _bsController.dispose();
    _tempController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the ViewModel changes
    return Consumer<RiskDetectorViewModel>(
      builder:
          (context, viewModel, _) => Scaffold(
            appBar: MamaCareAppBar(
              // Assuming this exists
              title: 'Health Prediction',
            ),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Enter Your Health Data",
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                // Adjusted style
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            _buildTextField(
                              "Age",
                              "Enter age in years",
                              _ageController,
                              TextInputType.number,
                              [FilteringTextInputFormatter.digitsOnly],
                            ),
                            SizedBox(height: 1.5.h),
                            _buildTextField(
                              "Systolic BP",
                              "e.g., 120",
                              _sbpController,
                              TextInputType.number,
                              [FilteringTextInputFormatter.digitsOnly],
                            ),
                            SizedBox(height: 1.5.h),
                            _buildTextField(
                              "Diastolic BP",
                              "e.g., 80",
                              _dbpController,
                              TextInputType.number,
                              [FilteringTextInputFormatter.digitsOnly],
                            ),
                            SizedBox(height: 1.5.h),
                            _buildTextField(
                              "Blood Sugar (BS)",
                              "e.g., 7.5",
                              _bsController,
                              TextInputType.numberWithOptions(decimal: true),
                              [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.5.h),
                            _buildTextField(
                              "Body Temperature",
                              "In Fahrenheit, e.g., 98.6",
                              _tempController,
                              TextInputType.numberWithOptions(decimal: true),
                              [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.5.h),
                            _buildTextField(
                              "Heart Rate",
                              "Beats per minute, e.g., 75",
                              _heartRateController,
                              TextInputType.number,
                              [FilteringTextInputFormatter.digitsOnly],
                            ),
                            SizedBox(height: 3.h),

                            // --- Button and Loading Indicator ---
                            if (viewModel.isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.pinkAccent,
                                ),
                              )
                            else
                              CustomButton(
                                // Assuming this exists
                                label: "Get Prediction",
                                onPressed: () {
                                  // Hide keyboard
                                  FocusScope.of(context).unfocus();
                                  if (_formKey.currentState?.validate() ==
                                      true) {
                                    // Call the ViewModel method to fetch prediction
                                    viewModel.fetchPredictionAndAdvice(
                                      age: int.parse(_ageController.text),
                                      systolicBP: int.parse(
                                        _sbpController.text,
                                      ),
                                      diastolicBP: int.parse(
                                        _dbpController.text,
                                      ),
                                      bs: double.parse(_bsController.text),
                                      bodyTemp: double.parse(
                                        _tempController.text,
                                      ),
                                      heartRate: int.parse(
                                        _heartRateController.text,
                                      ),
                                    );
                                    // DB saving is now handled within the ViewModel *after* successful API call
                                  }
                                },
                                color: Colors.pinkAccent,
                              ),
                            SizedBox(height: 3.h),

                            // --- Display Results or Error ---
                            if (viewModel.errorMessage != null)
                              Center(
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            if (viewModel.predictedRiskLevel != null)
                              _buildResultCard(context, viewModel),

                            SizedBox(height: 2.h), // Footer padding
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    TextInputType keyboardType,
    List<TextInputFormatter> formatters,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.pinkAccent.shade100,
          fontSize: 11.sp,
        ), // Slightly smaller label
        hintText: hint,
        hintStyle: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.pinkAccent.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
        ),
        errorStyle: TextStyle(fontSize: 9.sp), // Smaller error text
        isDense: true, // Makes field more compact
        contentPadding: EdgeInsets.symmetric(
          vertical: 1.5.h,
          horizontal: 3.w,
        ), // Adjust padding
      ),
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: TextStyle(fontSize: 11.sp), // Input text style
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Please enter $label';
        }
        // Optional: Add more specific validation (e.g., range checks)
        if (label == 'Age' && (int.tryParse(value!) ?? 0) < 10)
          return 'Age seems low';
        if (label == 'Systolic BP' && (int.tryParse(value!) ?? 0) < 50)
          return 'BP seems low';
        if (label == 'Diastolic BP' && (int.tryParse(value!) ?? 0) < 30)
          return 'BP seems low';
        if (label == 'Heart Rate' && (int.tryParse(value!) ?? 0) < 40)
          return 'Rate seems low';
        return null;
      },
    );
  }

  // --- Widget to display results ---
  Widget _buildResultCard(
    BuildContext context,
    RiskDetectorViewModel viewModel,
  ) {
    Color cardColor;
    IconData icon;

    switch (viewModel.predictedRiskLevel?.toLowerCase()) {
      case 'low risk':
        cardColor = Colors.green.shade100;
        icon = Icons.check_circle_outline;
        break;
      case 'mid risk':
        cardColor = Colors.orange.shade100;
        icon = Icons.warning_amber_rounded;
        break;
      case 'high risk':
        cardColor = Colors.red.shade100;
        icon = Icons.dangerous_outlined;
        break;
      default:
        cardColor = Colors.grey.shade200;
        icon = Icons.info_outline;
    }

    return Card(
      elevation: 3,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColorDark,
                  size: 20.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  "Prediction Result",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(
                          context,
                        ).primaryColorDark, // Darker color for contrast
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.h),
            Text(
              "Risk Level: ${viewModel.predictedRiskLevel ?? 'N/A'}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                // Make level stand out
                color: Theme.of(context).primaryColorDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              "Health Advice:",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600, // Bold title
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              viewModel.adviceMessage ?? "No advice available.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87, // Readable text color
                height: 1.4, // Line spacing
              ),
            ),
            // Optional: Display probabilities
            // if (viewModel.probabilities != null) ...[
            //   SizedBox(height: 2.h),
            //   Text("Probabilities:", style: Theme.of(context).textTheme.labelSmall),
            //   ...viewModel.probabilities!.entries.map((entry) => Text(
            //       "${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%",
            //       style: Theme.of(context).textTheme.labelSmall,
            //   )),
            // ]
          ],
        ),
      ),
    );
  }
}
