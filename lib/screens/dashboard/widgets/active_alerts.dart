import 'package:flutter/material.dart';
import '../../../../config/grainhero_colors.dart';
import '../../../../widgets/dashboard/dashboard_widgets.dart';

class ActiveAlertsSection extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final Function(String) onAcknowledge;

  const ActiveAlertsSection({
    super.key,
    required this.alerts,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Active Alerts',
                style: TextStyle(
                  color: GrainHeroColors.bodyText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: GrainHeroColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                alerts.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ActiveAlertCard(
          title: alerts.first['title'] ?? alerts.first['type'] ?? 'Alert',
          description: alerts.first['message'] ?? alerts.first['description'] ?? '',
          onAcknowledge: () {
            if (alerts.first['id'] != null) {
              onAcknowledge(alerts.first['id'].toString());
            } else if (alerts.first['_id'] != null) {
              onAcknowledge(alerts.first['_id'].toString());
            }
          },
        ),
      ],
    );
  }
}
