// lib/presentation/view/food_detail_view.dart (NEW FILE)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/food_detail_viewmodel.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:sizer/sizer.dart';

class FoodDetailView extends StatelessWidget {
  const FoodDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume the ViewModel provided by FoodDetailScreen
    return Consumer<FoodDetailViewModel>(
      builder: (context, viewModel, child) {
        final food = viewModel.foodItem; // Get the food item from VM

        // Handle loading or error state if VM loads by ID (not used in this example)
        // if (viewModel.isLoading) {
        //   return Scaffold(appBar: MamaCareAppBar(title: "Loading..."), body: Center(child: CircularProgressIndicator()));
        // }
        // if (viewModel.error != null) {
        //    return Scaffold(appBar: MamaCareAppBar(title: "Error"), body: Center(child: Text(viewModel.error!)));
        // }
        // Handle case where foodItem is somehow null (shouldn't happen with current setup)
        if (food == null) {
          return const Scaffold(
            appBar: MamaCareAppBar(title: "Error"),
            body: Center(child: Text("Food details not available.")),
          );
        }

        // Build the detail UI
        return Scaffold(
          appBar: MamaCareAppBar(
            title: food.name, // Show food name in AppBar
            // Optional: Add favorite toggle action here too
            // actions: [
            //    IconButton(
            //       icon: Icon(food.isFavorite ? Icons.favorite : Icons.favorite_border),
            //       onPressed: () { /* Call VM to toggle favorite */ },
            //    )
            // ],
          ),
          body: SingleChildScrollView(
            // Allow scrolling for long descriptions/benefits
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Image Header ---
                if (food.imageUrl != null && food.imageUrl!.isNotEmpty)
                  Hero(
                    // Add Hero animation for smooth transition
                    tag: 'food_image_${food.id}', // Use a unique tag
                    child: CachedNetworkImage(
                      imageUrl: food.imageUrl!,
                      height: 30.h, // Adjust height as needed
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            height: 30.h,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 30.h,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.textGrey,
                            ),
                          ),
                    ),
                  )
                else // Fallback if no image
                  Container(
                    height: 25.h,
                    width: double.infinity,
                    color: AppColors.primaryLight.withOpacity(0.2),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),

                // --- Content Padding ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Name and Category ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: TextStyles.headline2.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          // Optional: Favorite button inside content
                          // IconButton(...)
                        ],
                      ),
                      if (food.category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 4.0,
                            bottom: 12.0,
                          ),
                          child: Chip(
                            label: Text(food.category),
                            backgroundColor: AppColors.accent.withOpacity(0.15),
                            labelStyle: TextStyles.small.copyWith(
                              color: AppColors.accent,
                            ), // Use accent color maybe
                            materialTapTargetSize:
                                MaterialTapTargetSize
                                    .shrinkWrap, // Smaller tap target
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                          ),
                        ),
                      const Divider(),

                      // --- Description ---
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          "Description",
                          style: TextStyles.title.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(food.description, style: TextStyles.body),
                      const SizedBox(height: 20),

                      // --- Benefits ---
                      if (food.benefits.isNotEmpty) ...[
                        Text(
                          "Key Benefits",
                          style: TextStyles.title.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          // Use Wrap for flexible layout of benefit chips
                          spacing: 8.0, // Horizontal space between chips
                          runSpacing: 4.0, // Vertical space between lines
                          children:
                              food.benefits
                                  .map(
                                    (benefit) => Chip(
                                      label: Text(benefit),
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.1),
                                      labelStyle: TextStyles.small.copyWith(
                                        color: AppColors.primary,
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Add more sections as needed (e.g., Nutritional Info, Recipes)
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
