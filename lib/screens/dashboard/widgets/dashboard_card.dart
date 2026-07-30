import 'package:flutter/material.dart';
import '../../../../widgets/dashboard/dashboard_widgets.dart';
import '../../grain_batches/grain_batch_detail_screen.dart';
import '../../grain_batches/grain_batches_screen.dart';

class RecentBatchesSection extends StatelessWidget {
  final List<Map<String, dynamic>> recentBatches;
  final VoidCallback onViewAll;

  const RecentBatchesSection({
    super.key,
    required this.recentBatches, 
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recentBatches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Batches',
          actionLabel: 'VIEW ALL',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GrainBatchesScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        ...recentBatches.take(3).map((batch) {
          final id = batch['id'] ?? batch['_id'];
          final grainName = batch['grain'] ?? batch['crop'] ?? batch['grain_type'] ?? 'Rice';
          
          num weightNum = 0;
          if (batch['quantity'] != null) {
            weightNum = (batch['quantity'] is num) ? batch['quantity'] : num.tryParse(batch['quantity'].toString()) ?? 0;
          } else if (batch['weight'] != null) {
            weightNum = (batch['weight'] is num) ? batch['weight'] : num.tryParse(batch['weight'].toString()) ?? 0;
          } else if (batch['quantity_kg'] != null) {
            weightNum = (batch['quantity_kg'] is num) ? batch['quantity_kg'] : num.tryParse(batch['quantity_kg'].toString()) ?? 0;
          }
          final quantityStr = '${weightNum.toStringAsFixed(0)} kg';

          String siloName = 'Silo 1';
          if (batch['silo'] is Map) {
            siloName = batch['silo']['name'] ?? 'Silo 1';
          } else if (batch['silo'] is String && (batch['silo'] as String).isNotEmpty) {
            siloName = batch['silo'];
          }

          final rawRisk = batch['risk'] ?? batch['status'] ?? 'Low Risk';
          String riskLevel = rawRisk.toString();
          if (riskLevel.toLowerCase() == 'low' || riskLevel.toLowerCase() == 'stored' || riskLevel.toLowerCase() == 'active') {
            riskLevel = 'Low Risk';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: BatchCard(
              grainName: grainName,
              quantity: quantityStr,
              siloName: siloName,
              riskLevel: riskLevel,
              onPressed: () {
                if (id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GrainBatchDetailScreen(batchId: id.toString()),
                    ),
                  );
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

