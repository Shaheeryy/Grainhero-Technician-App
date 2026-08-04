import 'package:flutter/material.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/models/grain_batch_model.dart';
import 'package:grainhero_technician_app/services/grain_batch_service.dart';
import 'package:grainhero_technician_app/widgets/error_widget.dart';
import 'package:grainhero_technician_app/widgets/empty_state_widget.dart';
import 'package:grainhero_technician_app/widgets/status_badge.dart';
import 'grain_batch_detail_screen.dart';

class GrainBatchesScreen extends StatefulWidget {
  const GrainBatchesScreen({super.key});

  @override
  State<GrainBatchesScreen> createState() => _GrainBatchesScreenState();
}

class _GrainBatchesScreenState extends State<GrainBatchesScreen> {
  final _grainBatchService = GrainBatchService();
  List<GrainBatch> _batches = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasMore = true;
  String? _selectedStatus;
  String? _selectedGrainType;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBatches({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _batches = [];
        _hasMore = true;
      });
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _grainBatchService.getGrainBatches(
        page: _currentPage,
        limit: _limit,
        status: _selectedStatus,
        grainType: _selectedGrainType,
      );

      if (!mounted) return;

      setState(() {
        _batches = refresh
            ? (result['batches'] as List<GrainBatch>)
            : [..._batches, ...(result['batches'] as List<GrainBatch>)];
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
      _loadBatches();
    }
  }

  void _applyFilters() {
    _loadBatches(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Grain Batches',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_selectedStatus != null || _selectedGrainType != null)
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.filter_list,
                color: (_selectedStatus != null || _selectedGrainType != null)
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
                hintText: 'Search batches...',
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
                          _loadBatches(refresh: true);
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
              onSubmitted: (value) => _loadBatches(refresh: true),
            ),
          ),

          // Active filter chips
          if (_selectedStatus != null || _selectedGrainType != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingS,
              ),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedStatus != null)
                    _buildActiveFilterChip(
                      'Status: $_selectedStatus',
                      () {
                        setState(() => _selectedStatus = null);
                        _applyFilters();
                      },
                    ),
                  if (_selectedGrainType != null)
                    _buildActiveFilterChip(
                      'Type: $_selectedGrainType',
                      () {
                        setState(() => _selectedGrainType = null);
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _loading && _batches.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _error != null
                    ? AppErrorWidget(
                        message: _error!,
                        onRetry: () => _loadBatches(refresh: true),
                      )
                    : _batches.isEmpty
                        ? EmptyStateWidget(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Grain Batches',
                            subtitle: 'No batches match your query.',
                            onRetry: () => _loadBatches(refresh: true),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadBatches(refresh: true),
                            color: AppTheme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              itemCount: _batches.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _batches.length) {
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
                                return _buildBatchCard(_batches[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      labelStyle: const TextStyle(color: AppTheme.primaryColor),
      deleteIconColor: AppTheme.primaryColor,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildBatchCard(GrainBatch batch) {
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
                builder: (_) => GrainBatchDetailScreen(batchId: batch.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.batchId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            batch.grainType,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: batch.status, isCompact: true),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.scale_outlined,
                      '${batch.quantityKg.toStringAsFixed(0)} kg',
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    if (batch.silo != null)
                      Expanded(
                        child: _buildInfoItem(
                          Icons.warehouse_outlined,
                          batch.silo!.name,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Intake: ${_formatDate(batch.intakeDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (batch.qualityScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getQualityColor(batch.qualityScore!)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: _getQualityColor(batch.qualityScore!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quality: ${batch.qualityScore}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getQualityColor(batch.qualityScore!),
                              ),
                            ),
                          ],
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

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getQualityColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
              'Filter Batches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            
            // Status Filter
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
                _buildFilterChip('All', null, _selectedStatus, (val) => _selectedStatus = val),
                _buildFilterChip('Pending', 'pending', _selectedStatus, (val) => _selectedStatus = val),
                _buildFilterChip('Stored', 'stored', _selectedStatus, (val) => _selectedStatus = val),
                _buildFilterChip('Processing', 'processing', _selectedStatus, (val) => _selectedStatus = val),
                _buildFilterChip('Dispatched', 'dispatched', _selectedStatus, (val) => _selectedStatus = val),
                _buildFilterChip('Completed', 'completed', _selectedStatus, (val) => _selectedStatus = val),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Grain Type Filter
            const Text(
              'Grain Type',
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
                _buildFilterChip('All', null, _selectedGrainType, (val) => _selectedGrainType = val),
                _buildFilterChip('Wheat', 'Wheat', _selectedGrainType, (val) => _selectedGrainType = val),
                _buildFilterChip('Rice', 'Rice', _selectedGrainType, (val) => _selectedGrainType = val),
                _buildFilterChip('Maize', 'Maize', _selectedGrainType, (val) => _selectedGrainType = val),
                _buildFilterChip('Corn', 'Corn', _selectedGrainType, (val) => _selectedGrainType = val),
                _buildFilterChip('Barley', 'Barley', _selectedGrainType, (val) => _selectedGrainType = val),
                _buildFilterChip('Sorghum', 'Sorghum', _selectedGrainType, (val) => _selectedGrainType = val),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXXL),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedGrainType = null;
                      });
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

  Widget _buildFilterChip(
    String label, 
    String? value, 
    String? currentValue,
    Function(String?) onSelect,
  ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () {
        setState(() => onSelect(value));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
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
