import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/models/sensor_model.dart';
import 'package:grainhero_technician_app/services/sensor_service.dart';
import 'package:grainhero_technician_app/widgets/error_widget.dart';
import 'package:grainhero_technician_app/widgets/empty_state_widget.dart';
import 'package:grainhero_technician_app/widgets/status_badge.dart';
import 'sensor_detail_screen.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  final _sensorService = SensorService();
  List<SensorModel> _sensors = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  String? _selectedStatus;
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
      );

      if (!mounted) return;

      setState(() {
        _sensors = refresh
            ? (result['sensors'] as List<SensorModel>)
            : [..._sensors, ...(result['sensors'] as List<SensorModel>)];
        final pagination = result['pagination'] as Map<String, dynamic>;
        _hasMore = pagination['current_page'] < pagination['total_pages'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _loadMore() {
    if (!_loading && _hasMore) {
      setState(() {
        _currentPage++;
      });
      _loadSensors();
    }
  }

  void _applyFilters() {
    _loadSensors(refresh: true);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text(
          'Sensors',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
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
              AppTheme.spacingL,
              0,
              AppTheme.spacingL,
              AppTheme.spacingL,
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search sensors...',
                hintStyle: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _loadSensors(refresh: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Active filter chip
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
                    label: Text(
                      'Status: ${_selectedStatus!}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _selectedStatus = null);
                      _applyFilters();
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
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              itemCount: _sensors.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _sensors.length) {
                                  if (_hasMore) {
                                    _loadMore();
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(AppTheme.spacingL),
                                        child: CircularProgressIndicator(
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }
                                return _buildSensorCard(_sensors[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(SensorModel sensor) {
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
                // Header row
                Row(
                  children: [
                    // Sensor icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.sensors,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    // Name and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensor.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sensor.type,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    StatusBadge(status: sensor.status, isCompact: true),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Readings row
                Row(
                  children: [
                    // Temperature
                    if (sensor.temperature != null)
                      Expanded(
                        child: _buildReadingItem(
                          icon: Icons.thermostat_outlined,
                          color: AppTheme.temperatureOrange,
                          value: '${sensor.temperature!.toStringAsFixed(1)}°C',
                          label: 'Temperature',
                        ),
                      ),
                    // Humidity
                    if (sensor.humidity != null)
                      Expanded(
                        child: _buildReadingItem(
                          icon: Icons.water_drop_outlined,
                          color: AppTheme.humidityBlue,
                          value: '${sensor.humidity!.toStringAsFixed(1)}%',
                          label: 'Humidity',
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingM),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacingM),

                // Footer row
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sensor.siteName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(sensor.lastReading),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
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

  Widget _buildReadingItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
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
            // Handle
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

            // Title
            const Text(
              'Filter Sensors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Status options
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
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

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _selectedStatus = null);
                      Navigator.pop(context);
                      _applyFilters();
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
                      _applyFilters();
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
      onTap: () {
        setState(() => _selectedStatus = value);
      },
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
