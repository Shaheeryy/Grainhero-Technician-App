import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// A modern card widget for displaying sensor readings with temperature and humidity
/// Matches the reference design with left accent border and clean layout
class SensorReadingCard extends StatelessWidget {
  final String title;
  final double? temperature;
  final double? humidity;
  final String? subtitle;
  final String? timestamp;
  final Color? accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SensorReadingCard({
    super.key,
    required this.title,
    this.temperature,
    this.humidity,
    this.subtitle,
    this.timestamp,
    this.accentColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppTheme.temperatureOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border(
          left: BorderSide(color: accent, width: 4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        timestamp!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ?trailing,
                  ],
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Temperature and Humidity row
                Row(
                  children: [
                    // Temperature
                    if (temperature != null)
                      Expanded(
                        child: _ReadingItem(
                          icon: Icons.thermostat_outlined,
                          iconColor: AppTheme.temperatureOrange,
                          value: '${temperature!.toStringAsFixed(1)}°',
                          label: 'Temperature',
                        ),
                      ),

                    // Humidity
                    if (humidity != null)
                      Expanded(
                        child: _ReadingItem(
                          icon: Icons.water_drop_outlined,
                          iconColor: AppTheme.humidityBlue,
                          value: '${humidity!.toStringAsFixed(1)}%',
                          label: 'Humidity',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _ReadingItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 28,
          color: iconColor,
        ),
        const SizedBox(width: AppTheme.spacingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact version for list items
class SensorReadingCardCompact extends StatelessWidget {
  final String sensorId;
  final String? sensorName;
  final double? temperature;
  final double? humidity;
  final String? status;
  final VoidCallback? onTap;

  const SensorReadingCardCompact({
    super.key,
    required this.sensorId,
    this.sensorName,
    this.temperature,
    this.humidity,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sensorId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.getStatusColor(status!).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.getStatusColor(status!),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingM),

                // Readings row
                Row(
                  children: [
                    if (temperature != null) ...[
                      Icon(
                        Icons.thermostat_outlined,
                        size: 20,
                        color: AppTheme.temperatureOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${temperature!.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.temperatureOrange,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingL),
                    ],
                    if (humidity != null) ...[
                      Icon(
                        Icons.water_drop_outlined,
                        size: 20,
                        color: AppTheme.humidityBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${humidity!.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.humidityBlue,
                        ),
                      ),
                    ],
                  ],
                ),

                if (sensorName != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    sensorName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
