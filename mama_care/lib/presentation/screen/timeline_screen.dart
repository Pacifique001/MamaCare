import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/injection.dart';
import 'package:mama_care/presentation/view/timeline_view.dart';
import 'package:mama_care/presentation/viewmodel/timeline_viewmodel.dart';
import 'package:mama_care/domain/usecases/timeline_use_case.dart';
import 'package:mama_care/data/local/database_helper.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => TimelineViewModel(timelineUseCase: locator<TimelineUseCase>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Timeline')),
        body: const TimelineView(),
      ),
    );
  }
}
