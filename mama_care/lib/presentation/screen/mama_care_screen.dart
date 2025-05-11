import 'package:flutter/material.dart';
import 'package:mama_care/presentation/screen/calendar_screen.dart';
import 'package:mama_care/presentation/screen/dashboard_screen.dart';
import 'package:mama_care/presentation/screen/profile_screen.dart';
import 'package:mama_care/presentation/screen/timeline_screen.dart';
// Assuming AppColors are still needed, otherwise rely on Theme
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/theme_controller.dart'; // Import ThemeController
import 'package:provider/provider.dart'; // Import Provider
import 'package:flutter/services.dart'; // For HapticFeedback

class MamaCareScreen extends StatefulWidget {
  const MamaCareScreen({super.key});

  @override
  State<MamaCareScreen> createState() => _MamaCareScreenState();
}

class _MamaCareScreenState extends State<MamaCareScreen>
    with TickerProviderStateMixin {
  // _currentIndex tracks the index of the *active screen* (0 to 3)
  int _currentIndex = 0;
  late PageController _pageController;
  late List<AnimationController> _animationControllers;

  // --- Configuration for Navigable Screens ---
  final List<Widget> _screens = [
    const DashboardScreen(),
    const CalendarScreen(),
    const TimelineScreen(),
    const ProfileScreen(),
  ];

  // Data only for the items that correspond to screens
  final List<Map<String, dynamic>> _navItemsData = [
    {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
    {'icon': Icons.calendar_today_outlined, 'label': 'Calendar'},
    {'icon': Icons.view_timeline_outlined, 'label': 'Timeline'},
    {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
  ];

  // Define the fixed index for the theme toggle button in the BottomNavBar items list
  late final int _themeToggleIndex = _navItemsData.length; // Will be index 4

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize animation controllers ONLY for the navigable items (_navItemsData length)
    _animationControllers = List.generate(
      _navItemsData.length, // Should be 4 controllers
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    // Start animation for the initially selected navigable item
    _animationControllers[_currentIndex].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Unified Tap Handler for Bottom Navigation Bar ---
  void _onItemTapped(int index) {
    // --- Check if the Theme Toggle Button was tapped ---
    if (index == _themeToggleIndex) {
      final themeController = context.read<ThemeController>();
      // Determine the *new* theme based on the *current* theme
      final currentMode = themeController.themeMode;
      // Simple toggle: If dark, go light. Otherwise (light or system), go dark.
      final String newThemeString =
          (currentMode == ThemeMode.dark) ? 'light' : 'dark';

      // Call setThemeMode with the new theme string
      themeController.setThemeMode(newThemeString); // <<<--- Pass the argument

      HapticFeedback.lightImpact();
      return; // Stop further processing
    }

    // --- Handle Regular Navigation Item Taps ---
    // Ignore tap if the selected screen is already the current one
    if (_currentIndex == index) return;

    // Animate the icons (Forward new, Reverse old)
    for (int i = 0; i < _animationControllers.length; i++) {
      if (i == index) {
        _animationControllers[i].forward();
      } else if (i == _currentIndex) {
        // Only reverse the previously selected one
        _animationControllers[i].reverse();
      }
    }

    // Update the state to reflect the new active screen index
    setState(() {
      _currentIndex = index;
    });

    // Animate the PageView to the corresponding screen
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    HapticFeedback.mediumImpact(); // Haptic feedback for navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        // Disable user swiping between pages for consistency with bottom bar navigation
        physics: const NeverScrollableScrollPhysics(),
        // onPageChanged callback is less relevant now but can sync state if needed
        onPageChanged: (index) {
          // Ensure index is valid and different before updating state via tap logic
          if (index < _navItemsData.length && index != _currentIndex) {
            _onItemTapped(index);
          }
        },
        children: _screens, // List of screen widgets
      ),
      // Use the custom bottom navigation bar builder
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  // --- Custom Bottom Navigation Bar Builder ---
  Widget _buildCustomBottomNavBar() {
    // Watch ThemeController to rebuild toggle icon/label when theme changes
    final themeController = context.watch<ThemeController>();
    final bool isDarkMode = themeController.themeMode == ThemeMode.dark;
    final theme = Theme.of(context); // Get current theme
    final navBarTheme =
        theme.bottomNavigationBarTheme; // Get specific theme data

    // Generate the list of BottomNavigationBarItem widgets dynamically
    List<BottomNavigationBarItem> barItems = [];

    // 1. Add items for the navigable screens (_navItemsData)
    for (int i = 0; i < _navItemsData.length; i++) {
      barItems.add(
        _buildNavItem(
          icon: _navItemsData[i]['icon'] as IconData,
          label: _navItemsData[i]['label'] as String,
          itemIndex: i, // Pass the specific item index
          isSelected: _currentIndex == i, // Pass selection state
          selectedColor: navBarTheme.selectedItemColor ?? Colors.white,
          unselectedColor:
              navBarTheme.unselectedItemColor ?? Colors.white.withOpacity(0.6),
        ),
      );
    }

    // 2. Add the theme toggle item at the end
    barItems.add(
      BottomNavigationBarItem(
        icon: Icon(
          // Dynamically choose icon based on current theme mode
          isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 24, // Standard size for non-animated icon
          // Use unselected color for the theme icon for consistency
          color:
              navBarTheme.unselectedItemColor ?? Colors.white.withOpacity(0.6),
        ),
        label: isDarkMode ? 'Light' : 'Dark', // Dynamic label
        tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      ),
    );

    // Build the actual BottomNavigationBar widget
    return Container(
      // Apply shadow and rounded corners using Container + ClipRRect
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Shadow color
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          // currentIndex highlights the icon corresponding to the active screen
          currentIndex: _currentIndex,
          onTap: _onItemTapped, // Handles both navigation and theme toggle
          type: BottomNavigationBarType.fixed, // Ensures all items are visible
          // Use colors from BottomNavigationBarThemeData for better theming
          backgroundColor:
              navBarTheme.backgroundColor ??
              AppColors.primary, // Use theme or fallback
          selectedItemColor: navBarTheme.selectedItemColor ?? Colors.white,
          unselectedItemColor:
              navBarTheme.unselectedItemColor ?? Colors.white.withOpacity(0.6),
          selectedFontSize:
              navBarTheme.selectedLabelStyle?.fontSize ??
              12.0, // Use theme or default
          unselectedFontSize:
              navBarTheme.unselectedLabelStyle?.fontSize ??
              10.0, // Use theme or default
          elevation: 0, // Let the container handle elevation via shadow
          items: barItems, // Use the generated list of items
        ),
      ),
    );
  }

  // --- Helper to Build Individual Navigable Items ---
  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required int itemIndex,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    // Ensure index is valid for animation controllers
    final bool hasAnimation = itemIndex < _animationControllers.length;

    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min, // Important for vertical centering
        children: [
          // Apply scaling animation if controller exists and item is selected/animating
          hasAnimation
              ? ScaleTransition(
                scale: _animationControllers[itemIndex],
                child: Icon(
                  icon,
                  size: isSelected ? 28 : 24,
                  // Color is handled by BottomNavigationBar selectedItemColor/unselectedItemColor
                ),
              )
              // Fallback if animation controller doesn't exist (shouldn't happen here)
              : Icon(icon, size: isSelected ? 28 : 24),

          // Small indicator line under the selected navigable item
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            // Show indicator only if this navigable item is selected
            width: isSelected ? 20 : 0,
            decoration: BoxDecoration(
              color: selectedColor, // Use the passed selected color
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Add some spacing if needed, or adjust icon padding
          // const SizedBox(height: 2),
        ],
      ),
      label: label,
      tooltip: label, // Good for accessibility
    );
  }
}
