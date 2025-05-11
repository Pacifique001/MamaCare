
import '../../utils/asset_helper.dart';

class OnboardingEntity {
  final String image;
  final String title;
  final String description;

  OnboardingEntity({
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [image, title, description];
}

final List<OnboardingEntity> mainOnboardings = [
  OnboardingEntity(
    image: AssetsHelper.walking,
    title: 'Welcome to MamaCare',
    description: 'Your trusted companion for maternal health and wellness.',
  ),
  OnboardingEntity(
    image: AssetsHelper.swimming,
    title: 'Track Your Progress',
    description: 'Monitor your pregnancy journey with ease and confidence.',
  ),
  OnboardingEntity(
    image: AssetsHelper.yoga,
    title: 'Educational Resources',
    description: 'Access articles, videos, and podcasts to stay informed.',
  ),
  OnboardingEntity(
    image: AssetsHelper.dancing,
    title: 'Community Support',
    description: 'Connect with other moms and share your experiences.',
  ),
];
