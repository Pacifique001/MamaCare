// lib/presentation/screen/suggested_food_screen.dart (or view if separated)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import for network images
import 'package:mama_care/injection.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/app_colors.dart'; // Import AppColors
import 'package:mama_care/utils/text_styles.dart'; // Import TextStyles
import 'package:mama_care/domain/entities/food_model.dart'; // Import FoodModel
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/suggested_food_viewmodel.dart';
import 'package:logger/logger.dart'; // Import Logger

// Option 1: Combined Screen/View (Simpler for this case)
class SuggestedFoodScreen extends StatefulWidget {
  const SuggestedFoodScreen({super.key});

  @override
  State<SuggestedFoodScreen> createState() => _SuggestedFoodScreenState();
}

class _SuggestedFoodScreenState extends State<SuggestedFoodScreen> {
  final _searchController = TextEditingController();
  final Logger _logger = locator<Logger>(); // Get logger

  @override
  void initState() {
    super.initState();
    // Optional: Add listener to clear search on VM reload if desired
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<SuggestedFoodViewModel>().addListener(_handleViewModelChanges);
    // });
  }

  @override
  void dispose() {
    // context.read<SuggestedFoodViewModel>().removeListener(_handleViewModelChanges); // If listener added
    _searchController.dispose();
    super.dispose();
  }

  // Example listener (optional)
  // void _handleViewModelChanges() {
  //   final viewModel = context.read<SuggestedFoodViewModel>();
  //   // If data reloads completely, maybe clear local search state
  //   if (!viewModel.isLoading && _searchController.text.isNotEmpty && viewModel.searchQuery == null) {
  //      WidgetsBinding.instance.addPostFrameCallback((_) { // Ensure it runs after build
  //          if(mounted) _searchController.clear();
  //      });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // Provide the ViewModel using ChangeNotifierProvider
    return ChangeNotifierProvider<SuggestedFoodViewModel>(
      create: (_) => locator<SuggestedFoodViewModel>(), // Create via locator
      child: Consumer<SuggestedFoodViewModel>(
        // Use Consumer to access VM and rebuild
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: MamaCareAppBar(
              // Removed trailing icon, add actions if needed (like filter button)
              title: 'Suggested Foods',
              // Optional: Add filter action
              // actions: [
              //   IconButton(
              //     icon: Icon(Icons.filter_list),
              //     onPressed: () => _showFilterOptions(context, viewModel),
              //   ),
              // ],
            ),
            body: RefreshIndicator(
              onRefresh: () => viewModel.refreshFoods(), // Pull to refresh
              color: AppColors.primary,
              child: Column(
                children: [
                  // --- Search Bar ---
                  _buildSearchBar(context, viewModel),

                  // --- Optional: Filter Chips ---
                  _buildFilterChips(context, viewModel), // Add filter UI
                  // --- Loading / Error / Content ---
                  Expanded(child: _buildContentBody(context, viewModel)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI Building Helper Methods ---

  Widget _buildSearchBar(
    BuildContext context,
    SuggestedFoodViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search foods (name, description, benefits...)',
          prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textGrey),
                    onPressed: () {
                      _searchController.clear();
                      viewModel.searchFoods(null); // Clear search in VM
                      FocusManager.instance.primaryFocus
                          ?.unfocus(); // Dismiss keyboard
                    },
                  )
                  : null,
          filled: true,
          fillColor: AppColors.background, // Use background color
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 15.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none, // No border
          ),
        ),
        onChanged:
            (query) => viewModel.searchFoods(query), // Update VM on change
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    SuggestedFoodViewModel viewModel,
  ) {
    final categories = viewModel.availableCategories;
    if (categories.isEmpty && !viewModel.showFavoritesOnly)
      return const SizedBox.shrink(); // Hide if no categories and not filtering favs

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: SingleChildScrollView(
        // Allow horizontal scrolling for chips
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Favorite Filter Chip
            FilterChip(
              label: const Text("Favorites"),
              selected: viewModel.showFavoritesOnly,
              avatar: Icon(
                viewModel.showFavoritesOnly
                    ? Icons.favorite
                    : Icons.favorite_border,
                color:
                    viewModel.showFavoritesOnly
                        ? AppColors.primary
                        : AppColors.textGrey,
                size: 16,
              ),
              selectedColor: AppColors.primaryLight.withOpacity(0.2),
              checkmarkColor:
                  AppColors.primary, // Checkmark color when selected
              labelStyle: TextStyle(
                fontSize: 11.sp,
                fontWeight:
                    viewModel.showFavoritesOnly
                        ? FontWeight.bold
                        : FontWeight.normal,
                color:
                    viewModel.showFavoritesOnly
                        ? AppColors.primary
                        : AppColors.textGrey,
              ),
              onSelected: (selected) {
                viewModel.toggleFavoritesFilter(selected);
              },
              showCheckmark:
                  false, // Hide default checkmark, use avatar instead
              backgroundColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: viewModel.showFavoritesOnly ? 1 : 0,
              padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 0.5.h),
            ),
            const SizedBox(width: 8), // Spacing
            // "All" Category Chip (selected if no category filter is active)
            ChoiceChip(
              label: const Text("All"),
              selected: viewModel.selectedCategory == null,
              selectedColor: AppColors.primaryLight.withOpacity(0.2),
              labelStyle: TextStyle(
                fontSize: 11.sp,
                fontWeight:
                    viewModel.selectedCategory == null
                        ? FontWeight.bold
                        : FontWeight.normal,
                color:
                    viewModel.selectedCategory == null
                        ? AppColors.primary
                        : AppColors.textGrey,
              ),
              onSelected: (selected) {
                if (selected)
                  viewModel.filterByCategory(null); // Clear category filter
              },
              backgroundColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: viewModel.selectedCategory == null ? 1 : 0,
              padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 0.5.h),
            ),
            const SizedBox(width: 8), // Spacing
            // Category Chips
            ...categories.map((category) {
              bool isSelected = viewModel.selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontSize: 11.sp,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textGrey,
                  ),
                  onSelected: (selected) {
                    if (selected) viewModel.filterByCategory(category);
                  },
                  backgroundColor: Colors.white,
                  shape: StadiumBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: isSelected ? 1 : 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.sp,
                    vertical: 0.5.h,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBody(
    BuildContext context,
    SuggestedFoodViewModel viewModel,
  ) {
    if (viewModel.isLoading && viewModel.displayedFoods.isEmpty) {
      // Show loading indicator only if the list is empty during load
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (viewModel.errorMessage != null && viewModel.displayedFoods.isEmpty) {
      // Show error message only if the list is empty due to error
      return _buildErrorWidget(
        context,
        viewModel.errorMessage!,
        () => viewModel.refreshFoods(),
      );
    }

    if (!viewModel.isLoading && viewModel.displayedFoods.isEmpty) {
      // Show empty state message after loading is complete
      String emptyMsg = "No suggested foods found.";
      if (viewModel.showFavoritesOnly)
        emptyMsg = "You haven't marked any foods as favorite yet.";
      else if (viewModel.selectedCategory != null)
        emptyMsg =
            "No foods found in the '${viewModel.selectedCategory}' category.";
      else if (viewModel.searchQuery != null)
        emptyMsg = "No foods found matching '${viewModel.searchQuery}'.";

      return _buildEmptyListPlaceholder(
        context,
        emptyMsg,
        () => viewModel.refreshFoods(),
      );
    }

    // --- Display the List ---
    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: viewModel.displayedFoods.length,
      itemBuilder: (context, index) {
        final food = viewModel.displayedFoods[index]; // Get FoodModel
        return _buildFoodListTile(context, viewModel, food); // Use helper
      },
      separatorBuilder:
          (context, index) =>
              const Divider(height: 1, thickness: 1), // Add dividers
    );
  }

  // Helper to build individual list tiles
  Widget _buildFoodListTile(
    BuildContext context,
    SuggestedFoodViewModel viewModel,
    FoodModel food,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 4.0,
      ),
      leading: SizedBox(
        // Constrain leading widget size
        width: 15.w, // Adjust width as needed
        height: 15.w,
        child: ClipRRect(
          // Rounded corners for image
          borderRadius: BorderRadius.circular(8.0),
          child:
              food.imageUrl != null && food.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: food.imageUrl!,
                    placeholder:
                        (context, url) => Container(color: Colors.grey[200]),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: AppColors.textGrey,
                          ),
                        ),
                    fit: BoxFit.cover,
                  )
                  : Container(
                    // Fallback if no image URL
                    color: AppColors.primaryLight.withOpacity(0.1),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.primary,
                    ),
                  ),
        ),
      ),
      title: Text(food.name, style: TextStyles.listTitle), // Use FoodModel name
      subtitle: Text(
        food.description,
        style: TextStyles.listSubtitle,
        maxLines: 2, // Limit description lines
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          food.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: food.isFavorite ? AppColors.primary : AppColors.textGrey,
        ),
        tooltip: food.isFavorite ? "Remove from favorites" : "Add to favorites",
        onPressed: () => viewModel.toggleFavorite(food.id), // Call VM method
      ),
      onTap: () {
        _logger.i("Tapped food item: ${food.name} (ID: ${food.id})");
        // Navigate to Food Detail Screen, passing the tapped FoodModel
        Navigator.pushNamed(
          context,
          NavigationRoutes.foodDetail,
          arguments: food, // Pass the whole object
        );
      },
    );
  }

  // Helper for Error Widget
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
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 16),
            Text(
              "Something Went Wrong",
              style: TextStyles.title.copyWith(color: Colors.redAccent),
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

  // Helper for Empty List Placeholder
  Widget _buildEmptyListPlaceholder(
    BuildContext context,
    String message,
    VoidCallback onRefresh,
  ) {
    // Wrap with LayoutBuilder and SingleChildScrollView to make it refreshable
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Make it scrollable for RefreshIndicator
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - kToolbarHeight - 100,
            ), // Adjust height to fill space roughly
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.no_food_outlined,
                      size: 50,
                      color: AppColors.textGrey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyles.bodyGrey,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: onRefresh,
                      child: const Text("Tap to refresh"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} // End of _SuggestedFoodScreenState
