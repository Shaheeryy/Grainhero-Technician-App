import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../models/alert_model.dart';
import '../../config/app_theme.dart';
import '../../config/auth_theme.dart';

import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/app_toast.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AlertModel> _alerts = [];
  bool _isLoading = true;
  String? _error;
  final _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final alerts = await _alertService.fetchAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('Unauthorized')) {
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.logout();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        String errorMessage = e.toString();
        if (errorMessage.contains('Cannot connect to server')) {
          errorMessage = 'Cannot connect to server. Please check your connection.';
        } else if (errorMessage.contains('Failed to load alerts')) {
          errorMessage = 'Unable to load alerts. Service unavailable.';
        } else {
          errorMessage = errorMessage.replaceAll('Exception: ', '');
        }

        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.beigeBackground,
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AuthTheme.textPrimary,
          ),
        ),
        backgroundColor: AuthTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AuthTheme.textSecondary),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AuthTheme.primaryGreen),
      );
    }

    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _loadAlerts);
    }

    if (_alerts.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.notifications_none_outlined,
        title: 'No Active Alerts',
        subtitle: 'Everything is running smoothly!',
        onRetry: _loadAlerts,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      color: AuthTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          return _buildAlertCard(_alerts[index]);
        },
      ),
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: alert.acknowledged ? AuthTheme.dividerColor : AuthTheme.error,
            width: 4,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAlertDetails(alert),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(
                      status: alert.severity,
                      isSeverity: true,
                      label: alert.getSeverityLabel(),
                      isCompact: true,
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AuthTheme.beigeBackground,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        alert.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AuthTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (alert.acknowledged)
                      const Icon(
                        Icons.check_circle_outline,
                        color: AuthTheme.primaryGreen,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AuthTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AuthTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingL),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    if (alert.location != null) ...[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AuthTheme.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          alert.location!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AuthTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AuthTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(alert.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AuthTheme.textHint,
                      ),
                    ),
                  ],
                ),
                if (!alert.acknowledged) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _acknowledgeAlert(alert.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AuthTheme.primaryGreen,
                        side: BorderSide(color: AuthTheme.primaryGreen.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                      ),
                      child: const Text(
                        'ACKNOWLEDGE',
                        style: TextStyle(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  void _showAlertDetails(AlertModel alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AuthTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AuthTheme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: alert.acknowledged 
                                ? AuthTheme.primaryGreen.withValues(alpha: 0.1)
                                : AuthTheme.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            alert.acknowledged ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                            color: alert.acknowledged ? AuthTheme.primaryGreen : AuthTheme.error,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingL),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AuthTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(alert.createdAt),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AuthTheme.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXL),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacingL),

                    // Details
                    _buildDetailRow('Category', alert.category),
                    _buildDetailRow('Severity', alert.getSeverityLabel(), 
                        isBadge: true, severity: alert.severity),
                    _buildDetailRow('Status', alert.status, isBadge: true),
                    if (alert.location != null)
                      _buildDetailRow('Location', alert.location!),
                    
                    const SizedBox(height: AppTheme.spacingL),
                    
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AuthTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      alert.message, // Use message as description if description is null
                      style: const TextStyle(
                        fontSize: 16,
                        color: AuthTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    if (alert.description != null && alert.description != alert.message) ...[
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        alert.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AuthTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],

                    if (!alert.acknowledged) ...[
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _acknowledgeAlert(alert.id);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AuthTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: const Text(
                            'ACKNOWLEDGE ALERT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBadge = false, String? severity}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AuthTheme.textSecondary,
              ),
            ),
          ),
          if (isBadge)
            StatusBadge(
              status: severity ?? value,
              isSeverity: severity != null,
              label: value,
              isCompact: true,
            )
          else
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AuthTheme.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(timestamp);
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      await _alertService.acknowledgeAlert(alertId);

      if (!mounted) return;

      AppToast.show(context, 'Alert successfully acknowledged');

      _loadAlerts();
    } catch (e) {
      if (!mounted) return;

      AppToast.show(context, 'Failed to acknowledge alert: $e', isError: true);
    }
  }
}
