// lib/presentation/view/article_list_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart'; // For logging taps
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:mama_care/presentation/viewmodel/article_list_viewmodel.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/navigation/router.dart';
import 'package:mama_care/domain/entities/article_model.dart';
import 'package:mama_care/utils/app_colors.dart';
import 'package:mama_care/utils/text_styles.dart';
import 'package:mama_care/injection.dart'; // For logger
import 'package:cached_network_image/cached_network_image.dart'; // For images


class ArticleListView extends StatefulWidget {
  const ArticleListView({super.key});

  @override
  State<ArticleListView> createState() => _ArticleListViewState();
}

class _ArticleListViewState extends State<ArticleListView> {
  final Logger _logger = locator<Logger>(); // Logger

  @override
  void initState() {
    super.initState();
    // Fetch articles when the view is initialized
    // Use addPostFrameCallback to access provider safely in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Use context.read as it's a one-time action in initState
      context.read<ArticleListViewModel>().fetchArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react to ViewModel changes
    return Consumer<ArticleListViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: MamaCareAppBar(
            title: "Helpful Articles", // Updated title
             actions: [
                 IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: "Search Articles",
                    onPressed: () => _showSearchDialog(context, viewModel), // Implement search
                  ),
                // Optional: Filter button
                //  IconButton(
                //     icon: const Icon(Icons.filter_list),
                //     tooltip: "Filter Articles",
                //     onPressed: () => _showFilterDialog(context, viewModel),
                //   ),
             ],
          ),
          body: _buildBody(context, viewModel),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ArticleListViewModel vm) {
    if (vm.isLoading && vm.articles.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    // Show error only if the list is also empty (allow showing stale data during failed refresh)
    if (vm.errorMessage != null && vm.articles.isEmpty) {
      return Center(
          child: Padding( padding: const EdgeInsets.all(20), child: Text("Error: ${vm.errorMessage}", style: TextStyles.bodyGrey.copyWith(color: Colors.redAccent)) )
      );
    }
    if (vm.articles.isEmpty && !vm.isLoading) { // Handle empty state after load
      return Center(child: Text("No articles available.", style: TextStyles.bodyGrey));
    }

    // Display the list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: vm.refreshArticles,
      color: AppColors.primary,
      child: ListView.builder(
        key: const PageStorageKey('articleList'), // Keep scroll position
        padding: const EdgeInsets.all(16),
        itemCount: vm.articles.length,
        itemBuilder: (context, index) {
          final article = vm.articles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ArticleListCard(
              key: ValueKey(article.id), // Use unique key
              article: article, // Pass the full model
              onTap: () => _navigateToArticleDetail(context, article.id),
              onBookmarkTap: () => _toggleBookmark(context, vm, article),
            ),
          );
        },
      ),
    );
  }

   void _navigateToArticleDetail(BuildContext context, String articleId) {
      _logger.d("Navigating to article detail: $articleId");
      // Pass articleId as argument to the ArticleScreen route
      Navigator.pushNamed(
          context,
          NavigationRoutes.article,
          arguments: articleId,
      );
   }

   Future<void> _toggleBookmark(BuildContext context, ArticleListViewModel vm, ArticleModel article) async {
      final bool success = await vm.toggleBookmark(article);
      if (!mounted) return; // Check mounted state after await
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (article.isBookmarked // Use OLD status for message logic
                  ? "Removed from Bookmarks"
                  : "Article Bookmarked!")
              : vm.errorMessage ?? "Failed to update bookmark"), // Use error from VM if toggle failed
          backgroundColor: success ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
   }

   // --- Placeholder Search/Filter Dialogs ---
   void _showSearchDialog(BuildContext context, ArticleListViewModel viewModel) {
      _logger.d("Show search dialog triggered");
      // Example: Using showSearch delegate
      showSearch(context: context, delegate: ArticleSearchDelegate(viewModel));
   }
    // void _showFilterDialog(BuildContext context, ArticleListViewModel viewModel) {
    //    _logger.d("Show filter dialog triggered");
    //    // Implement filter options (e.g., by tag/category)
    // }
}


// --- Article List Card Widget ---
class ArticleListCard extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  const ArticleListCard({
    super.key,
    required this.article,
    required this.onTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = article.imageUrl.isNotEmpty; // Check if URL is not empty

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        clipBehavior: Clip.antiAlias, // Clip image
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (hasImage) // Only show image if URL exists
               Hero( // Add Hero animation for transition
                  tag: 'article_image_${article.id}', // Unique tag
                  child: CachedNetworkImage( // Use CachedNetworkImage
                     imageUrl: article.imageUrl,
                     height: 25.h,
                     width: double.infinity,
                     fit: BoxFit.cover,
                     placeholder: (context, url) => Container(height: 25.h, alignment: Alignment.center, color: Colors.grey.shade200, child: const CircularProgressIndicator(strokeWidth: 2)),
                     errorWidget: (context, url, error) => Container(height: 25.h, alignment: Alignment.center, color: Colors.grey.shade200, child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 40)),
                   ),
               )
            else // Placeholder if no image
                Container(height: 10, color: Colors.grey.shade100), // Minimal space or specific placeholder

            // Text Content Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if(article.tags.isNotEmpty) // Display tags if available
                     Padding(
                       padding: const EdgeInsets.only(bottom: 6.0),
                       child: Wrap( spacing: 6, runSpacing: 4, children: article.tags.map((tag) => Chip( label: Text(tag), padding: EdgeInsets.zero, labelStyle: TextStyles.small.copyWith(color: AppColors.primary), backgroundColor: AppColors.primary.withOpacity(0.1), visualDensity: VisualDensity.compact, side: BorderSide.none )).toList(), ),
                     ),
                  Text( article.title, style: TextStyles.titleCard, maxLines: 2, overflow: TextOverflow.ellipsis, ),
                  const SizedBox(height: 6),
                  Text( article.content, style: TextStyles.bodyGrey, maxLines: 3, overflow: TextOverflow.ellipsis, ),
                  const SizedBox(height: 8),
                  // Footer Row
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(article.author, style: TextStyles.smallGrey, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textGrey),
                       const SizedBox(width: 4),
                      Text(DateFormat.yMd().format(article.publishDate), style: TextStyles.smallGrey), // Format date
                      const Spacer(), // Pushes bookmark to the end
                      IconButton(
                        visualDensity: VisualDensity.compact, // Make button smaller
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(), // Remove default padding
                        iconSize: 22, // Adjust icon size
                        onPressed: onBookmarkTap,
                        icon: Icon(
                          article.isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                          color: AppColors.primary,
                        ),
                        tooltip: article.isBookmarked ? "Remove Bookmark" : "Bookmark Article",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Search Delegate Example ---
class ArticleSearchDelegate extends SearchDelegate<ArticleModel?> {
   final ArticleListViewModel viewModel;

   ArticleSearchDelegate(this.viewModel);

   @override
   ThemeData appBarTheme(BuildContext context) {
     // Customize search app bar theme
     return Theme.of(context).copyWith(
       appBarTheme: Theme.of(context).appBarTheme.copyWith(
         backgroundColor: AppColors.background, // Example color
         foregroundColor: AppColors.textDark,
         elevation: 1.0
       ),
       inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyles.bodyGrey,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
       ),
     );
   }


   @override
   List<Widget>? buildActions(BuildContext context) {
     // Actions for the app bar (e.g., clear query button)
     return [
       if (query.isNotEmpty)
         IconButton(
           icon: const Icon(Icons.clear),
           tooltip: "Clear Search",
           onPressed: () {
             query = ''; // Clear the search query
             showSuggestions(context); // Show suggestions again
           },
         ),
     ];
   }

   @override
   Widget? buildLeading(BuildContext context) {
     // Leading icon on the left of the app bar (e.g., back button)
     return IconButton(
       icon: const Icon(Icons.arrow_back),
       tooltip: "Back",
       onPressed: () {
         close(context, null); // Close the search delegate, return null
       },
     );
   }

   @override
   Widget buildResults(BuildContext context) {
     // Show results based on the query after user presses search/enter
      if (query.trim().isEmpty) {
         return const Center(child: Text("Please enter a search term."));
      }
      // Trigger search in ViewModel (debouncing recommended for real app)
      viewModel.searchArticles(query);
      // Use a Consumer to display results from the ViewModel
      return Consumer<ArticleListViewModel>(
        builder: (context, vm, _) {
           if (vm.isLoading) return const Center(child: CircularProgressIndicator());
           if (vm.errorMessage != null) return Center(child: Text("Error: ${vm.errorMessage}"));
           if (vm.articles.isEmpty) return Center(child: Text("No results found for '$query'."));

           // Display results using the same card as the main list
           return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.articles.length,
              itemBuilder: (context, index) {
                 final article = vm.articles[index];
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 16.0),
                   child: ArticleListCard(
                     article: article,
                     onTap: () => close(context, article), // Close search and return selected article
                     onBookmarkTap: () => vm.toggleBookmark(article), // Allow bookmarking from search
                   ),
                 );
              },
           );
        }
      );
   }

   @override
   Widget buildSuggestions(BuildContext context) {
     // Show suggestions as the user types (optional)
     // You could show recent searches or pre-fetched suggestions here.
     // For simplicity, we'll just show a prompt.
     return Center(
       child: Text("Enter keywords to search articles...", style: TextStyles.bodyGrey),
     );
   }
}