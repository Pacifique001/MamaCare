// lib/presentation/viewmodel/hospital_viewmodel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/domain/entities/place_api/place_result.dart';
import 'package:mama_care/domain/usecases/hospital_use_case.dart';
import 'package:mama_care/core/error/exceptions.dart';
import 'package:collection/collection.dart';
import 'package:mama_care/utils/app_colors.dart'; // Assuming colors are needed for Circle

@injectable
class HospitalViewModel extends ChangeNotifier {
  final HospitalUseCase _hospitalUseCase;
  final Logger _logger;

  List<PlaceResult> _nearbyHospitals = [];
  List<PlaceResult> _favoriteHospitals = [];
  List<PlaceResult> _filteredHospitals = []; // Holds the list after filtering/sorting
  LatLng? _currentPosition;
  DateTime? _lastLocationFetchTime; // Track when location was last fetched
  Set<Marker> _markers = {};
  Circle? _searchRadiusCircle; // Circle to show search radius
  bool _isLoading = false;
  String? _errorMessage;
  bool _locationPermissionGranted = false;
  PlaceResult? _selectedHospital;

  // --- Search, Filter & Sort State ---
  String _searchQuery = "";
  bool _filterOpenNow = false;
  bool _filterTopRated = false; // Example: rating >= 4.0
  bool _filterFavorites = false;
  String _sortCriteria = 'distance'; // 'distance', 'rating', 'name'
  bool _isRadiusSelectionMode = false;
  double _searchRadius = 2000.0; // Default search radius in meters (2km)

  HospitalViewModel(this._hospitalUseCase, this._logger) {
    _logger.i("HospitalViewModel initialized.");
    // Fetch favorites initially or on demand
    fetchFavoriteHospitals();
  }

  // --- Getters ---
  List<PlaceResult> get nearbyHospitals => List.unmodifiable(_nearbyHospitals);
  List<PlaceResult> get favoriteHospitals => List.unmodifiable(_favoriteHospitals);
  List<PlaceResult> get filteredHospitals => List.unmodifiable(_filteredHospitals); // Use this for the list UI
  LatLng? get currentPosition => _currentPosition;
  Set<Marker> get markers => Set.unmodifiable(_markers);
  Circle? get searchRadiusCircle => _searchRadiusCircle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get locationPermissionGranted => _locationPermissionGranted;
  PlaceResult? get selectedHospital => _selectedHospital;
  bool get isRadiusSelectionMode => _isRadiusSelectionMode;
  double get searchRadius => _searchRadius;
  String get searchQuery => _searchQuery;
  bool get filterOpenNow => _filterOpenNow;
  bool get filterTopRated => _filterTopRated;
  bool get filterFavorites => _filterFavorites;
  String get sortCriteria => _sortCriteria;

  // --- Private State Setters ---
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    if (_errorMessage == message) return;
    _errorMessage = message;
    if (message != null) _logger.e("HospitalViewModel Error: $message");
    notifyListeners();
  }

  void clearError() => _setError(null);

  // --- Marker and Circle Update ---
  void _updateMarkersAndCircle() {
    _logger.d("Updating map markers and search circle.");
    final Set<Marker> newMarkers = {};

    if (_currentPosition != null) {
      newMarkers.add(Marker(markerId: const MarkerId('currentLocation'), position: _currentPosition!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), infoWindow: const InfoWindow(title: 'Your Location')));
      // Update or create search radius circle
      _searchRadiusCircle = Circle(
          circleId: const CircleId('searchRadius'),
          center: _currentPosition!,
          radius: _searchRadius,
          fillColor: AppColors.primaryLight.withOpacity(0.15),
          strokeColor: AppColors.primary.withOpacity(0.5),
          strokeWidth: 1,
      );
    } else {
       _searchRadiusCircle = null; // Remove circle if no position
    }

    // Add markers only for hospitals currently in the main nearby list
    for (final hospital in _nearbyHospitals) {
      if (hospital.location == null) continue;
      BitmapDescriptor markerIcon = hospital.isFavorite ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet) : BitmapDescriptor.defaultMarker;
      newMarkers.add(
        Marker(
          markerId: MarkerId(hospital.placeId), position: LatLng(hospital.location!.latitude, hospital.location!.longitude),
          icon: markerIcon,
          infoWindow: InfoWindow(title: hospital.name ?? 'Unknown Hospital', snippet: hospital.displayAddress, onTap: () => selectHospital(hospital)),
          onTap: () => selectHospital(hospital),
        ),
      );
    }
    _markers = newMarkers;
    // NotifyListeners is called by the methods that trigger this update
  }

   // --- Filtering and Sorting Logic ---
   void _applyFiltersAndSort() {
     _logger.d("Applying filters and sorting: Query='$_searchQuery', Open=$_filterOpenNow, Rated=$_filterTopRated, Favs=$_filterFavorites, Sort=$_sortCriteria");
     List<PlaceResult> result = _nearbyHospitals;

     // 1. Filter by Search Query
     if (_searchQuery.isNotEmpty) {
       final lowerQuery = _searchQuery.toLowerCase();
       result = result.where((h) => (h.name?.toLowerCase().contains(lowerQuery) ?? false) || (h.displayAddress.toLowerCase().contains(lowerQuery))).toList();
     }

     // 2. Filter by Open Now
     if (_filterOpenNow) {
       result = result.where((h) => h.isOpen).toList();
     }

     // 3. Filter by Top Rated (e.g., >= 4.0)
     if (_filterTopRated) {
       result = result.where((h) => (h.rating ?? 0.0) >= 4.0).toList();
     }

      // 4. Filter by Favorites
     if (_filterFavorites) {
       result = result.where((h) => h.isFavorite).toList();
     }

     // 5. Sort
     if (_currentPosition != null) { // Only sort by distance if location known
        result.sort((a, b) {
            int comparison;
            switch (_sortCriteria) {
            case 'rating':
                comparison = (b.rating ?? 0.0).compareTo(a.rating ?? 0.0); // Descending rating
                break;
            case 'name':
                comparison = (a.name ?? '').compareTo(b.name ?? ''); // Ascending name
                break;
            case 'distance':
            default:
                double distA = _calculateDistance(a);
                double distB = _calculateDistance(b);
                comparison = distA.compareTo(distB); // Ascending distance
                break;
            }
            // If primary sort is equal, sort by name as secondary
            if (comparison == 0 && _sortCriteria != 'name') {
               return (a.name ?? '').compareTo(b.name ?? '');
            }
            return comparison;
        });
     } else {
       // Fallback sort if no location (e.g., by name)
        result.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
     }


     _filteredHospitals = result;
     _logger.d("Filtering/Sorting complete. Result count: ${_filteredHospitals.length}");
     notifyListeners(); // Update the UI list
   }

   // Helper to calculate distance for sorting
   double _calculateDistance(PlaceResult hospital) {
       if (_currentPosition == null || hospital.location == null) return double.maxFinite; // Treat unknown distances as furthest
       try {
           return Geolocator.distanceBetween(
             _currentPosition!.latitude, _currentPosition!.longitude,
             hospital.location!.latitude, hospital.location!.longitude,
           );
       } catch (e) {
           _logger.e("Error calculating distance for sort: $e");
           return double.maxFinite;
       }
   }

  // --- Public Methods ---

  Future<bool> checkAndRequestLocationPermission() async {
    _logger.i("Checking location permission...");
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _logger.w("Location permission denied status: $permission. Requesting...");
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _logger.e("Location permission denied by user (status: $permission).");
        final msg = permission == LocationPermission.deniedForever ? 'Location permission is permanently denied. Please enable it in app settings.' : 'Location permission is required to find nearby hospitals.';
        _setError(msg); _locationPermissionGranted = false; notifyListeners(); return false;
      }
    }
    _logger.i("Location permission granted.");
    _locationPermissionGranted = true;
    if (_errorMessage?.contains('Location permission') ?? false) { clearError(); }
    notifyListeners(); return true;
  }

  Future<void> findUserAndNearbyHospitals() async {
    _logger.i("Attempting to find user location and nearby hospitals...");
    _setLoading(true); clearError(); _selectedHospital = null;

    final hasPermission = await checkAndRequestLocationPermission();
    if (!hasPermission) { _setLoading(false); return; }

    try {
      _logger.d("Getting current position...");
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 15)); // Increased accuracy/timeout
      _currentPosition = LatLng(position.latitude, position.longitude);
      _lastLocationFetchTime = DateTime.now(); // Store fetch time
      _logger.i("Current position obtained: $_currentPosition");
      await _fetchNearbyHospitals(); // Fetch hospitals using the new location & radius
    } on TimeoutException catch (e, stackTrace) {
      _logger.e("Timeout getting current location", error: e, stackTrace: stackTrace);
      _setError("Could not get your location in time. Check GPS and try again.");
    } on LocationServiceDisabledException catch (e, stackTrace) {
      _logger.e("Location services disabled", error: e, stackTrace: stackTrace);
      _setError("Location services are disabled. Please enable GPS/Location.");
    } catch (e, stackTrace) {
      _logger.e("Error getting current location", error: e, stackTrace: stackTrace);
      _setError("Failed to get current location.");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchNearbyHospitals() async {
    if (_currentPosition == null) { _setError("Cannot find hospitals: Your location is unknown."); _logger.w("Skipping hospital fetch: Current position is null."); return; }
    _logger.i("Fetching nearby hospitals for pos: $_currentPosition, radius: $_searchRadius");
    // Loading state is usually set by the calling function (findUserAndNearbyHospitals or applyRadiusAndSearch)
    try {
      final hospitals = await _hospitalUseCase.getHospitalList(_currentPosition!, radius: _searchRadius); // Pass radius
      _nearbyHospitals = List<PlaceResult>.from(hospitals); // Ensure correct type
      await fetchFavoriteHospitals(); // Refresh favorites to merge status correctly
      _mergeFavoriteStatus(); // Merge favorite status into nearby list
      _logger.i("Fetched ${_nearbyHospitals.length} nearby hospitals.");
      _applyFiltersAndSort(); // Apply current filters/sort to populate _filteredHospitals
      _updateMarkersAndCircle(); // Update map visuals
    } catch (e, stackTrace) {
      _logger.e("Error during _fetchNearbyHospitals", error: e, stackTrace: stackTrace);
      if (e is ApiException) _setError("API Error: ${e.message}");
      else if (e is NetworkException) _setError("Network Error: Check connection.");
      else if (e is DatabaseException) _setError("Database Error: Could not retrieve data.");
      else _setError("An unexpected error occurred finding hospitals.");
      _nearbyHospitals = []; _filteredHospitals = [];
      _updateMarkersAndCircle(); // Clear markers
    }
    // Loading state handled by caller
  }

  Future<void> fetchFavoriteHospitals() async {
    _logger.d("Fetching favorite hospitals...");
    // No separate loading state needed if called during main fetch
    try {
      _favoriteHospitals = await _hospitalUseCase.getFavoriteHospitals();
      _logger.i("Fetched ${_favoriteHospitals.length} favorite hospitals.");
      _mergeFavoriteStatus(); // Update nearby list with latest fav status
      _applyFiltersAndSort(); // Re-apply filters if favorites filter is active
      _updateMarkersAndCircle(); // Update marker colors
    } catch (e, stackTrace) {
      _logger.e("Error fetching favorite hospitals", error: e, stackTrace: stackTrace);
      _setError("Could not load your favorite hospitals.");
      _favoriteHospitals = [];
    }
  }

   // Merges favorite status from _favoriteHospitals into _nearbyHospitals
   void _mergeFavoriteStatus() {
     if (_favoriteHospitals.isEmpty) {
         // If no favorites loaded, ensure all nearby are marked false (unless already fetched with status)
         _nearbyHospitals = _nearbyHospitals.map((h) => h.copyWith(isFavorite: false)).toList();
         return;
     }
     final favoriteIds = _favoriteHospitals.map((fav) => fav.placeId).toSet();
     _nearbyHospitals = _nearbyHospitals.map((h) {
       final isFav = favoriteIds.contains(h.placeId);
       return h.isFavorite == isFav ? h : h.copyWith(isFavorite: isFav); // Only copy if status changed
     }).toList();
   }

  Future<void> toggleFavorite(PlaceResult hospital) async {
    _logger.d("ViewModel: Toggling favorite for ${hospital.placeId}");
    final originalFavoriteStatus = hospital.isFavorite;
    final optimisticHospital = hospital.copyWith(isFavorite: !originalFavoriteStatus);
    _updateHospitalInLists(optimisticHospital);
    clearError();
    try {
      await _hospitalUseCase.toggleFavorite(optimisticHospital);
      _logger.i("ViewModel: Favorite toggled successfully for ${hospital.placeId}");
      // Optionally refresh _favoriteHospitals list from source after successful toggle
      // await fetchFavoriteHospitals(); // This will re-merge and re-filter
    } catch (e, stackTrace) {
      _logger.e("ViewModel: Failed to toggle favorite for ${hospital.placeId}", error: e, stackTrace: stackTrace);
      _setError("Failed to update favorite status.");
      _updateHospitalInLists(hospital.copyWith(isFavorite: originalFavoriteStatus)); // Revert UI
    }
  }

  void _updateHospitalInLists(PlaceResult updatedHospital) {
    bool changed = false;
    // Update nearby list
    final nearbyIndex = _nearbyHospitals.indexWhere((h) => h.placeId == updatedHospital.placeId);
    if (nearbyIndex != -1 && _nearbyHospitals[nearbyIndex].isFavorite != updatedHospital.isFavorite) {
      _nearbyHospitals[nearbyIndex] = updatedHospital;
      changed = true;
    }
    // Update/Add/Remove from favorites list
    final favIndex = _favoriteHospitals.indexWhere((h) => h.placeId == updatedHospital.placeId);
    if (updatedHospital.isFavorite) {
      if (favIndex == -1) { _favoriteHospitals.add(updatedHospital); changed = true; }
      else if (_favoriteHospitals[favIndex].isFavorite != updatedHospital.isFavorite) { _favoriteHospitals[favIndex] = updatedHospital; changed = true; }
    } else {
      if (favIndex != -1) { _favoriteHospitals.removeAt(favIndex); changed = true; }
    }

    if(changed) {
        _applyFiltersAndSort(); // Re-filter list if needed (e.g., if filtering by favs)
        _updateMarkersAndCircle(); // Update marker colors
        notifyListeners();
    }
  }

  void selectHospital(PlaceResult hospital) {
    _logger.d("Hospital selected: ${hospital.name} (ID: ${hospital.placeId})");
    if (_selectedHospital?.placeId != hospital.placeId) {
        _selectedHospital = hospital;
        notifyListeners();
    }
  }

  void clearHospitalSelection() {
    if (_selectedHospital != null) {
      _logger.d("Clearing hospital selection.");
      _selectedHospital = null;
      notifyListeners();
    }
  }

  // --- New Methods for View Interaction ---

  bool isLocationStale({Duration staleDuration = const Duration(minutes: 5)}) {
    if (_lastLocationFetchTime == null) return true; // Stale if never fetched
    return DateTime.now().difference(_lastLocationFetchTime!) > staleDuration;
  }

  void toggleRadiusSelectionMode() {
    _isRadiusSelectionMode = !_isRadiusSelectionMode;
    _logger.d("Radius selection mode toggled: $_isRadiusSelectionMode");
    if (!_isRadiusSelectionMode) {
      // Optionally clear circle immediately when toggling off, or wait for apply
      // _searchRadiusCircle = null;
    } else {
       // Ensure circle is shown when mode is on (if position known)
       _updateMarkersAndCircle();
    }
    notifyListeners();
  }

  void updateSearchRadius(double radius) {
    if (_searchRadius == radius) return;
    _searchRadius = radius;
    _logger.d("Search radius updated: $_searchRadius meters");
    // Update the circle visually on the map
    if (_currentPosition != null) {
        _searchRadiusCircle = Circle(
            circleId: const CircleId('searchRadius'),
            center: _currentPosition!,
            radius: _searchRadius,
            fillColor: AppColors.primaryLight.withOpacity(0.15),
            strokeColor: AppColors.primary.withOpacity(0.5),
            strokeWidth: 1,
        );
    }
    notifyListeners(); // Update slider and potentially map circle
  }

  Future<void> applyRadiusAndSearch() async {
    _logger.i("Applying radius $_searchRadius and searching again...");
    _isRadiusSelectionMode = false; // Turn off selection mode
    _setLoading(true); // Show loading for the search
    clearError();
    await _fetchNearbyHospitals(); // Re-fetch with the new radius
    _setLoading(false);
  }

  void searchHospitals(String query) {
     _searchQuery = query.trim();
     _applyFiltersAndSort(); // Refilter list based on new query
  }

  void setFilterOpenNow(bool value) {
    if (_filterOpenNow == value) return;
    _filterOpenNow = value;
    _applyFiltersAndSort();
  }

  void setFilterTopRated(bool value) {
    if (_filterTopRated == value) return;
    _filterTopRated = value;
    _applyFiltersAndSort();
  }

   void setFilterFavorites(bool value) {
    if (_filterFavorites == value) return;
    _filterFavorites = value;
    _applyFiltersAndSort();
  }

  void setSortCriteria(String criteria) {
    if (_sortCriteria == criteria) return;
    _sortCriteria = criteria;
    _applyFiltersAndSort();
  }

  void resetFilters() {
     bool changed = _filterOpenNow || _filterTopRated || _filterFavorites || _searchQuery.isNotEmpty || _sortCriteria != 'distance';
     _searchQuery = "";
     _filterOpenNow = false;
     _filterTopRated = false;
     _filterFavorites = false;
     _sortCriteria = 'distance'; // Reset to default sort
     if (changed) {
        _logger.i("Filters and sort reset.");
        _applyFiltersAndSort();
     }
  }

  Future<void> refreshHospitals() async {
     _logger.i("Refreshing hospitals list...");
     // Optionally reset filters/sort on manual refresh? Or keep current settings?
     // resetFilters(); // Uncomment to reset filters on refresh
     await findUserAndNearbyHospitals(); // Re-run the full fetch process
  }


  @override
  void dispose() {
    _logger.i("Disposing HospitalViewModel.");
    super.dispose();
  }
}