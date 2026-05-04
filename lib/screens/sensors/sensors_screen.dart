import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/sensor_model.dart';
import '../../services/sensor_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';
import 'sensor_detail_screen.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  final _sensorService = SensorService();
  List<SensorDevice> _sensors = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  final int _limit = 50;
  bool _hasMore = true;
  String? _selectedStatus;
  String? _selectedSiloId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSensors({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _sensors = [];
        _hasMore = true;
      });
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _sensorService.getAllSensors(
        page: _currentPage,
        limit: _limit,
        status: _selectedStatus,
        siloId: _selectedSiloId,
      );

      if (!mounted) return;

      setState(() {
        final newSensors = result['sensors'] as List<SensorDevice>;
        _sensors = refresh ? newSensors : [..._sensors, ...newSensors];
        final pagination = result['pagination'] as Map<String, dynamic>;
        _hasMore = (pagination['current_page'] ?? 1) < (pagination['total_pages'] ?? 1);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _loadMore() {
    if (!_loading && _hasMore) {
      setState(() => _currentPage++);
      _loadSensors();
    }
  }

  /// Group sensors by silo name.
  Map<String, List<SensorDevice>> get _groupedSensors {
    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? _sensors
        : _sensors.where((s) =>
            s.deviceName.toLowerCase().contains(query) ||
            s.deviceId.toLowerCase().contains(query) ||
            (s.siloName?.toLowerCase().contains(query) ?? false)).toList();

    final grouped = <String, List<SensorDevice>>{};
    for (final sensor in filtered) {
      final siloName = sensor.siloName ?? 'Unassigned';
      grouped.putIfAbsent(siloName, () => []).add(sensor);
    }
    return grouped;
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '--';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          title: const Text(
            'Sensors',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedStatus != null
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: _selectedStatus != null
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              onPressed: _showFilterSheet,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              color: AppTheme.surfaceColor,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL, 0, AppTheme.spacingL, AppTheme.spacingL,
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search sensors by name or ID...',
                  hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),

            // Active filter chips
            if (_selectedStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingS,
                ),
                child: Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text('Status: $_selectedStatus', style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() => _selectedStatus = null);
                        _loadSensors(refresh: true);
                      },
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      labelStyle: const TextStyle(color: AppTheme.primaryColor),
                      deleteIconColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _loading && _sensors.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    )
                  : _error != null
                      ? AppErrorWidget(
                          message: _error!,
                          onRetry: () => _loadSensors(refresh: true),
                        )
                      : _sensors.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.sensors,
                              title: 'No Sensors Found',
                              subtitle: 'No sensors match your filters',
                              onRetry: () => _loadSensors(refresh: true),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _loadSensors(refresh: true),
                              color: AppTheme.primaryColor,
                              child: _buildGroupedList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList() {
    final grouped = _groupedSensors;
    if (grouped.isEmpty) {
      return Center(
        child: Text(
          'No sensors match "${_searchController.text}"',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final siloNames = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      itemCount: siloNames.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == siloNames.length) {
          if (_hasMore) {
            _loadMore();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingL),
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final siloName = siloNames[index];
        final sensors = grouped[siloName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Silo header
            Padding(
              padding: EdgeInsets.only(
                bottom: AppTheme.spacingM,
                top: index > 0 ? AppTheme.spacingXL : 0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(Icons.domain, size: 18, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Text(
                      siloName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${sensors.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sensor cards for this silo
            ...sensors.map((sensor) => _buildSensorCard(sensor)),
          ],
        );
      },
    );
  }

  Widget _buildSensorCard(SensorDevice sensor) {
    final reading = sensor.latestReading;
    final isOnline = sensor.connectionStatus == 'online';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SensorDetailScreen(sensorId: sensor.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: icon, name, device_id, status, connection
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(Icons.sensors, color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensor.deviceName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sensor.deviceId,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    ),
                    // Connection dot
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.successColor : AppTheme.errorColor,
                        shape: BoxShape.circle,
                        boxShadow: isOnline
                            ? [BoxShadow(color: AppTheme.successColor.withOpacity(0.4), blurRadius: 4)]
                            : null,
                      ),
                    ),
                    StatusBadge(status: sensor.status, isCompact: true),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingM),

                // Sensor type chips
                if (sensor.sensorTypes.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: sensor.sensorTypes.map((type) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getSensorTypeColor(type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getSensorTypeColor(type).withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _getSensorTypeLabel(type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _getSensorTypeColor(type),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: AppTheme.spacingM),

                // Live metric values in a 2x2 grid
                _buildMetricsGrid(sensor, reading),

                const SizedBox(height: AppTheme.spacingM),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacingM),

                // Footer: battery, signal, last reading time
                Row(
                  children: [
                    if (sensor.batteryLevel != null) ...[
                      Icon(
                        _getBatteryIcon(sensor.batteryLevel!),
                        size: 14,
                        color: sensor.batteryLevel! < 20
                            ? AppTheme.errorColor
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${sensor.batteryLevel}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: sensor.batteryLevel! < 20
                              ? AppTheme.errorColor
                              : AppTheme.textHint,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (sensor.signalStrength != null) ...[
                      Icon(Icons.signal_cellular_alt, size: 14, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${sensor.signalStrength} dBm',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                    const Spacer(),
                    Icon(Icons.access_time, size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeAgo(sensor.lastReadingTime),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
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

  Widget _buildMetricsGrid(SensorDevice sensor, SensorReading? reading) {
    final metrics = <Widget>[];

    if (sensor.latestTemperature != null) {
      metrics.add(_buildMetricItem(
        icon: Icons.thermostat_outlined,
        color: AppTheme.temperatureOrange,
        value: '${sensor.latestTemperature!.toStringAsFixed(1)}°C',
        label: 'Temp',
      ));
    }
    if (sensor.latestHumidity != null) {
      metrics.add(_buildMetricItem(
        icon: Icons.water_drop_outlined,
        color: AppTheme.humidityBlue,
        value: '${sensor.latestHumidity!.toStringAsFixed(1)}%',
        label: 'Humidity',
      ));
    }
    if (sensor.latestVoc != null) {
      metrics.add(_buildMetricItem(
        icon: Icons.science_outlined,
        color: const Color(0xFFAB47BC),
        value: '${sensor.latestVoc!.toStringAsFixed(0)} ppb',
        label: 'VOC',
      ));
    }
    if (sensor.latestMoisture != null) {
      metrics.add(_buildMetricItem(
        icon: Icons.grain,
        color: const Color(0xFF26A69A),
        value: '${sensor.latestMoisture!.toStringAsFixed(1)}%',
        label: 'Moisture',
      ));
    }

    if (metrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: const Text(
          'No readings available',
          style: TextStyle(fontSize: 12, color: AppTheme.textHint),
        ),
      );
    }

    return Row(children: metrics.map((m) => Expanded(child: m)).toList());
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getSensorTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return AppTheme.temperatureOrange;
      case 'humidity':
        return AppTheme.humidityBlue;
      case 'voc':
        return const Color(0xFFAB47BC);
      case 'moisture':
        return const Color(0xFF26A69A);
      case 'co2':
        return const Color(0xFFFF7043);
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getSensorTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return '🌡️ Temp';
      case 'humidity':
        return '💧 Humidity';
      case 'voc':
        return '🧪 VOC';
      case 'moisture':
        return '🌾 Moisture';
      case 'co2':
        return '☁️ CO₂';
      default:
        return type;
    }
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 50) return Icons.battery_5_bar;
    if (level > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            const Text(
              'Filter Sensors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            const Text(
              'Status',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilterChip('All', null),
                _buildFilterChip('Active', 'active'),
                _buildFilterChip('Offline', 'offline'),
                _buildFilterChip('Maintenance', 'maintenance'),
                _buildFilterChip('Error', 'error'),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _selectedStatus = null);
                      Navigator.pop(context);
                      _loadSensors(refresh: true);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadSensors(refresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
