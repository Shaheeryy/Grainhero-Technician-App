import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/silo_model.dart';
import '../../models/grain_batch_model.dart';
import '../../services/grain_batch_service.dart';
import '../../widgets/common/custom_card.dart';
import '../actuators/actuators_screen.dart';
import '../sensors/sensors_screen.dart';
import '../grain_batches/grain_batch_detail_screen.dart';

class SiloDetailScreen extends StatefulWidget {
  final SiloModel silo;

  const SiloDetailScreen({super.key, required this.silo});

  @override
  State<SiloDetailScreen> createState() => _SiloDetailScreenState();
}

class _SiloDetailScreenState extends State<SiloDetailScreen> {
  final _batchService = GrainBatchService();
  List<GrainBatch> _batches = [];
  bool _loadingBatches = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      // Query batches for this silo using its UUID
      var result = await _batchService.getGrainBatches(siloId: widget.silo.id, status: 'stored');
      var batches = (result['batches'] as List).cast<GrainBatch>();

      debugPrint('DEBUG: Silo batches statuses: ${batches.map((b) => b.status).toList()}');
      
      debugPrint('Loaded ${batches.length} batches for silo ${widget.silo.name}');
      
      if (mounted) {
        setState(() {
          _batches = batches;
          _loadingBatches = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading batches for silo: $e');
      if (mounted) setState(() => _loadingBatches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('${widget.silo.name} Details', style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surfaceColor,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
            const SizedBox(height: 20),
            _buildSectionTitle('Current Conditions'),
            const SizedBox(height: 10),
            _buildConditionsGrid(),
            const SizedBox(height: 20),
            _buildSectionTitle('Active Batches'),
            const SizedBox(height: 10),
            _buildBatchesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final statusColor = widget.silo.status.toLowerCase() == 'active' ? AppTheme.successColor : AppTheme.warningColor;
    return CustomCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.silo.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Capacity', '${widget.silo.capacity.toInt()} kg'),
              _buildStatItem('Occupancy', '${widget.silo.currentLevel.toInt()} kg'),
              _buildStatItem('Fill Level', '${(widget.silo.fillPercentage * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.silo.fillPercentage,
              backgroundColor: AppTheme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.silo.fillPercentage > 0.9 ? AppTheme.errorColor : AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sensors),
                label: const Text('Sensors'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardColor,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SensorsScreen()));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings_input_component),
                label: const Text('Actuators'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardColor,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ActuatorsScreen()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildConditionCard(Icons.thermostat, '${widget.silo.temperature}°C', 'Temperature', Colors.orange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildConditionCard(Icons.water_drop, '${widget.silo.humidity}%', 'Humidity', Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildConditionCard(Icons.air, '${widget.silo.tvoc} ppb', 'TVOC', Colors.green),
        ),
      ],
    );
  }

  Widget _buildConditionCard(IconData icon, String value, String label, Color color) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBatchesList() {
    if (_loadingBatches) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_batches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor, width: 0.5),
        ),
        child: const Center(child: Text('No active batches in this silo', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return Column(
      children: _batches.map((batch) => _buildBatchCard(batch)).toList(),
    );
  }

  Widget _buildBatchCard(GrainBatch batch) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => GrainBatchDetailScreen(batchId: batch.id)));
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor),
        ),
        title: Text(batch.batchId, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        subtitle: Text('${batch.grainType} • ${batch.quantityKg} kg', style: const TextStyle(color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
    );
  }

}
