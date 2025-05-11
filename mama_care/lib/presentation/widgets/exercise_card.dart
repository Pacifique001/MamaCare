import 'package:flutter/material.dart';
import '../screen/exercise_detail_screen.dart';

class ExerciseCard extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final Color cardColor;
  final double borderRadius;
  final EdgeInsetsGeometry margin;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final double imageSize;
  final double imageBorderRadius;

  const ExerciseCard({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    this.cardColor = Colors.white,
    this.borderRadius = 10.0,
    this.margin = const EdgeInsets.symmetric(vertical: 10),
    this.titleStyle,
    this.descriptionStyle,
    this.imageSize = 80,
    this.imageBorderRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: margin,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        highlightColor: Colors.transparent,
        splashColor: Colors.pinkAccent.withOpacity(0.2),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseDetailPage(
                title: title,
                description: description,
                image: image,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: imageSize,
                height: imageSize,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(imageBorderRadius),
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleStyle ?? const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${description.substring(0, 30)}...',
                      style: descriptionStyle ?? const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
