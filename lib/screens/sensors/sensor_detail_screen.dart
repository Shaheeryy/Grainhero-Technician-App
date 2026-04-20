import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/models/sensor_model.dart';
import 'package:grainhero_technician_app/services/sensor_service.dart';
import 'package:grainhero_technician_app/widgets/error_widget.dart';
import 'package:grainhero_technician_app/widgets/status_badge.dart';
import 'package:grainhero_technician_app/widgets/temperature_chart.dart';
import 'package:intl/intl.dart';

class SensorDetailScreen extends StatefulWidget {
  final String sensorId;
  const SensorDetailScreen({super.key, required this.sensorId});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  final _sensorService = SensorService();
  SensorModel? _sensor;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _readings = [];
  bool _loadingReadings = false;
  String? _readingsError;

  @override
  void initState() {
    super.initState();
    _loadSensorDetails();
  }

  Future<void> _loadSensorDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sensor = await _sensorService.fetchSensorDetails(widget.sensorId);
      if (!mounted) return;
      setState(() {
        _sensor = sensor;
        _loading = false;
      });
      _loadReadings();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadReadings() async {
    setState(() {
      _loadingReadings = true;
      _readingsError = null;
    });

    try {
      final result = await _sensorService.getSensorReadings(
        widget.sensorId,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _readings = (result['readings'] as List<dynamic>?)
                ?.map((r) => r as Map<String, dynamic>)
                .toList() ??
            [];
        _loadingReadings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingReadings = false;
        _readingsError = e.toString();
      });
    }
  }

  List<ChartDataPoint> _getTemperatureData() {
    final tempReadings = _readings
        .where((r) => r['temperature'] != null)
        .toList()
        .reversed
        .take(24)
        .toList();

    return tempReadings.asMap().entries.map((entry) {
      return ChartDataPoint(
        x: entry.key.toDouble(),
        y: (entry.value['temperature'] as num).toDouble(),
      );
    }).toList();
  }

  List<ChartDataPoint> _getHumidityData() {
    final humidityReadings = _readings
        .where((r) => r['humidity'] != null)
        .toList()
        .reversed
        .take(24)
        .toList();

    return humidityReadings.asMap().entries.map((entry) {
      return ChartDataPoint(
        x: entry.key.toDouble(),
        y: (entry.value['humidity'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text(
          'Sensor Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _loading ? null : _loadSensorDetails,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadSensorDetails,
                )
              : _sensor == null
                  ? const Center(child: Text('Sensor not found'))
                  : RefreshIndicator(
                      onRefresh: _loadSensorDetails,
                      color: AppTheme.primaryColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Card
                            _buildHeaderCard(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Current Readings
                            _buildCurrentReadings(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Temperature Chart
                            if (_readings.isNotEmpty && _getTemperatureData().isNotEmpty) ...[
                              TemperatureChart(
                                title: 'Temperature History (Last 24 readings)',
                                dataSeries: [
                                  ChartDataSeries.temperature(
                                    'Temperature',
                                    _getTemperatureData(),
                                  ),
                                ],
                                height: 180,
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                            ],

                            // Humidity Chart
                            if (_readings.isNotEmpty && _getHumidityData().isNotEmpty) ...[
                              TemperatureChart(
                                title: 'Humidity History (Last 24 readings)',
                                dataSeries: [
                                  ChartDataSeries.humidity(
                                    'Humidity',
                                    _getHumidityData(),
                                  ),
                                ],
                                height: 180,
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                            ],

                            // Recent Readings List
                            _buildReadingsList(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Action Buttons (sensor.calibrate & sensor.maintain)
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.sensors,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sensor!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sensor!.type,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: _sensor!.status),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _sensor!.siteName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Updated ${_formatTimeAgo(_sensor!.lastReading)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentReadings() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Readings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildReadingTile(
                  icon: Icons.thermostat_outlined,
                  color: AppTheme.temperatureOrange,
                  label: 'Temperature',
                  value: _sensor!.temperature != null
                      ? '${_sensor!.temperature!.toStringAsFixed(1)}°C'
                      : 'N/A',
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildReadingTile(
                  icon: Icons.water_drop_outlined,
                  color: AppTheme.humidityBlue,
                  label: 'Humidity',
                  value: _sensor!.humidity != null
                      ? '${_sensor!.humidity!.toStringAsFixed(1)}%'
                      : 'N/A',
                ),
              ),
            ],
          ),
          if (_sensor!.spoilageRisk != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            _buildReadingTile(
              icon: Icons.warning_amber_outlined,
              color: _sensor!.spoilageRisk! > 50
                  ? AppTheme.errorColor
                  : AppTheme.warningColor,
              label: 'Spoilage Risk',
              value: '${_sensor!.spoilageRisk!.toStringAsFixed(1)}%',
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: fullWidth ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsList() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Readings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_loadingReadings)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_readingsError != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to load readings',
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadReadings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_readings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: AppTheme.textHint.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    const Text(
                      'No readings available',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_readings.take(10).map((reading) {
              final timestamp = reading['timestamp'] != null
                  ? DateTime.parse(reading['timestamp'])
                  : DateTime.now();
              final temp = reading['temperature'];
              final humidity = reading['humidity'];

              return Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    Text(
                      _formatTimestamp(timestamp),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (temp != null) ...[
                      Icon(
                        Icons.thermostat_outlined,
                        size: 14,
                        color: AppTheme.temperatureOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(temp as num).toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.temperatureOrange,
                        ),
                      ),
                    ],
                    if (temp != null && humidity != null)
                      const SizedBox(width: AppTheme.spacingM),
                    if (humidity != null) ...[
                      Icon(
                        Icons.water_drop_outlined,
                        size: 14,
                        color: AppTheme.humidityBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(humidity as num).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.humidityBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('MMM dd, HH:mm').format(timestamp);
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  // ---------- ACTION BUTTONS ----------
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          // Calibrate Sensor
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sensor == null ? null : _calibrateSensor,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Calibrate Sensor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Log Maintenance
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sensor == null ? null : _showMaintenanceDialog,
              icon: const Icon(Icons.build_outlined, size: 18),
              label: const Text('Log Maintenance'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _calibrateSensor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Calibrate Sensor', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to calibrate "${_sensor!.name}"?\nThis will initiate the calibration process.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Calibrate', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _sensorService.calibrateSensor(widget.sensorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sensor calibration initiated'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadSensorDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calibration failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMaintenanceDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Log Maintenance', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Describe the maintenance performed...',
            hintStyle: const TextStyle(color: AppTheme.textHint),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notes = controller.text.trim();
              if (notes.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _sensorService.logSensorMaintenance(widget.sensorId, notes);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maintenance logged successfully'),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Submit', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
