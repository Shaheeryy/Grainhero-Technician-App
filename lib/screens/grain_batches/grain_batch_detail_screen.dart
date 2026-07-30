import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/models/grain_batch_model.dart';
import 'package:grainhero_technician_app/services/grain_batch_service.dart';
import 'package:grainhero_technician_app/widgets/common/error_widget.dart';
import 'package:grainhero_technician_app/widgets/common/status_badge.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GrainBatchDetailScreen extends StatefulWidget {
  final String batchId;
  const GrainBatchDetailScreen({super.key, required this.batchId});

  @override
  State<GrainBatchDetailScreen> createState() => _GrainBatchDetailScreenState();
}

class _GrainBatchDetailScreenState extends State<GrainBatchDetailScreen> {
  final _grainBatchService = GrainBatchService();
  GrainBatch? _batch;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatchDetails();
  }

  Future<void> _loadBatchDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final batch = await _grainBatchService.getGrainBatchById(widget.batchId);
      if (!mounted) return;
      setState(() {
        _batch = batch;
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

  Future<void> _updateStatus(String newStatus) async {
    try {
      final updated = await _grainBatchService.updateGrainBatch(
        widget.batchId,
        status: newStatus,
      );
      if (!mounted) return;
      setState(() {
        _batch = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch status updated successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Batch Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _loading ? null : _loadBatchDetails,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadBatchDetails)
              : _batch == null
                  ? const Center(child: Text('Batch not found'))
                  : DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          Container(
                            color: AppTheme.surfaceColor,
                            child: const TabBar(
                              labelColor: AppTheme.primaryColor,
                              unselectedLabelColor: AppTheme.textSecondary,
                              indicatorColor: AppTheme.primaryColor,
                              tabs: [
                                Tab(text: 'Overview'),
                                Tab(text: 'Details'),
                                Tab(text: 'Timeline'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildOverviewTab(),
                                _buildDetailsTab(),
                                _buildTimelineTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadBatchDetails,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Key Statistics
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Weight',
                    value: '${_batch!.quantityKg.toStringAsFixed(0)} kg',
                    icon: Icons.scale_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Risk Score',
                    value: '${_batch!.riskScore}',
                    icon: Icons.warning_amber_rounded,
                    color: _batch!.riskScore > 50 ? AppTheme.errorColor : AppTheme.successColor,
                    subtitle: _batch!.riskScore > 50 ? 'Needs Attention' : 'Optimal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildDetailSection(
              'Location & Status',
              Icons.location_on_outlined,
              [
                _buildDetailRow(
                  'Current Status',
                  _batch!.status,
                  isStatus: true,
                ),
                if (_batch!.silo != null) ...[
                  _buildDetailRow(
                    'Silo Name',
                    _batch!.silo!.name,
                    icon: Icons.warehouse_outlined,
                  ),
                  _buildDetailRow(
                    'Silo ID',
                    _batch!.silo!.siloId,
                    icon: Icons.qr_code,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          _buildDetailSection(
            'Quality & Specs',
            Icons.verified_outlined,
            [
              if (_batch!.variety != null)
                _buildDetailRow(
                  'Variety',
                  _batch!.variety!,
                  icon: Icons.grass,
                ),
              if (_batch!.grade != null)
                _buildDetailRow(
                  'Grade',
                  _batch!.grade!,
                  icon: Icons.workspace_premium_outlined,
                ),
              if (_batch!.qualityScore != null)
                _buildDetailRow(
                  'Quality Score',
                  '${_batch!.qualityScore}/100',
                  icon: Icons.star_outline_rounded,
                ),
              _buildDetailRow(
                'Spoilage Label',
                _batch!.spoilageLabel,
                icon: Icons.label_outlined,
              ),
              if (_batch!.moistureContent != null)
                _buildDetailRow(
                  'Moisture Content',
                  '${_batch!.moistureContent}%',
                  icon: Icons.water_drop_outlined,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (_batch!.farmerName != null || _batch!.farmerContact != null)
            _buildDetailSection(
              'Farmer Information',
              Icons.person_outline,
              [
                if (_batch!.farmerName != null)
                  _buildDetailRow(
                    'Name',
                    _batch!.farmerName!,
                    icon: Icons.person,
                  ),
                if (_batch!.farmerContact != null)
                  _buildDetailRow(
                    'Contact',
                    _batch!.farmerContact!,
                    icon: Icons.phone_outlined,
                  ),
              ],
            ),
          const SizedBox(height: AppTheme.spacingL),
          if (_batch!.qrCode != null) _buildQrSection(),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          _buildDetailSection(
            'Timeline',
            Icons.access_time_outlined,
            [
              _buildDetailRow(
                'Intake Date',
                _formatDateTime(_batch!.intakeDate),
                icon: Icons.login,
              ),
              if (_batch!.harvestDate != null)
                _buildDetailRow(
                  'Harvest Date',
                  _batch!.harvestDate!,
                  icon: Icons.calendar_today_outlined,
                ),
              _buildDetailRow(
                'Created',
                _formatDateTime(_batch!.createdAt),
                icon: Icons.add_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method for header card remains same...
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
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
                      _batch!.batchId,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _batch!.grainType,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showUpdateStatusSheet,
                child: StatusBadge(status: _batch!.status),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              _buildHeaderStat(
                'Quantity',
                '${_batch!.quantityKg.toStringAsFixed(0)} kg',
              ),
              _buildHeaderStat(
                'Quality',
                '${_batch!.qualityScore ?? "N/A"}',
                color: _batch!.qualityScore != null 
                    ? _getQualityColor(_batch!.qualityScore!) 
                    : null,
              ),
              _buildHeaderStat(
                'Risk',
                '${_batch!.riskScore}%',
                color: _batch!.riskScore > 50 ? AppTheme.errorColor : AppTheme.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Keep other private methods like _buildHeaderStat, _buildDetailSection, _buildDetailRow, etc.
  // which are below this replacement range.

  Widget _buildHeaderStat(String label, String value, {Color? color}) {
    return Expanded(
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
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isStatus
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(status: value, isCompact: true),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingM),
              const Text(
                'QR Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          GestureDetector(
            onTap: () {
               // Copy batch ID to clipboard
               // Clipboard.setData(ClipboardData(text: _batch!.batchId));
               // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch ID copied to clipboard')));
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: _batch!.batchId,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _batch!.batchId,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showUpdateStatusSheet() {
    final statuses = [
      'pending',
      'stored',
      'processing',
      'dispatched',
      'completed',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(bottom: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Update Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final isSelected = _batch!.status == status;
                  return ListTile(
                    leading: isSelected 
                        ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                        : const Icon(Icons.circle_outlined, color: AppTheme.textHint),
                    title: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (!isSelected) _updateStatus(status);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
