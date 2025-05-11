// TODO Implement this library.
// lib/utils/constants.dart

import 'package:flutter/material.dart'; // Optional: if you need Material constants

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // --- API Keys (Load from .env recommended) ---
  // Example: static final String googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_FALLBACK_API_KEY';
  // Make sure you have flutter_dotenv setup if using .env

  // --- Durations ---
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration locationStaleDuration = Duration(minutes: 5); // How long before location is considered old
  static const Duration locationRequestTimeout = Duration(seconds: 15); // Max time to wait for location

  // --- Default Values ---
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 4.0;
  static const double defaultSearchRadiusMeters = 2000.0; // e.g., 2km

  // --- Map Styles ---
  // Get your custom map style JSON from platforms like Snazzy Maps or Google's styling wizard
  // https://mapstyle.withgoogle.com/
  // Replace the multi-line string below with your actual JSON.
  // Keep it as 'null' or empty string ('') if you want the default Google Maps style.
  //static const String? mapStyle = null; // Set to null for default style

  // Example of how to include a JSON style:
  static const String? mapStyle = """
  [
    {
      "featureType": "poi.business",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "road.local",
      "elementType": "labels",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
    // ... more style rules
  ]
  """;



  // --- Strings / Keys (Examples) ---
  static const String appName = "MamaCare";
  static const String preferenceKeyEmail = "saved_email";
  static const String fcmTopicGeneral = "general_updates";

  // --- Asset Paths (Example) ---
  // static const String logoPath = 'assets/images/logo.png';
  // static const String placeholderImagePath = 'assets/images/placeholder.png';

  // --- Other Constants ---
  static const int itemsPerPage = 20; // For pagination
  static const double maxImageUploadSizeMb = 5.0;

}

// --- Example Usage ---
// import 'package:mama_care/utils/constants.dart';
//
// double padding = AppConstants.defaultPadding;
// Duration timeout = AppConstants.locationRequestTimeout;
// String? style = AppConstants.mapStyle;