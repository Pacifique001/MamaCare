import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:mama_care/presentation/view/article_view.dart';
import 'package:mama_care/presentation/viewmodel/article_viewmodel.dart';
import 'package:mama_care/domain/usecases/article_usecase.dart';
import 'package:mama_care/injection.dart';

class ArticleScreen extends StatelessWidget {
  final String articleId;

  const ArticleScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ArticleViewModel(
        locator<ArticleUseCase>(),
        locator<Logger>(),
        articleId,
      ),
      child: const ArticleView(),
    );
  }
}