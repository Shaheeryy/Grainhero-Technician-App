import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:grainhero_technician_app/config/api_config.dart';
import 'package:grainhero_technician_app/config/app_theme.dart';
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
      backgroundColor: AppTheme.backgroundColor,
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : error != null
              ? AppErrorWidget(message: error!, onRetry: _fetchDashboard)
              : RefreshIndicator(
                  onRefresh: _fetchDashboard,
                  color: AppTheme.primaryColor,
                  backgroundColor: AppTheme.surfaceColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildQuickStats(),
                              const SizedBox(height: 24),
                              _buildSilosEnvironment(),
                              const SizedBox(height: 24),
                              if (_recentBatches.isNotEmpty) ...[
                                _buildRecentBatchesSection(),
                                const SizedBox(height: 24),
                              ],
                              if (_alerts.isNotEmpty) ...[
                                _buildAlertsSection(),
                                const SizedBox(height: 24),
                              ],
                              _buildQuickActions(),
                              const SizedBox(height: 100), // Bottom nav spacing
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _techName.isNotEmpty ? _techName[0].toUpperCase() : 'T',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _techName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Technical Panel',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // QR button
          _buildHeaderIcon(
            Icons.qr_code_scanner_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            ),
          ),
          const SizedBox(width: 8),
          // Notification bell
          _buildHeaderIcon(
            Icons.notifications_outlined,
            badge: _alerts.length,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap, int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor, width: 0.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- QUICK STATS ----------
  Widget _buildQuickStats() {
    final siloCount = _realSiloCount;
    final alertCount = _alerts.length;
    final batchCount = _realBatchCount;
    final sensorCount = _sensorSnapshots.length;

    return Row(
      children: [
        _buildStatPill(Icons.domain_rounded, '$siloCount', 'Silos', AppTheme.primaryColor),
        const SizedBox(width: 10),
        _buildStatPill(Icons.warning_amber_rounded, '$alertCount', 'Alerts', AppTheme.warningColor),
        const SizedBox(width: 10),
        _buildStatPill(Icons.inventory_2_rounded, '$batchCount', 'Batches', AppTheme.humidityBlue),
        const SizedBox(width: 10),
        _buildStatPill(Icons.sensors_rounded, '$sensorCount', 'Sensors', AppTheme.co2Purple),
      ],
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- SILOS ENVIRONMENT CAROUSEL ----------
  Widget _buildSilosEnvironment() {
    if (_silos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Silo Environments'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'No silos available',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Silo Environments'),
        const SizedBox(height: 12),
        SizedBox(
          height: 140, // Height for the cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _silos.length,
            itemBuilder: (context, index) {
              final silo = _silos[index] as SiloModel;
              return _buildSiloEnvironmentCard(silo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSiloEnvironmentCard(SiloModel silo) {
    final temp = silo.temperature ?? 0;
    final hum = silo.humidity ?? 0;
    final tvoc = silo.tvoc ?? 0;

    return Container(
      width: 280, // Fixed width for each card
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: silo.status.toLowerCase() == 'active'
                      ? AppTheme.successColor.withOpacity(0.15)
                      : AppTheme.textSecondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  silo.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: silo.status.toLowerCase() == 'active'
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(Icons.thermostat, '${temp.toStringAsFixed(1)}°C', AppTheme.temperatureOrange),
              _buildMiniMetric(Icons.water_drop, '${hum.toStringAsFixed(1)}%', AppTheme.humidityBlue),
              _buildMiniMetric(Icons.air, '${tvoc.toStringAsFixed(0)}ppb', AppTheme.co2Purple),
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
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding from 16
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4), // Reduced spacing
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10, // Reduced font size
                    color: AppTheme.textSecondary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24, // Kept large but wrapped in FittedBox
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- RECENT BATCHES ----------
  Widget _buildRecentBatchesSection() {
    final batches = _recentBatches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Recent Batches'),
        const SizedBox(height: 12),
        ...batches.take(3).map((batch) => _buildBatchCard(batch)),
      ],
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    final risk = (batch['risk'] ?? 'low').toString().toLowerCase();
    final riskColor = AppTheme.getRiskColor(risk);

    return GestureDetector(
      onTap: () {
        final id = batch['id'] ?? batch['_id'];
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => GrainBatchDetailScreen(batchId: id)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch['grain'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${batch['quantity']} kg • ${batch['silo'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withOpacity(0.3), width: 1),
              ),
              child: Text(
                risk.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: riskColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- ALERTS SECTION ----------
  Widget _buildAlertsSection() {
    final alerts = _alerts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Active Alerts'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${alerts.length}',
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Feature the first alert as a prominent action card
        if (alerts.isNotEmpty) _buildAlertActionCard(alerts.first),
        // Show rest as compact cards
        ...alerts.skip(1).take(2).map((a) => _buildCompactAlertCard(a)),
      ],
    );
  }

  Widget _buildAlertActionCard(Map<String, dynamic> alert) {
    final severity = (alert['severity'] ?? 'low').toString().toLowerCase();
    final color = AppTheme.getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['type'] ?? 'Alert',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert['message'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ACKNOWLEDGE button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ACKNOWLEDGE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAlertCard(Map<String, dynamic> alert) {
    final severity = (alert['severity'] ?? 'low').toString().toLowerCase();
    final color = AppTheme.getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert['message'] ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              severity.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- QUICK ACTIONS ----------
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionCard(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan QR',
              color: AppTheme.primaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              ),
            ),
            const SizedBox(width: 10),
            _buildActionCard(
              icon: Icons.notifications_active_rounded,
              label: 'All Alerts',
              color: AppTheme.warningColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor, width: 0.5),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- COMMON ----------
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        letterSpacing: 0.3,
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
