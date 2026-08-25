import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/grainhero_colors.dart';
import '../../config/typography.dart';
import '../../models/actuator_model.dart';
import '../../services/actuator_service.dart';
import '../../widgets/common/error_widget.dart';

enum _ActuatorFilter { all, running, stopped, needsAttention, recentlyUpdated }

extension on _ActuatorFilter {
  String get label => switch (this) {
    _ActuatorFilter.all => 'All',
    _ActuatorFilter.running => 'Running',
    _ActuatorFilter.stopped => 'Stopped',
    _ActuatorFilter.needsAttention => 'Needs attention',
    _ActuatorFilter.recentlyUpdated => 'Recently updated',
  };
}

class ActuatorsScreen extends StatefulWidget {
  const ActuatorsScreen({super.key});

  @override
  State<ActuatorsScreen> createState() => _ActuatorsScreenState();
}

class _ActuatorsScreenState extends State<ActuatorsScreen> {
  List<ActuatorModel> _actuators = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _togglingIds = {};

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchExpanded = false;
  Set<_ActuatorFilter> _selectedFilters = {_ActuatorFilter.all};
  DateTime _lastSyncedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadActuators();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadActuators() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ActuatorService.getActuators();
      if (mounted) {
        setState(() {
          _actuators = result['actuators'] as List<ActuatorModel>;
          _isLoading = false;
          _lastSyncedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleActuator(ActuatorModel actuator) async {
    if (_togglingIds.contains(actuator.id)) return;
    setState(() => _togglingIds.add(actuator.id));

    final newState = !actuator.isOn;
    // Optimistic update
    setState(() {
      final idx = _actuators.indexWhere((a) => a.id == actuator.id);
      if (idx != -1) _actuators[idx] = actuator.copyWith(isOn: newState);
    });

    try {
      await ActuatorService.toggleActuator(actuator.id, newState);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: GrainHeroColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  newState ? Icons.check_circle_rounded : Icons.power_settings_new_rounded,
                  color: newState ? GrainHeroColors.primary : GrainHeroColors.mutedText,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  newState ? '${actuator.name} Turned ON' : '${actuator.name} Turned OFF',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingStyle(
                    color: GrainHeroColors.dark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  newState
                      ? 'The device is now running successfully.'
                      : 'The device has been powered down.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyStyle(
                    color: GrainHeroColors.bodyText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GrainHeroColors.dark,
                      foregroundColor: GrainHeroColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Done',
                      style: AppTypography.bodyStyle(
                        color: GrainHeroColors.surface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update
      if (mounted) {
        setState(() {
          final idx = _actuators.indexWhere((a) => a.id == actuator.id);
          if (idx != -1) _actuators[idx] = actuator; // revert
        });
        final msg = e.toString().replaceAll('Exception: ', '');
        if (!msg.contains('_no_actuator_in_response')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $msg'),
              backgroundColor: GrainHeroColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        } else {
          // Server didn't return actuator but action succeeded - refresh
          _loadActuators();
        }
      }
    } finally {
      if (mounted) setState(() => _togglingIds.remove(actuator.id));
    }
  }

  bool _needsAttention(ActuatorModel actuator) {
    return actuator.healthMetrics.errorCount > 0 ||
        actuator.maintenanceStatus.toUpperCase() == 'DUE SOON' ||
        actuator.maintenanceStatus.toUpperCase() == 'REVIEW';
  }

  bool _wasRecentlyUpdated(ActuatorModel actuator) {
    if (actuator.healthMetrics.lastHeartbeat == null) return false;
    return DateTime.now().difference(actuator.healthMetrics.lastHeartbeat!).inMinutes < 60;
  }

  bool _matchesFilter(ActuatorModel actuator) {
    if (_selectedFilters.contains(_ActuatorFilter.all)) return true;
    final isRunning = actuator.isOn;
    return (isRunning && _selectedFilters.contains(_ActuatorFilter.running)) ||
        (!isRunning && _selectedFilters.contains(_ActuatorFilter.stopped)) ||
        (_needsAttention(actuator) && _selectedFilters.contains(_ActuatorFilter.needsAttention)) ||
        (_wasRecentlyUpdated(actuator) && _selectedFilters.contains(_ActuatorFilter.recentlyUpdated));
  }

  bool _matchesQuery(ActuatorModel actuator) {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return actuator.name.toLowerCase().contains(query) ||
        actuator.actuatorId.toLowerCase().contains(query) ||
        (actuator.siloName?.toLowerCase().contains(query) ?? false);
  }

  List<ActuatorModel> get _filteredActuators {
    return _actuators.where((a) => _matchesFilter(a) && _matchesQuery(a)).toList();
  }

  Map<String, List<ActuatorModel>> get _groupedFiltered {
    final map = <String, List<ActuatorModel>>{};
    for (final a in _filteredActuators) {
      final silo = a.siloName ?? 'Unassigned';
      map.putIfAbsent(silo, () => []).add(a);
    }
    return map;
  }

  void _toggleFilter(_ActuatorFilter filter) {
    setState(() {
      if (filter == _ActuatorFilter.all) {
        _selectedFilters = {_ActuatorFilter.all};
        return;
      }
      _selectedFilters.remove(_ActuatorFilter.all);
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
      if (_selectedFilters.isEmpty) _selectedFilters = {_ActuatorFilter.all};
    });
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

  void _clearSearchAndFilters() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _selectedFilters = {_ActuatorFilter.all});
  }

  String get _lastSyncedLabel {
    final Duration elapsed = DateTime.now().difference(_lastSyncedAt);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
    return '${elapsed.inHours}h ago';
  }

  String _timeAgo(DateTime? d) {
    if (d == null) return '--';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showDetailSheet(ActuatorModel actuator) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActuatorDetailSheet(
        actuator: actuator,
        onToggle: () {
          Navigator.pop(ctx);
          _toggleActuator(actuator);
        },
        onPowerChanged: (level) async {
          Navigator.pop(ctx);
          // Optimistic update
          setState(() {
            final idx = _actuators.indexWhere((a) => a.id == actuator.id);
            if (idx != -1) {
              _actuators[idx] = actuator.copyWith(
                powerLevel: level,
                isOn: level > 0,
              );
            }
          });

          try {
            await ActuatorService.setPowerLevel(actuator.id, level);
          } catch (e) {
            // Revert on error
            setState(() {
              final idx = _actuators.indexWhere((a) => a.id == actuator.id);
              if (idx != -1) _actuators[idx] = actuator;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
                  backgroundColor: GrainHeroColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalSilos = _actuators.map((a) => a.siloName ?? 'Unassigned').toSet().length;
    final int totalActuators = _actuators.length;
    final int onlineCount = _actuators.where((a) => a.isOn).length;

    final int runningCount = _actuators.where((a) => a.isOn).length;
    final int attentionCount = _actuators.where(_needsAttention).length;
    final int recentCount = _actuators.where(_wasRecentlyUpdated).length;

    final groupedFiltered = _groupedFiltered;

    return Scaffold(
      backgroundColor: GrainHeroColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: GrainHeroColors.primary,
          backgroundColor: GrainHeroColors.surface,
          onRefresh: _loadActuators,
          child: ListView(
            padding: EdgeInsets.zero,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              _ActuatorsHeader(
                isRefreshing: _isLoading,
                onRefreshPressed: _loadActuators,
                isSearchExpanded: _isSearchExpanded,
                onSearchPressed: _toggleSearch,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isSearchExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                        child: _ActuatorSearchBar(
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  _isSearchExpanded ? 0 : 12,
                  16,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isSearchExpanded) ...[
                      _GlobalOverview(
                        siloCount: totalSilos,
                        actuatorCount: totalActuators,
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
                              size: 13,
                              color: GrainHeroColors.mutedText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Synced $_lastSyncedLabel',
                              style: AppTypography.bodyStyle(
                                color: GrainHeroColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _ActuatorFilterStrip(
                      selectedFilters: _selectedFilters,
                      runningCount: runningCount,
                      attentionCount: attentionCount,
                      recentCount: recentCount,
                      onSelected: _toggleFilter,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading && _actuators.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: GrainHeroColors.primaryDark,
                          ),
                        ),
                      )
                    else if (_error != null && _actuators.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: AppErrorWidget(
                          message: _error!,
                          onRetry: _loadActuators,
                        ),
                      )
                    else if (groupedFiltered.isEmpty)
                      _NoMatchingActuatorsCard(
                        onClear: _clearSearchAndFilters,
                      )
                    else
                      ..._buildSiloGroups(groupedFiltered),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSiloGroups(Map<String, List<ActuatorModel>> grouped) {
    final silos = grouped.keys.toList()..sort();
    final List<Widget> widgets = [];

    for (int i = 0; i < silos.length; i++) {
      final silo = silos[i];
      final actuators = grouped[silo]!;

      if (i > 0) {
        widgets.add(const SizedBox(height: 28));
      }

      // Silo Section Header
      widgets.add(
        _SiloSectionHeader(
          name: silo,
          actuatorCount: actuators.length,
        ),
      );
      widgets.add(const SizedBox(height: 14));

      // Actuator Cards
      for (int j = 0; j < actuators.length; j++) {
        final a = actuators[j];
        if (j > 0) widgets.add(const SizedBox(height: 12));

        widgets.add(
          _ActuatorCard(
            actuator: a,
            isToggling: _togglingIds.contains(a.id),
            timeAgoText: _timeAgo(a.healthMetrics.lastHeartbeat),
            onTap: () => _showDetailSheet(a),
            onToggle: () => _toggleActuator(a),
          ),
        );
      }
    }

    return widgets;
  }
}

// =====================================================
// UI Header Component
// =====================================================
class _ActuatorsHeader extends StatelessWidget {
  const _ActuatorsHeader({
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
          Expanded(
            child: Text(
              'Actuators',
              style: AppTypography.headingStyle(
                color: GrainHeroColors.dark,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          IconButton(
            onPressed: onSearchPressed,
            tooltip: isSearchExpanded ? 'Close search' : 'Search actuators',
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              foregroundColor: GrainHeroColors.dark,
              backgroundColor: GrainHeroColors.surface.withValues(alpha: 0.72),
              side: BorderSide(
                color: GrainHeroColors.outline.withValues(alpha: 0.34),
              ),
              shape: const CircleBorder(),
            ),
            icon: Icon(
              isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isRefreshing ? null : onRefreshPressed,
            tooltip: 'Refresh actuators',
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              foregroundColor: GrainHeroColors.primaryDark,
              disabledForegroundColor: GrainHeroColors.mutedText,
              backgroundColor: GrainHeroColors.surface.withValues(alpha: 0.72),
              side: BorderSide(
                color: GrainHeroColors.outline.withValues(alpha: 0.34),
              ),
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
                        color: GrainHeroColors.primaryDark,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      key: ValueKey('refresh'),
                      size: 23,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActuatorSearchBar extends StatelessWidget {
  const _ActuatorSearchBar({
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
    final bool hasText = controller.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: GrainHeroColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GrainHeroColors.outline.withValues(alpha: 0.40),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: GrainHeroColors.mutedText,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: AppTypography.bodyStyle(
                color: GrainHeroColors.dark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Search by device name, ID, or silo...',
                hintStyle: TextStyle(
                  color: GrainHeroColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.cancel_rounded, size: 18),
              color: GrainHeroColors.mutedText,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

class _ActuatorFilterStrip extends StatelessWidget {
  const _ActuatorFilterStrip({
    required this.selectedFilters,
    required this.runningCount,
    required this.attentionCount,
    required this.recentCount,
    required this.onSelected,
  });

  final Set<_ActuatorFilter> selectedFilters;
  final int runningCount;
  final int attentionCount;
  final int recentCount;
  final ValueChanged<_ActuatorFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _ActuatorFilter.values.map((filter) {
          final bool isSelected = selectedFilters.contains(filter);
          final String label = switch (filter) {
            _ActuatorFilter.all => filter.label,
            _ActuatorFilter.running => '${filter.label} ($runningCount)',
            _ActuatorFilter.stopped => filter.label,
            _ActuatorFilter.needsAttention =>
              attentionCount > 0 ? '${filter.label} ($attentionCount)' : filter.label,
            _ActuatorFilter.recentlyUpdated =>
              recentCount > 0 ? '${filter.label} ($recentCount)' : filter.label,
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(label),
              labelStyle: AppTypography.bodyStyle(
                color: isSelected ? Colors.white : GrainHeroColors.bodyText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              backgroundColor: GrainHeroColors.surface,
              selectedColor: GrainHeroColors.primaryDark,
              side: BorderSide(
                color: isSelected
                    ? GrainHeroColors.primaryDark
                    : GrainHeroColors.outline.withValues(alpha: 0.38),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onSelected: (_) => onSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NoMatchingActuatorsCard extends StatelessWidget {
  const _NoMatchingActuatorsCard({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: GrainHeroColors.tonedEggshell,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: GrainHeroColors.primaryDark,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No actuators match your search',
              style: AppTypography.headingStyle(
                color: GrainHeroColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search query or clear active filters.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyStyle(
                color: GrainHeroColors.mutedText,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GrainHeroColors.primaryDark,
                side: const BorderSide(color: GrainHeroColors.primaryDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// Global Overview Component
// =====================================================
class _GlobalOverview extends StatelessWidget {
  const _GlobalOverview({
    required this.siloCount,
    required this.actuatorCount,
    required this.onlineCount,
  });

  final int siloCount;
  final int actuatorCount;
  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: GrainHeroColors.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: _OverviewMetric(
                value: siloCount,
                singularLabel: 'SILO',
                pluralLabel: 'SILOS',
              ),
            ),
            Container(
              width: 1,
              height: 38,
              color: GrainHeroColors.outline.withValues(alpha: 0.48),
            ),
            Expanded(
              child: _OverviewMetric(
                value: actuatorCount,
                singularLabel: 'ACTUATOR',
                pluralLabel: 'ACTUATORS',
              ),
            ),
            Container(
              width: 1,
              height: 38,
              color: GrainHeroColors.outline.withValues(alpha: 0.48),
            ),
            Expanded(
              child: _OverviewMetric(
                value: onlineCount,
                singularLabel: 'ONLINE',
                pluralLabel: 'ONLINE',
                isOnlineMetric: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.value,
    required this.singularLabel,
    required this.pluralLabel,
    this.isOnlineMetric = false,
  });

  final int value;
  final String singularLabel;
  final String pluralLabel;
  final bool isOnlineMetric;

  @override
  Widget build(BuildContext context) {
    final String label = value == 1 ? singularLabel : pluralLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: AppTypography.headingStyle(
            color: isOnlineMetric && value > 0
                ? GrainHeroColors.primaryDark
                : GrainHeroColors.dark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyStyle(
            color: GrainHeroColors.mutedText,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// =====================================================
// Silo Section Header Component
// =====================================================
class _SiloSectionHeader extends StatelessWidget {
  const _SiloSectionHeader({
    required this.name,
    required this.actuatorCount,
  });

  final String name;
  final int actuatorCount;

  @override
  Widget build(BuildContext context) {
    final String countLabel = actuatorCount == 1
        ? '1 ACTUATOR'
        : '$actuatorCount ACTUATORS';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTypography.headingStyle(
                color: GrainHeroColors.dark,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: GrainHeroColors.tonedEggshell,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: GrainHeroColors.outline.withValues(alpha: 0.55),
              ),
            ),
            child: Text(
              countLabel,
              style: AppTypography.bodyStyle(
                color: GrainHeroColors.primaryDark,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// Actuator Card Component
// =====================================================
class _ActuatorCard extends StatelessWidget {
  const _ActuatorCard({
    required this.actuator,
    required this.isToggling,
    required this.timeAgoText,
    required this.onTap,
    required this.onToggle,
  });

  final ActuatorModel actuator;
  final bool isToggling;
  final String timeAgoText;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final bool canToggle = actuator.status != 'offline' &&
        actuator.status != 'error' &&
        actuator.isEnabled;

    return Material(
      color: GrainHeroColors.surface,
      elevation: 3,
      shadowColor: GrainHeroColors.primary.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.42),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              top: -45,
              right: -42,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: GrainHeroColors.primary.withValues(alpha: 0.055),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Device Row
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: actuator.isOn
                              ? GrainHeroColors.tonedEggshell
                              : GrainHeroColors.outline.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Icon(
                          actuator.typeIcon,
                          color: actuator.isOn
                              ? GrainHeroColors.primaryDark
                              : GrainHeroColors.bodyText,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              actuator.name,
                              style: AppTypography.headingStyle(
                                color: GrainHeroColors.dark,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              actuator.actuatorId,
                              style: AppTypography.bodyStyle(
                                color: GrainHeroColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isToggling)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: GrainHeroColors.primaryDark,
                          ),
                        )
                      else
                        Switch(
                          value: actuator.isOn,
                          onChanged: canToggle ? (_) => onToggle() : null,
                          activeTrackColor: GrainHeroColors.primary,
                          activeThumbColor: Colors.white,
                          inactiveTrackColor: GrainHeroColors.outline,
                          inactiveThumbColor: Colors.white,
                          trackOutlineColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // State Chips (Control Mode, Triggered By, AI, ML)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StateChip(
                        label: actuator.controlModeLabel,
                        icon: Icons.touch_app_rounded,
                        emphasized: true,
                      ),
                      if (actuator.currentOperation?.triggeredBy != null)
                        _StateChip(
                          label: 'By: ${actuator.currentOperation!.triggeredBy}',
                          icon: Icons.auto_mode_rounded,
                        ),
                      if (actuator.aiControl.enabled)
                        const _StateChip(
                          label: 'AI Active',
                          icon: Icons.psychology_rounded,
                        ),
                      if (actuator.mlDecision != 'idle')
                        _StateChip(
                          label: 'ML: ${actuator.mlDecision}',
                          icon: Icons.memory_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Power Output Bar & Runtime
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Power output',
                          style: AppTypography.bodyStyle(
                            color: GrainHeroColors.bodyText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${actuator.powerLevel}%',
                        style: AppTypography.headingStyle(
                          color: GrainHeroColors.dark,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double factor = (actuator.powerLevel / 100).clamp(0.0, 1.0);
                      return Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: GrainHeroColors.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 650),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * factor,
                            decoration: BoxDecoration(
                              color: GrainHeroColors.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  Divider(
                    height: 1,
                    color: GrainHeroColors.outline.withValues(alpha: 0.32),
                  ),
                  const SizedBox(height: 14),

                  // Card Footer (Running status + last heartbeat)
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: actuator.isOn
                              ? GrainHeroColors.primary
                              : GrainHeroColors.bodyText.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          boxShadow: actuator.isOn
                              ? [
                                  BoxShadow(
                                    color: GrainHeroColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 7,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        actuator.isOn ? 'RUNNING' : 'IDLE',
                        style: AppTypography.bodyStyle(
                          color: actuator.isOn
                              ? GrainHeroColors.primaryDark
                              : GrainHeroColors.bodyText,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: GrainHeroColors.bodyText.withValues(alpha: 0.56),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeAgoText,
                        style: AppTypography.bodyStyle(
                          color: GrainHeroColors.bodyText.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final Color foreground = emphasized
        ? GrainHeroColors.primaryDark
        : GrainHeroColors.bodyText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? GrainHeroColors.primary.withValues(alpha: 0.12)
            : GrainHeroColors.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: emphasized
              ? GrainHeroColors.primary.withValues(alpha: 0.22)
              : GrainHeroColors.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodyStyle(
              color: foreground,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// Actuator Detail Sheet Component
// Modal sheet retaining full power slider controls, AI info,
// runtime, health metrics, and safety limits.
// =====================================================
class _ActuatorDetailSheet extends StatefulWidget {
  final ActuatorModel actuator;
  final VoidCallback onToggle;
  final ValueChanged<int> onPowerChanged;

  const _ActuatorDetailSheet({
    required this.actuator,
    required this.onToggle,
    required this.onPowerChanged,
  });

  @override
  State<_ActuatorDetailSheet> createState() => _ActuatorDetailSheetState();
}

class _ActuatorDetailSheetState extends State<_ActuatorDetailSheet> {
  late double _powerSlider;

  @override
  void initState() {
    super.initState();
    _powerSlider = widget.actuator.powerLevel.toDouble();
  }

  String _timeAgo(DateTime? d) {
    if (d == null) return '--';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.actuator;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: GrainHeroColors.pageBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: GrainHeroColors.dark.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Info Card
              Material(
                color: GrainHeroColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: GrainHeroColors.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GrainHeroColors.tonedEggshell,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          a.typeIcon,
                          size: 30,
                          color: GrainHeroColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              style: AppTypography.headingStyle(
                                color: GrainHeroColors.dark,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.siloName ?? 'Unassigned',
                              style: AppTypography.bodyStyle(
                                color: GrainHeroColors.bodyText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              a.actuatorId,
                              style: AppTypography.bodyStyle(
                                color: GrainHeroColors.mutedText,
                                fontSize: 11,
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
              const SizedBox(height: 20),

              // Toggle Power Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onToggle,
                  icon: Icon(
                    a.isOn ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    a.isOn ? 'TURN OFF DEVICE' : 'TURN ON DEVICE',
                    style: AppTypography.bodyStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: a.isOn ? GrainHeroColors.error : GrainHeroColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Power Level Slider Box
              Material(
                color: GrainHeroColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: GrainHeroColors.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Power Level Control',
                            style: AppTypography.headingStyle(
                              color: GrainHeroColors.dark,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_powerSlider.toInt()}%',
                            style: AppTypography.headingStyle(
                              color: GrainHeroColors.primaryDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: GrainHeroColors.primary,
                          thumbColor: GrainHeroColors.primaryDark,
                        ),
                        child: Slider(
                          value: _powerSlider,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${_powerSlider.toInt()}%',
                          onChanged: (v) => setState(() => _powerSlider = v),
                        ),
                      ),
                      if (_powerSlider.toInt() != a.powerLevel)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => widget.onPowerChanged(_powerSlider.toInt()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GrainHeroColors.primaryDark,
                              side: const BorderSide(color: GrainHeroColors.primaryDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Apply Power Level'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Details & Operations Section
              _DetailGroupCard(
                title: 'Operational Status',
                rows: [
                  _DetailRow('Control Mode', a.controlModeLabel),
                  if (a.currentOperation?.triggeredBy != null)
                    _DetailRow('Triggered By', a.currentOperation!.triggeredBy!),
                  if (a.isOn && a.currentOperation?.startedAt != null)
                    _DetailRow(
                      'Running Since',
                      DateFormat('MMM d, HH:mm').format(a.currentOperation!.startedAt!),
                    ),
                  if (a.isOn) _DetailRow('Runtime', a.runtimeDisplay),
                  _DetailRow('Operation Status', a.operationStatus.toUpperCase()),
                ],
              ),
              const SizedBox(height: 16),

              // AI Control Section
              _DetailGroupCard(
                title: 'AI & ML Control',
                rows: [
                  _DetailRow('AI Enabled', a.aiControl.enabled ? 'Yes' : 'No'),
                  _DetailRow('Risk Threshold', '${a.aiControl.riskScoreThreshold.toInt()}%'),
                  _DetailRow('ML Decision', a.mlDecision),
                  _DetailRow('ML Requested Fan', a.mlRequestedFan ? 'Yes' : 'No'),
                  _DetailRow('Human Requested', a.humanRequestedFan ? 'Yes' : 'No'),
                ],
                footer: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GrainHeroColors.tonedEggshell,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: GrainHeroColors.primaryDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Contact admin to change AI settings',
                          style: AppTypography.bodyStyle(
                            color: GrainHeroColors.primaryDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Health Metrics Section
              _DetailGroupCard(
                title: 'Health & Performance',
                rows: [
                  _DetailRow('Uptime', '${a.healthMetrics.uptimePercentage.toStringAsFixed(1)}%'),
                  _DetailRow('Total Operations', '${a.healthMetrics.totalOperations}'),
                  _DetailRow(
                    'Total Runtime',
                    '${a.healthMetrics.totalRuntimeHours.toStringAsFixed(1)} hrs',
                  ),
                  _DetailRow('Errors', '${a.healthMetrics.errorCount}'),
                  _DetailRow('Last Heartbeat', _timeAgo(a.healthMetrics.lastHeartbeat)),
                ],
              ),
              const SizedBox(height: 16),

              // Maintenance & Limits Section
              _DetailGroupCard(
                title: 'Maintenance & Safety Limits',
                rows: [
                  _DetailRow(
                    'Last Maintenance',
                    a.performanceMetrics.lastMaintenance != null
                        ? DateFormat('MMM d, yyyy').format(a.performanceMetrics.lastMaintenance!)
                        : '--',
                  ),
                  _DetailRow(
                    'Next Due',
                    a.performanceMetrics.nextMaintenanceDue != null
                        ? DateFormat('MMM d, yyyy').format(a.performanceMetrics.nextMaintenanceDue!)
                        : '--',
                  ),
                  _DetailRow('Maintenance Status', a.maintenanceStatus.toUpperCase()),
                  _DetailRow('Max Runtime', '${a.safetyLimits.maxRuntimeHours} hrs'),
                  _DetailRow('Cooldown Period', '${a.safetyLimits.cooldownPeriodMinutes} min'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailGroupCard extends StatelessWidget {
  const _DetailGroupCard({
    required this.title,
    required this.rows,
    this.footer,
  });

  final String title;
  final List<_DetailRow> rows;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GrainHeroColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.headingStyle(
                color: GrainHeroColors.dark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.label,
                      style: AppTypography.bodyStyle(
                        color: GrainHeroColors.bodyText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      row.value,
                      style: AppTypography.bodyStyle(
                        color: GrainHeroColors.dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
}


