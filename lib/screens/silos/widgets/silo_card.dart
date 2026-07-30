import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/models/silo_model.dart';
import 'package:grainhero_technician_app/screens/silos/silo_detail_screen.dart';

class SiloCard extends StatelessWidget {
  final SiloModel silo;

  const SiloCard({super.key, required this.silo});

  @override
  Widget build(BuildContext context) {
    final fillPercent = silo.fillPercentage;
    final isFull = fillPercent > 0.9;
    final isEmpty = fillPercent < 0.1;
    final statusColor = silo.status.toLowerCase() == 'active' ? AuthTheme.primaryGreen : const Color(0xFFFF5C5C);
    
    final temp = silo.temperature ?? 0;
    final hum = silo.humidity ?? 0;
    final tvoc = silo.tvoc ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthTheme.primaryGreen.withValues(alpha: 0.20), width: 1),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SiloDetailScreen(silo: silo)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        silo.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AuthTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${silo.grainType} • ${silo.capacity.toInt()}kg',
                        style: const TextStyle(fontSize: 14, color: AuthTheme.textHint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    silo.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(fillPercent * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isFull ? AuthTheme.error : isEmpty ? AuthTheme.textHint : AuthTheme.primaryGreen,
                        ),
                      ),
                      const Text('Occupancy', style: TextStyle(fontSize: 12, color: AuthTheme.textHint)),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildMetric(Icons.thermostat, '${temp.toStringAsFixed(1)}°C', 'Temp', const Color(0xFFFF5C5C)),
                ),
                Expanded(
                  child: _buildMetric(Icons.water_drop, '${hum.toStringAsFixed(1)}%', 'Hum', const Color(0xFF4D9FFF)),
                ),
                Expanded(
                  child: _buildMetric(Icons.air, '${tvoc.toStringAsFixed(0)}ppb', 'TVOC', const Color(0xFFA970FF)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fillPercent,
                backgroundColor: AuthTheme.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFull ? AuthTheme.error : AuthTheme.primaryGreen,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AuthTheme.textPrimary)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AuthTheme.textHint, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
