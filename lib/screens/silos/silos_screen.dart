import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/silo_model.dart';
import '../../services/silo_service.dart';
import '../../widgets/custom_card.dart';
import 'silo_detail_screen.dart';

class SilosScreen extends StatefulWidget {
  const SilosScreen({super.key});

  @override
  State<SilosScreen> createState() => _SilosScreenState();
}

class _SilosScreenState extends State<SilosScreen> {
  List<SiloModel> _silos = [];
  List<SiloModel> _filteredSilos = [];
  bool _isLoading = true;
  String? _error;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All'; // All, Active, Maintenance, Offline

  @override
  void initState() {
    super.initState();
    _loadSilos();
    _searchController.addListener(_filterSilos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSilos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final silos = await SiloService.getSilos();
      if (mounted) {
        setState(() {
          _silos = silos;
          _filteredSilos = silos;
          _isLoading = false;
        });
        _filterSilos();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load silos';
          _isLoading = false;
          debugPrint('Error loading silos: $e');
        });
      }
    }
  }

  void _filterSilos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSilos = _silos.where((silo) {
        final matchesQuery = silo.name.toLowerCase().contains(query) ||
            silo.grainType.toLowerCase().contains(query);
        
        final matchesStatus = _statusFilter == 'All' || 
            silo.status.toLowerCase() == _statusFilter.toLowerCase();
            
        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Silos', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadSilos,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor)))
                    : _filteredSilos.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredSilos.length,
                            itemBuilder: (context, index) {
                              final silo = _filteredSilos[index];
                              return _buildSiloCard(silo);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      color: AppTheme.surfaceColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search Silos...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                dropdownColor: AppTheme.surfaceColor,
                icon: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _statusFilter = value);
                    _filterSilos();
                  }
                },
                items: ['All', 'Active', 'Maintenance', 'Offline'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: AppTheme.textPrimary, 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.domain_disabled_outlined, size: 60, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text('No silos found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSiloCard(SiloModel silo) {
    final fillPercent = silo.fillPercentage;
    final isFull = fillPercent > 0.9;
    final isEmpty = fillPercent < 0.1;
    final statusColor = silo.status.toLowerCase() == 'active' ? AppTheme.successColor : AppTheme.warningColor;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SiloDetailScreen(silo: silo)),
        );
      },
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.domain, color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      silo.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${silo.grainType} • ${silo.capacity.toInt()}kg',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  silo.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(fillPercent * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isFull ? AppTheme.errorColor : isEmpty ? AppTheme.textSecondary : AppTheme.primaryColor,
                      ),
                    ),
                    const Text('Occupancy', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: _buildMetric(Icons.thermostat, '${silo.temperature}°C', 'Temp'),
              ),
              Expanded(
                child: _buildMetric(Icons.water_drop, '${silo.humidity}%', 'Humidity'),
              ),
              Expanded(
                child: _buildMetric(Icons.air, '${silo.tvoc} ppb', 'TVOC'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillPercent,
              backgroundColor: AppTheme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? AppTheme.errorColor : AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ),
            ),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
