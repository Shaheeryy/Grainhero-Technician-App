import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/auth_theme.dart';
import '../../widgets/silos_widgets.dart';
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
      backgroundColor: AuthTheme.beigeBackground,
      body: Column(
        children: [
          SilosHeader(
            searchController: _searchController,
            selectedFilter: _statusFilter,
            filters: const ['All', 'Active', 'Maintenance', 'Offline'],
            isRefreshing: _isLoading,
            onRefreshPressed: _loadSilos,
            onSearchChanged: (_) {
              _filterSilos();
            },
            onClearSearch: () {
              _searchController.clear();
              _filterSilos();
            },
            onFilterSelected: (filter) {
              setState(() {
                _statusFilter = filter;
              });
              _filterSilos();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              color: AuthTheme.primaryGreen,
              backgroundColor: Colors.white,
              onRefresh: _loadSilos,
              child: _isLoading && _silos.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AuthTheme.primaryGreen))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: AuthTheme.error)))
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                          children: [
                            if (_filteredSilos.isEmpty) ...[
                              SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
                              EmptySilosState(
                                hasSearchOrFilter: _searchController.text.trim().isNotEmpty || _statusFilter != 'All',
                                onClearPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _statusFilter = 'All';
                                  });
                                  _filterSilos();
                                },
                              ),
                            ] else ...[
                              ..._filteredSilos.map((silo) => _buildSiloCard(silo)),
                            ],
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiloCard(SiloModel silo) {
    final fillPercent = silo.fillPercentage;
    final isFull = fillPercent > 0.9;
    final isEmpty = fillPercent < 0.1;
    final statusColor = silo.status.toLowerCase() == 'active' ? AuthTheme.primaryGreen : const Color(0xFFFF5C5C);
    
    final temp = silo.temperature ?? 0;
    final hum = silo.humidity ?? 0;
    final tvoc = silo.tvoc ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthTheme.primaryGreen.withValues(alpha: 0.20), width: 1),
        boxShadow: [
          BoxShadow(
            color: AuthTheme.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SiloDetailScreen(silo: silo)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        silo.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AuthTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${silo.grainType} • ${silo.capacity.toInt()}kg',
                        style: const TextStyle(fontSize: 14, color: AuthTheme.textHint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    silo.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
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
                          color: isFull ? AuthTheme.error : isEmpty ? AuthTheme.textHint : AuthTheme.primaryGreen,
                        ),
                      ),
                      const Text('Occupancy', style: TextStyle(fontSize: 12, color: AuthTheme.textHint)),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildMetric(Icons.thermostat, '${temp.toStringAsFixed(1)}°C', 'Temp', const Color(0xFFFF5C5C)),
                ),
                Expanded(
                  child: _buildMetric(Icons.water_drop, '${hum.toStringAsFixed(1)}%', 'Hum', const Color(0xFF4D9FFF)),
                ),
                Expanded(
                  child: _buildMetric(Icons.air, '${tvoc.toStringAsFixed(0)}ppb', 'TVOC', const Color(0xFFA970FF)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fillPercent,
                backgroundColor: AuthTheme.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFull ? AuthTheme.error : AuthTheme.primaryGreen,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AuthTheme.textPrimary)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AuthTheme.textHint, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
