import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:grainhero_technician_app/config/api_config.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/config/auth_theme.dart';
import 'package:grainhero_technician_app/widgets/dashboard_widgets.dart';
import 'package:grainhero_technician_app/utils/secure_storage.dart';
import 'package:grainhero_technician_app/services/user_service.dart';
import 'package:grainhero_technician_app/services/auth_service.dart';
import 'package:grainhero_technician_app/models/user_model.dart';
import 'package:grainhero_technician_app/widgets/error_widget.dart';
import 'package:grainhero_technician_app/services/grain_batch_service.dart';
import 'package:grainhero_technician_app/services/silo_service.dart';
import 'package:grainhero_technician_app/models/silo_model.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../alerts/alerts_screen.dart';
import '../grain_batches/grain_batch_detail_screen.dart';
import 'package:grainhero_technician_app/services/alert_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? dashboardData;
  UserModel? userProfile;
  int _realSiloCount = 0;
  int _realBatchCount = 0;
  List<dynamic> _silos = []; // Using dynamic or SiloModel if imported. 
  // Wait, I should import SiloModel or use dynamic. 
  // The file imports SiloService but maybe not SiloModel?
  // Checking imports...
  // Line 13: import 'package:grainhero_technician_app/services/silo_service.dart';
  // SiloService returns List<SiloModel>.
  // I need to import SiloModel? 
  // I'll check imports again in previous view_file (Step 1810).
  // It DOES NOT import silo_model.dart directly.
  // SiloService might export it? Or I should add import.
  // I'll add import if missing.
  // For now, I'll use dynamic or List<dynamic> to be safe or add import.
  // Actually, I'll check imports.
  // Step 1810 lines 1-17:
  // import 'package:grainhero_technician_app/services/silo_service.dart';
  // No silo_model.dart.
  // I will add import in next step. For now adds variable.
  bool loading = true;
  String? error;
  final _userService = UserService();
  final _grainBatchService = GrainBatchService();
  final _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboard();
    });
  }

  Future<void> _fetchDashboard() async {
    try {
      final token = await SecureStorage.getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          loading = false;
          error = 'No authentication token found. Please login again.';
        });
        return;
      }

      UserModel? user;
      try {
        user = await _userService.getMyProfile();
      } catch (e) {
        debugPrint('Failed to fetch user profile: $e');
      }

      int? realBatchCount;
      try {
        // Fetch a few batches to inspect their statuses
        final result = await _grainBatchService.getGrainBatches(page: 1, limit: 5);
        if (result['pagination'] != null && result['pagination']['total_count'] != null) {
          realBatchCount = result['pagination']['total_count'];
        } else {
          realBatchCount = (result['batches'] as List).length;
        }
        
        // DEBUG: Print statuses to finding the correct filter
        final batches = (result['batches'] as List);
        debugPrint('DEBUG: Fetched ${batches.length} batches. Statuses: ${batches.map((b) => b.status).toList()}');
        
      } catch (e) {
        debugPrint('Failed to fetch real batch count: $e');
      }

      int? realSiloCount;
      try {
        final silos = await SiloService.getSilos();
        realSiloCount = silos.length;
          if (mounted) {
            setState(() {
              _silos = silos;
            });
            // DEBUG LOG FOR DATA VERIFICATION
            for (var s in silos) {
              debugPrint('DEBUG SILO DATA: ${s.name} (Status: ${s.status}) -> Temp: ${s.temperature}, Hum: ${s.humidity}, TVOC: ${s.tvoc}');
            }
          }
      } catch (e) {
        debugPrint('Failed to fetch real silo count: $e');
      }

      final dashboardResponse = await http.get(
        Uri.parse(ApiConfig.technicianDashboard),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (!mounted) return;

      if (dashboardResponse.statusCode == 200 || dashboardResponse.statusCode == 201) {
        try {
          final responseData = jsonDecode(dashboardResponse.body);
          debugPrint('Dashboard response keys: ${responseData.keys.toList()}');
          if (responseData['stats'] != null) {
            debugPrint('Dashboard stats: ${responseData['stats']}');
          }
          setState(() {
            dashboardData = responseData;
            // Use directly fetched counts (bypasses unreliable stat title matching)
            if (realSiloCount != null) _realSiloCount = realSiloCount!;
            if (realBatchCount != null) _realBatchCount = realBatchCount!;

            userProfile = user;
            loading = false;
            error = null;
          });
        } catch (e) {
          setState(() {
            loading = false;
            error = 'Error parsing dashboard data: $e';
          });
        }
      } else if (dashboardResponse.statusCode == 401) {
        setState(() {
          loading = false;
          error = 'Session expired. Please login again.';
        });
        await SecureStorage.clearAll();
      } else {
        setState(() {
          loading = false;
          error = 'Failed to load dashboard (Status: ${dashboardResponse.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Connection error: ${e.toString()}';
      });
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      await _alertService.acknowledgeAlert(alertId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Alert successfully acknowledged',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Refresh dashboard to remove the alert
      _fetchDashboard();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to acknowledge: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------- HELPERS ----------
  void _updateStat(String title, int value) {
    if (dashboardData == null || dashboardData!['stats'] == null) return;
    final stats = dashboardData!['stats'] as List<dynamic>;
    for (var i = 0; i < stats.length; i++) {
      if ((stats[i]['title'] ?? '').toString().toLowerCase().contains(title.toLowerCase())) {
        stats[i]['value'] = value;
        return;
      }
    }
    // If not found, add it (optional, but good for robustness)
    // stats.add({'title': title, 'value': value, 'icon': 'default', 'change': 0});
  }

  String get _techName {
    final authService = Provider.of<AuthService>(context, listen: false);
    return userProfile?.name ?? authService.user?.name ?? 'Technician';
  }

  int _getStatValue(String key) {
    if (dashboardData == null || dashboardData!['stats'] == null) return 0;
    final stats = dashboardData!['stats'] as List<dynamic>;
    for (final s in stats) {
      if ((s['title'] ?? '').toString().toLowerCase().contains(key.toLowerCase())) {
        // Handle both "Silos" and "Active Batches" dynamically updated values
        return (s['value'] ?? 0) is int ? s['value'] : (s['value'] as num).toInt();
      }
    }
    return 0;
  }

  List<Map<String, dynamic>> get _sensorSnapshots {
    if (dashboardData == null || dashboardData!['sensors'] == null) return [];
    return List<Map<String, dynamic>>.from(dashboardData!['sensors'] as List);
  }

  List<Map<String, dynamic>> get _alerts {
    if (dashboardData == null || dashboardData!['alerts'] == null) return [];
    return List<Map<String, dynamic>>.from(dashboardData!['alerts'] as List);
  }

  List<Map<String, dynamic>> get _recentBatches {
    if (dashboardData == null || dashboardData!['recentBatches'] == null) return [];
    return List<Map<String, dynamic>>.from(dashboardData!['recentBatches'] as List);
  }


  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.beigeBackground,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AuthTheme.primaryGreen),
            )
          : error != null
              ? AppErrorWidget(message: error!, onRetry: _fetchDashboard)
              : RefreshIndicator(
                  onRefresh: _fetchDashboard,
                  color: AuthTheme.primaryGreen,
                  backgroundColor: AuthTheme.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        _buildDashboardHeader(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: 'Silo Environments',
                                actionLabel: 'ADD NEW',
                                onPressed: () {
                                  // Can implement add new silo
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSilosContent(),
                              
                              const SizedBox(height: 28),
                              
                              if (_alerts.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Active Alerts',
                                        style: TextStyle(
                                          color: AuthTheme.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: AuthTheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${_alerts.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildAlertActionCard(_alerts.first),
                                const SizedBox(height: 28),
                              ],

                              if (_recentBatches.isNotEmpty) ...[
                                SectionHeader(
                                  title: 'Recent Batches',
                                  actionLabel: 'VIEW ALL',
                                  onPressed: () {
                                    // Handle view all batches
                                  },
                                ),
                                const SizedBox(height: 12),
                                ..._recentBatches.take(3).map((batch) => _buildBatchCard(batch)),
                              ],
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDashboardHeader() {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 14, 16, 32),
      decoration: BoxDecoration(
        color: AuthTheme.greenOverlay,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(56)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AuthTheme.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AuthTheme.primaryGreen, width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AuthTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _techName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                ),
                tooltip: 'Scan QR code',
                style: IconButton.styleFrom(
                  fixedSize: const Size(42, 42),
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AlertsScreen()),
                    ).then((_) => _fetchDashboard()),
                    tooltip: 'Notifications',
                    style: IconButton.styleFrom(
                      fixedSize: const Size(42, 42),
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  if (_alerts.isNotEmpty)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AuthTheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AuthTheme.greenOverlay, width: 1.5),
                        ),
                        child: Text(
                          '${_alerts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          StatusOverview(
            silosCount: _realSiloCount,
            alertsCount: _alerts.length,
            batchesCount: _realBatchCount,
            sensorsCount: _sensorSnapshots.length,
          ),
        ],
      ),
    );
  }

  Widget _buildSilosContent() {
    if (_silos.isEmpty) {
      return EmptySiloCard(
        onPressed: () {
          // Action for adding silo
        },
      );
    }

    return SizedBox(
      height: 140, // Height for the cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _silos.length,
        itemBuilder: (context, index) {
          final silo = _silos[index] as SiloModel;
          return _buildSiloEnvironmentCard(silo);
        },
      ),
    );
  }

  Widget _buildSiloEnvironmentCard(SiloModel silo) {
    final temp = silo.temperature ?? 0;
    final hum = silo.humidity ?? 0;
    final tvoc = silo.tvoc ?? 0;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                silo.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AuthTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: silo.status.toLowerCase() == 'active'
                      ? AuthTheme.primaryGreen.withOpacity(0.15)
                      : AuthTheme.greenOverlay.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  silo.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: silo.status.toLowerCase() == 'active'
                        ? AuthTheme.primaryGreen
                        : AuthTheme.greenOverlay,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(Icons.thermostat, '${temp.toStringAsFixed(1)}°C', const Color(0xFFFF5C5C)),
              _buildMiniMetric(Icons.water_drop, '${hum.toStringAsFixed(1)}%', const Color(0xFF4D9FFF)),
              _buildMiniMetric(Icons.air, '${tvoc.toStringAsFixed(0)}ppb', const Color(0xFFA970FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AuthTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertActionCard(Map<String, dynamic> alert) {
    return ActiveAlertCard(
      title: alert['type'] ?? 'Alert',
      description: alert['message'] ?? '',
      onAcknowledge: () {
        final alertId = alert['_id']?.toString();
        if (alertId != null) {
          _acknowledgeAlert(alertId);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlertsScreen()),
          ).then((_) => _fetchDashboard());
        }
      },
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    final risk = (batch['risk'] ?? 'low').toString().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BatchCard(
        grainName: batch['grain'] ?? 'Unknown',
        quantity: '${batch['quantity']} kg',
        siloName: batch['silo'] ?? '',
        riskLevel: risk.toUpperCase(),
        onPressed: () {
          final id = batch['id'] ?? batch['_id'];
          if (id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GrainBatchDetailScreen(batchId: id)),
            );
          }
        },
      ),
    );
  }
}

// ========================================
// SEARCH DELEGATE (kept and themed dark)
// ========================================
class GrainBatchSearchDelegate extends SearchDelegate<String> {
  final GrainBatchService _batchService = GrainBatchService();

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppTheme.backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(
        color: AppTheme.backgroundColor,
        child: const Center(
          child: Text(
            'Enter a batch ID or grain type',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _batchService.getGrainBatches(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final batches = (snapshot.data?['batches'] as List?) ?? [];
          final results = batches.where((batch) {
            final id = batch['batch_id']?.toString().toLowerCase() ?? '';
            final grain = batch['grain_type']?.toString().toLowerCase() ?? '';
            final q = query.toLowerCase();
            return id.contains(q) || grain.contains(q);
          }).toList();

          if (results.isEmpty) {
            return const Center(
              child: Text(
                'No batches found',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final batch = results[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: AppTheme.primaryColor),
                ),
                title: Text(
                  batch['batch_id'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${batch['grain_type']} • ${batch['quantity_kg']} kg',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GrainBatchDetailScreen(
                        batchId: batch['_id'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(color: AppTheme.backgroundColor);
  }
}
