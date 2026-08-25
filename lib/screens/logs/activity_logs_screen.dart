import 'dart:async';

import 'package:flutter/material.dart';

import '../profile/legal_page_components.dart';
import '../../config/grainhero_colors.dart';
import '../../config/typography.dart';
import '../../models/activity_log_model.dart';
import '../../services/activity_log_service.dart';

enum _ActivityTypeFilter { all, maintenance, alerts }
enum _ActivityPeriodFilter { all, today, week }

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen>
    with WidgetsBindingObserver {
  final List<ActivityLogModel> _logs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchAnchorKey = GlobalKey();
  Timer? _keyboardSettleTimer;

  _ActivityTypeFilter _typeFilter = _ActivityTypeFilter.all;
  _ActivityPeriodFilter _periodFilter = _ActivityPeriodFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  void _handleSearchFocusChanged() {
    if (mounted) {
      setState(() {});
    }
    if (_searchFocusNode.hasFocus) {
      _scheduleSearchReveal();
    }
  }

  @override
  void didChangeMetrics() {
    if (_searchFocusNode.hasFocus) {
      _scheduleSearchReveal(delay: const Duration(milliseconds: 90));
    }
  }

  void _scheduleSearchReveal({
    Duration delay = const Duration(milliseconds: 180),
  }) {
    _keyboardSettleTimer?.cancel();
    _keyboardSettleTimer = Timer(delay, () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? anchorContext = _searchAnchorKey.currentContext;
        if (!mounted || !_searchFocusNode.hasFocus || anchorContext == null) {
          return;
        }
        Scrollable.ensureVisible(
          anchorContext,
          alignment: 0.02,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardSettleTimer?.cancel();
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _logs.clear();
      _hasMore = true;
    });

    try {
      final result = await ActivityLogService.fetchLogs(page: _currentPage);
      if (mounted) {
        setState(() {
          _logs.addAll(result['logs'] as List<ActivityLogModel>);
          final pagination = result['pagination'];
          if (pagination != null) {
            _hasMore = _currentPage < (pagination['total_pages'] ?? 1);
          } else {
            _hasMore = false;
          }
          _isLoading = false;
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

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final result = await ActivityLogService.fetchLogs(page: _currentPage);
      if (mounted) {
        setState(() {
          _logs.addAll(result['logs'] as List<ActivityLogModel>);
          final pagination = result['pagination'];
          if (pagination != null) {
            _hasMore = _currentPage < (pagination['total_pages'] ?? 1);
          } else {
            _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  bool _isAlert(ActivityLogModel entry) {
    return entry.severity.toLowerCase() == 'warning' ||
        entry.severity.toLowerCase() == 'critical';
  }

  bool _matchesFilters(ActivityLogModel entry) {
    final bool matchesType = switch (_typeFilter) {
      _ActivityTypeFilter.all => true,
      _ActivityTypeFilter.maintenance => !_isAlert(entry),
      _ActivityTypeFilter.alerts => _isAlert(entry),
    };
    final bool matchesPeriod = _matchesPeriod(entry, _periodFilter);
    return matchesType && matchesPeriod;
  }

  bool _matchesPeriod(ActivityLogModel entry, _ActivityPeriodFilter period) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime eventDay = DateTime(
      entry.createdAt.year,
      entry.createdAt.month,
      entry.createdAt.day,
    );
    return switch (period) {
      _ActivityPeriodFilter.all => true,
      _ActivityPeriodFilter.today => eventDay == today,
      _ActivityPeriodFilter.week =>
        !eventDay.isBefore(today.subtract(const Duration(days: 6))) &&
            !eventDay.isAfter(today),
    };
  }

  int _countForType(bool isAlert) =>
      _logs.where((entry) => _isAlert(entry) == isAlert).length;

  int _countForPeriod(_ActivityPeriodFilter period) =>
      _logs.where((entry) => _matchesPeriod(entry, period)).length;

  List<ActivityLogModel> get _visibleEntries {
    final String query = _query.trim().toLowerCase();
    return _logs.where((entry) {
      final bool matchesQuery = query.isEmpty ||
          entry.action.toLowerCase().contains(query) ||
          entry.description.toLowerCase().contains(query) ||
          entry.entityRef.toLowerCase().contains(query);
      return matchesQuery && _matchesFilters(entry);
    }).toList();
  }

  String _dateLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime eventDay = DateTime(date.year, date.month, date.day);
    if (eventDay == today) return 'Today';
    if (eventDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Map<String, List<ActivityLogModel>> _groupEntries(
    List<ActivityLogModel> entries,
  ) {
    final Map<String, List<ActivityLogModel>> grouped = {};
    for (final ActivityLogModel entry in entries) {
      grouped.putIfAbsent(_dateLabel(entry.createdAt), () => []).add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final List<ActivityLogModel> visibleEntries = _visibleEntries;
    final Map<String, List<ActivityLogModel>> groupedEntries = _groupEntries(
      visibleEntries,
    );
    final bool compactSearchMode =
        _searchFocusNode.hasFocus && _query.trim().isNotEmpty;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double compactResultsEndSpace = compactSearchMode
        ? switch (visibleEntries.length) {
            0 => (screenHeight * 0.40).clamp(240.0, 360.0).toDouble(),
            1 => (screenHeight * 0.38).clamp(220.0, 340.0).toDouble(),
            2 => (screenHeight * 0.24).clamp(130.0, 220.0).toDouble(),
            3 => (screenHeight * 0.12).clamp(70.0, 120.0).toDouble(),
            _ => 0,
          }
        : 0;

    return LegalPageScaffold(
      title: 'Activity Logs',
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActivityOverview(
                  visibleCount: visibleEntries.length,
                  totalCount: _logs.length,
                ),
                const SizedBox(height: 16),
                SearchBar(
                  key: _searchAnchorKey,
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Search activity, device or action',
                  onChanged: (value) => setState(() => _query = value),
                  onTapOutside: (_) => _searchFocusNode.unfocus(),
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.search_rounded,
                      color: GrainHeroColors.primaryDark,
                    ),
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      TextFieldTapRegion(
                        child: IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: GrainHeroColors.primaryDark,
                          ),
                        ),
                      ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: const WidgetStatePropertyAll(
                    GrainHeroColors.surface,
                  ),
                  side: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return const BorderSide(
                        color: GrainHeroColors.primary,
                        width: 2,
                      );
                    }
                    return BorderSide(
                      color: GrainHeroColors.outline,
                    );
                  }),
                  textStyle: WidgetStatePropertyAll(
                    AppTypography.bodyStyle(
                      color: GrainHeroColors.bodyText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  hintStyle: WidgetStatePropertyAll(
                    AppTypography.bodyStyle(
                      color: GrainHeroColors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: compactSearchMode
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                const _FilterGroupLabel(label: 'Type'),
                                const SizedBox(width: 8),
                                for (final _ActivityTypeFilter filter
                                    in _ActivityTypeFilter.values) ...[
                                  if (filter !=
                                      _ActivityTypeFilter.values.first)
                                    const SizedBox(width: 8),
                                  _ActivityFilterChip(
                                    label: switch (filter) {
                                      _ActivityTypeFilter.all =>
                                        'All · ${_logs.length}',
                                      _ActivityTypeFilter.maintenance =>
                                        'Maintenance · ${_countForType(false)}',
                                      _ActivityTypeFilter.alerts =>
                                        'Alerts · ${_countForType(true)}',
                                    },
                                    selected: _typeFilter == filter,
                                    onSelected: () =>
                                        setState(() => _typeFilter = filter),
                                  ),
                                ],
                                const SizedBox(width: 16),
                                const _FilterGroupLabel(label: 'Period'),
                                const SizedBox(width: 8),
                                for (final _ActivityPeriodFilter filter
                                    in _ActivityPeriodFilter.values) ...[
                                  if (filter !=
                                      _ActivityPeriodFilter.values.first)
                                    const SizedBox(width: 8),
                                  _ActivityFilterChip(
                                    label: switch (filter) {
                                      _ActivityPeriodFilter.all => 'All time',
                                      _ActivityPeriodFilter.today =>
                                        'Today · ${_countForPeriod(filter)}',
                                      _ActivityPeriodFilter.week =>
                                        'Last 7 days · ${_countForPeriod(filter)}',
                                    },
                                    selected: _periodFilter == filter,
                                    onSelected: () =>
                                        setState(() => _periodFilter = filter),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading && _logs.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: GrainHeroColors.primaryDark),
            ),
          )
        else if (_error != null && _logs.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: GrainHeroColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(_error!, style: AppTypography.bodyStyle(color: GrainHeroColors.error, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadLogs, child: const Text('Retry'))
                ],
              ),
            ),
          )
        else if (groupedEntries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyActivityState(
              showResetAction:
                  _query.trim().isNotEmpty ||
                  _typeFilter != _ActivityTypeFilter.all ||
                  _periodFilter != _ActivityPeriodFilter.all,
              onReset: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
                setState(() {
                  _query = '';
                  _typeFilter = _ActivityTypeFilter.all;
                  _periodFilter = _ActivityPeriodFilter.all;
                });
              },
            ),
          )
        else
          for (final MapEntry<String, List<ActivityLogModel>> group
              in groupedEntries.entries) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 9),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${group.key.toUpperCase()} · ${group.value.length} ${group.value.length == 1 ? 'EVENT' : 'EVENTS'}',
                  style: AppTypography.bodyStyle(
                    color: GrainHeroColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: group.value.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ActivityLogModel entry = group.value[index];
                  return _ActivityCard(entry: entry);
                },
              ),
            ),
          ],
        if (_hasMore && groupedEntries.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator(color: GrainHeroColors.primaryDark)
                    : TextButton(
                        onPressed: _loadMore,
                        child: Text('Load More', style: AppTypography.bodyStyle(color: GrainHeroColors.primaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: 36 + compactResultsEndSpace),
        ),
      ],
    );
  }
}

class _ActivityOverview extends StatelessWidget {
  const _ActivityOverview({
    required this.visibleCount,
    required this.totalCount,
  });

  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: GrainHeroColors.dark,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.history_rounded,
            color: GrainHeroColors.surface,
            size: 26,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity history',
                style: AppTypography.headingStyle(
                  color: GrainHeroColors.dark,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$visibleCount of $totalCount events shown',
                style: AppTypography.bodyStyle(
                  color: GrainHeroColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityFilterChip extends StatelessWidget {
  const _ActivityFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: GrainHeroColors.dark,
      backgroundColor: GrainHeroColors.surface,
      checkmarkColor: GrainHeroColors.surface,
      side: BorderSide(
        color: selected
            ? GrainHeroColors.dark
            : GrainHeroColors.primaryDark.withValues(alpha: 0.45),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: AppTypography.bodyStyle(
        color: selected ? GrainHeroColors.surface : GrainHeroColors.primaryDark,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _FilterGroupLabel extends StatelessWidget {
  const _FilterGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.bodyStyle(
        color: GrainHeroColors.mutedText,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entry});

  final ActivityLogModel entry;

  String _time(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  bool _isAlert() {
    return entry.severity.toLowerCase() == 'warning' ||
        entry.severity.toLowerCase() == 'critical';
  }

  @override
  Widget build(BuildContext context) {
    final bool alert = _isAlert();
    final String typeLabel = alert ? 'ALERT' : 'MAINTENANCE';

    return Material(
      color: GrainHeroColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: GrainHeroColors.dark.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: GrainHeroColors.outline.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                alert
                    ? Icons.notifications_active_outlined
                    : Icons.build_circle_outlined,
                color: GrainHeroColors.primaryDark,
                size: 30,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          typeLabel,
                          style: AppTypography.bodyStyle(
                            color: GrainHeroColors.primaryDark,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _time(entry.createdAt),
                        style: AppTypography.bodyStyle(
                          color: GrainHeroColors.mutedText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.action.replaceAll('_', ' ').toUpperCase(),
                    style: AppTypography.headingStyle(
                      color: GrainHeroColors.dark,
                      fontSize: 15.5,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    style: AppTypography.bodyStyle(
                      color: GrainHeroColors.bodyText,
                      fontSize: 13,
                      height: 1.42,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (entry.entityRef.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.sensors_rounded,
                            color: GrainHeroColors.primaryDark,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.entityRef,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyStyle(
                              color: GrainHeroColors.bodyText.withValues(
                                alpha: 0.72,
                              ),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState({
    required this.showResetAction,
    required this.onReset,
  });

  final bool showResetAction;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              color: GrainHeroColors.primaryDark,
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              'No matching activity',
              textAlign: TextAlign.center,
              style: AppTypography.headingStyle(
                color: GrainHeroColors.dark,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try another search or activity filter.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyStyle(
                color: GrainHeroColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showResetAction) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Future<void>.delayed(
                    const Duration(milliseconds: 100),
                    onReset,
                  );
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(
                  'Show all activity',
                  style: AppTypography.bodyStyle(
                    color: GrainHeroColors.surface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style:
                    FilledButton.styleFrom(
                      foregroundColor: GrainHeroColors.surface,
                      backgroundColor: GrainHeroColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ).copyWith(
                  splashFactory: InkRipple.splashFactory,
                  overlayColor: WidgetStatePropertyAll(
                    GrainHeroColors.surface.withValues(alpha: 0.14),
                  ),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
