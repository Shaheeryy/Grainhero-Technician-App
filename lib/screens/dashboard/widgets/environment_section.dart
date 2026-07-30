import 'package:flutter/material.dart';
import '../../../../config/grainhero_colors.dart';
import '../../../../widgets/dashboard/dashboard_widgets.dart';
import '../../../../models/silo_model.dart';
import '../../silos/silo_detail_screen.dart';

class SiloEnvironmentSection extends StatelessWidget {
  final int realSiloCount;
  final List<dynamic> silos;
  final VoidCallback onAddNew;

  const SiloEnvironmentSection({
    super.key,
    required this.realSiloCount,
    required this.silos,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Silo Environments',
          actionLabel: 'ADD NEW',
          onPressed: onAddNew,
        ),
        const SizedBox(height: 12),
        if (realSiloCount == 0 || silos.isEmpty)
          EmptySiloCard(onPressed: onAddNew)
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: silos.length,
              itemBuilder: (context, index) {
                final silo = silos[index] as SiloModel;
                return _buildSiloEnvironmentCard(context, silo);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSiloEnvironmentCard(BuildContext context, SiloModel silo) {
    final temp = silo.temperature ?? 0;
    final hum = silo.humidity ?? 0;
    final tvoc = silo.tvoc ?? 0;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: GrainHeroColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GrainHeroColors.primary.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GrainHeroColors.primary.withValues(alpha: 0.12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      silo.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: GrainHeroColors.dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: silo.status.toLowerCase() == 'active'
                          ? GrainHeroColors.primary.withValues(alpha: 0.15)
                          : const Color(0xFFFF5C5C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      silo.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: silo.status.toLowerCase() == 'active'
                            ? GrainHeroColors.primary
                            : const Color(0xFFFF5C5C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniMetric(Icons.thermostat, '${temp.toStringAsFixed(1)}°C', const Color(0xFFFF5C5C)),
                  _buildMiniMetric(Icons.water_drop, '${hum.toStringAsFixed(1)}%', const Color(0xFF4D9FFF)),
                  _buildMiniMetric(Icons.air, '${tvoc.toStringAsFixed(0)}ppb', const Color(0xFFA970FF)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: GrainHeroColors.dark,
          ),
        ),
      ],
    );
  }
}

