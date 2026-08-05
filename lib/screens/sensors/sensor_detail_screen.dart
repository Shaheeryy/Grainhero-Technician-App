import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/sensor_model.dart';
import '../../services/sensor_service.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/dashboard/temperature_chart.dart';

class SensorDetailScreen extends StatefulWidget {
  final String sensorId;
  const SensorDetailScreen({super.key, required this.sensorId});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  final _svc = SensorService();
  SensorDevice? _sensor;
  bool _loading = true;
  String? _error;
  List<SensorReading> _readings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sensor = await _svc.fetchSensorDetails(widget.sensorId);
      if (!mounted) return;
      setState(() { _sensor = sensor; _loading = false; });
      _loadReadings();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
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

  // Chart helpers
  List<ChartDataPoint> _chartData(double? Function(SensorReading) extractor) {
    final valid = _readings.where((r) => extractor(r) != null).toList().reversed.take(24).toList();
    return valid.asMap().entries.map((e) => ChartDataPoint(x: e.key.toDouble(), y: extractor(e.value)!)).toList();
  }

  String _timeAgo(DateTime? d) {
    if (d == null) return '--';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _thresholdColor(String? status) {
    if (status == 'critical') return AppTheme.errorColor;
    if (status == 'warning') return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  Color _riskColor(String? cls) {
    switch (cls?.toLowerCase()) {
      case 'spoiled': return AppTheme.errorColor;
      case 'risky': return AppTheme.warningColor;
      case 'safe': return AppTheme.successColor;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor, elevation: 0,
        title: const Text('Sensor Details', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.textSecondary), onPressed: _loading ? null : _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : _sensor == null
                  ? const Center(child: Text('Sensor not found'))
                  : RefreshIndicator(
                      onRefresh: _load, color: AppTheme.primaryColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _headerCard(),
                          const SizedBox(height: AppTheme.spacingL),
                          _liveReadingsCard(),
                          const SizedBox(height: AppTheme.spacingL),
                          if (_sensor!.latestReading?.derivedMetrics != null) ...[
                            _riskCard(), const SizedBox(height: AppTheme.spacingL),
                          ],
                          if (_sensor!.latestReading?.ambient != null) ...[
                            _ambientCard(), const SizedBox(height: AppTheme.spacingL),
                          ],
                          if (_sensor!.latestReading?.actuationState != null) ...[
                            _fanStatusCard(), const SizedBox(height: AppTheme.spacingL),
                          ],
                          // Charts
                          ..._buildCharts(),
                          _deviceHealthCard(),
                          const SizedBox(height: AppTheme.spacingL),
                        ]),
                      ),
                    ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: AppTheme.spacingL),
        ...children,
      ]),
    );
  }

  Widget _headerCard() {
    final s = _sensor!;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL), decoration: AppTheme.cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            child: const Icon(Icons.sensors, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.deviceName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(s.deviceId, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ])),
          StatusBadge(status: s.status),
        ]),
        const SizedBox(height: AppTheme.spacingL), const Divider(height: 1), const SizedBox(height: AppTheme.spacingL),
        Wrap(spacing: 16, runSpacing: 8, children: [
          if (s.model != null) _infoChip(Icons.memory, '${s.model}'),
          if (s.manufacturer != null) _infoChip(Icons.business, '${s.manufacturer}'),
          if (s.firmwareVersion != null) _infoChip(Icons.system_update, 'v${s.firmwareVersion}'),
          if (s.siloName != null) _infoChip(Icons.location_on_outlined, s.siloName!),
        ]),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppTheme.textSecondary),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ]);
  }

  Widget _liveReadingsCard() {
    final s = _sensor!;
    return _card('Live Readings', [
      Row(children: [
        Expanded(child: _metricTile(Icons.thermostat_outlined, AppTheme.temperatureOrange, 'Temperature',
            s.latestTemperature != null ? '${s.latestTemperature!.toStringAsFixed(1)}°C' : 'N/A',
            thresholdStatus: s.thresholds?.temperature?.getStatus(s.latestTemperature ?? 0))),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(child: _metricTile(Icons.water_drop_outlined, AppTheme.humidityBlue, 'Humidity',
            s.latestHumidity != null ? '${s.latestHumidity!.toStringAsFixed(1)}%' : 'N/A',
            thresholdStatus: s.thresholds?.humidity?.getStatus(s.latestHumidity ?? 0))),
      ]),
      const SizedBox(height: AppTheme.spacingM),
      Row(children: [
        Expanded(child: _metricTile(Icons.science_outlined, const Color(0xFFAB47BC), 'VOC',
            s.latestVoc != null ? '${s.latestVoc!.toStringAsFixed(0)} ppb' : 'N/A',
            thresholdStatus: s.thresholds?.voc?.getStatus(s.latestVoc ?? 0))),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(child: _metricTile(Icons.grain, const Color(0xFF26A69A), 'Moisture',
            s.latestMoisture != null ? '${s.latestMoisture!.toStringAsFixed(1)}%' : 'N/A',
            thresholdStatus: s.thresholds?.moisture?.getStatus(s.latestMoisture ?? 0))),
      ]),
    ]);
  }

  Widget _metricTile(IconData icon, Color color, String label, String value, {String? thresholdStatus}) {
    final indicatorColor = _thresholdColor(thresholdStatus);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border(left: BorderSide(color: indicatorColor, width: 3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ])),
      ]),
    );
  }

  Widget _riskCard() {
    final dm = _sensor!.latestReading!.derivedMetrics!;
    return _card('Risk Assessment', [
      Row(children: [
        // Risk class badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _riskColor(dm.mlRiskClass).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: _riskColor(dm.mlRiskClass).withValues(alpha: 0.4)),
          ),
          child: Text((dm.mlRiskClass ?? 'Unknown').toUpperCase(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _riskColor(dm.mlRiskClass), letterSpacing: 1)),
        ),
        const SizedBox(width: 16),
        // Risk score
        if (dm.mlRiskScore != null) Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Risk Score', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: dm.mlRiskScore! / 100, backgroundColor: AppTheme.dividerColor,
                color: _riskColor(dm.mlRiskClass), minHeight: 6))),
            const SizedBox(width: 8),
            Text('${dm.mlRiskScore!.toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ]),
        ])),
      ]),
      const SizedBox(height: AppTheme.spacingL),
      Wrap(spacing: 12, runSpacing: 8, children: [
        if (dm.fanRecommendation != null) _tagChip('Fan: ${dm.fanRecommendation}', dm.fanRecommendation == 'run' ? AppTheme.successColor : AppTheme.textSecondary),
        if (dm.condensationRisk == true) _tagChip('⚠ Condensation Risk', AppTheme.warningColor),
        if (dm.pestPresenceFlag == true) _tagChip('🐛 Pest Detected', AppTheme.errorColor),
        if (dm.dewPoint != null) _tagChip('Dew Point: ${dm.dewPoint!.toStringAsFixed(1)}°C', AppTheme.humidityBlue),
      ]),
    ]);
  }

  Widget _tagChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Widget _ambientCard() {
    final a = _sensor!.latestReading!.ambient!;
    return _card('Ambient Conditions', [
      Row(children: [
        if (a.temperature != null) Expanded(child: _smallMetric('Ext. Temp', '${a.temperature!.toStringAsFixed(1)}°C', Icons.thermostat_outlined)),
        if (a.humidity != null) Expanded(child: _smallMetric('Ext. Humidity', '${a.humidity!.toStringAsFixed(1)}%', Icons.water_drop_outlined)),
        if (a.light != null) Expanded(child: _smallMetric('Light', '${a.light!.toStringAsFixed(0)} lux', Icons.light_mode_outlined)),
      ]),
    ]);
  }

  Widget _fanStatusCard() {
    final as_ = _sensor!.latestReading!.actuationState!;
    return _card('Fan / Actuation Status', [
      Row(children: [
        Expanded(child: _smallMetric('Fan', as_.fanStatus?.toUpperCase() ?? '--', Icons.air)),
        if (as_.fanDutyCycle != null) Expanded(child: _smallMetric('Duty Cycle', '${as_.fanDutyCycle}%', Icons.speed)),
        if (as_.fanRpm != null) Expanded(child: _smallMetric('RPM', '${as_.fanRpm}', Icons.rotate_right)),
      ]),
    ]);
  }

  Widget _smallMetric(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, size: 20, color: AppTheme.textSecondary),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ]);
  }

  List<Widget> _buildCharts() {
    final tempData = _chartData((r) => r.temperature);
    final humData = _chartData((r) => r.humidity);
    final vocData = _chartData((r) => r.voc);
    final moistData = _chartData((r) => r.moisture);
    final widgets = <Widget>[];

    if (tempData.isNotEmpty) {
      widgets.addAll([TemperatureChart(title: 'Temperature History', dataSeries: [ChartDataSeries.temperature('Temp', tempData)], height: 160), const SizedBox(height: AppTheme.spacingL)]);
    }
    if (humData.isNotEmpty) {
      widgets.addAll([TemperatureChart(title: 'Humidity History', dataSeries: [ChartDataSeries.humidity('Humidity', humData)], height: 160), const SizedBox(height: AppTheme.spacingL)]);
    }
    if (vocData.isNotEmpty) {
      widgets.addAll([TemperatureChart(title: 'VOC Trend', dataSeries: [ChartDataSeries(label: 'VOC', dataPoints: vocData, color: const Color(0xFFAB47BC), unit: 'ppb')], height: 160), const SizedBox(height: AppTheme.spacingL)]);
    }
    if (moistData.isNotEmpty) {
      widgets.addAll([TemperatureChart(title: 'Moisture Trend', dataSeries: [ChartDataSeries(label: 'Moisture', dataPoints: moistData, color: const Color(0xFF26A69A), unit: '%')], height: 160), const SizedBox(height: AppTheme.spacingL)]);
    }
    return widgets;
  }

  Widget _deviceHealthCard() {
    final s = _sensor!;
    return _card('Device Health', [
      Row(children: [
        if (s.batteryLevel != null) Expanded(child: _smallMetric('Battery', '${s.batteryLevel}%', Icons.battery_full)),
        if (s.signalStrength != null) Expanded(child: _smallMetric('Signal', '${s.signalStrength} dBm', Icons.signal_cellular_alt)),
        if (s.healthMetrics?.uptimePercentage != null) Expanded(child: _smallMetric('Uptime', '${s.healthMetrics!.uptimePercentage!.toStringAsFixed(1)}%', Icons.timer)),
        if (s.healthMetrics?.errorCount != null) Expanded(child: _smallMetric('Errors', '${s.healthMetrics!.errorCount}', Icons.error_outline)),
      ]),
      if (s.healthMetrics?.lastHeartbeat != null) ...[
        const SizedBox(height: AppTheme.spacingM),
        Row(children: [
          const Icon(Icons.favorite, size: 14, color: AppTheme.successColor),
          const SizedBox(width: 6),
          Text('Last heartbeat: ${_timeAgo(s.healthMetrics!.lastHeartbeat)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
      ],
    ]);
  }
}
