import 'package:flutter/material.dart';
import 'package:mama_care/domain/entities/pregnancy_details.dart';
import 'package:path/path.dart';
import 'package:mama_care/utils/app_theme.dart';


class BabyInfoSection extends StatelessWidget {
  final PregnancyDetails? details;

   const   BabyInfoSection({
        super.key,
        required this.details});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricRow(
              icon: Icons.monitor_weight,
              label: 'Weight',
              value: '${details?.babyWeight ?? 'N/A'} kg',
            ),
            const Divider(),
            _buildMetricRow(
              icon: Icons.height,
              label: 'Height',
              value: '${details?.babyHeight ?? 'N/A'} cm',
            ),
            const Divider(),
            _buildMetricRow(
              icon: Icons.timeline,
              label: 'Days Remaining',
              value: '${details?.daysRemaining ?? 'N/A'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.pinkAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context as BuildContext).babyMetricLabel),
                Text(value, style: Theme.of(context as BuildContext).babyMetricValue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}