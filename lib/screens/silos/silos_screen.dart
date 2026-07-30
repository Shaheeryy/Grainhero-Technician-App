import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/auth_theme.dart';
import '../../widgets/silos/silos_widgets.dart';
import '../../models/silo_model.dart';
import '../../services/silo_service.dart';
import '../../widgets/common/custom_card.dart';
import 'silo_detail_screen.dart';
import 'widgets/silo_card.dart';

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
          // =====================================================
          // HEADER (SEARCH & FILTERS)
          // =====================================================
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
          
          // =====================================================
          // SILO LIST
          // =====================================================
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
                              ..._filteredSilos.map((silo) => SiloCard(silo: silo)),
                            ],
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }


}
