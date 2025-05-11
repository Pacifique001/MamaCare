// lib/navigation/navigation_service.dart

import 'package:flutter/material.dart';
//import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart'; // Using package:logger for consistency with other parts
import 'package:mama_care/injection.dart';
//import 'package:flutter/foundation.dart';// Assuming locator is setup here

/// A utility class for handling navigation actions globally within the app.
///
/// This service uses a static `GlobalKey<NavigatorState>` to access the
/// Navigator from anywhere without needing a `BuildContext`.
//@injectable
class NavigationService {
  const NavigationService._(); // Private constructor to prevent instantiation

  // --- Navigator Key ---
  /// A global key used to access the Navigator's state.
  /// Assign this key to the `navigatorKey` property of your `MaterialApp`.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // --- Logger ---
  /// Internal logger instance. Uses the registered Logger from GetIt/locator
  /// or creates a simple one if none is registered.
  static final Logger _log =
      locator.isRegistered<Logger>()
          ? locator<Logger>()
          : Logger(
            printer: SimplePrinter(printTime: true),
          ); // Basic logger if DI fails

  // --- Getters ---
  /// Returns the current `BuildContext` associated with the navigatorKey.
  ///
  /// Can be useful for accessing providers or themes from outside the widget tree,
  /// but should be used cautiously as the context might be unavailable or outdated.
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Returns the `NavigatorState` if available.
  static NavigatorState? get _navigatorState => navigatorKey.currentState;

  // --- Navigation Methods ---

  /// Navigates to a named route defined in your `RouteGenerator`.
  ///
  /// - `routeName`: The named route to navigate to (e.g., `/details`).
  /// - `arguments`: Optional data to pass to the new route.
  ///
  /// Returns a `Future` that completes to the result passed back by the popped route.
  static Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    if (_navigatorState != null) {
      _log.d(
        "Navigating to '$routeName'${arguments != null ? ' with args' : ''}",
      );
      try {
        return _navigatorState!.pushNamed(routeName, arguments: arguments);
      } catch (e, stackTrace) {
        _log.e(
          "Error during pushNamed to '$routeName'",
          error: e,
          stackTrace: stackTrace,
        );
        return null; // Indicate failure
      }
    } else {
      _log.e(
        "Navigation Error: NavigatorState is null. Cannot navigate to '$routeName'.",
      );
      return null; // Indicate navigation failure
    }
  }

  /// Navigates to a named route and removes all routes beneath it in the stack.
  ///
  /// Useful for navigation after login/signup or navigating to a main section
  /// where going back is not desired.
  ///
  /// - `routeName`: The named route to navigate to.
  /// - `arguments`: Optional data to pass to the new route.
  ///
  /// Returns a `Future` that completes to the result passed back by the popped route(s).
  static Future<dynamic>? navigateToAndRemoveAll(
    String routeName, {
    Object? arguments,
  }) {
    if (_navigatorState != null) {
      _log.d(
        "Navigating to '$routeName' and removing all previous routes${arguments != null ? ' with args' : ''}",
      );
      try {
        return _navigatorState!.pushNamedAndRemoveUntil(
          routeName,
          (Route<dynamic> route) =>
              false, // Predicate always returns false to remove all
          arguments: arguments,
        );
      } catch (e, stackTrace) {
        _log.e(
          "Error during pushNamedAndRemoveUntil to '$routeName'",
          error: e,
          stackTrace: stackTrace,
        );
        return null;
      }
    } else {
      _log.e(
        "Navigation Error: NavigatorState is null. Cannot navigate to '$routeName' and remove until.",
      );
      return null;
    }
  }

  /// Replaces the current route with a new named route.
  ///
  /// The new route takes the place of the current route in the stack.
  ///
  /// - `routeName`: The named route to navigate to.
  /// - `arguments`: Optional data to pass to the new route.
  ///
  /// Returns a `Future` that completes to the result passed back when the *new* route is eventually popped.
  static Future<dynamic>? navigateToAndReplace(
    String routeName, {
    Object? arguments,
  }) {
    if (_navigatorState != null) {
      _log.d(
        "Replacing current route with '$routeName'${arguments != null ? ' with args' : ''}",
      );
      try {
        return _navigatorState!.pushReplacementNamed(
          routeName,
          arguments: arguments,
        );
      } catch (e, stackTrace) {
        _log.e(
          "Error during pushReplacementNamed with '$routeName'",
          error: e,
          stackTrace: stackTrace,
        );
        return null;
      }
    } else {
      _log.e(
        "Navigation Error: NavigatorState is null. Cannot replace route with '$routeName'.",
      );
      return null;
    }
  }

  /// Pops the current route off the navigator stack.
  ///
  /// - `result`: Optional data to pass back to the previous route.
  static void goBack([dynamic result]) {
    if (_navigatorState != null && _navigatorState!.canPop()) {
      _log.d("Navigating back${result != null ? ' with result: $result' : ''}");
      _navigatorState!.pop(result);
    } else {
      _log.w(
        "Navigation Warning: Cannot go back. Either no route to pop or NavigatorState is null.",
      );
    }
  }

  /// Pops routes until the route with the specified `routeName` is reached.
  ///
  /// - `routeName`: The name of the route to pop back to.
  static void popUntil(String routeName) {
    if (_navigatorState != null) {
      _log.d("Popping routes until '$routeName' is reached.");
      try {
        _navigatorState!.popUntil(ModalRoute.withName(routeName));
      } catch (e, stackTrace) {
        _log.e(
          "Error during popUntil '$routeName'",
          error: e,
          stackTrace: stackTrace,
        );
      }
    } else {
      _log.e(
        "Navigation Error: NavigatorState is null. Cannot popUntil '$routeName'.",
      );
    }
  }
}
