import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/actuator_model.dart';
import '../../services/actuator_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/empty_state_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _loadActuators();
  }

  Future<void> _loadActuators() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await ActuatorService.getActuators();
      if (mounted) setState(() { _actuators = result['actuators'] as List<ActuatorModel>; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${actuator.name} turned ${newState ? "ON" : "OFF"}'),
          backgroundColor: newState ? AppTheme.successColor : AppTheme.textSecondary,
          behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
        ));
        // We do NOT call _loadActuators() here because the backend sends commands via MQTT
        // and doesn't immediately update MongoDB. We rely on the optimistic update above.
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: $msg'), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating,
          ));
        } else {
          // Server didn't return actuator but action succeeded - refresh
          _loadActuators();
        }
      }
    } finally {
      if (mounted) setState(() => _togglingIds.remove(actuator.id));
    }
  }

  Map<String, List<ActuatorModel>> get _grouped {
    final map = <String, List<ActuatorModel>>{};
    for (final a in _actuators) {
      final silo = a.siloName ?? 'Unassigned';
      map.putIfAbsent(silo, () => []).add(a);
    }
    return map;
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor, elevation: 0,
        title: const Text('Actuators', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadActuators)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActuators, color: AppTheme.primaryColor,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : _error != null
                ? AppErrorWidget(message: _error!, onRetry: _loadActuators)
                : _actuators.isEmpty
                    ? EmptyStateWidget(icon: Icons.settings_input_component, title: 'No Actuators', subtitle: 'Actuators will appear here', onRetry: _loadActuators)
                    : _buildGroupedList(),
      ),
    );
  }

  Widget _buildGroupedList() {
    final grouped = _grouped;
    final silos = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      itemCount: silos.length,
      itemBuilder: (context, index) {
        final silo = silos[index];
        final actuators = grouped[silo]!;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Silo header with bulk controls
          Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacingM, top: index > 0 ? AppTheme.spacingXL : 0),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                child: const Icon(Icons.domain, size: 18, color: AppTheme.primaryColor)),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(child: Text(silo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(10)),
                child: Text('${actuators.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary))),
            ]),
          ),

          // Actuator cards
          ...actuators.map((a) => _buildActuatorCard(a)),
        ]);
      },
    );
  }

  Widget _buildActuatorCard(ActuatorModel a) {
    final isToggling = _togglingIds.contains(a.id);
    final accentColor = a.isOn ? AppTheme.successColor : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.cardColor, borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Material(color: Colors.transparent, child: InkWell(
        onTap: () => _showDetailSheet(a),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(padding: const EdgeInsets.all(AppTheme.spacingL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: icon, name, actuator_id, toggle
          Row(children: [
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              child: Icon(a.typeIcon, size: 24, color: accentColor)),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(a.actuatorId, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
            ])),
            if (isToggling)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Switch(value: a.isOn,
                onChanged: a.status != 'offline' && a.status != 'error' && a.isEnabled ? (v) => _toggleActuator(a) : null,
                activeColor: AppTheme.successColor, activeTrackColor: AppTheme.successColor.withOpacity(0.4),
                inactiveThumbColor: AppTheme.textSecondary, inactiveTrackColor: AppTheme.textSecondary.withOpacity(0.3)),
          ]),

          const SizedBox(height: AppTheme.spacingS),

          // Badges row: control mode, triggered by, AI indicator
          Wrap(spacing: 6, runSpacing: 4, children: [
            _modeBadge(a.controlModeLabel, _modeColor(a.controlMode)),
            if (a.currentOperation?.triggeredBy != null)
              _modeBadge('By: ${a.currentOperation!.triggeredBy}', AppTheme.textSecondary),
            if (a.aiControl.enabled) _modeBadge('🤖 AI', const Color(0xFF7C4DFF)),
            if (a.mlDecision != 'idle') _modeBadge('ML: ${a.mlDecision}', const Color(0xFF7C4DFF)),
          ]),

          const SizedBox(height: AppTheme.spacingM),

          // Power level bar + runtime
          Row(children: [
            // Power level
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Power: ${a.powerLevel}%', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: a.powerLevel / 100, backgroundColor: AppTheme.dividerColor,
                  color: accentColor, minHeight: 4)),
            ])),
            const SizedBox(width: 16),
            // Runtime
            if (a.isOn && a.currentOperation?.startedAt != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Runtime', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                Text(a.runtimeDisplay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ]),
          ]),

          const SizedBox(height: AppTheme.spacingS),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingS),

          // Footer: status, operation status, heartbeat
          Row(children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(color: AppTheme.getStatusColor(a.operationStatus), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(a.operationStatus.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.getStatusColor(a.operationStatus))),
            const Spacer(),
            Icon(Icons.access_time, size: 13, color: AppTheme.textHint),
            const SizedBox(width: 4),
            Text(_timeAgo(a.healthMetrics.lastHeartbeat), style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
          ]),
        ])),
      )),
    );
  }

  Widget _modeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Color _modeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'manual': return AppTheme.infoColor;
      case 'ai': case 'automatic': return const Color(0xFF7C4DFF);
      case 'scheduled': return AppTheme.warningColor;
      default: return AppTheme.textSecondary;
    }
  }

  // ============================================
  // DETAIL BOTTOM SHEET
  // ============================================
  void _showDetailSheet(ActuatorModel actuator) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _ActuatorDetailSheet(
        actuator: actuator,
        onToggle: () { Navigator.pop(ctx); _toggleActuator(actuator); },
        onPowerChanged: (level) async {
          Navigator.pop(ctx);
          // Optimistic update
          setState(() {
            final idx = _actuators.indexWhere((a) => a.id == actuator.id);
            if (idx != -1) {
              _actuators[idx] = actuator.copyWith(powerLevel: level, isOn: level > 0);
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
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating));
          }
        },
        onMaintenance: () { Navigator.pop(ctx); _showMaintenanceDialog(actuator); },
      ),
    );
  }

  void _showMaintenanceDialog(ActuatorModel actuator) {
    final notesCtrl = TextEditingController();
    String selectedType = 'filter_replacement';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Text('Maintenance: ${actuator.name}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: selectedType, dropdownColor: AppTheme.cardColor,
          decoration: const InputDecoration(labelText: 'Type', filled: true, fillColor: AppTheme.backgroundColor),
          items: const [
            DropdownMenuItem(value: 'filter_replacement', child: Text('Filter Replacement')),
            DropdownMenuItem(value: 'lubrication', child: Text('Lubrication')),
            DropdownMenuItem(value: 'inspection', child: Text('Inspection')),
            DropdownMenuItem(value: 'repair', child: Text('Repair')),
            DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (v) => setDialogState(() => selectedType = v!),
        ),
        const SizedBox(height: 12),
        TextField(controller: notesCtrl, maxLines: 3, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(hintText: 'Notes...', hintStyle: const TextStyle(color: AppTheme.textHint),
            filled: true, fillColor: AppTheme.backgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (notesCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            try {
              await ActuatorService.logMaintenance(actuator.id, maintenanceType: selectedType, notes: notesCtrl.text.trim());
              if (mounted) {
                // Professional Success UI
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surfaceColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.successColor, size: 60),
                        const SizedBox(height: 16),
                        const Text(
                          'Maintenance Logged',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The maintenance record has been saved and the farm administrator has been notified.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
                _loadActuators();
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          child: const Text('Submit', style: TextStyle(color: Colors.black)),
        ),
      ],
    )));
  }
}

// ============================================
// DETAIL BOTTOM SHEET WIDGET
// ============================================
class _ActuatorDetailSheet extends StatefulWidget {
  final ActuatorModel actuator;
  final VoidCallback onToggle;
  final ValueChanged<int> onPowerChanged;
  final VoidCallback onMaintenance;

  const _ActuatorDetailSheet({required this.actuator, required this.onToggle, required this.onPowerChanged, required this.onMaintenance});

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
    final accentColor = a.isOn ? AppTheme.successColor : AppTheme.textSecondary;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: AppTheme.spacingXL),

          // Header
          Row(children: [
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              child: Icon(a.typeIcon, size: 32, color: accentColor)),
            const SizedBox(width: AppTheme.spacingL),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(a.siloName ?? 'Unknown', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              Text(a.actuatorId, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
            ])),
          ]),

          const SizedBox(height: AppTheme.spacingXL),

          // ON/OFF Toggle Button
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: widget.onToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: a.isOn ? AppTheme.errorColor : AppTheme.successColor,
              padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(a.isOn ? 'TURN OFF' : 'TURN ON', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          )),

          const SizedBox(height: AppTheme.spacingXL),

          // Power Level Slider
          const Text('Power Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Row(children: [
            Expanded(child: Slider(value: _powerSlider, min: 0, max: 100, divisions: 20,
              activeColor: AppTheme.primaryColor,
              label: '${_powerSlider.toInt()}%',
              onChanged: (v) => setState(() => _powerSlider = v))),
            Text('${_powerSlider.toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ]),
          if (_powerSlider.toInt() != a.powerLevel)
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () => widget.onPowerChanged(_powerSlider.toInt()),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryColor)),
              child: const Text('Apply Power Level'),
            )),

          const SizedBox(height: AppTheme.spacingXL), const Divider(), const SizedBox(height: AppTheme.spacingL),

          // Status Info
          _row('Control Mode', a.controlModeLabel),
          if (a.currentOperation?.triggeredBy != null) _row('Triggered By', a.currentOperation!.triggeredBy!),
          if (a.isOn && a.currentOperation?.startedAt != null) _row('Running Since', DateFormat('MMM d, HH:mm').format(a.currentOperation!.startedAt!)),
          if (a.isOn) _row('Runtime', a.runtimeDisplay),
          _row('Operation Status', a.operationStatus.toUpperCase()),

          const SizedBox(height: AppTheme.spacingL), const Divider(), const SizedBox(height: AppTheme.spacingL),

          // AI Control (read-only)
          const Text('AI Control', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          _row('AI Enabled', a.aiControl.enabled ? 'Yes' : 'No'),
          _row('Risk Threshold', '${a.aiControl.riskScoreThreshold.toInt()}%'),
          _row('ML Decision', a.mlDecision),
          _row('ML Requested Fan', a.mlRequestedFan ? 'Yes' : 'No'),
          _row('Human Requested', a.humanRequestedFan ? 'Yes' : 'No'),
          Container(
            margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: AppTheme.warningColor),
              const SizedBox(width: 6),
              Expanded(child: Text('Contact admin to change AI settings', style: TextStyle(fontSize: 11, color: AppTheme.warningColor))),
            ]),
          ),

          const SizedBox(height: AppTheme.spacingL), const Divider(), const SizedBox(height: AppTheme.spacingL),

          // Health & Performance
          const Text('Health & Performance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          _row('Uptime', '${a.healthMetrics.uptimePercentage.toStringAsFixed(1)}%'),
          _row('Total Operations', '${a.healthMetrics.totalOperations}'),
          _row('Total Runtime', '${a.healthMetrics.totalRuntimeHours.toStringAsFixed(1)} hrs'),
          _row('Errors', '${a.healthMetrics.errorCount}'),
          _row('Last Heartbeat', _timeAgo(a.healthMetrics.lastHeartbeat)),

          const SizedBox(height: AppTheme.spacingL), const Divider(), const SizedBox(height: AppTheme.spacingL),

          // Maintenance
          _row('Last Maintenance', a.performanceMetrics.lastMaintenance != null ? DateFormat('MMM d, yyyy').format(a.performanceMetrics.lastMaintenance!) : '--'),
          _row('Next Due', a.performanceMetrics.nextMaintenanceDue != null ? DateFormat('MMM d, yyyy').format(a.performanceMetrics.nextMaintenanceDue!) : '--'),
          _row('Maintenance Status', a.maintenanceStatus.toUpperCase()),

          const SizedBox(height: AppTheme.spacingL),

          // Safety Limits
          _row('Max Runtime', '${a.safetyLimits.maxRuntimeHours} hrs'),
          _row('Cooldown', '${a.safetyLimits.cooldownPeriodMinutes} min'),

          const SizedBox(height: AppTheme.spacingXL),

          // Maintenance Button
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            icon: const Icon(Icons.build_circle_outlined), label: const Text('Log Maintenance'),
            onPressed: widget.onMaintenance,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppTheme.primaryColor)),
          )),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]));
  }
}
