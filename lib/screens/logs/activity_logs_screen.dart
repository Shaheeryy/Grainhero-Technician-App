import 'package:flutter/material.dart';
import '../../models/activity_log_model.dart';
import '../../services/activity_log_service.dart';
import '../../config/app_theme.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({Key? key}) : super(key: key);

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final List<ActivityLogModel> _logs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'info':
        return AppTheme.infoColor;
      case 'warning':
        return AppTheme.warningColor;
      case 'critical':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'batch':
        return Icons.inventory_2;
      case 'spoilage':
        return Icons.warning_amber;
      case 'silo':
        return Icons.domain;
      case 'sensor':
        return Icons.sensors;
      case 'actuator':
        return Icons.settings_input_component;
      case 'user':
        return Icons.person;
      default:
        return Icons.event_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLogs,
        color: AppTheme.primaryColor,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _error != null
                ? AppErrorWidget(message: _error!, onRetry: _loadLogs)
                : _logs.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.history,
                        title: 'No Activity Found',
                        subtitle: 'System activity will appear here',
                        onRetry: _loadLogs,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(vertical: AppTheme.spacingM, horizontal: AppTheme.spacingL),
                        itemCount: _logs.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _logs.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppTheme.spacingM),
                              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2)),
                            );
                          }
                          final log = _logs[index];
                          return _buildLogCard(log);
                        },
                      ),
      ),
    );
  }

  Widget _buildLogCard(ActivityLogModel log) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getSeverityColor(log.severity).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(log.category),
              color: _getSeverityColor(log.severity),
              size: 20,
            ),
          ),
          SizedBox(width: AppTheme.spacingM),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.action.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${log.formattedDate} • ${log.formattedTime}',
                      style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (log.entityRef.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.entityRef,
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
