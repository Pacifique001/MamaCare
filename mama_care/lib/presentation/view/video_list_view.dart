// presentation/view/video_list_view.dart (or screen)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:mama_care/presentation/viewmodel/video_list_viewmodel.dart';
import 'package:mama_care/navigation/router.dart'; // Make sure router has videoPlayer route
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/domain/entities/video_model.dart'; // Import model
import 'package:mama_care/utils/app_colors.dart'; // For colors
import 'package:cached_network_image/cached_network_image.dart'; // Use cached_network_image
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart'; // <-- Import AuthViewModel

class VideoListView extends StatefulWidget {
  const VideoListView({super.key});

  @override
  State<VideoListView> createState() => _VideoListViewState();
}

class _VideoListViewState extends State<VideoListView> {
  String? _userId; // Store the user ID

  @override
  void initState() {
    super.initState();
    // Fetch video data when the view is initialized
    // Use addPostFrameCallback to safely call Provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // Helper function to load initial data requiring userId
  void _loadInitialData() {
    // Get userId from AuthViewModel
    // Use read as it's for an initial action, not continuous listening here
    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.uid; // Or localUser?.id

    if (currentUserId != null) {
      setState(() {
        _userId = currentUserId; // Store userId for later use (e.g., refresh)
      });
      // Call loadVideos with userId
      context.read<VideoListViewModel>().loadVideos(userId: currentUserId);
    } else {
      // Handle user not logged in
      debugPrint("VideoListView: User not logged in, cannot load favorite videos.");
      // Optionally, load videos without favorites or show a message
      // context.read<VideoListViewModel>().loadVideosWithoutFavorites(); // Needs implementation in VM
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Log in to see personalized video recommendations and favorites.")),
       );
       // Load the basic list anyway, without favorites marked
       context.read<VideoListViewModel>().loadVideos(userId: ''); // Pass empty ID or handle in VM
    }
  }

  // Function to handle refresh action
  Future<void> _handleRefresh() async {
    if (_userId != null) {
      // Pass the stored userId to refresh
      await context.read<VideoListViewModel>().refreshVideos(userId: _userId!);
    } else {
      // If userId wasn't available initially, try loading again
      _loadInitialData();
    }
  }


  @override
  Widget build(BuildContext context) {
    // Use Consumer for better rebuilding control based on VideoListViewModel changes
    return Consumer<VideoListViewModel>(
      builder: (context, videoViewModel, child) {
        return Scaffold(
          appBar: MamaCareAppBar(
            title: "Helpful Videos",
             // TODO: Implement search functionality if needed
             // actions: [
             //   IconButton(
             //     icon: Icon(Icons.search, color: AppColors.primary),
             //     onPressed: () { /* Show search bar or dialog */ },
             //   ),
             // ],
          ),
          // Use a nested Consumer for AuthViewModel ONLY if needed within the body
          // Otherwise, accessing via context.read in actions is better.
          body: _buildBody(context, videoViewModel),
        );
      },
    );
  }

   Widget _buildBody(BuildContext context, VideoListViewModel videoViewModel) {
     // Show loading indicator only when loading initial data
     if (videoViewModel.isLoading && videoViewModel.videos.isEmpty) {
       return const Center(child: CircularProgressIndicator(color: AppColors.primary));
     }

     // Show error message if present
     if (videoViewModel.errorMessage != null) {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(20.0),
           child: Column( // Use Column for text and refresh button
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text(
                 'Error: ${videoViewModel.errorMessage}',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: Colors.red.shade700, fontSize: 16),
               ),
               const SizedBox(height: 15),
               ElevatedButton.icon(
                 icon: const Icon(Icons.refresh),
                 label: const Text('Retry'),
                 onPressed: _handleRefresh, // Call retry function
                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
               )
             ],
           ),
         ),
       );
     }

     // Show 'No videos found' message if list is empty after loading
     if (!videoViewModel.isLoading && videoViewModel.videos.isEmpty) {
       return const Center(
         child: Text('No videos found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
       );
     }

     // Use RefreshIndicator for pull-to-refresh
     return RefreshIndicator(
       onRefresh: _handleRefresh, // Use the refresh handler
       color: AppColors.primary,
       child: ListView.builder(
         padding: const EdgeInsets.all(12), // Adjusted padding
         itemCount: videoViewModel.videos.length,
         itemBuilder: (context, index) {
           final video = videoViewModel.videos[index];
           // Pass the video model and the necessary userId to the card
           return VideoListCard(
             video: video,
             userId: _userId, // Pass userId for favorite action
           );
         },
       ),
     );
   }
}


class VideoListCard extends StatelessWidget {
  final VideoModel video;
  final String? userId; // Receive userId from the parent

  const VideoListCard({
    super.key,
    required this.video,
    required this.userId, // Add userId parameter
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the video player screen, passing the video URL
        if (video.url.isNotEmpty) {
             Navigator.pushNamed(
               context,
            NavigationRoutes.videoPlayer, // Navigate to the PLAYER route
            arguments: video.url, // Pass the video URL
             );
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Video URL is missing.")),
            );
        }
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                           color: Colors.grey.shade300,
                           child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight)),
                       ),
                      errorWidget: (context, url, error) => Container(
                           color: Colors.grey.shade100,
                           child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                      ),
                  ),
                  Container(
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 60,
                          color: Colors.white,
                      ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(
                       video.title,
                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: AppColors.textDark,
                       ),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.8.h),
                    Text(
                       video.description,
                       style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                          // --- Updated Favorite Button ---
                          IconButton(
                             iconSize: 28,
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                             tooltip: video.isFavorite ? "Remove from Favorites" : "Save to Favorites",
                             // Disable button if userId is null (user not logged in)
                             onPressed: userId == null ? () {
                                // Prompt user to log in if they try to favorite while logged out
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please log in to save favorites.")),
                                );
                             } : () async {
                                // User is logged in, proceed with toggle
                                final videoViewModel = Provider.of<VideoListViewModel>(
                                  context,
                                  listen: false,
                                );
                                // Call toggleFavorite with the received userId and videoId
                                await videoViewModel.toggleFavorite(
                                  userId: userId!, // Use the passed userId
                                  videoId: video.id,
                                );

                                // Show feedback based on new status
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                // Check the updated status from the ViewModel for accurate feedback
                                final updatedVideo = videoViewModel.getVideoById(video.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                       (updatedVideo?.isFavorite ?? video.isFavorite) // Use updated status if available
                                           ? "'${video.title}' saved to favorites!"
                                           : "'${video.title}' removed from favorites."
                                    ),
                                     behavior: SnackBarBehavior.floating,
                                     duration: const Duration(seconds: 2),
                                  ),
                                );
                             },
                             icon: Icon(
                               video.isFavorite
                                   ? Icons.bookmark_rounded // Filled icon for favorite
                                   : Icons.bookmark_border_rounded, // Border icon otherwise
                               // Dim the icon if the user is not logged in
                               color: userId != null ? AppColors.primary : Colors.grey,
                             ),
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