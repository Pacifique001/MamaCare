import 'package:flutter/material.dart';
import 'package:mama_care/presentation/widgets/mama_care_app_bar.dart';
import 'package:mama_care/utils/asset_helper.dart';
import 'package:mama_care/presentation/screen/exercise_detail_screen.dart';
import '../widgets/exercise_card.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int _currentTrimester = 1;

  final List<Map<String, dynamic>> _firstTrimesterExercises = [
    {
      'title': 'Walking',
      'description':
          'Walking is a great low-impact exercise that can help maintain fitness during the first trimester. Its easy to do and can be done anywhere.',
      'image': AssetsHelper.walking,
    },
    {
      'title': 'Swimming',
      'description':
          'Swimming is a safe and low-impact exercise that can help alleviate pregnancy-related discomforts such as back pain and swollen ankles.',
      'image': AssetsHelper.swimming,
    },
    {
      'title': 'Yoga',
      'description':
          'Yoga is a gentle form of exercise that can help improve flexibility, balance, and strength. Its also a great way to reduce stress and improve sleep.',
      'image': AssetsHelper.yoga,
    },
    {
      'title': 'Strength training',
      'description':
          'Strength training with light weights or resistance bands can help maintain muscle tone and prepare the body for the physical demands of pregnancy.',
      'image': AssetsHelper.strengthTraining,
    },
    {
      'title': 'Stretching',
      'description':
          'Gentle stretching can help alleviate muscle tension and improve flexibility during the first trimester.',
      'image': AssetsHelper.stretching,
    },
    {
      'title': 'Kegels',
      'description':
          'Kegel exercises can help strengthen the pelvic floor muscles, which can be weakened during pregnancy and childbirth.',
      'image': AssetsHelper.kegels,
    }
  ];

  final List<Map<String, dynamic>> _secondTrimesterExercises = [
    {
      'title': 'Prenatal Pilates',
      'description':
          'Pilates is a great way to strengthen your core and improve your posture during pregnancy. Prenatal Pilates classes are designed to be safe and effective for expectant mothers.',
      'image': AssetsHelper.prenatalPilates,
    },
    {
      'title': 'Low-impact aerobics',
      'description':
          'Low-impact aerobics can help improve cardiovascular fitness and maintain muscle tone. Its important to choose a class specifically designed for pregnant women.',
      'image': AssetsHelper.lowImpactAerobics,
    },
    {
      'title': 'Stationary cycling',
      'description':
          'Stationary cycling is a low-impact exercise that can help improve cardiovascular fitness and strengthen leg muscles.',
      'image': AssetsHelper.stationaryCycling,
    },
    {
      'title': 'Dancing',
      'description':
          'Dancing is a fun and low-impact way to improve cardiovascular fitness and maintain muscle tone during pregnancy.',
      'image': AssetsHelper.dancing,
    },
    {
      'title': 'Squats',
      'description':
          'Squats can help strengthen the legs and prepare the body for the physical demands of labor and delivery.',
      'image': AssetsHelper.squats,
    }
  ];

  final List<Map<String, dynamic>> _thirdTrimesterExercises = [
    {
      'title': 'Prenatal yoga',
      'description':
          'Prenatal yoga can help prepare the body for labor and delivery by improving flexibility and strength. Its also a great way to reduce stress and improve sleep.',
      'image': AssetsHelper.prenatalYoga,
    },
    {
      'title': 'Swimming',
      'description':
          'Swimming is a great exercise during the third trimester because it reduces stress on the joints and can help alleviate discomforts such as back pain and swollen ankles.',
      'image': AssetsHelper.swimming,
    },
    {
      'title': 'Walking',
      'description':
          'Walking is a safe and easy way to maintain fitness during the third trimester. It can also help prepare the body for labor by improving endurance.',
      'image': AssetsHelper.walking,
    },
    {
      'title': 'Pelvic tilts',
      'description':
          'Pelvic tilts can help alleviate back pain and improve posture during the third trimester.',
      'image': AssetsHelper.pelvicTilts,
    },
    {
      'title': 'Wall push-ups',
      'description':
          'Wall push-ups can help maintain upper body strength and prepare the body for the physical demands of labor and delivery.',
      'image': AssetsHelper.wallPushUps,
    },
    {
      'title': 'Modified planks',
      'description':
          'Modified planks can help strengthen the core muscles and prepare the body for pushing during labor.',
      'image': AssetsHelper.modifiedPlanks,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MamaCareAppBar(
        title: "Exercise",
        trailingWidget: null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildTrimesterButtons(),
              const SizedBox(height: 10),
              ..._getExercisesList(_currentTrimester),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrimesterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTrimesterButton("1st Trimester", 1),
        const SizedBox(width: 10),
        _buildTrimesterButton("2nd Trimester", 2),
        const SizedBox(width: 10),
        _buildTrimesterButton("3rd Trimester", 3),
      ],
    );
  }

  Widget _buildTrimesterButton(String label, int trimester) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _currentTrimester = trimester;
          });
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: _currentTrimester == trimester ? Colors.white : Colors.grey,
          backgroundColor: _currentTrimester == trimester ? Colors.pink : Colors.white,
          fixedSize: const Size.fromHeight(45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<Widget> _getExercisesList(int trimester) {
    List<Map<String, dynamic>> exercises;
    switch (trimester) {
      case 1:
        exercises = _firstTrimesterExercises;
        break;
      case 2:
        exercises = _secondTrimesterExercises;
        break;
      case 3:
        exercises = _thirdTrimesterExercises;
        break;
      default:
        exercises = [];
    }
    return exercises
        .map(
          (exercise) => GestureDetector(
            onTap: () {
              // Navigate to exercise detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailPage(
                    title: exercise['title'],
                    description: exercise['description'],
                    image: exercise['image'],
                  ),
                ),
              );
            },
            child: ExerciseCard(
              title: exercise['title'],
              description: exercise['description'],
              image: exercise['image'],
            ),
          ),
        )
        .toList();
  }
}
