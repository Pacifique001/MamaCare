import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/pregnancy_detail_viewmodel.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:sizer/sizer.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart';
import 'package:intl/intl.dart'; // For date formatting if needed

class PregnancyDetailView extends StatefulWidget {
  const PregnancyDetailView({super.key});

  @override
  State<PregnancyDetailView> createState() => _PregnancyDetailViewState();
}

class _PregnancyDetailViewState extends State<PregnancyDetailView> {
  final _formKey = GlobalKey<FormState>();
  final _babyWeightController = TextEditingController();
  final _babyHeightController = TextEditingController();
  final _carouselController = CarouselSliderController();
  final Logger _logger = locator<Logger>();
  int _currentPage = 0;
  bool _initialDataLoaded = false; // Track if initial load attempted

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to access context safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Load existing data if available (optional, for editing scenario)
        // context.read<PregnancyDetailViewModel>().loadExistingData().then((_) {
        //   if (mounted) {
        //     _initializeControllers(); // Initialize after data loads
        //     setState(() => _initialDataLoaded = true );
        //   }
        // });
        // If not loading existing data, initialize immediately
        _initializeControllers();
        setState(() => _initialDataLoaded = true);
      }
    });
  }

  // Helper to initialize text controllers based on ViewModel state
  void _initializeControllers() {
    if (!mounted) return;
    final viewModel = context.read<PregnancyDetailViewModel>();
    if (viewModel.babyWeight != null) {
      _babyWeightController.text = viewModel.babyWeight!.toStringAsFixed(1);
    }
    if (viewModel.babyHeight != null) {
      _babyHeightController.text = viewModel.babyHeight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _babyWeightController.dispose();
    _babyHeightController.dispose();
    super.dispose();
  }

  // Snackbar helper
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Handle Final Submission
  Future<void> _handleFinalSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackbar("Please correct the errors.", isError: true);
      // Find first invalid field and go to its slide (more complex logic needed)
      // For simplicity, just show snackbar for now.
      return;
    }

    final viewModel = context.read<PregnancyDetailViewModel>();

    // Update VM state from controllers one last time before saving
    final weight = double.tryParse(_babyWeightController.text.trim());
    final height = double.tryParse(_babyHeightController.text.trim());
    if (weight != null) viewModel.onBabyWeightChanged(weight);
    if (height != null) viewModel.onBabyHeightChanged(height);

    // Ensure date was selected
    if (viewModel.startingDate == null) {
      _showSnackbar("Please select the start date.", isError: true);
      _carouselController.animateToPage(2);
      return;
    }

    _logger.i("Attempting to save/update pregnancy details...");
    // Use the renamed ViewModel method
    final success = await viewModel.addOrUpdatePregnancyDetail();

    if (!mounted) return;

    if (success) {
      _showSnackbar("Pregnancy details saved!");
      Navigator.pop(context);
    } else {
      _showSnackbar(
        viewModel.errorMessage ?? "Failed to save details.",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PregnancyDetailViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: AppColors.primaryLight.withOpacity(0.8),
          bottomNavigationBar: _buildBottomNavBar(viewModel),
          body: Stack(
            children: [
              // Only build Carousel once initial data load attempt is done
              if (_initialDataLoaded)
                Form(
                  key: _formKey,
                  child: CarouselSlider(
                    carouselController: _carouselController,
                    items: [
                      _buildBabyWeightSlide(viewModel, _babyWeightController),
                      _buildBabyHeightSlide(viewModel, _babyHeightController),
                      _buildCalendarSlide(viewModel),
                    ],
                    options: CarouselOptions(
                      height: 100.h,
                      enableInfiniteScroll: false,
                      viewportFraction: 1.0,
                      scrollPhysics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index, reason) {
                        setState(() => _currentPage = index);
                      },
                    ),
                  ),
                )
              else // Show loading indicator before initial data check
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Loading Overlay during save operation
              if (viewModel.isLoading)
                Opacity(
                  opacity: 0.7,
                  child: ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              if (viewModel.isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar(PregnancyDetailViewModel viewModel) {
    return BottomAppBar(
      color: AppColors.primary,
      elevation: 8.0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            Opacity(
              opacity: _currentPage > 0 ? 1.0 : 0.0, // Hide if on first page
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 30,
                ),
                tooltip: "Previous",
                // Disable if loading or on first page
                onPressed:
                    (viewModel.isLoading || _currentPage == 0)
                        ? null
                        : () {
                          _carouselController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          );
                        },
              ),
            ),
            // Indicator Text
            Text(
              "Step ${_currentPage + 1} of 3",
              style: TextStyles.bodyWhite.copyWith(fontWeight: FontWeight.bold),
            ),
            // Next / Done Button
            IconButton(
              icon: Icon(
                _currentPage == 2 ? Icons.check_rounded : Icons.chevron_right,
                color: Colors.white,
                size: 30,
              ),
              tooltip: _currentPage == 2 ? "Save Details" : "Next",
              onPressed:
                  viewModel.isLoading
                      ? null
                      : () {
                        if (_currentPage == 2) {
                          _handleFinalSubmit(); // Attempt to save
                        } else {
                          // Validate current slide before moving next (optional but good UX)
                          bool canMoveNext = true;
                          if (_currentPage == 0 &&
                              !(_formKey.currentState?.validate() ?? false)) {
                            // Manually trigger validation only for weight if needed
                            // For simplicity, often validation happens on final submit
                            // canMoveNext = false;
                            // _showSnackbar("Please enter valid weight.", isError: true);
                          } else if (_currentPage == 1 &&
                              !(_formKey.currentState?.validate() ?? false)) {
                            // Manually trigger validation only for height if needed
                            // canMoveNext = false;
                            // _showSnackbar("Please enter valid height.", isError: true);
                          }

                          if (canMoveNext) {
                            _carouselController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                          }
                        }
                      },
            ),
          ],
        ),
      ),
    );
  }

  // Takes ViewModel and controller
  Widget _buildBabyWeightSlide(
    PregnancyDetailViewModel viewModel,
    TextEditingController controller,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Baby's Estimated Weight",
                style: TextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5.h),
              // Image Card (keep as is)
              Card(
                /* ... */ child: Image.asset(
                  AssetsHelper.babyWeight,
                  height: 15.h,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: controller,
                style: TextStyles.bodyBold.copyWith(fontSize: 16.sp),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter Weight (e.g., 1.5)",
                  hintStyle: TextStyles.bodyGrey,
                  suffixText: "kg",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 2.h,
                    horizontal: 5.w,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter weight';
                  final number = double.tryParse(value.trim());
                  if (number == null) return 'Invalid number';
                  if (number <= 0)
                    return 'Weight must be positive'; // Add value validation
                  return null;
                },
                onChanged: (value) {
                  // Update VM on valid input change
                  final weight = double.tryParse(value);
                  if (weight != null) viewModel.onBabyWeightChanged(weight);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Takes ViewModel and controller
  Widget _buildBabyHeightSlide(
    PregnancyDetailViewModel viewModel,
    TextEditingController controller,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Baby's Estimated Height",
                style: TextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 5.h),
              // Image Card (keep as is)
              Card(
                /* ... */ child: Image.asset(
                  AssetsHelper.babyHeight,
                  height: 15.h,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: controller,
                style: TextStyles.bodyBold.copyWith(fontSize: 16.sp),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Enter Height (e.g., 30.5)",
                  hintStyle: TextStyles.bodyGrey,
                  suffixText: "cm",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 2.h,
                    horizontal: 5.w,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter height';
                  final number = double.tryParse(value.trim());
                  if (number == null) return 'Invalid number';
                  if (number <= 0)
                    return 'Height must be positive'; // Add value validation
                  return null;
                },
                onChanged: (value) {
                  // Update VM on valid input change
                  final height = double.tryParse(value);
                  if (height != null) viewModel.onBabyHeightChanged(height);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Takes ViewModel
  Widget _buildCalendarSlide(PregnancyDetailViewModel viewModel) {
    // *** Corrected Date Handling ***
    final DateTime firstAllowedDate = DateTime.now().subtract(
      const Duration(days: 365),
    );
    final DateTime lastAllowedDate = DateTime.now();
    // Use the DateTime directly from the ViewModel, provide default if null
    final DateTime initialDisplayDate =
        viewModel.startingDate ?? lastAllowedDate; // Default to today if null
    // Ensure the initial date is within bounds
    final DateTime validInitialDate =
        initialDisplayDate.isBefore(firstAllowedDate)
            ? firstAllowedDate
            : (initialDisplayDate.isAfter(lastAllowedDate)
                ? lastAllowedDate
                : initialDisplayDate);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "First Day of Last Period",
              style: TextStyles.headline2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CalendarDatePicker(
                  // Use the validated initial date
                  key: ValueKey(
                    validInitialDate.toIso8601String(),
                  ), // Key ensures widget updates if date changes externally
                  initialDate: validInitialDate,
                  firstDate: firstAllowedDate,
                  lastDate: lastAllowedDate,
                  onDateChanged: (dateTime) {
                    viewModel.onStartingDayChanged(
                      dateTime,
                    ); // Update ViewModel
                    _logger.d("Selected Start Date: $dateTime");
                  },
                  initialCalendarMode: DatePickerMode.day,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              "(Select the first day of your last menstrual period)",
              style: TextStyles.bodyWhite.copyWith(fontSize: 11.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
