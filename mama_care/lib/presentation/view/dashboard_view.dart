import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/appointment_status.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/presentation/viewmodel/dashboard_viewmodel.dart';
import 'package:mama_care/presentation/widgets/dashboard_card.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:mama_care/domain/entities/appointment.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/widgets/appointment_card.dart';
import 'package:mama_care/domain/entities/user_role.dart';
import 'package:flutter_svg/svg.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  DateTime _focusedCalendarDate = DateTime.now();
  int _drawerIndex = 0; // Default to Dashboard item index
  final Logger _logger = locator<Logger>();
  bool _hasInitiatedLoad = false; // Flag to prevent multiple load calls

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupFirebaseMessaging();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch both ViewModels for state changes
    final authVm = context.watch<AuthViewModel>();
    final dashboardVm = context.watch<DashboardViewModel>();
    // Get the userId reliably from the watched AuthViewModel
    final currentUserId = authVm.localUser?.id ?? authVm.currentUser?.uid;

    // Trigger Data Load When Auth is Ready (if not already initiated)
    if (currentUserId != null && !_hasInitiatedLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check mounted again inside callback
        if (mounted) {
          _initiateDashboardLoad(currentUserId);
        }
      });
    }

    final String currentScreenTitle = _getScreenTitleFromDrawerIndex(
      _drawerIndex,
    );

    return Scaffold(
      drawer: _buildNavigationDrawer(context, dashboardVm, authVm),
      appBar: MamaCareAppBar(
        title: currentScreenTitle,
        trailingWidget: _buildUserAvatar(authVm),
      ),
      floatingActionButton: _buildFab(context, dashboardVm),
      body: _buildBodyContent(context, dashboardVm, authVm, currentUserId),
    );
  }

  // Firebase Messaging Setup
  void _setupFirebaseMessaging() async {
    _logger.d("DashboardView: Setting up Firebase Messaging...");
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      _logger.i(
        "DashboardView: Notification permission status: ${settings.authorizationStatus}",
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Handle any messages that caused the app to open
        RemoteMessage? initialMessage =
            await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _logger.i("DashboardView: Handling initial FCM message.");
          _handleMessageOpenedApp(initialMessage);
        }

        _logger.d("DashboardView: Firebase Messaging listeners attached.");
      } else {
        _logger.w("DashboardView: User denied notification permissions.");
      }
    } catch (e, stackTrace) {
      _logger.e(
        "DashboardView: Firebase Messaging setup failed",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _logger.d("DashboardView: Foreground FCM received: ${message.messageId}");
    final notification = message.notification;
    if (notification != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${notification.title ?? 'Notification'}: ${notification.body ?? ''}',
          ),
          backgroundColor: AppColors.primary.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    _refreshDataFromFcmIfNeeded(message.data);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _logger.i("DashboardView: FCM message opened app: ${message.messageId}");
    final route = message.data['route'] as String?;
    if (route != null && mounted) {
      _logger.i("DashboardView: Navigating via FCM data: $route");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<DashboardViewModel>().navigateToRoute(
            route,
            arguments: message.data,
          );
        }
      });
    } else {
      _logger.w(
        "FCM opened app message has no 'route' data or widget not mounted.",
      );
    }
    _refreshDataFromFcmIfNeeded(message.data);
  }

  void _refreshDataFromFcmIfNeeded(Map<String, dynamic> data) {
    if (data['refresh'] == 'appointments' || data['refresh'] == 'all') {
      final authVm = context.read<AuthViewModel>();
      final userId = authVm.localUser?.id ?? authVm.currentUser?.uid;
      if (userId != null && mounted) {
        _logger.i("DashboardView: Refreshing data due to FCM payload.");
        context.read<DashboardViewModel>().loadData(userId: userId);
      }
    }
  }

  // Data Loading
  void _initiateDashboardLoad(String userId) {
    if (!_hasInitiatedLoad && mounted) {
      setState(() {
        _hasInitiatedLoad = true;
      });
      _logger.d(
        "DashboardView: Auth ready, User ID ($userId). Initiating data load.",
      );

      context.read<DashboardViewModel>().loadData(userId: userId).catchError((
        e,
        s,
      ) {
        _logger.e(
          "Error during initial dashboard data load",
          error: e,
          stackTrace: s,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to load dashboard data: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  // UI Building Methods
  String _getScreenTitleFromDrawerIndex(int index) {
    switch (index) {
      case 0:
        return "Dashboard";
      case 1:
        return "Calendar";
      case 2:
        return "Timeline";
      case 3:
        return "Profile";
      default:
        return "MamaCare";
    }
  }

  Widget? _buildFab(BuildContext context, DashboardViewModel vm) {
    if (vm.user != null && (_drawerIndex == 0 || _drawerIndex == 1)) {
      return FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Appointment',
        onPressed: vm.navigateToAddAppointment,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  Widget _buildUserAvatar(AuthViewModel authVm) {
    final user = authVm.localUser;
    final photoUrl = user?.profileImageUrl;
    final nameInitial =
        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primaryLight.withOpacity(0.2),
        backgroundImage:
            (photoUrl != null && photoUrl.isNotEmpty)
                ? CachedNetworkImageProvider(photoUrl)
                : null,
        child:
            (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                  nameInitial,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
                : null,
      ),
    );
  }

  // Main body content
  Widget _buildBodyContent(
    BuildContext context,
    DashboardViewModel dashboardVm,
    AuthViewModel authVm,
    String? currentUserId,
  ) {
    // Handle various states with appropriate UI response

    // User logged out after initial load
    if (currentUserId == null && _hasInitiatedLoad) {
      _logger.w("DashboardView: Building content after logout detected.");
      return const SizedBox.shrink(); // Let AuthWrapper handle redirection
    }

    // Waiting for initial Auth state before load attempt
    if (currentUserId == null && !_hasInitiatedLoad) {
      _logger.d("DashboardView: Displaying initial loading indicator.");
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Dashboard VM loading its data after userId is known
    if (dashboardVm.isLoading &&
        dashboardVm.user == null &&
        _hasInitiatedLoad) {
      _logger.d("DashboardView: Displaying dashboard data loading indicator.");
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Critical error loading dashboard data
    if (dashboardVm.error != null && dashboardVm.user == null) {
      _logger.w(
        "DashboardView: Displaying critical dashboard error screen - ${dashboardVm.error}",
      );

      if (currentUserId != null) {
        return _buildErrorWidget(
          context,
          dashboardVm.error!,
          () => dashboardVm.loadData(userId: currentUserId),
        );
      } else {
        // Fallback if something went wrong
        return _buildErrorWidget(
          context,
          "Session error occurred. Please retry.",
          () => authVm.logout(),
        );
      }
    }

    // Defensive check for null userId
    if (currentUserId == null) {
      _logger.e(
        "DashboardView: FATAL - Reached content build with null userId unexpectedly.",
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          authVm.logout();
          Navigator.pushNamedAndRemoveUntil(
            context,
            NavigationRoutes.login,
            (route) => false,
          );
        }
      });
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Main content display when everything is ready
    _logger.d("DashboardView: Building main content for user $currentUserId");
    return _buildMainContent(dashboardVm, authVm, currentUserId);
  }

  Widget _buildMainContent(
    DashboardViewModel dashboardVm,
    AuthViewModel authVm,
    String currentUserId,
  ) {
    return RefreshIndicator(
      onRefresh: () => dashboardVm.loadData(userId: currentUserId),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWelcomeHeader(authVm),
          const SizedBox(height: 16),

          // Pregnancy Details Section
          dashboardVm.pregnancyDetails == null
              ? _buildAddDetailsCard(context, dashboardVm)
              : _buildPregnancyContent(context, dashboardVm),

          const SizedBox(height: 24),

          // Appointments Section
          _buildAppointmentsSection(
            context,
            dashboardVm,
            currentUserId,
            authVm.userRole,
          ),

          const SizedBox(height: 24),

          // Features Grid
          _buildDashboardGrid(context, dashboardVm),

          const SizedBox(height: 80), // Padding for FAB visibility
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(AuthViewModel authVm) {
    final name = authVm.localUser?.name.split(' ').first ?? "User";
    return Text(
      "Hi $name 👋,",
      style: TextStyles.headline2.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildAddDetailsCard(BuildContext context, DashboardViewModel vm) {
    return Card(
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: vm.navigateToPregnancyDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Add your pregnancy details to get personalized insights!",
                  style: TextStyles.titleWhite,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPregnancyContent(BuildContext context, DashboardViewModel vm) {
    if (vm.pregnancyDetails == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeekInfo(context, vm.pregnancyDetails!),
        const SizedBox(height: 20),
        _buildCalendar(context, vm),
        const SizedBox(height: 20),
        _buildBabyInfoCard(context, vm.pregnancyDetails!),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text("Update Pregnancy Details"),
            onPressed:
                () => Navigator.pushNamed(
                  context,
                  NavigationRoutes.pregnancy_detail,
                ),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekInfo(BuildContext context, PregnancyDetails details) {
    final weekNumber = context.read<DashboardViewModel>().currentWeek;
    return Text(
      "$weekNumber${_getDaySuffix(weekNumber)} Week of Pregnancy",
      style: TextStyles.headline1.copyWith(color: AppColors.primary),
    );
  }

  Widget _buildCalendar(BuildContext context, DashboardViewModel vm) {
    final focusedDay = _focusedCalendarDate;
    final firstDay = DateTime.utc(focusedDay.year, focusedDay.month - 3, 1);
    final lastDay = DateTime.utc(focusedDay.year, focusedDay.month + 6, 0);

    return TableCalendar<Appointment>(
      focusedDay: focusedDay,
      firstDay: firstDay,
      lastDay: lastDay,
      calendarFormat: CalendarFormat.week,
      headerVisible: false,
      daysOfWeekVisible: true,
      rowHeight: 65,
      selectedDayPredicate: (day) => isSameDay(focusedDay, day),
      onDaySelected: (selectedDay, newFocusedDay) {
        if (!isSameDay(_focusedCalendarDate, selectedDay)) {
          setState(() {
            _focusedCalendarDate = newFocusedDay;
          });
          _logger.d("Calendar day selected/focused: $_focusedCalendarDate");
        }
      },
      onPageChanged: (newFocusedDay) {
        setState(() {
          _focusedCalendarDate = newFocusedDay;
        });
      },
      eventLoader:
          (day) =>
              vm.appointments.where((appt) {
                final DateTime apptDateTime = appt.dateTime.toDate();
                return isSameDay(apptDateTime, day);
              }).toList(),
      calendarBuilders: CalendarBuilders<Appointment>(
        defaultBuilder: (_, day, __) => _CalendarDayWidget(day: day),
        todayBuilder:
            (_, day, __) => _CalendarDayWidget(day: day, isToday: true),
        selectedBuilder:
            (_, day, __) => _CalendarDayWidget(day: day, isSelected: true),
        outsideBuilder:
            (_, day, __) => _CalendarDayWidget(day: day, isOutside: true),
        markerBuilder: (_, day, events) => _buildEventMarker(events),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: const BoxDecoration(shape: BoxShape.circle),
        selectedDecoration: const BoxDecoration(shape: BoxShape.circle),
        outsideDaysVisible: false,
        defaultTextStyle: TextStyle(fontSize: 11.sp),
        weekendTextStyle: TextStyle(fontSize: 11.sp, color: AppColors.primary),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyles.smallGrey,
        weekendStyle: TextStyles.smallGrey.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget? _buildEventMarker(List<Appointment> appointments) {
    if (appointments.isEmpty) return null;

    return Positioned(
      right: 6,
      bottom: 6,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildBabyInfoCard(BuildContext context, PregnancyDetails details) {
    final weekNumber = context.read<DashboardViewModel>().currentWeek;
    String babySizeComparison = _getBabySizeComparison(weekNumber);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.1),
                ),
                child: SvgPicture.asset(
                  AssetsHelper.maternalImage,
                  height: 36,
                  width: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Baby is about the size of a $babySizeComparison",
                  style: TextStyles.bodyBold.copyWith(fontSize: 12.sp),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: AppColors.greyLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BabyInfoColumnWidget(
                title: "Est. Height",
                value: details.babyHeight?.toStringAsFixed(1) ?? "--",
                unit: "cm",
              ),
              _BabyInfoColumnWidget(
                title: "Est. Weight",
                value: details.babyWeight?.toStringAsFixed(1) ?? "--",
                unit: "kg",
              ),
              _TimeRemainingMetricsWidget(details: details),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsSection(
    BuildContext context,
    DashboardViewModel vm,
    String userId,
    UserRole userRole,
  ) {
    final now = DateTime.now();
    final upcomingAppointments =
        vm.appointments.where((a) {
          final DateTime displayTime = a.dateTime.toDate();
          final todayDateOnly = DateTime(now.year, now.month, now.day);
          final apptDateOnly = DateTime(
            displayTime.year,
            displayTime.month,
            displayTime.day,
          );

          bool isTodayOrLater = !apptDateOnly.isBefore(todayDateOnly);
          bool isRelevantStatus =
              a.status == AppointmentStatus.pending ||
              a.status == AppointmentStatus.confirmed ||
              a.status == AppointmentStatus.scheduled;

          return isTodayOrLater && isRelevantStatus;
        }).toList();

    // Sort by date
    upcomingAppointments.sort((a, b) {
      final DateTime timeA = a.dateTime.toDate();
      final DateTime timeB = b.dateTime.toDate();
      return timeA.compareTo(timeB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upcoming Appointments', style: TextStyles.title),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
                tooltip: 'Add Appointment',
                onPressed: vm.navigateToAddAppointment,
              ),
            ],
          ),
        ),

        upcomingAppointments.isEmpty
            ? _buildNoAppointmentsPlaceholder(context, vm)
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  upcomingAppointments.length > 3
                      ? 3
                      : upcomingAppointments.length,
              itemBuilder: (context, index) {
                final appt = upcomingAppointments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppointmentCard(
                    appointment: appt,
                    userRole: userRole,
                    currentUserId: userId,
                    onTap: () {
                      _logger.d("Tapped upcoming appointment: ${appt.id}");
                    },
                  ),
                );
              },
            ),

        if (upcomingAppointments.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => vm.navigateToRoute(NavigationRoutes.calendar),
              child: Text("View All", style: TextStyles.linkText),
            ),
          ),
      ],
    );
  }

  Widget _buildNoAppointmentsPlaceholder(
    BuildContext context,
    DashboardViewModel vm,
  ) {
    return InkWell(
      onTap: vm.navigateToAddAppointment,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.edit_calendar_outlined,
              size: 48,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 16),
            Text('No upcoming appointments', style: TextStyles.bodyGrey),
            const SizedBox(height: 8),
            Text(
              'Tap here to schedule one',
              style: TextStyles.smallGrey,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid(BuildContext context, DashboardViewModel vm) {
    final List<_DashboardGridItemData> gridItems = [
      _DashboardGridItemData(
        icon: Icons.monitor_heart_outlined,
        label: "Prediction",
        route: NavigationRoutes.predictor,
      ),
      _DashboardGridItemData(
        icon: Icons.local_hospital_outlined,
        label: "Hospitals",
        route: NavigationRoutes.map,
      ),
      _DashboardGridItemData(
        icon: Icons.fitness_center_outlined,
        label: "Exercises",
        route: NavigationRoutes.exercise,
      ),
      _DashboardGridItemData(
        icon: Icons.article_outlined,
        label: "Articles",
        route: NavigationRoutes.articleList,
      ),
      _DashboardGridItemData(
        icon: Icons.play_circle_outline,
        label: "Videos",
        route: NavigationRoutes.video_list,
      ),
      _DashboardGridItemData(
        icon: Icons.restaurant_menu_outlined,
        label: "Food Guide",
        route: NavigationRoutes.food,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: gridItems.length,
      itemBuilder: (context, index) {
        final item = gridItems[index];
        return _DashboardGridItemWidget(
          icon: item.icon,
          label: item.label,
          onTap: () => vm.navigateToRoute(item.route),
        );
      },
    );
  }

  Widget _buildNavigationDrawer(
    BuildContext context,
    DashboardViewModel dashboardVm,
    AuthViewModel authVm,
  ) {
    final List<_DrawerItemData> drawerItems = [
      _DrawerItemData(
        index: 0,
        icon: Icons.dashboard_outlined,
        label: "Dashboard",
      ),
      _DrawerItemData(
        index: 1,
        icon: Icons.calendar_today_outlined,
        label: "Calendar",
        route: NavigationRoutes.calendar,
      ),
      _DrawerItemData(
        index: 2,
        icon: Icons.view_timeline_outlined,
        label: "Timeline",
        route: NavigationRoutes.timeline,
      ),
      _DrawerItemData(
        index: 3,
        icon: Icons.person_outline_rounded,
        label: "Profile",
        route: NavigationRoutes.profile,
      ),
      _DrawerItemData(index: 4, icon: Icons.logout, label: "Logout"),
    ];

    final user = authVm.localUser;
    final userName = user?.name ?? "MamaCare User";
    final userEmail = user?.email ?? "";
    final userPhotoUrl = user?.profileImageUrl;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName, style: TextStyles.titleWhite),
            accountEmail: Text(userEmail, style: TextStyles.bodyWhite),
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.accent.withOpacity(0.8),
              backgroundImage:
                  (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
                      ? CachedNetworkImageProvider(userPhotoUrl)
                      : null,
              child:
                  (userPhotoUrl == null || userPhotoUrl.isEmpty)
                      ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          ...drawerItems.map((item) {
            bool isSelected = _drawerIndex == item.index;
            return ListTile(
              leading: Icon(
                item.icon,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
              selected: isSelected,
              selectedTileColor: AppColors.primaryLight.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                if (item.label == "Logout") {
                  _logger.i("Logout tapped from drawer.");
                  // Perform logout AND navigate explicitly
                  authVm.logout().then((_) {
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        NavigationRoutes.login,
                        (route) => false,
                      );
                    }
                  });
                } else if (item.route != null) {
                  if (_drawerIndex != item.index) {
                    setState(() => _drawerIndex = item.index);
                    dashboardVm.navigateToRoute(item.route!);
                  }
                } else if (_drawerIndex != item.index) {
                  // For items like Dashboard itself
                  setState(() => _drawerIndex = item.index);
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- Calculation and Formatting Helpers ---
  String _getDaySuffix(int day) {
    // Keep implementation as is
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getBabySizeComparison(int week) {
    // Keep implementation as is
    if (week <= 6) return "Poppy Seed";
    if (week <= 8) return "Raspberry";
    if (week <= 10) return "Prune";
    if (week <= 12) return "Lime";
    if (week <= 14) return "Lemon";
    if (week <= 16) return "Avocado";
    if (week <= 18) return "Sweet Potato";
    if (week <= 20) return "Banana";
    if (week <= 24) return "Corn Cob";
    if (week <= 28) return "Eggplant";
    if (week <= 32) return "Squash";
    if (week <= 36) return "Honeydew Melon";
    return "Watermelon";
  }
} // End of _DashboardViewState

class _CalendarDayWidget extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;
  const _CalendarDayWidget({
    required this.day,
    this.isToday = false,
    this.isSelected = false,
    this.isOutside = false,
  });
  @override
  Widget build(BuildContext context) {
    final Color textColor =
        isSelected
            ? Colors.white
            : (isToday
                ? AppColors.primary
                : (isOutside
                    ? AppColors.textGrey.withOpacity(0.5)
                    : Colors.black87));
    final Color backgroundColor =
        isSelected ? AppColors.primary : Colors.transparent;
    final FontWeight fontWeight =
        isToday || isSelected ? FontWeight.bold : FontWeight.normal;
    return Container(
      margin: const EdgeInsets.all(3.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border:
            isToday && !isSelected
                ? Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1.5,
                )
                : null,
      ),
      child: Text(
        '${day.day}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class _BabyInfoColumnWidget extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  const _BabyInfoColumnWidget({
    required this.title,
    required this.value,
    this.unit,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyles.smallGrey.copyWith(fontSize: 10.sp)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyles.bodyBold.copyWith(fontSize: 13.sp)),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(
                unit!,
                style: TextStyles.smallGrey.copyWith(fontSize: 10.sp),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DashboardGridItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DashboardGridItemWidget({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: DashboardCard(icon: icon, name: label),
    );
  }
}

class _DrawerItemData {
  final int index;
  final IconData icon;
  final String label;
  final String? route;
  const _DrawerItemData({
    required this.index,
    required this.icon,
    required this.label,
    this.route,
  });
}

Widget _buildErrorWidget(
  BuildContext context,
  String errorMsg,
  VoidCallback onRetry,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
          const SizedBox(height: 16),
          Text(
            "Error Loading Data",
            style: TextStyles.title.copyWith(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            errorMsg,
            style: TextStyles.bodyGrey,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashboardGridItemData {
  final IconData icon;
  final String label;
  final String route;
  const _DashboardGridItemData({
    required this.icon,
    required this.label,
    required this.route,
  });
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
