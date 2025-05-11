// lib/presentation/view/profile_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart'; // Assuming used in AssetsHelper/widgets
import 'package:image_picker/image_picker.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/presentation/widgets/appointment_card.dart'; // Assuming used elsewhere or remove
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mama_care/presentation/viewmodel/profile_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/utils/asset_helper.dart'; // Assuming exists
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart'; // Assuming exists
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:mama_care/domain/entities/user_model.dart';
import 'package:mama_care/utils/app_colors.dart'; // Assuming exists
import 'package:mama_care/utils/text_styles.dart'; // Assuming exists
import 'package:mama_care/presentation/widgets/custom_text_field.dart'; // Assuming exists
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart'; // Assuming exists
import 'package:table_calendar/table_calendar.dart';

// --- Helper Extension for Capitalization ---
// Put this outside the class, maybe in a general utils file
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final Logger _logger = locator<Logger>();

  @override
  void initState() {
    super.initState();
    // Fetch data when the view model is ready, if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileVm = Provider.of<ProfileViewModel>(context, listen: false);
      // Check if details are null before fetching to avoid redundant calls
      if (profileVm.pregnancyDetails == null &&
          profileVm.viewState != ViewState.loading) {
        profileVm.getPregnancyDetails();
      }
    });
  }

  Future<void> _pickImage(ProfileViewModel viewModel) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        viewModel.setImageFilePath(pickedFile.path);
      } else {
        _logger.i("Image picking cancelled by user.");
      }
    } catch (e, s) {
      _logger.e("Error picking image", error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not pick image."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileViewModel, AuthViewModel>(
      builder: (context, profileViewModel, authViewModel, child) {
        final user = authViewModel.localUser;

        return Scaffold(
          appBar: _buildAppBar(context, profileViewModel, authViewModel),
          body: _buildContent(context, profileViewModel, authViewModel, user),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ProfileViewModel profileVm,
    AuthViewModel authVm,
  ) {
    return MamaCareAppBar(
      title: "My Profile",
      titleStyle: TextStyles.appBarTitle,
      automaticallyImplyLeading: true,
      actions: [
        if (profileVm.isEditing)
          TextButton(
            onPressed: profileVm.isLoading ? null : profileVm.cancelEditing,
            child: Text(
              "Cancel",
              style: TextStyle(
                color: authVm.isLoading ? Colors.grey : AppColors.primary,
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit Profile",
            onPressed: authVm.localUser == null ? null : profileVm.startEditing,
          ),
        if (profileVm.isEditing)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed:
                  authVm.isLoading || profileVm.isLoading
                      ? null
                      : () async {
                        // Check both loading states
                        final success =
                            await profileVm.saveUserProfileChanges();
                        if (!mounted) return; // Check mount status AFTER await
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                profileVm.errorMessage ??
                                    "Failed to save changes",
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Profile updated!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
              child: Text(
                "Save",
                style: TextStyle(
                  color:
                      authVm.isLoading || profileVm.isLoading
                          ? Colors.grey
                          : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProfileViewModel profileVm,
    AuthViewModel authVm,
    UserModel? user,
  ) {
    if (authVm.isLoading && user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (authVm.errorMessage != null && user == null) {
      return _buildErrorWidget(
        "Error loading profile: ${authVm.errorMessage}",
        authVm.clearError,
      );
    }
    if (user == null) {
      return _buildErrorWidget(
        "User data not available. Please log in again.",
        () {
          authVm.logout();
          // Ensure router is accessible or use direct navigation
          Navigator.pushNamedAndRemoveUntil(
            context,
            NavigationRoutes.login,
            (route) => false,
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: profileVm.refreshData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildUserProfileHeader(context, profileVm, authVm, user),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildPregnancySection(context, profileVm),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(
              Icons.bookmark_border,
              color: AppColors.primary,
            ),
            title: Text("My Saved Content", style: TextStyles.bodyBold),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _logger.w("Navigation to Saved Content not implemented.");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Saved Content screen not implemented."),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
              color: AppColors.textGrey,
            ),
            title: Text("Settings", style: TextStyles.body),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _logger.w("Navigation to Settings ");

              Navigator.pushNamed(context, NavigationRoutes.editScreen);
            },
          ),
          const Divider(),
          // Optional Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                "Log Out",
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                await authVm.logout();
                // Navigate back to login after logout
                if (mounted) {
                  // Check mount status before navigating
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    NavigationRoutes.login,
                    (route) => false,
                  );
                }
              },
              style: TextButton.styleFrom(padding: const EdgeInsets.all(15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader(
    BuildContext context,
    ProfileViewModel profileVm,
    AuthViewModel authVm,
    UserModel user,
  ) {
    final bool isEditing = profileVm.isEditing;
    final imagePath = profileVm.selectedImageFilePath;
    // Use the user model passed from AuthViewModel for the initial image URL
    final imageUrl = user.profileImageUrl;
    File? imageFile = imagePath != null ? File(imagePath) : null;

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 55.sp,
                backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                backgroundImage:
                    imageFile != null
                        ? FileImage(imageFile) as ImageProvider
                        : (imageUrl != null && imageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(imageUrl)
                            : null),
                child:
                    (imageFile == null &&
                            (imageUrl == null || imageUrl.isEmpty))
                        ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 40.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              if (isEditing)
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _pickImage(profileVm),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!isEditing) ...[
          Text(
            user.name,
            style: TextStyles.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyles.bodyGrey,
            textAlign: TextAlign.center,
          ),
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.phoneNumber!,
              style: TextStyles.bodyGrey,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            StringExtension(user.role.name).capitalize(),
            style: TextStyles.smallPrimary.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          // Use VM controllers guaranteed to be non-null in edit mode
          CustomTextField(
            controller: profileVm.nameController!,
            hint: "Full Name",
            prefixIcon: const Icon(Icons.person_outline),
            validator:
                (v) => v == null || v.isEmpty ? "Name cannot be empty" : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: profileVm.phoneController!,
            hint: "Phone Number (e.g., +1...)",
            prefixIcon: const Icon(Icons.phone_outlined),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator:
                (v) =>
                    v != null && v.isNotEmpty && !authVm.validatePhoneNumber(v)
                        ? "Invalid format"
                        : null,
          ),
        ],
      ],
    );
  }

  Widget _buildPregnancySection(
    BuildContext context,
    ProfileViewModel profileVm,
  ) {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final user = authVm.localUser;

    if (user?.role != UserRole.patient) {
      return const SizedBox.shrink();
    }

    return Selector<ProfileViewModel, ViewState>(
      selector: (_, vm) => vm.viewState,
      builder: (context, state, _) {
        if (state == ViewState.loading && profileVm.pregnancyDetails == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Loading pregnancy details..."),
            ),
          );
        }

        final details = profileVm.pregnancyDetails;

        if (details == null) {
          if (!profileVm.isEditing) {
            return Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
                title: const Text("Track Your Pregnancy"),
                subtitle: const Text("Add your details to get started."),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      NavigationRoutes.pregnancy_detail,
                    ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // Add row for title and edit button
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Pregnancy Progress", style: TextStyles.title),
                IconButton(
                  // Use IconButton for consistency
                  icon: const Icon(
                    Icons.edit_note,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  tooltip: "Update Pregnancy Details",
                  onPressed:
                      () => Navigator.pushNamed(
                        context,
                        NavigationRoutes.pregnancy_detail,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PregnancyCalendarWidget(details: details),
            const SizedBox(height: 16),
            _BabyInfoCardWidget(details: details),
            const SizedBox(height: 16),
            // Removed redundant button from here
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyles.bodyGrey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Re-usable Widgets (_PregnancyCalendarWidget, _CalendarDayWidget, _BabyInfoCardWidget, _MetricRowWidget, _TimeRemainingMetricsWidget, _TimeMetricWidget) ---
// Keep these implementations as they were, they seem correct based on the structure.
// Ensure they use the corrected TextStyles.

class _PregnancyCalendarWidget extends StatelessWidget {
  final PregnancyDetails details;
  const _PregnancyCalendarWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    final startDate = details.startingDay;
    final today = DateTime.now();
    final focusedDay =
        (today.isAfter(startDate!) && today.isBefore(details.dueDate!))
            ? today
            : startDate;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: TableCalendar(
          headerVisible: false,
          daysOfWeekVisible: true,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyles.smallGrey,
            weekendStyle: TextStyles.smallGrey.copyWith(
              color: AppColors.primary,
            ),
          ),
          focusedDay: focusedDay!,
          firstDay: startDate!,
          lastDay: details.dueDate!,
          calendarFormat: CalendarFormat.week,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarBuilders: CalendarBuilders(
            todayBuilder:
                (context, day, _) => _CalendarDayWidget(
                  day: day,
                  startDate: startDate!,
                  isToday: true,
                ),
            defaultBuilder:
                (context, day, _) => _CalendarDayWidget(
                  day: day,
                  startDate: startDate!,
                  isToday: false,
                ),
            outsideBuilder:
                (context, day, _) => Opacity(
                  opacity: 0.5,
                  child: _CalendarDayWidget(
                    day: day,
                    startDate: startDate!,
                    isToday: false,
                  ),
                ),
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(shape: BoxShape.circle),
            outsideDaysVisible: false,
          ),
        ),
      ),
    );
  }
}

class _CalendarDayWidget extends StatelessWidget {
  final DateTime day;
  final DateTime startDate;
  final bool isToday;
  const _CalendarDayWidget({
    required this.day,
    required this.startDate,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isToday ? Colors.white : Colors.black87;
    final Color backgroundColor =
        isToday ? AppColors.primary : Colors.transparent;
    return Container(
      margin: const EdgeInsets.all(3.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border:
            isToday ? null : Border.all(color: AppColors.greyLight, width: 0.5),
      ),
      child: Text(
        '${day.day}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _BabyInfoCardWidget extends StatelessWidget {
  final PregnancyDetails details;
  const _BabyInfoCardWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.1),
            ),
            child: SvgPicture.asset(
              AssetsHelper.maternalImage,
              height: 40,
              width: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricRowWidget(
                  label: "Baby Weight Est.",
                  value: details.babyWeight!.toStringAsFixed(1),
                  unit: "kg",
                ),
                const SizedBox(height: 10),
                _MetricRowWidget(
                  label: "Baby Height Est.",
                  value: details.babyHeight!.toStringAsFixed(1),
                  unit: "cm",
                ),
                const SizedBox(height: 10),
                _TimeRemainingMetricsWidget(details: details),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _MetricRowWidget({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyles.smallGrey.copyWith(fontSize: 10.sp)),
        Text(
          "$value $unit",
          style: TextStyles.bodyBold.copyWith(fontSize: 13.sp),
        ),
      ],
    );
  }
}

class _TimeRemainingMetricsWidget extends StatelessWidget {
  final PregnancyDetails details;
  const _TimeRemainingMetricsWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    final daysRemaining = details.daysRemaining ?? 0;
    final weeksRemaining = (daysRemaining / 7).floor();
    return Row(
      children: [
        _TimeMetricWidget(label: "Days Left", value: daysRemaining.toString()),
        SizedBox(width: 4.w),
        _TimeMetricWidget(
          label: "Weeks Left",
          value: weeksRemaining.toString(),
        ),
      ],
    );
  }
}

class _TimeMetricWidget extends StatelessWidget {
  final String label;
  final String value;
  const _TimeMetricWidget({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyles.smallGrey.copyWith(fontSize: 10.sp)),
        Text(value, style: TextStyles.bodyBold.copyWith(fontSize: 13.sp)),
      ],
    );
  }
}
