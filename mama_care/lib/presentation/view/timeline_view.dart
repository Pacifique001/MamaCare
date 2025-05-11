import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/viewmodel/timeline_viewmodel.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:sizer/sizer.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<TimelineViewModel>();
      viewModel.fetchPregnancyDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null) {
          return Center(child: Text(viewModel.errorMessage!));
        }

        return Scaffold(
          appBar: MamaCareAppBar(
            title: "Timeline",
            trailingWidget: const Icon(Icons.more_vert, color: Colors.pinkAccent),
          ),
          body: _buildTimelineList(viewModel),
        );
      },
    );
  }

  Widget _buildTimelineList(TimelineViewModel viewModel) {
    final currentWeek = viewModel.weeksPregnant.clamp(0, viewModel.weeks.length - 1);

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: viewModel.weeks.length,
      separatorBuilder: (context, index) => Divider(height: 2.h, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final isCurrentWeek = index == currentWeek;
        final weekData = viewModel.weeks[index];

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineIndicator(isCurrentWeek),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekData[0],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrentWeek ? Colors.pinkAccent : Colors.grey[700],
                          ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      weekData[1],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineIndicator(bool isCurrentWeek) {
    return Column(
      children: [
        SvgPicture.asset(
          AssetsHelper.timelineIndicator,
          color: isCurrentWeek ? Colors.pinkAccent : const Color(0xFFFFCDD2),
          width: 6.w,
        ),
        if (isCurrentWeek)
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 2.w,
            height: 2.w,
            decoration: const BoxDecoration(
              color: Colors.pinkAccent,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}