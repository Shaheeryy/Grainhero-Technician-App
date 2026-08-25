import 'package:flutter/material.dart';
import '../../config/grainhero_colors.dart';
import '../../models/sensor_model.dart';
import '../../services/sensor_service.dart';
import '../../widgets/common/error_widget.dart';
import 'sensor_detail_screen.dart';

enum _SensorStatusFilter {
  all,
  active,
  offline,
  maintenance,
  error,
  needsAttention,
  recentlyUpdated,
}

extension on _SensorStatusFilter {
  String get label => switch (this) {
        _SensorStatusFilter.all => 'All',
        _SensorStatusFilter.active => 'Active',
        _SensorStatusFilter.offline => 'Offline',
        _SensorStatusFilter.maintenance => 'Maintenance',
        _SensorStatusFilter.error => 'Error',
        _SensorStatusFilter.needsAttention => 'Needs attention',
        _SensorStatusFilter.recentlyUpdated => 'Recently updated',
      };
}

Color _statusFilterColor(_SensorStatusFilter status) => switch (status) {
      _SensorStatusFilter.active => LegalPageColors.primaryDark,
      _SensorStatusFilter.maintenance => const Color(0xFF8A6510),
      _SensorStatusFilter.offline => LegalPageColors.mutedText,
      _SensorStatusFilter.error => const Color(0xFFBA1A1A),
      _SensorStatusFilter.needsAttention => const Color(0xFF8A6510),
      _SensorStatusFilter.recentlyUpdated => LegalPageColors.primaryDark,
      _SensorStatusFilter.all => LegalPageColors.brandDark,
    };

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
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  Set<_SensorStatusFilter> _selectedStatuses = {_SensorStatusFilter.all};
  bool _isRefreshing = false;
  bool _isSearchExpanded = false;
  DateTime _lastSyncedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
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
        _lastSyncedAt = DateTime.now();
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

  List<SensorDevice> get _visibleSensors {
    final String query = _searchController.text.trim().toLowerCase();
    return _sensors.where((sensor) {
      final bool matchesStatus = _selectedStatuses.contains(_SensorStatusFilter.all) ||
          (_selectedStatuses.contains(_SensorStatusFilter.active) &&
              (sensor.status.toLowerCase() == 'active' || sensor.connectionStatus == 'online')) ||
          (_selectedStatuses.contains(_SensorStatusFilter.offline) &&
              (sensor.status.toLowerCase() == 'offline' || sensor.connectionStatus == 'offline')) ||
          (_selectedStatuses.contains(_SensorStatusFilter.maintenance) &&
              sensor.status.toLowerCase() == 'maintenance') ||
          (_selectedStatuses.contains(_SensorStatusFilter.error) &&
              (sensor.status.toLowerCase() == 'error' || sensor.status.toLowerCase() == 'critical')) ||
          (_selectedStatuses.contains(_SensorStatusFilter.needsAttention) &&
              (sensor.status.toLowerCase() == 'maintenance' ||
                  sensor.status.toLowerCase() == 'error' ||
                  sensor.status.toLowerCase() == 'critical')) ||
          (_selectedStatuses.contains(_SensorStatusFilter.recentlyUpdated) &&
              _wasRecentlyUpdated(sensor));

      final bool matchesQuery = query.isEmpty ||
          sensor.deviceName.toLowerCase().contains(query) ||
          sensor.deviceId.toLowerCase().contains(query) ||
          (sensor.siloName?.toLowerCase().contains(query) ?? false);

      return matchesStatus && matchesQuery;
    }).toList(growable: false);
  }

  bool _wasRecentlyUpdated(SensorDevice sensor) {
    if (sensor.lastReadingTime == null) return false;
    final diff = DateTime.now().difference(sensor.lastReadingTime!);
    return diff.inMinutes <= 15;
  }

  void _clearAllFilters() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _selectedStatuses = {_SensorStatusFilter.all};
      _selectedStatus = null;
    });
    _loadSensors(refresh: true);
  }

  Future<void> _refreshSensors() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadSensors(refresh: true);
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _lastSyncedAt = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sensor status refreshed'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Future<void> _openSensorDetails(SensorDevice sensor) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => SensorDetailScreen(
          sensorId: sensor.id,
          initialName: sensor.deviceName,
          initialSiloName: sensor.siloName,
          initialStatus: sensor.status,
          initialLastUpdated: _formatTimeAgo(sensor.lastReadingTime),
        ),
      ),
    );
  }

  void _toggleSearch() {
    if (_isSearchExpanded) {
      _searchController.clear();
      _searchFocusNode.unfocus();
      setState(() => _isSearchExpanded = false);
      return;
    }

    setState(() => _isSearchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  Future<void> _toggleStatusFilter(_SensorStatusFilter status) async {
    if (status != _SensorStatusFilter.all &&
        _scrollController.hasClients &&
        _scrollController.offset > 8) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
    }

    setState(() {
      if (status == _SensorStatusFilter.all) {
        _selectedStatuses = {_SensorStatusFilter.all};
        _selectedStatus = null;
        return;
      }
      _selectedStatuses.remove(_SensorStatusFilter.all);
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
      if (_selectedStatuses.isEmpty) {
        _selectedStatuses = {_SensorStatusFilter.all};
        _selectedStatus = null;
      } else {
        _selectedStatus = status.name;
      }
    });
  }

  String get _lastSyncedLabel {
    final Duration elapsed = DateTime.now().difference(_lastSyncedAt);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
    return '${elapsed.inHours}h ago';
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
    final List<SensorDevice> visibleSensors = _visibleSensors;
    final int siloCount =
        _sensors.map((sensor) => sensor.siloName ?? 'Unassigned').toSet().length;
    final int onlineCount = _sensors
        .where(
          (sensor) =>
              sensor.status.toLowerCase() == 'active' ||
              sensor.connectionStatus == 'online' ||
              sensor.status.toLowerCase() == 'maintenance',
        )
        .length;

    return Scaffold(
      backgroundColor: LegalPageColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: _loading && _sensors.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: LegalPageColors.primaryDark),
              )
            : _error != null
                ? AppErrorWidget(
                    message: _error!,
                    onRetry: () => _loadSensors(refresh: true),
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: _SensorsHeader(
                          isRefreshing: _isRefreshing || _loading,
                          onRefreshPressed: _refreshSensors,
                          isSearchExpanded: _isSearchExpanded,
                          onSearchPressed: _toggleSearch,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _isSearchExpanded
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                                  child: _SensorSearchBar(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    onChanged: (_) => setState(() {}),
                                    onClear: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      if (!_isSearchExpanded)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SensorOverview(
                                  siloCount: siloCount,
                                  sensorCount: _sensors.length,
                                  onlineCount: onlineCount,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.sync_rounded,
                                        size: 14,
                                        color: LegalPageColors.primaryDark,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Last synced: $_lastSyncedLabel',
                                        style: const TextStyle(
                                          color: LegalPageColors.mainText,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedSensorFilterHeader(
                          child: _SensorFilterStrip(
                            selectedStatuses: _selectedStatuses,
                            onStatusSelected: _toggleStatusFilter,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (visibleSensors.isEmpty)
                                Transform.translate(
                                  offset: const Offset(0, 2),
                                  child: SizedBox(
                                    height: MediaQuery.sizeOf(context).height * 0.46,
                                    child: _EmptySensorsState(onClear: _clearAllFilters),
                                  ),
                                )
                              else
                                ..._buildSensorGroups(visibleSensors),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _buildSensorGroups(List<SensorDevice> sensors) {
    final Map<String, List<SensorDevice>> grouped = {};
    for (final sensor in sensors) {
      final siloName = sensor.siloName ?? 'Unassigned';
      grouped.putIfAbsent(siloName, () => []).add(sensor);
    }

    return [
      for (final entry in grouped.entries) ...[
        _SiloHeading(name: entry.key, count: entry.value.length),
        const SizedBox(height: 14),
        for (int index = 0; index < entry.value.length; index++) ...[
          _SensorCard(
            sensor: entry.value[index],
            formattedTimeAgo: _formatTimeAgo(entry.value[index].lastReadingTime),
            onTap: () => _openSensorDetails(entry.value[index]),
          ),
          if (index != entry.value.length - 1) const SizedBox(height: 12),
        ],
        if (entry.key != grouped.keys.last) const SizedBox(height: 28),
      ],
      if (_hasMore) ...[
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.arrow_downward, size: 16),
            label: const Text('Load More Sensors'),
            style: TextButton.styleFrom(
              foregroundColor: LegalPageColors.primaryDark,
            ),
          ),
        ),
      ],
    ];
  }
}

class _SensorsHeader extends StatelessWidget {
  const _SensorsHeader({
    required this.isRefreshing,
    required this.onRefreshPressed,
    required this.isSearchExpanded,
    required this.onSearchPressed,
  });

  final bool isRefreshing;
  final VoidCallback onRefreshPressed;
  final bool isSearchExpanded;
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Sensors',
              style: TextStyle(
                color: LegalPageColors.brandDark,
                fontSize: 28,
                height: 1.2,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          IconButton(
            onPressed: onSearchPressed,
            tooltip: isSearchExpanded ? 'Close search' : 'Search sensors',
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              foregroundColor: LegalPageColors.primaryDark,
              backgroundColor: LegalPageColors.surface,
              shape: const CircleBorder(),
            ),
            icon: Icon(
              isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
              size: 23,
            ),
          ),
          const SizedBox(width: 8),
          _SensorRefreshButton(
            isRefreshing: isRefreshing,
            onPressed: onRefreshPressed,
          ),
        ],
      ),
    );
  }
}

class _SensorRefreshButton extends StatelessWidget {
  const _SensorRefreshButton({
    required this.isRefreshing,
    required this.onPressed,
  });

  final bool isRefreshing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isRefreshing ? null : onPressed,
      tooltip: 'Refresh sensors',
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        backgroundColor: LegalPageColors.brandDark,
        disabledBackgroundColor: LegalPageColors.brandDark,
        shape: const CircleBorder(),
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: isRefreshing
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.refresh_rounded,
                key: ValueKey('refresh'),
                size: 23,
              ),
      ),
    );
  }
}

class _PinnedSensorFilterHeader extends SliverPersistentHeaderDelegate {
  _PinnedSensorFilterHeader({required this.child});

  final Widget child;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: LegalPageColors.pageBackground,
      elevation: overlapsContent ? 2 : 0,
      shadowColor: LegalPageColors.brandDark.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedSensorFilterHeader oldDelegate) => child != oldDelegate.child;
}

class _SensorFilterStrip extends StatelessWidget {
  const _SensorFilterStrip({
    required this.selectedStatuses,
    required this.onStatusSelected,
  });

  final Set<_SensorStatusFilter> selectedStatuses;
  final ValueChanged<_SensorStatusFilter> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: _SensorStatusFilter.values.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final status = _SensorStatusFilter.values[index];
        final isSelected = selectedStatuses.contains(status);
        final color = _statusFilterColor(status);

        return FilterChip(
          selected: isSelected,
          label: Text(status.label),
          onSelected: (_) => onStatusSelected(status),
          elevation: isSelected ? 1 : 0,
          pressElevation: 2,
          selectedColor: LegalPageColors.brandDark,
          backgroundColor: LegalPageColors.surface,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected
                ? LegalPageColors.brandDark
                : LegalPageColors.outline.withValues(alpha: 0.36),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : LegalPageColors.brandDark,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
          avatar: isSelected || status == _SensorStatusFilter.all
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
        );
      },
    );
  }
}

class _SensorOverview extends StatelessWidget {
  const _SensorOverview({
    required this.siloCount,
    required this.sensorCount,
    required this.onlineCount,
  });

  final int siloCount;
  final int sensorCount;
  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LegalPageColors.surface,
      elevation: 1,
      shadowColor: LegalPageColors.brandDark.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: LegalPageColors.outline.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            _OverviewItem(
              label: 'Silos',
              value: '$siloCount',
              icon: Icons.domain_rounded,
            ),
            _OverviewDivider(),
            _OverviewItem(
              label: 'Total sensors',
              value: '$sensorCount',
              icon: Icons.sensors_rounded,
            ),
            _OverviewDivider(),
            _OverviewItem(
              label: 'Online',
              value: '$onlineCount',
              icon: Icons.wifi_rounded,
              valueColor: LegalPageColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: LegalPageColors.primaryDark),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? LegalPageColors.brandDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LegalPageColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: LegalPageColors.outline.withValues(alpha: 0.28),
    );
  }
}

class _SensorSearchBar extends StatelessWidget {
  const _SensorSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(
        color: LegalPageColors.brandDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Search by sensor name, ID or silo...',
        hintStyle: const TextStyle(
          color: LegalPageColors.mutedText,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: LegalPageColors.primaryDark,
          size: 20,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
                color: LegalPageColors.mutedText,
              )
            : null,
        filled: true,
        fillColor: LegalPageColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: LegalPageColors.outline.withValues(alpha: 0.32)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: LegalPageColors.outline.withValues(alpha: 0.32)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: LegalPageColors.primaryDark, width: 1.5),
        ),
      ),
    );
  }
}

class _SiloHeading extends StatelessWidget {
  const _SiloHeading({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: LegalPageColors.tonedEggshell,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.domain_rounded,
            color: LegalPageColors.primaryDark,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: const TextStyle(
            color: LegalPageColors.brandDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: LegalPageColors.outline.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: LegalPageColors.brandDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.sensor,
    required this.formattedTimeAgo,
    required this.onTap,
  });

  final SensorDevice sensor;
  final String formattedTimeAgo;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'online':
        return LegalPageColors.primaryDark;
      case 'maintenance':
        return const Color(0xFF8A6510);
      case 'offline':
        return LegalPageColors.mutedText;
      case 'error':
      case 'critical':
        return const Color(0xFFBA1A1A);
      default:
        return LegalPageColors.brandDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(sensor.status);
    final temp = sensor.latestTemperature != null
        ? '${sensor.latestTemperature!.toStringAsFixed(1)}°C'
        : null;
    final hum = sensor.latestHumidity != null
        ? '${sensor.latestHumidity!.toStringAsFixed(1)}%'
        : null;
    final moist = sensor.latestMoisture != null
        ? '${sensor.latestMoisture!.toStringAsFixed(1)}%'
        : null;
    final voc = sensor.latestVoc != null
        ? '${sensor.latestVoc!.toStringAsFixed(0)} ppb'
        : null;

    return Material(
      color: LegalPageColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: LegalPageColors.brandDark.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: LegalPageColors.outline.withValues(alpha: 0.28),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        overlayColor: WidgetStateProperty.all(
          LegalPageColors.primaryDark.withValues(alpha: 0.05),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: LegalPageColors.tonedEggshell,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.sensors_rounded,
                      color: LegalPageColors.primaryDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensor.deviceName,
                          style: const TextStyle(
                            color: LegalPageColors.brandDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sensor.deviceId,
                          style: const TextStyle(
                            color: LegalPageColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
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
                          const SizedBox(width: 6),
                          Text(
                            sensor.status.toUpperCase(),
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
                        formattedTimeAgo,
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
              const SizedBox(height: 14),
              _SensorMetricsGrid(
                temp: temp,
                humidity: hum,
                moisture: moist,
                voc: voc,
              ),
              if (sensor.batteryLevel != null || sensor.signalStrength != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (sensor.batteryLevel != null) ...[
                      Icon(
                        sensor.batteryLevel! < 20
                            ? Icons.battery_alert_rounded
                            : Icons.battery_charging_full_rounded,
                        size: 14,
                        color: sensor.batteryLevel! < 20
                            ? const Color(0xFFBA1A1A)
                            : LegalPageColors.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${sensor.batteryLevel}%',
                        style: TextStyle(
                          color: sensor.batteryLevel! < 20
                              ? const Color(0xFFBA1A1A)
                              : LegalPageColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (sensor.signalStrength != null) ...[
                      const Icon(
                        Icons.signal_cellular_alt_rounded,
                        size: 14,
                        color: LegalPageColors.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${sensor.signalStrength} dBm',
                        style: const TextStyle(
                          color: LegalPageColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: LegalPageColors.mutedText,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorMetricsGrid extends StatelessWidget {
  const _SensorMetricsGrid({
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
        final double itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricTile(
              width: itemWidth,
              icon: Icons.thermostat_rounded,
              label: 'Temp',
              value: temp ?? 'N/A',
            ),
            _MetricTile(
              width: itemWidth,
              icon: Icons.water_drop_rounded,
              label: 'Humidity',
              value: humidity ?? 'N/A',
            ),
            _MetricTile(
              width: itemWidth,
              icon: Icons.water_rounded,
              label: 'Moisture',
              value: moisture ?? 'N/A',
            ),
            _MetricTile(
              width: itemWidth,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LegalPageColors.tonedEggshell,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LegalPageColors.outline.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: LegalPageColors.primaryDark, size: 18),
          const SizedBox(width: 8),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LegalPageColors.brandDark,
                    fontSize: 15,
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

class _EmptySensorsState extends StatelessWidget {
  const _EmptySensorsState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: LegalPageColors.tonedEggshell,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sensors_off_rounded,
              size: 34,
              color: LegalPageColors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No sensors match filter',
            style: TextStyle(
              color: LegalPageColors.brandDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try clearing your search query or status filter.',
            style: TextStyle(
              color: LegalPageColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
            label: const Text('Reset filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LegalPageColors.brandDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
