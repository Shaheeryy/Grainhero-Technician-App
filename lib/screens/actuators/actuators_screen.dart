import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/actuator_model.dart';
import '../../services/actuator_service.dart';
import '../../widgets/actuator_control_card.dart';

class ActuatorsScreen extends StatefulWidget {
  const ActuatorsScreen({super.key});

  @override
  State<ActuatorsScreen> createState() => _ActuatorsScreenState();
}

class _ActuatorsScreenState extends State<ActuatorsScreen> {
  List<ActuatorModel> _actuators = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedSilo;
  String? _selectedType;
  Set<String> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    _loadActuators();
  }

  Future<void> _loadActuators() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final actuators = await ActuatorService.getActuators(
        siloId: _selectedSilo,
        type: _selectedType,
      );
      
      if (mounted) {
        setState(() {
          _actuators = actuators;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load actuators';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleActuator(ActuatorModel actuator) async {
    if (_togglingIds.contains(actuator.id)) return;

    setState(() {
      _togglingIds.add(actuator.id);
    });

    try {
      final newState = !actuator.isOn;
      final success = await ActuatorService.toggleActuator(actuator.id, newState);
      
      if (success && mounted) {
        setState(() {
          final index = _actuators.indexWhere((a) => a.id == actuator.id);
          if (index != -1) {
            _actuators[index] = actuator.copyWith(
              isOn: newState,
              lastAction: DateTime.now(),
            );
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${actuator.name} turned ${newState ? "ON" : "OFF"}'),
            backgroundColor: newState ? AppTheme.successColor : AppTheme.textSecondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle ${actuator.name}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _togglingIds.remove(actuator.id);
        });
      }
    }
  }

  List<String> get _siloNames {
    final silos = _actuators
        .map((a) => a.siloName)
        .where((s) => s != null)
        .cast<String>()
        .toSet()
        .toList();
    silos.sort();
    return silos;
  }

  List<String> get _actuatorTypes {
    return _actuators.map((a) => a.type).toSet().toList()..sort();
  }

  Map<String, List<ActuatorModel>> get _groupedActuators {
    final grouped = <String, List<ActuatorModel>>{};
    for (final actuator in _actuators) {
      final siloName = actuator.siloName ?? 'Other';
      grouped.putIfAbsent(siloName, () => []).add(actuator);
    }
    return grouped;
  }

  String _formatLastAction(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text(
          'Actuators',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActuators,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActuators,
        color: AppTheme.primaryColor,
        child: Column(
          children: [
            // Filters
            Container(
              color: AppTheme.surfaceColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              child: Row(
                children: [
                  // Silo filter
                  Expanded(
                    child: _buildFilterDropdown(
                      value: _selectedSilo,
                      hint: 'All Silos',
                      items: _siloNames,
                      onChanged: (value) {
                        setState(() => _selectedSilo = value);
                        _loadActuators();
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  // Type filter
                  Expanded(
                    child: _buildFilterDropdown(
                      value: _selectedType,
                      hint: 'All Types',
                      items: _actuatorTypes,
                      onChanged: (value) {
                        setState(() => _selectedType = value);
                        _loadActuators();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint, style: const TextStyle(fontSize: 13)),
            ),
            ...items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton(
              onPressed: _loadActuators,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_actuators.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_input_component,
              size: 64,
              color: AppTheme.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'No actuators found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'Actuators will appear here when available',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupedActuators;

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final siloName = grouped.keys.elementAt(index);
        final actuators = grouped[siloName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Silo header
            Padding(
              padding: EdgeInsets.only(
                bottom: AppTheme.spacingM,
                top: index > 0 ? AppTheme.spacingL : 0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.domain,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Text(
                    siloName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${actuators.length}',
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

            // Actuator cards
            ...actuators.map((actuator) => ActuatorControlCard(
              id: actuator.id,
              name: actuator.name,
              type: actuator.type,
              siloName: null, // Already shown in header
              isOn: actuator.isOn,
              status: actuator.status,
              lastAction: _formatLastAction(actuator.lastAction),
              isLoading: _togglingIds.contains(actuator.id),
              onToggle: (newState) => _toggleActuator(actuator),
              onTap: () => _showActuatorDetails(actuator),
            )),
          ],
        );
      },
    );
  }

  void _showActuatorDetails(ActuatorModel actuator) {
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

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (actuator.isOn ? AppTheme.successColor : AppTheme.textSecondary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    _getActuatorIcon(actuator.type),
                    size: 28,
                    color: actuator.isOn ? AppTheme.successColor : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actuator.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        actuator.siloName ?? 'Unknown Location',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
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
            _buildDetailRow('Type', actuator.typeLabel),
            _buildDetailRow('Status', actuator.statusLabel),
            _buildDetailRow('Current State', actuator.isOn ? 'ON' : 'OFF'),
            if (actuator.lastAction != null)
              _buildDetailRow(
                'Last Action',
                DateFormat('MMM d, yyyy - HH:mm').format(actuator.lastAction!),
              ),
            if (actuator.lastActionBy != null)
              _buildDetailRow('Action By', actuator.lastActionBy!),

            const SizedBox(height: AppTheme.spacingXL),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _togglingIds.contains(actuator.id)
                    ? null
                    : () {
                        Navigator.pop(context);
                        _toggleActuator(actuator);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: actuator.isOn ? AppTheme.errorColor : AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  actuator.isOn ? 'Turn OFF' : 'Turn ON',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Maintenance Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.build_circle_outlined),
                label: const Text('Log Maintenance'),
                onPressed: () {
                  Navigator.pop(context);
                  _showMaintenanceDialog(actuator);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActuatorIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fan':
        return Icons.air;
      case 'lid':
        return Icons.door_sliding_outlined;
      case 'ventilation':
        return Icons.hvac;
      case 'heater':
        return Icons.local_fire_department_outlined;
      case 'cooler':
        return Icons.ac_unit;
      default:
        return Icons.settings_input_component;
    }
  }

  void _showMaintenanceDialog(ActuatorModel actuator) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Maintenance for ${actuator.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter maintenance notes below:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Replaced filter, Lubricated bearings...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (notesController.text.isNotEmpty) {
                Navigator.pop(context);
                final success = await ActuatorService.logMaintenance(actuator.id, notesController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Maintenance logged' : 'Failed to log maintenance'),
                      backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
