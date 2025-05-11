import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/view/video_list_view.dart';
import 'package:mama_care/presentation/viewmodel/video_list_viewmodel.dart';
import 'package:mama_care/domain/usecases/video_usecase.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/injection.dart';

class VideoListScreen extends StatelessWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoListViewModel(
        locator<DatabaseHelper>(),
      ),
      child: const Scaffold(
        body: VideoListView(),
      ),
    );
  }
}
