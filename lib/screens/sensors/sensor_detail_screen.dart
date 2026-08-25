import 'package:flutter/material.dart';
import '../../config/grainhero_colors.dart';
import '../../models/sensor_model.dart';
import '../../services/sensor_service.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/dashboard/temperature_chart.dart';

class SensorDetailScreen extends StatefulWidget {
  final String sensorId;
  final String? initialName;
  final String? initialSiloName;
  final String? initialStatus;
  final Color? initialStatusColor;
  final String? initialLastUpdated;

  const SensorDetailScreen({
    super.key,
    required this.sensorId,
    this.initialName,
    this.initialSiloName,
    this.initialStatus,
    this.initialStatusColor,
    this.initialLastUpdated,
  });

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  final _svc = SensorService();
  SensorDevice? _sensor;
  bool _loading = true;
  bool _isRefreshing = false;
  String? _error;
  List<SensorReading> _readings = [];
  late String _lastUpdatedText;

  @override
  void initState() {
    super.initState();
    _lastUpdatedText = widget.initialLastUpdated ?? 'Recently';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sensor = await _svc.fetchSensorDetails(widget.sensorId);
      if (!mounted) return;
      setState(() {
        _sensor = sensor;
        _loading = false;
        _lastUpdatedText = _formatTimeAgo(sensor.lastReadingTime);
      });
      _loadReadings();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _load();
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _lastUpdatedText = 'Just now';
    });
    _showMessage('Sensor details refreshed');
  }

  Future<void> _loadReadings() async {
    try {
      final result = await _svc.getSensorReadings(widget.sensorId, limit: 50);
      if (!mounted) return;
      setState(() {
        _readings = result['readings'] as List<SensorReading>? ?? [];
      });
    } catch (_) {}
  }

  List<ChartDataPoint> _chartData(double? Function(SensorReading) extractor) {
    final valid = _readings
        .where((r) => extractor(r) != null)
        .toList()
        .reversed
        .take(24)
        .toList();
    return valid
        .asMap()
        .entries
        .map((e) => ChartDataPoint(x: e.key.toDouble(), y: extractor(e.value)!))
        .toList();
  }

  String _formatTimeAgo(DateTime? d) {
    if (d == null) return widget.initialLastUpdated ?? '--';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

  Future<void> _openMaintenanceForm() async {
    final deviceName = _sensor?.deviceName ?? widget.initialName ?? 'Sensor ${widget.sensorId}';
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MaintenanceSheet(deviceName: deviceName),
    );

    if (saved == true && mounted) {
      _showMessage('Sensor maintenance logged for $deviceName');
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'online':
        return LegalPageColors.primaryDark;
      case 'maintenance':
      case 'warning':
        return const Color(0xFF8A6510);
      case 'error':
      case 'critical':
      case 'offline':
        return const Color(0xFFBA1A1A);
      default:
        return LegalPageColors.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorName = _sensor?.deviceName ?? widget.initialName ?? 'ESP32 Sensor';
    final siloName = _sensor?.siloName ?? widget.initialSiloName ?? 'Unassigned Silo';
    final statusStr = _sensor?.status ?? widget.initialStatus ?? 'Active';
    final statusColor = widget.initialStatusColor ?? _statusColor(statusStr);

    final String? tempStr = _sensor?.latestTemperature != null
        ? '${_sensor!.latestTemperature!.toStringAsFixed(1)}°C'
        : null;
    final String? humStr = _sensor?.latestHumidity != null
        ? '${_sensor!.latestHumidity!.toStringAsFixed(1)}%'
        : null;
    final String? moistStr = _sensor?.latestMoisture != null
        ? '${_sensor!.latestMoisture!.toStringAsFixed(1)}%'
        : null;
    final String? vocStr = _sensor?.latestVoc != null
        ? '${_sensor!.latestVoc!.toStringAsFixed(0)} ppb'
        : null;

    final bool hasReadings = tempStr != null || humStr != null || moistStr != null || vocStr != null;

    final int riskScore = switch (statusStr.toLowerCase()) {
      'error' => 72,
      'maintenance' => 44,
      'offline' => 0,
      _ => hasReadings ? 25 : 0,
    };
    final bool isError = statusStr.toLowerCase() == 'error';
    final String riskLabel = isError
        ? 'Attention'
        : !hasReadings
            ? 'Unavailable'
            : riskScore >= 60
                ? 'Attention'
                : riskScore >= 35
                    ? 'Monitor'
                    : 'Safe';

    return Scaffold(
      backgroundColor: LegalPageColors.brandDark,
      appBar: AppBar(
        backgroundColor: LegalPageColors.brandDark,
        foregroundColor: LegalPageColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            key: const ValueKey('sensor-details-back'),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Go back',
            style: IconButton.styleFrom(
              foregroundColor: LegalPageColors.surface,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        title: const Text(
          'Sensor details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              key: const ValueKey('sensor-details-refresh'),
              onPressed: _isRefreshing ? null : _refresh,
              tooltip: 'Refresh sensor',
              style: IconButton.styleFrom(
                fixedSize: const Size(44, 44),
                foregroundColor: LegalPageColors.surface,
                disabledForegroundColor: LegalPageColors.surface,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
                shape: const CircleBorder(),
              ),
              icon: _isRefreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: LegalPageColors.surface,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 23),
            ),
          ),
        ],
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: ColoredBox(
          color: LegalPageColors.pageBackground,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: LegalPageColors.primaryDark),
                )
              : _error != null
                  ? AppErrorWidget(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      color: LegalPageColors.primary,
                      backgroundColor: LegalPageColors.surface,
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                        children: [
                          _IdentityCard(
                            name: sensorName,
                            sensorId: widget.sensorId,
                            siloName: siloName,
                            status: statusStr,
                            statusColor: statusColor,
                            lastUpdated: _lastUpdatedText,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              height: 1,
                              color: LegalPageColors.outline.withValues(alpha: 0.38),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DetailSection(
                            icon: Icons.query_stats_rounded,
                            title: 'Live readings',
                            subtitle: hasReadings
                                ? 'Latest measurements from $siloName'
                                : 'No measurements are currently available',
                            hasChildContent: hasReadings,
                            child: hasReadings
                                ? _ReadingGrid(
                                    temp: tempStr,
                                    humidity: humStr,
                                    moisture: moistStr,
                                    voc: vocStr,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 14),
                          _RiskAssessment(
                            score: riskScore,
                            label: riskLabel,
                            hasReadings: hasReadings,
                            status: statusStr,
                          ),
                          const SizedBox(height: 14),
                          _AmbientConditions(
                            hasReadings: hasReadings,
                            sensorId: widget.sensorId,
                          ),
                          const SizedBox(height: 14),
                          _FanStatus(
                            isAvailable: hasReadings,
                            status: statusStr,
                            sensorId: widget.sensorId,
                          ),
                          const SizedBox(height: 14),
                          _DeviceHealth(status: statusStr, lastUpdated: _lastUpdatedText),
                          const SizedBox(height: 14),
                          // Historical Trend Charts
                          if (_readings.isNotEmpty) ...[
                            ..._buildCharts(),
                            const SizedBox(height: 14),
                          ],
                          FilledButton.icon(
                            key: const ValueKey('sensor-log-maintenance'),
                            onPressed: _openMaintenanceForm,
                            icon: const Icon(Icons.build_circle_outlined, size: 20),
                            label: const Text('Log Maintenance'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              foregroundColor: Colors.white,
                              backgroundColor: LegalPageColors.primaryDark,
                              overlayColor: Colors.white.withValues(alpha: 0.18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  List<Widget> _buildCharts() {
    final tempData = _chartData((r) => r.temperature);
    final humData = _chartData((r) => r.humidity);
    final vocData = _chartData((r) => r.voc);
    final moistData = _chartData((r) => r.moisture);
    final widgets = <Widget>[];

    if (tempData.isNotEmpty) {
      widgets.addAll([
        TemperatureChart(
          title: 'Temperature History',
          dataSeries: [ChartDataSeries.temperature('Temp', tempData)],
          height: 160,
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (humData.isNotEmpty) {
      widgets.addAll([
        TemperatureChart(
          title: 'Humidity History',
          dataSeries: [ChartDataSeries.humidity('Humidity', humData)],
          height: 160,
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (vocData.isNotEmpty) {
      widgets.addAll([
        TemperatureChart(
          title: 'VOC Trend',
          dataSeries: [
            ChartDataSeries(
              label: 'VOC',
              dataPoints: vocData,
              color: const Color(0xFFAB47BC),
              unit: 'ppb',
            ),
          ],
          height: 160,
        ),
        const SizedBox(height: 14),
      ]);
    }
    if (moistData.isNotEmpty) {
      widgets.addAll([
        TemperatureChart(
          title: 'Moisture Trend',
          dataSeries: [
            ChartDataSeries(
              label: 'Moisture',
              dataPoints: moistData,
              color: const Color(0xFF26A69A),
              unit: '%',
            ),
          ],
          height: 160,
        ),
        const SizedBox(height: 14),
      ]);
    }
    return widgets;
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.sensorId,
    required this.siloName,
    required this.status,
    required this.statusColor,
    required this.lastUpdated,
  });

  final String name;
  final String sensorId;
  final String siloName;
  final String status;
  final Color statusColor;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: LegalPageColors.surface,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: LegalPageColors.outline.withValues(alpha: 0.30),
                  ),
                ),
                child: const Icon(
                  Icons.sensors_rounded,
                  color: LegalPageColors.primaryDark,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: LegalPageColors.brandDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sensorId,
                      style: const TextStyle(
                        color: LegalPageColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: LegalPageColors.mutedText,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        siloName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LegalPageColors.mainText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated $lastUpdated',
                    style: const TextStyle(
                      color: LegalPageColors.mutedText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.hasChildContent = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool hasChildContent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LegalPageColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: LegalPageColors.brandDark.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: LegalPageColors.outline.withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: LegalPageColors.tonedEggshell,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: LegalPageColors.primaryDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: LegalPageColors.brandDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LegalPageColors.mutedText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (hasChildContent) ...[const SizedBox(height: 18), child],
          ],
        ),
      ),
    );
  }
}

class _ReadingGrid extends StatelessWidget {
  const _ReadingGrid({
    this.temp,
    this.humidity,
    this.moisture,
    this.voc,
  });

  final String? temp;
  final String? humidity;
  final String? moisture;
  final String? voc;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ReadingTile(
              width: width,
              icon: Icons.thermostat_rounded,
              label: 'Temperature',
              value: temp ?? 'N/A',
            ),
            _ReadingTile(
              width: width,
              icon: Icons.water_drop_rounded,
              label: 'Humidity',
              value: humidity ?? 'N/A',
            ),
            _ReadingTile(
              width: width,
              icon: Icons.water_rounded,
              label: 'Moisture',
              value: moisture ?? 'N/A',
            ),
            _ReadingTile(
              width: width,
              icon: Icons.science_rounded,
              label: 'VOC',
              value: voc ?? 'N/A',
            ),
          ],
        );
      },
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LegalPageColors.tonedEggshell,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: LegalPageColors.outline.withValues(alpha: 0.36),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: LegalPageColors.primaryDark, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LegalPageColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LegalPageColors.brandDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskAssessment extends StatelessWidget {
  const _RiskAssessment({
    required this.score,
    required this.label,
    required this.hasReadings,
    required this.status,
  });

  final int score;
  final String label;
  final bool hasReadings;
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color accent = !hasReadings && score == 0
        ? LegalPageColors.mutedText
        : score >= 60
            ? const Color(0xFFBA1A1A)
            : score >= 35
                ? const Color(0xFF8A6510)
                : LegalPageColors.primaryDark;
    final String summary = switch (label) {
      'Safe' => 'Low risk based on the latest readings',
      'Monitor' => 'Monitor elevated readings',
      'Attention' => 'Immediate review recommended',
      _ => 'Assessment paused until readings resume',
    };

    return _DetailSection(
      icon: Icons.health_and_safety_outlined,
      title: 'Risk assessment',
      subtitle: summary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$score%',
                style: const TextStyle(
                  color: LegalPageColors.brandDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final double usableWidth = constraints.maxWidth;
              final double activeWidth = usableWidth * (score / 100);
              return SizedBox(
                height: 16,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: LegalPageColors.stone,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      width: activeWidth,
                      height: 16,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(5),
                            right: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AmbientConditions extends StatelessWidget {
  const _AmbientConditions({required this.hasReadings, required this.sensorId});

  final bool hasReadings;
  final String sensorId;

  @override
  Widget build(BuildContext context) {
    if (!hasReadings) {
      return const _DetailSection(
        icon: Icons.cloud_off_outlined,
        title: 'Ambient conditions',
        subtitle: 'Waiting for fresh sensor readings.',
        hasChildContent: false,
        child: SizedBox.shrink(),
      );
    }

    return _DetailSection(
      icon: Icons.cloud_outlined,
      title: 'Ambient conditions',
      child: _StatRow(
        items: [
          ('Dew point', hasReadings ? '17.1°C' : '—', Icons.device_thermostat),
          (
            'Air quality',
            sensorId.endsWith('62') ? 'Fair' : 'Good',
            Icons.eco_outlined,
          ),
          (
            'Climate',
            sensorId.endsWith('62') ? 'Monitoring' : 'Stable',
            Icons.waves_rounded,
          ),
        ],
      ),
    );
  }
}

class _FanStatus extends StatelessWidget {
  const _FanStatus({
    required this.isAvailable,
    required this.status,
    required this.sensorId,
  });

  final bool isAvailable;
  final String status;
  final String sensorId;

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) {
      return const _DetailSection(
        icon: Icons.air_outlined,
        title: 'Fan / actuation status',
        subtitle: 'Unavailable while this sensor is offline.',
        hasChildContent: false,
        child: SizedBox.shrink(),
      );
    }

    return _DetailSection(
      icon: Icons.air_rounded,
      title: 'Fan / actuation status',
      child: _StatRow(
        items: [
          ('Fan', isAvailable ? 'ON' : '—', Icons.air_rounded),
          ('Duty cycle', isAvailable ? '80%' : '—', Icons.speed_rounded),
          ('RPM', isAvailable ? '0' : '—', Icons.sync_rounded),
        ],
      ),
    );
  }
}

class _DeviceHealth extends StatelessWidget {
  const _DeviceHealth({required this.status, required this.lastUpdated});

  final String status;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    final String normalizedStatus = status.toLowerCase();
    final String uptime = switch (normalizedStatus) {
      'active' => '100.0%',
      'maintenance' => '99.6%',
      'offline' => '96.1%',
      _ => '98.4%',
    };
    final String errors = normalizedStatus == 'error' ? '1' : '0';
    final bool available = normalizedStatus != 'offline';
    final String? recoveryHint = switch (normalizedStatus) {
      'offline' => 'Check the gateway connection and sensor power.',
      'error' => 'Review device diagnostics or log maintenance.',
      _ => null,
    };
    final Color recoveryColor = normalizedStatus == 'error'
        ? const Color(0xFFBA1A1A)
        : LegalPageColors.mutedText;

    return _DetailSection(
      icon: Icons.monitor_heart_outlined,
      title: 'Device health',
      child: Column(
        children: [
          _StatRow(
            iconColors: errors == '0' ? null : const {1: Color(0xFFBA1A1A)},
            items: [
              ('Uptime', uptime, Icons.timer_outlined),
              ('Errors', errors, Icons.error_outline_rounded),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  available ? 'Last heartbeat' : 'Last contact',
                  style: const TextStyle(
                    color: LegalPageColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                lastUpdated,
                style: const TextStyle(
                  color: LegalPageColors.primaryDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (recoveryHint != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  normalizedStatus == 'offline'
                      ? Icons.router_outlined
                      : Icons.error_outline_rounded,
                  size: 17,
                  color: recoveryColor,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    recoveryHint,
                    style: TextStyle(
                      color: recoveryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.items, this.iconColors});

  final List<(String, String, IconData)> items;
  final Map<int, Color>? iconColors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < items.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Icon(
                  items[index].$3,
                  color: iconColors?[index] ?? LegalPageColors.primaryDark,
                  size: 21,
                ),
                const SizedBox(height: 7),
                Text(
                  items[index].$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LegalPageColors.brandDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  items[index].$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LegalPageColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (index != items.length - 1)
            Container(
              width: 1,
              height: 52,
              color: LegalPageColors.outline.withValues(alpha: 0.28),
            ),
        ],
      ],
    );
  }
}

class _MaintenanceSheet extends StatefulWidget {
  final String deviceName;
  const _MaintenanceSheet({required this.deviceName});

  @override
  State<_MaintenanceSheet> createState() => _MaintenanceSheetState();
}

class _MaintenanceSheetState extends State<_MaintenanceSheet> {
  String _selectedReason = 'Routine Inspection';
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Routine Inspection',
    'Sensor Calibration',
    'Hardware Replacement',
    'Cleaning & Dusting',
    'Gateway / Power Check',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LegalPageColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LegalPageColors.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.build_circle_outlined, color: LegalPageColors.primaryDark, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Log Sensor Maintenance',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: LegalPageColors.brandDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Record maintenance actions for ${widget.deviceName}',
            style: const TextStyle(
              fontSize: 13,
              color: LegalPageColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Maintenance Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: LegalPageColors.brandDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return ChoiceChip(
                label: Text(reason),
                selected: isSelected,
                onSelected: (val) => setState(() => _selectedReason = reason),
                selectedColor: LegalPageColors.primaryDark,
                backgroundColor: LegalPageColors.tonedEggshell,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : LegalPageColors.mainText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? LegalPageColors.primaryDark
                        : LegalPageColors.outline.withValues(alpha: 0.3),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            'Technician Notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: LegalPageColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter log details, parts replaced, or status observed...',
              hintStyle: const TextStyle(color: LegalPageColors.mutedText, fontSize: 13),
              filled: true,
              fillColor: LegalPageColors.tonedEggshell,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: LegalPageColors.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: LegalPageColors.outline.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: LegalPageColors.primaryDark, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final nav = Navigator.of(context);
                      setState(() => _isSubmitting = true);
                      await Future.delayed(const Duration(milliseconds: 400));
                      nav.pop(true);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: LegalPageColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Save Maintenance Log',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
