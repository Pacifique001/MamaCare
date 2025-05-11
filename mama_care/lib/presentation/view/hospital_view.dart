// lib/presentation/view/hospital_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/hospital_viewmodel.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart'; // Assuming exists
import 'package:mama_care/domain/entities/place_api/place_result.dart';
import 'package:mama_care/utils/app_colors.dart'; // Assuming exists
import 'package:mama_care/utils/text_styles.dart'; // Assuming exists
import 'package:mama_care/utils/constants.dart'; // Assuming exists
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/injection.dart'; // Assuming exists
import 'package:connectivity_plus/connectivity_plus.dart';

class HospitalView extends StatefulWidget {
  const HospitalView({super.key});

  @override
  State<HospitalView> createState() => _HospitalViewState();
}

class _HospitalViewState extends State<HospitalView>
    with WidgetsBindingObserver {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  final Logger _logger = locator<Logger>();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  bool _isFirstLocationUpdate = true;
  StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription; // Correct Type

  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;

  static const double _defaultZoom = 14.5;
  static const double _detailZoom = 16.0;

  static const CameraPosition _initialCameraPos = CameraPosition(
    target: LatLng(-1.9464192, 30.0875776), // Example: Rwanda Center
    zoom: 10.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupConnectivityMonitoring();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeLocationAndHospitals();
      }
    });
  }

  void _setupConnectivityMonitoring() {
    // Corrected listener type
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        final viewModel = Provider.of<HospitalViewModel>(
          context,
          listen: false,
        );
        if (viewModel.nearbyHospitals.isEmpty &&
            !viewModel.isLoading &&
            viewModel.errorMessage == null) {
          _logger.i("Connectivity restored, attempting to fetch hospitals.");
          _initializeLocationAndHospitals();
        }
      } else if (results.contains(ConnectivityResult.none)) {
        _logger.w("No network connection detected.");
      }
    });
  }

  void _initializeLocationAndHospitals() async {
    final viewModel = Provider.of<HospitalViewModel>(context, listen: false);
    await viewModel.findUserAndNearbyHospitals();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final viewModel = Provider.of<HospitalViewModel>(context, listen: false);
      if (viewModel.isLocationStale()) {
        _logger.i("App resumed and location is stale, refreshing...");
        _initializeLocationAndHospitals();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _connectivitySubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _goToLocation(
    LatLng target, {
    double zoom = _defaultZoom,
  }) async {
    if (!_isMapReady && !_mapControllerCompleter.isCompleted) {
      _logger.w(
        "Map not ready and completer not finished, waiting for controller...",
      );
      try {
        // Wait for the controller if the map wasn't ready initially
        _mapController = await _mapControllerCompleter.future;
        _isMapReady = true; // Ensure flag is set
        await _loadMapStyle(); // Apply style once controller is obtained here
      } catch (e) {
        _logger.e("Error getting map controller on demand: $e");
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Map initialization error.")),
          );
        return; // Exit if controller retrieval fails
      }
    } else if (_mapController == null && _mapControllerCompleter.isCompleted) {
      // If completer finished but controller is still null (edge case)
      _mapController = await _mapControllerCompleter.future;
    }

    if (_mapController == null) {
      _logger.e("Cannot go to location: Map controller is still null.");
      return;
    }

    try {
      _logger.d("Animating camera to $target with zoom $zoom");
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          // Added await
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } catch (e) {
      _logger.e("Error animating map camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to move map view.")),
        );
      }
    }
  }

  Future<void> _launchMapUrl(
    double? lat,
    double? lng,
    String? placeId, {
    String? name,
  }) async {
    if (lat == null || lng == null) {
      _logger.w("Cannot launch map: Lat/Lng is null.");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location data unavailable.")),
        );
      return;
    }
    String queryParam = '$lat,$lng';
    if (placeId != null && placeId.isNotEmpty) {
      queryParam = 'place_id:$placeId';
    }
    final String encodedQuery = Uri.encodeComponent(queryParam);
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedQuery',
    );

    try {
      if (!await launchUrl(mapUri, mode: LaunchMode.externalApplication)) {
        _logger.e('Could not launch $mapUri');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open map application.")),
          );
      }
    } catch (e) {
      _logger.e('Error launching map URL: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error opening maps.")));
    }
  }

  Future<void> _callHospital(String? phoneNumber) async {
    // Use the getter added to PlaceResult
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number not available.")),
        );
      return;
    }
    final Uri callUri = Uri.parse('tel:$phoneNumber');
    try {
      if (!await launchUrl(callUri)) {
        _logger.e('Could not launch $callUri');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not make phone call.")),
          );
      }
    } catch (e) {
      _logger.e('Error launching phone call: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error making call.")));
    }
  }

  void _changeMapType() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal
              ? MapType.satellite
              : MapType.normal;
    });
  }

  void _toggleTraffic() {
    setState(() {
      _trafficEnabled = !_trafficEnabled;
    });
    // Removed erroneous call: _mapController?.setTrafficEnabled(_trafficEnabled).catchError((e) { _logger.e("Error toggling traffic: $e"); });
    // Traffic is controlled declaratively by the GoogleMap widget property
  }

  Future<void> _loadMapStyle() async {
    String? mapStyleJson = AppConstants.mapStyle;
    try {
      if (_mapController != null &&
          mapStyleJson != null &&
          mapStyleJson.isNotEmpty) {
        await _mapController!.setMapStyle(mapStyleJson);
        _logger.i("Custom map style applied.");
      } else {
        await _mapController?.setMapStyle(null); // Set default explicitly
        if (mapStyleJson == null || mapStyleJson.isEmpty) {
          _logger.w(
            "Map style constant is empty or null, using default map style.",
          );
        }
      }
    } catch (e) {
      _logger.e("Error setting map style: $e");
      await _mapController?.setMapStyle(null); // Fallback to default on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HospitalViewModel>(
      builder: (context, viewModel, child) {
        final selectedHospital = viewModel.selectedHospital;
        final currentPosition = viewModel.currentPosition;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (selectedHospital != null &&
              selectedHospital.location != null &&
              _isMapReady) {
            _goToLocation(
              LatLng(
                selectedHospital.location!.latitude,
                selectedHospital.location!.longitude,
              ),
              zoom: _detailZoom,
            );
          } else if (currentPosition != null &&
              _isFirstLocationUpdate &&
              _isMapReady) {
            _isFirstLocationUpdate = false;
            _goToLocation(currentPosition, zoom: _defaultZoom);
          }
        });

        return Scaffold(
          appBar: MamaCareAppBar(
            // Corrected: Use 'title' if MamaCareAppBar expects Widget, or pass Text directly
            title: "Nearby Hospitals",
            titleStyle: TextStyles.appBarTitle,
            // Pass Text widget directly
            actions: [
              IconButton(
                icon: Icon(
                  _currentMapType == MapType.normal
                      ? Icons.satellite_alt
                      : Icons.map,
                  color: AppColors.textDark,
                ),
                onPressed: _changeMapType,
                tooltip: 'Change Map Type',
              ),
              IconButton(
                icon: Icon(
                  Icons.traffic,
                  color:
                      _trafficEnabled ? AppColors.primary : AppColors.textDark,
                ),
                onPressed: _toggleTraffic,
                tooltip: 'Toggle Traffic',
              ),
            ],
          ),
          body: Stack(
            children: [
              GoogleMap(
                mapType: _currentMapType,
                initialCameraPosition: _initialCameraPos,
                onMapCreated: (GoogleMapController controller) async {
                  if (!_mapControllerCompleter.isCompleted) {
                    _mapControllerCompleter.complete(controller);
                    _mapController = controller;
                    _isMapReady = true;
                    _logger.i("GoogleMap created and controller completed.");
                    await _loadMapStyle();
                  } else {
                    // If map recreated, update controller reference and style
                    _mapController = controller;
                    await _loadMapStyle();
                  }
                },
                markers: viewModel.markers,
                circles:
                    viewModel.searchRadiusCircle != null
                        ? {viewModel.searchRadiusCircle!}
                        : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
                trafficEnabled:
                    _trafficEnabled, // Control traffic declaratively
                compassEnabled: true,
                padding: EdgeInsets.only(
                  bottom: (viewModel.selectedHospital != null ? 25.h : 8.h),
                  top: 10,
                ),
                onTap: (_) => viewModel.clearHospitalSelection(),
              ),

              // Loading Indicator
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 16),
                            Text("Finding hospitals nearby..."),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Error/No Results Messages
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildTopMessageBanner(viewModel),
                ),
              ),

              // Selected hospital info card
              if (viewModel.selectedHospital != null)
                _buildSelectedHospitalCard(
                  context,
                  viewModel.selectedHospital!,
                ),

              // Radius control slider
              if (viewModel.isRadiusSelectionMode)
                _buildRadiusSelector(context, viewModel),
            ],
          ),

          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_radius',
                backgroundColor:
                    viewModel.isRadiusSelectionMode
                        ? AppColors.primary
                        : Colors.white,
                foregroundColor:
                    viewModel.isRadiusSelectionMode
                        ? Colors.white
                        : AppColors.primary,
                tooltip: 'Set Search Radius',
                child: const Icon(Icons.radar),
                onPressed: () => viewModel.toggleRadiusSelectionMode(),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(
                heroTag: 'fab_location',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                tooltip: 'My Location',
                child: const Icon(Icons.my_location),
                onPressed: () {
                  if (viewModel.currentPosition != null) {
                    _goToLocation(viewModel.currentPosition!);
                  } else {
                    _initializeLocationAndHospitals();
                  }
                },
                // Removed onLongPress as it's not supported by FAB.small
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'fab_list',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                tooltip: 'Show Nearby Hospitals',
                child: const Icon(Icons.list_alt_rounded),
                onPressed:
                    () => _showHospitalListBottomSheet(context, viewModel),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopMessageBanner(HospitalViewModel viewModel) {
    if (viewModel.errorMessage != null && viewModel.currentPosition == null) {
      return _buildErrorBanner(
        viewModel.errorMessage!,
        onRetry: _initializeLocationAndHospitals,
        onClear: viewModel.clearError,
      );
    } else if (viewModel.errorMessage != null) {
      return _buildErrorBanner(
        viewModel.errorMessage!,
        onRetry: viewModel.refreshHospitals,
        onClear: viewModel.clearError,
      );
    } else if (!viewModel.isLoading &&
        viewModel.currentPosition != null &&
        viewModel.nearbyHospitals.isEmpty) {
      return _buildNoResultsBanner();
    } else {
      return const SizedBox.shrink(key: ValueKey('empty_banner'));
    }
  }

  Widget _buildErrorBanner(
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onClear,
  }) {
    return Container(
      key: const ValueKey('error_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.error_outline, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyles.bodyWhite.copyWith(fontSize: 11.sp),
                ),
              ),
              if (onClear != null)
                InkWell(
                  onTap: onClear,
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  textStyle: TextStyle(fontSize: 10.sp),
                ),
                child: const Text("Retry"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResultsBanner() {
    return Container(
      key: const ValueKey('no_results_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade700.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "No hospitals found nearby with current filters.",
              style: TextStyles.bodyWhite.copyWith(fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector(
    BuildContext context,
    HospitalViewModel viewModel,
  ) {
    return Positioned(
      bottom: 15.h,
      left: 20,
      right: 20,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Search Radius", style: TextStyles.bodyBold),
                  Text(
                    "${(viewModel.searchRadius / 1000).toStringAsFixed(1)} km",
                    style: TextStyles.bodyBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: viewModel.searchRadius,
                min: 500,
                max: 5000,
                divisions: 9,
                activeColor: AppColors.primary,
                label:
                    "${(viewModel.searchRadius / 1000).toStringAsFixed(1)} km",
                onChanged:
                    (value) =>
                        viewModel.updateSearchRadius(value.roundToDouble()),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => viewModel.applyRadiusAndSearch(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Apply & Search"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Bottom Sheet Widgets (Keep _showHospitalListBottomSheet, _buildFilterChipsRow, _buildSortDropdown, _buildFilterChip, _buildBottomSheetHospitalList) ---
  void _showHospitalListBottomSheet(
    BuildContext context,
    HospitalViewModel viewModel,
  ) {
    _searchController.clear();
    viewModel.searchHospitals(""); // Reset search
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ChangeNotifierProvider.value(
          value: viewModel,
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Consumer<HospitalViewModel>(
                  builder: (sheetContext, sheetViewModel, _) {
                    return Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Nearby Hospitals (${sheetViewModel.filteredHospitals.length})",
                                style: TextStyles.headline2,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(sheetContext),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15.0,
                            vertical: 10.0,
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search hospitals...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          sheetViewModel.searchHospitals("");
                                        },
                                      )
                                      : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 0,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                            onChanged: sheetViewModel.searchHospitals,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 35,
                                child: _buildFilterChipsRow(sheetViewModel),
                              ),
                              const SizedBox(height: 5),
                              _buildSortDropdown(sheetViewModel),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _buildBottomSheetHospitalList(
                            sheetContext,
                            sheetViewModel,
                            scrollController,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChipsRow(HospitalViewModel sheetViewModel) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _buildFilterChip(
          label: "Open Now",
          selected: sheetViewModel.filterOpenNow,
          onSelected: sheetViewModel.setFilterOpenNow,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: "Top Rated",
          selected: sheetViewModel.filterTopRated,
          onSelected: sheetViewModel.setFilterTopRated,
        ),
        const SizedBox(width: 8),
        _buildFilterChip(
          label: "Favorites",
          selected: sheetViewModel.filterFavorites,
          onSelected: sheetViewModel.setFilterFavorites,
        ),
      ],
    );
  }

  Widget _buildSortDropdown(HospitalViewModel sheetViewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("Sort by:", style: TextStyles.smallBold),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: sheetViewModel.sortCriteria,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          elevation: 2,
          style: TextStyles.smallBody,
          underline: Container(),
          onChanged: (String? value) {
            if (value != null) {
              sheetViewModel.setSortCriteria(value);
            }
          },
          items: const [
            DropdownMenuItem(value: 'distance', child: Text('Distance')),
            DropdownMenuItem(value: 'rating', child: Text('Rating')),
            DropdownMenuItem(value: 'name', child: Text('Name (A-Z)')),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 10.sp)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primaryLight.withOpacity(0.3),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textDark,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 10.sp,
      ),
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.grey.shade300,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildBottomSheetHospitalList(
    BuildContext sheetContext,
    HospitalViewModel sheetViewModel,
    ScrollController scrollController,
  ) {
    if (sheetViewModel.isLoading && sheetViewModel.nearbyHospitals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sheetViewModel.errorMessage != null &&
        sheetViewModel.nearbyHospitals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Error: ${sheetViewModel.errorMessage}",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (sheetViewModel.filteredHospitals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No hospitals match your filters.",
            textAlign: TextAlign.center,
            style: TextStyles.bodyGrey,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: sheetViewModel.refreshHospitals,
      child: ListView.separated(
        controller: scrollController,
        itemCount: sheetViewModel.filteredHospitals.length,
        padding: const EdgeInsets.only(bottom: 20),
        separatorBuilder:
            (context, index) =>
                const Divider(height: 0.5, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final hospital = sheetViewModel.filteredHospitals[index];
          if (hospital.location == null) return const SizedBox.shrink();
          String distanceStr = _getDistanceString(sheetViewModel, hospital);

          return ListTile(
            key: ValueKey(hospital.placeId),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildHospitalAvatar(hospital),
            title: Text(
              hospital.name ?? 'Unknown Hospital',
              style: TextStyles.listTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.displayAddress,
                  style: TextStyles.listSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (hospital.rating != null) ...[
                      Icon(Icons.star, color: Colors.amber.shade700, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${hospital.rating?.toStringAsFixed(1)}",
                        style: TextStyles.smallBold,
                      ),
                      if (hospital.userRatingsTotal != null)
                        Text(
                          " (${hospital.userRatingsTotal})",
                          style: TextStyles.smallGrey,
                        ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      hospital.isOpen ? "Open" : "Closed",
                      style: TextStyles.smallBold.copyWith(
                        color:
                            hospital.isOpen
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(distanceStr, style: TextStyles.smallGrey),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    hospital.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color:
                        hospital.isFavorite
                            ? AppColors.primary
                            : AppColors.textGrey,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip:
                      hospital.isFavorite ? "Remove favorite" : "Add favorite",
                  onPressed: () => sheetViewModel.toggleFavorite(hospital),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.directions,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: "Get Directions",
                  onPressed:
                      () => _launchMapUrl(
                        hospital.location?.latitude,
                        hospital.location?.longitude,
                        hospital.placeId,
                      ),
                ),
              ],
            ),
            onTap: () {
              sheetViewModel.selectHospital(hospital);
              _goToLocation(
                LatLng(
                  hospital.location!.latitude,
                  hospital.location!.longitude,
                ),
                zoom: _detailZoom,
              );
              Navigator.pop(sheetContext);
            },
          );
        },
      ),
    );
  }

  Widget _buildHospitalAvatar(PlaceResult hospital) {
    // Use the imageUrl getter which handles API key logic
    String? imageUrl = hospital.imageUrl;
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
      child:
          (imageUrl != null)
              ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder:
                      (context, url) => const Icon(
                        Icons.local_hospital_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                  errorWidget:
                      (context, url, error) => const Icon(
                        Icons.business,
                        color: Colors.grey,
                        size: 24,
                      ),
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                ),
              )
              : const Icon(
                Icons.local_hospital,
                color: AppColors.primary,
                size: 24,
              ),
    );
  }

  String _getDistanceString(HospitalViewModel viewModel, PlaceResult hospital) {
    if (viewModel.currentPosition == null || hospital.location == null)
      return '';
    try {
      double distanceInMeters = Geolocator.distanceBetween(
        viewModel.currentPosition!.latitude,
        viewModel.currentPosition!.longitude,
        hospital.location!.latitude,
        hospital.location!.longitude,
      );
      if (distanceInMeters < 1000) {
        return "${distanceInMeters.toStringAsFixed(0)} m";
      } else {
        return "${(distanceInMeters / 1000).toStringAsFixed(1)} km";
      }
    } catch (e) {
      _logger.e("Error calculating distance: $e");
      return '';
    }
  }

  Widget _buildSelectedHospitalCard(
    BuildContext context,
    PlaceResult hospital,
  ) {
    if (hospital.location == null) return const SizedBox.shrink();
    final viewModel = Provider.of<HospitalViewModel>(context, listen: false);
    String distanceStr = _getDistanceString(viewModel, hospital);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHospitalAvatar(hospital),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name ?? 'Unknown Hospital',
                          style: TextStyles.titleBold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hospital.displayAddress,
                          style: TextStyles.bodyGrey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      hospital.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          hospital.isFavorite
                              ? AppColors.primary
                              : AppColors.textGrey,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip:
                        hospital.isFavorite
                            ? "Remove favorite"
                            : "Add favorite",
                    onPressed: () => viewModel.toggleFavorite(hospital),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
                    onPressed: () => viewModel.clearHospitalSelection(),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hospital.rating != null)
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${hospital.rating?.toStringAsFixed(1)}",
                          style: TextStyles.bodyBold,
                        ),
                        if (hospital.userRatingsTotal != null)
                          Text(
                            " (${hospital.userRatingsTotal} reviews)",
                            style: TextStyles.smallGrey,
                          ),
                      ],
                    ),
                  Text(
                    hospital.isOpen ? "Open Now" : "Closed",
                    style: TextStyles.bodyBold.copyWith(
                      color:
                          hospital.isOpen
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                  if (distanceStr.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(distanceStr, style: TextStyles.bodyGrey),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text("Directions"),
                      onPressed:
                          () => _launchMapUrl(
                            hospital.location?.latitude,
                            hospital.location?.longitude,
                            hospital.placeId,
                            name: hospital.name,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: TextStyles.buttonTextSmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text("Call"),
                      onPressed:
                          hospital.phoneNumber != null
                              ? () => _callHospital(hospital.phoneNumber)
                              : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: TextStyles.buttonTextSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
