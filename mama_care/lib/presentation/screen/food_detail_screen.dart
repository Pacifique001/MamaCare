// lib/presentation/screen/food_detail_screen.dart (NEW FILE)

import 'package:flutter/material.dart';
import 'package:mama_care/domain/entities/food_model.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/viewmodel/food_detail_viewmodel.dart';
import 'package:mama_care/presentation/view/food_detail_view.dart';

class FoodDetailScreen extends StatelessWidget {
  // Accept the FoodModel as an argument during navigation
  final FoodModel foodItem;

  const FoodDetailScreen({super.key, required this.foodItem});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FoodDetailViewModel>(
      create: (_) {
        final viewModel = locator<FoodDetailViewModel>();
        // Immediately set the food item in the ViewModel
        viewModel.setFoodItem(foodItem);
        return viewModel;
      },
      child: const FoodDetailView(), // Display the view
    );
  }
}