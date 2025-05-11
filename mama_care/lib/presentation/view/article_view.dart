// lib/presentation/view/article_view.dart

import 'package:cached_network_image/cached_network_image.dart'; // Use cached_network_image
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:mama_care/presentation/viewmodel/article_viewmodel.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/domain/entities/article_model.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/injection.dart'; // For locator
import 'package:mama_care/domain/usecases/article_usecase.dart'; // Import UseCase
import 'package:share_plus/share_plus.dart'; // For sharing

// Screen wrapper that provides the ViewModel with the required articleId
class ArticleScreen extends StatelessWidget {
  final String articleId;
  const ArticleScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Create ViewModel instance using locator, passing articleId as factoryParam
      create: (_) => locator<ArticleViewModel>(param1: articleId),
      child: const ArticleView(), // The actual view widget
    );
  }
}

// The actual Screen content widget
class ArticleView extends StatelessWidget {
  const ArticleView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to ViewModel changes
    return Consumer<ArticleViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          // AppBar appears over image
          extendBodyBehindAppBar: true,
          appBar: AppBar( // Use standard AppBar for more flexibility here
            backgroundColor: Colors.transparent, // Make AppBar transparent
            elevation: 0, // Remove shadow
            leading: IconButton( // Custom back button
               icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)
               ),
               tooltip: 'Back',
               onPressed: () => Navigator.pop(context),
             ),
            actions: [ // Share and Bookmark actions
              if (vm.article != null)
                 IconButton(
                   icon: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                     child: const Icon(Icons.share_outlined, color: Colors.white, size: 18)
                   ),
                   tooltip: 'Share Article',
                   onPressed: vm.shareArticle,
                 ),
              if (vm.article != null)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                    child: Icon(
                      vm.isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                      color: vm.isBookmarked ? AppColors.accent : Colors.white, // Highlight if bookmarked
                      size: 18,
                    ),
                  ),
                  tooltip: vm.isBookmarked ? 'Remove Bookmark' : 'Bookmark Article',
                  onPressed: vm.isLoading ? null : () => _handleBookmarkToggle(context, vm), // Disable while loading
                ),
               const SizedBox(width: 8), // Padding for actions
            ],
          ),
          body: _buildBody(context, vm),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ArticleViewModel vm) {
    if (vm.isLoading && vm.article == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (vm.errorMessage != null && vm.article == null) {
      return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Text("Error: ${vm.errorMessage}", style: TextStyles.bodyGrey.copyWith(color: Colors.redAccent)),),);
    }
    if (vm.article == null) {
      return Center(child: Text("Article details not available.", style: TextStyles.bodyGrey));
    }

    final article = vm.article!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article Image Header with Hero animation
          Hero(
             tag: 'article_image_${article.id}', // Must match tag in list card
             child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                height: 35.h, // Adjust height as needed
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 35.h, color: Colors.grey.shade300, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, url, error) => Container(height: 35.h, color: Colors.grey.shade200, alignment: Alignment.center, child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 50)),
              ),
          ),

          // Content Padding
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Title
                Text( article.title, style: TextStyles.headline1.copyWith(color: AppColors.primary), ),
                const SizedBox(height: 12),
                 // Author and Date Row
                Row( children: [ const Icon(Icons.person_outline, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(article.author, style: TextStyles.smallGrey), const SizedBox(width: 12), const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(DateFormat.yMMMd().format(article.publishDate), style: TextStyles.smallGrey), ], ),
                const Divider(height: 24, thickness: 1),
                 // Article Content
                Text( article.content, style: TextStyles.body.copyWith(fontSize: 14.sp, height: 1.6), ), // Adjust size/line height
                const SizedBox(height: 20),
                 // Tags
                 if (article.tags.isNotEmpty)
                   Wrap( spacing: 8.0, runSpacing: 4.0, children: article.tags.map((tag) => Chip( label: Text(tag), backgroundColor: AppColors.primaryLight.withOpacity(0.1), labelStyle: TextStyles.smallPrimary, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), side: BorderSide.none )).toList(), ),
                 const SizedBox(height: 30),
                 // Placeholder for Comments
                   Text("Comments", style: TextStyles.title),
                   Divider(),
                 // ... comment list and input ...
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handle bookmark toggle with feedback
  Future<void> _handleBookmarkToggle(BuildContext context, ArticleViewModel vm) async {
     final bool success = await vm.toggleBookmark();
      if (!context.mounted) return; // Check mounted after await
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text(success
             ? (vm.isBookmarked ? "Article Bookmarked!" : "Bookmark Removed")
             : vm.errorMessage ?? "Failed to update bookmark"),
         backgroundColor: success ? Colors.green : Colors.redAccent,
      ));
  }
}