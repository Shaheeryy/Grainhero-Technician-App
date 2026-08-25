import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
import 'package:grainhero_technician_app/config/grainhero_colors.dart';
import 'package:grainhero_technician_app/services/user_service.dart';
import 'package:grainhero_technician_app/services/auth_service.dart';
import 'package:grainhero_technician_app/models/user_model.dart';
import 'package:grainhero_technician_app/widgets/common/error_widget.dart';
import 'package:grainhero_technician_app/widgets/common/app_toast.dart';
import 'package:grainhero_technician_app/services/grain_batch_service.dart';
import 'package:grainhero_technician_app/services/silo_service.dart';
import 'package:grainhero_technician_app/models/silo_model.dart';
import 'package:grainhero_technician_app/services/sensor_service.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../alerts/alerts_screen.dart';
import '../grain_batches/grain_batch_detail_screen.dart';
import 'package:grainhero_technician_app/services/alert_service.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/environment_section.dart';
import 'widgets/active_alerts.dart';
import 'widgets/dashboard_card.dart';

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
  Timer? _refreshTimer;
  final _userService = UserService();
  final _grainBatchService = GrainBatchService();
  final _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboard();
    });
    // Auto-refresh every 30 seconds to pick up latest sensor/alert changes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !loading) _fetchDashboard();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        setState(() {
          loading = false;
          error = 'No active session found. Please login again.';
        });
        return;
      }

      // These four fetches don't depend on each other's results, so run
      // them concurrently instead of one-after-another — each still
      // tolerates its own failure independently, matching the previous
      // sequential behavior, just without waiting for each in turn.
      Future<UserModel?> safeGetProfile() async {
        try {
          return await _userService.getMyProfile();
        } catch (e) {
          debugPrint('Failed to fetch user profile: $e');
          return null;
        }
      }

      Future<Map<String, dynamic>?> safeGetBatches() async {
        try {
          return await _grainBatchService.getGrainBatches(page: 1, limit: 5);
        } catch (e) {
          debugPrint('Failed to fetch real batch count: $e');
          return null;
        }
      }

      Future<List<SiloModel>?> safeGetSilos() async {
        try {
          return await SiloService.getSilos();
        } catch (e) {
          debugPrint('Failed to fetch real silo count: $e');
          return null;
        }
      }

      Future<Map<String, dynamic>?> safeGetDashboard() async {
        try {
          return await SensorService().fetchDashboard();
        } catch (e) {
          debugPrint('Failed to fetch dashboard aggregate: $e');
          return null;
        }
      }

      // Start all four independent fetches before awaiting any of them, so
      // they actually run concurrently instead of one-after-another.
      final userFuture = safeGetProfile();
      final batchResultFuture = safeGetBatches();
      final silosFuture = safeGetSilos();
      final responseDataFuture = safeGetDashboard();
      final user = await userFuture;
      final batchResult = await batchResultFuture;
      final silos = await silosFuture;
      final responseData = await responseDataFuture;

      int? realBatchCount;
      if (batchResult != null) {
        if (batchResult['pagination'] != null && batchResult['pagination']['total_count'] != null) {
          realBatchCount = batchResult['pagination']['total_count'];
        } else {
          realBatchCount = (batchResult['batches'] as List).length;
        }
      }
      final realSiloCount = silos?.length;

      if (!mounted) return;

      try {
        setState(() {
          if (responseData != null) dashboardData = responseData;
          if (silos != null) _silos = silos;
          // Use directly fetched counts
          if (realSiloCount != null) _realSiloCount = realSiloCount;
          if (realBatchCount != null) _realBatchCount = realBatchCount;

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
      
      AppToast.show(context, 'Alert successfully acknowledged');

      // Refresh dashboard to remove the alert
      _fetchDashboard();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Failed to acknowledge: $e', isError: true);
    }
  }

  // ---------- HELPERS ----------
  String get _techName {
    final authService = Provider.of<AuthService>(context, listen: false);
    return userProfile?.name ?? authService.user?.name ?? 'Technician';
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
      backgroundColor: GrainHeroColors.pageBackground,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: GrainHeroColors.primary),
            )
          : error != null
              ? AppErrorWidget(message: error!, onRetry: _fetchDashboard)
              : RefreshIndicator(
                  onRefresh: _fetchDashboard,
                  color: GrainHeroColors.primary,
                  backgroundColor: GrainHeroColors.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        // =====================================================
                        // HEADER
                        // =====================================================
                        DashboardHeader(
                          techName: _techName,
                          alertsCount: _alerts.length,
                          onQrPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                          ),
                          onAlertsPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AlertsScreen()),
                          ).then((_) => _fetchDashboard()),
                          silosCount: _realSiloCount,
                          batchesCount: _realBatchCount,
                          sensorsCount: _sensorSnapshots.length,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // =====================================================
                              // SILO ENVIRONMENTS
                              // =====================================================
                              SiloEnvironmentSection(
                                realSiloCount: _realSiloCount,
                                silos: _silos,
                                onAddNew: () {},
                              ),
                              
                              const SizedBox(height: 28),
                              
                              // =====================================================
                              // ACTIVE ALERTS
                              // =====================================================
                              ActiveAlertsSection(
                                alerts: _alerts,
                                onAcknowledge: _acknowledgeAlert,
                              ),

                              const SizedBox(height: 28),

                              // =====================================================
                              // RECENT BATCHES
                              // =====================================================
                              RecentBatchesSection(
                                recentBatches: _recentBatches,
                                onViewAll: () {},
                              ),
                              
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
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
