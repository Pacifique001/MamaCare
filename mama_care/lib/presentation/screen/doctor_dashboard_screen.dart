// lib/presentation/screen/doctor_dashboard_screen.dart

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/presentation/viewmodel/doctor_dashboard_viewmodel.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/presentation/widgets/appointment_card.dart';
import 'package:mama_care/presentation/widgets/nurse_assignment_card.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/domain/entities/appointment_status.dart'; // Import AppointmentStatus enum
import 'package:mama_care/presentation/widgets/nurse_assignment_header.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:flutter_svg/svg.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final Logger _logger = locator<Logger>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoadingData = false;
  bool _hasAttemptedLoad = false;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDataWithCheck();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _loadInitialDataWithCheck() {
    if (!mounted) return;
    final authViewModel = context.read<AuthViewModel>();
    final doctorId =
        authViewModel.localUser?.id ?? authViewModel.currentUser?.uid;

    if (doctorId != null && doctorId.isNotEmpty) {
      _logger.d(
        "DoctorDashboardScreen: Doctor ID available ($doctorId). Loading data.",
      );
      setState(() {
        _isLoadingData = true;
        _hasAttemptedLoad = true;
      });

      Provider.of<DoctorDashboardViewModel>(context, listen: false)
          .loadData(doctorId)
          .whenComplete(() {
            if (mounted) {
              setState(() {
                _isLoadingData = false;
              });
            }
          })
          .catchError((error, stackTrace) {
            _logger.e(
              "Error loading doctor dashboard data",
              error: error,
              stackTrace: stackTrace,
            );
            if (mounted) {
              setState(() {
                _isLoadingData = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error loading data: $error"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
    } else {
      _logger.w(
        "DoctorDashboardScreen: Doctor ID not yet available. Waiting for AuthViewModel update.",
      );
    }
  }

  void _navigateTo(String routeName, {Object? arguments}) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final doctorUser = authViewModel.localUser;
    final permissions = authViewModel.userPermissions;
    final doctorId =
        doctorUser?.id ??
        authViewModel.currentUser?.uid; // Safely get the DoctorId

    // Ensure we're trying to load data if the ID is available
    if (!_hasAttemptedLoad && doctorId != null && doctorId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialDataWithCheck();
      });
    }

    // Render loading indicator if required
    if (doctorId == null || _isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text("Loading...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DoctorDashboardViewModel>(
          create: (_) => locator<DoctorDashboardViewModel>(),
        ),
      ],
      child: DefaultTabController(
        length: 1,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(
              doctorUser?.name ?? 'Doctor Dashboard',
            ), // Safely show doctor name
            backgroundColor:
                Theme.of(context).appBarTheme.backgroundColor ??
                AppColors.primary,
            foregroundColor:
                Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
            bottom: TabBar(
              indicatorColor: AppColors.accent,
              labelColor:
                  Theme.of(context).tabBarTheme.labelColor ?? AppColors.accent,
              unselectedLabelColor:
                  Theme.of(context).tabBarTheme.unselectedLabelColor ??
                  Colors.white70,
              labelStyle: TextStyles.bodyBold.copyWith(fontSize: 12.sp),
              unselectedLabelStyle: TextStyles.body.copyWith(fontSize: 12.sp),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Appointments'),
                    ],
                  ),
                ),
                // REMOVED Nurse Tab
              ],
            ),
          ),
          drawer: _buildDrawer(context, authViewModel),
          body: const TabBarView(children: [AppointmentManagementTab()]),
          // Only add FAB to Appointment Tab
          floatingActionButton: Builder(
            builder: (context) {
              //final tabIndex = DefaultTabController.of(context).index;
              bool canManageNurses =
                  permissions.contains('manage_nurses') ||
                  permissions.contains('assign_nurse');
              // Use manage_appointments instead for appointment tab
              bool canManageAppts = permissions.contains('manage_appointments');

              //  return FloatingActionButton(
              //    onPressed: () {  },
              //    tooltip: 'Block Schedule',
              //    child: const Icon(Icons.event_busy_outlined),
              //  );

              return FloatingActionButton(
                onPressed:
                    canManageAppts
                        ? () => _onFabPressed(context, 0, permissions)
                        : null,
                backgroundColor:
                    canManageAppts ? AppColors.accent : Colors.grey,
                foregroundColor:
                    canManageAppts ? Colors.black87 : Colors.grey.shade400,
                tooltip: 'Block Schedule', // Fixed tooltip
                child: const Icon(Icons.event_busy_outlined),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onFabPressed(
    BuildContext context,
    int tabIndex,
    List<String> permissions,
  ) {
    _logger.i("FAB tapped: Action for Appointments tab (e.g., Block Schedule)");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Schedule blocking feature not implemented."),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthViewModel authViewModel) {
    final doctorUser = authViewModel.localUser;
    final permissions = authViewModel.userPermissions;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              doctorUser?.name ?? 'Doctor',
              style: TextStyles.title.copyWith(color: Colors.white),
            ),
            accountEmail: Text(
              doctorUser?.email ?? '',
              style: TextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.accent.withOpacity(0.8),
              backgroundImage:
                  (doctorUser?.profileImageUrl != null &&
                          doctorUser!.profileImageUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(doctorUser.profileImageUrl!)
                      : null,
              child:
                  (doctorUser?.profileImageUrl == null ||
                          doctorUser!.profileImageUrl!.isEmpty)
                      ? Text(
                        doctorUser?.name.isNotEmpty == true
                            ? doctorUser!.name[0].toUpperCase()
                            : 'D',
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: Colors.black87,
                        ),
                      )
                      : null,
            ),
            decoration: const BoxDecoration(color: AppColors.primaryDark),
            otherAccountsPictures: [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white70,
                ),
                tooltip: "Settings",
                onPressed: () {
                  _logger.i("Settings icon tapped in drawer");
                },
              ),
            ],
          ),

          if (permissions.contains('view_profile'))
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile'),
              onTap: () => _navigateTo(NavigationRoutes.profile),
            ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),

          if (permissions.contains('view_all_patients'))
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('View Patients'),
              onTap: () {
                _logger.i("Navigate to Patient List (Placeholder)");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Patient list screen not implemented."),
                  ),
                );
              },
            ),

          if (permissions.contains('manage_nurses'))
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Manage Nurses'),
              onTap: () {
                _logger.i("Navigate to Nurse Management");
                _navigateTo(NavigationRoutes.nurseDetail);
              },
            ),

          if (permissions.contains('view_reports'))
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('View Reports'),
              onTap: () {
                _logger.i("Navigate to Reports (Placeholder)");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Reports screen not implemented."),
                  ),
                );
              },
            ),

          if (permissions.contains('edit_articles') ||
              permissions.contains('edit_videos')) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 5.0),
              child: Text(
                "Content Management",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (permissions.contains('edit_articles'))
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Edit Articles'),
                onTap: () {
                  _logger.i("Navigate to Article Editor");
                  _navigateTo(NavigationRoutes.articleList);
                },
              ),
            if (permissions.contains('edit_videos'))
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Edit Videos'),
                onTap: () {
                  _logger.i("Navigate to Video Editor");
                  _navigateTo(NavigationRoutes.video_list);
                },
              ),
          ],

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('Logout'),
            onTap: () {
              _logger.i("Logout tapped");
              context.read<AuthViewModel>().logout();
              _navigateTo(NavigationRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

// --- Tab 1: Appointment Management ---
class AppointmentManagementTab extends StatelessWidget {
  const AppointmentManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DoctorDashboardViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final doctorId = authViewModel.currentUser?.uid;

    if (doctorId == null) {
      return const Center(child: Text("Error: Doctor ID not found."));
    }

    return Column(
      children: [
        _buildStatusFilter(context, viewModel),
        Expanded(child: _buildAppointmentList(context, viewModel, doctorId)),
      ],
    );
  }

  Widget _buildAppointmentList(
    BuildContext context,
    DoctorDashboardViewModel viewModel,
    String doctorId,
  ) {
    final appointments = viewModel.filteredAppointments;
    final bool hasNoFilteredAppointments = appointments.isEmpty;
    final bool hasNoAppointmentsAtAll = viewModel.appointments.isEmpty;

    if (hasNoAppointmentsAtAll && viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (hasNoFilteredAppointments) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            viewModel.selectedFilterStatus == null
                ? "No appointments scheduled."
                : "No ${viewModel.selectedFilterStatus?.name} appointments found.",
            style: TextStyles.bodyGrey,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      key: PageStorageKey('appointments_${viewModel.selectedFilterStatus}'),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppointmentCard(
          appointment: appointment,
          userRole: UserRole.doctor,
          currentUserId: doctorId,
          onTap: () {
            // Optional: Navigate to detail view
          },
        );
      },
    );
  }

  Widget _buildStatusFilter(
    BuildContext context,
    DoctorDashboardViewModel viewModel,
  ) {
    final List<AppointmentStatus> allStatuses = AppointmentStatus.values;
    final AppointmentStatus? currentFilter = viewModel.selectedFilterStatus;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: SizedBox(
        height: 4.5.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: allStatuses.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            bool isSelected;
            String label;
            VoidCallback? onPressed;

            if (index == 0) {
              isSelected = currentFilter == null;
              label = 'All';
              onPressed = () {
                if (!isSelected) viewModel.setStatusFilter(null);
              };
            } else {
              final status = allStatuses[index - 1];
              isSelected = currentFilter == status;
              label = StringExtension(status.name).capitalize();
              onPressed = () {
                if (!isSelected) viewModel.setStatusFilter(status);
              };
            }

            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onPressed?.call();
              },
              selectedColor: AppColors.primaryLight.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textGrey,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              showCheckmark: false,
              backgroundColor: Colors.white,
              elevation: isSelected ? 1 : 0,
              padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 0.5.h),
            );
          },
        ),
      ),
    );
  }
}

// --- Tab 2: Nurse Management ---
class NurseManagementTab extends StatelessWidget {
  const NurseManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Nurse management moved to sidebar for better access."),
    );
  }
}

// --- Extension ---
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
