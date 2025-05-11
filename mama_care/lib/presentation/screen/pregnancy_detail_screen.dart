import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mama_care/presentation/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/domain/usecases/pregnancy_detail_use_case.dart';
import 'package:mama_care/data/local/database_helper.dart';
import 'package:mama_care/presentation/viewmodel/pregnancy_detail_viewmodel.dart';
import 'package:mama_care/presentation/view/pregnancy_detail_view.dart';
import 'package:mama_care/injection.dart';

class PregnancyDetailScreen extends StatelessWidget {
  const PregnancyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PregnancyDetailViewModel(
        locator<PregnancyDetailUseCase>(),
        locator<AuthViewModel>(),
        locator<Logger>(),
      ),
      child: PregnancyDetailView(),
    );
  }
}
