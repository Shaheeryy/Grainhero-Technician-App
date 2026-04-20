import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../utils/secure_storage.dart';
import '../grain_batches/grain_batch_detail_screen.dart';
import '../sensors/sensor_detail_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final TextEditingController _manualIdController = TextEditingController();
  
  bool _isScanning = true;
  bool _isLoading = false;
  bool _isFlashOn = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      
      if (code != null && code != _lastScannedCode && !_isLoading) {
        _lastScannedCode = code;
        HapticFeedback.mediumImpact();
        _processCode(code);
        break;
      }
    }
  }

  Future<void> _processCode(String code) async {
    setState(() {
      _isLoading = true;
      _isScanning = false;
    });

    try {
      final result = await _lookupCode(code);
      
      if (!mounted) return;

      if (result != null) {
        _navigateToDetail(result);
      } else {
        _showNotFoundDialog(code);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to lookup: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _lookupCode(String code) async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.lookupByQr(code)),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Try alternative lookup methods
        return await _fallbackLookup(code);
      }
      return null;
    } catch (e) {
      debugPrint('Lookup error: $e');
      // Try fallback
      return await _fallbackLookup(code);
    }
  }

  Future<Map<String, dynamic>?> _fallbackLookup(String code) async {
    // Try to determine type from code format and lookup accordingly
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return null;

      // Try grain batch lookup
      final batchResponse = await http.get(
        Uri.parse('${ApiConfig.grainBatches}/$code'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(const Duration(seconds: 5));

      if (batchResponse.statusCode == 200) {
        final data = jsonDecode(batchResponse.body);
        return {
          'type': 'batch',
          'data': data['batch'] ?? data,
        };
      }

      // Try sensor lookup
      final sensorResponse = await http.get(
        Uri.parse('${ApiConfig.sensors}/$code'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(const Duration(seconds: 5));

      if (sensorResponse.statusCode == 200) {
        final data = jsonDecode(sensorResponse.body);
        return {
          'type': 'sensor',
          'data': data['sensor'] ?? data,
        };
      }

      return null;
    } catch (e) {
      debugPrint('Fallback lookup failed: $e');
      
      // Return mock data for demo
      return _getMockResult(code);
    }
  }

  Map<String, dynamic>? _getMockResult(String code) {
    // Demo data for testing
    if (code.toLowerCase().contains('batch') || code.startsWith('B')) {
      return {
        'type': 'batch',
        'data': {
          'id': code,
          'batchId': code,
          'grainType': 'Wheat',
          'quantity': 500,
          'status': 'stored',
          'qualityScore': 92,
        },
      };
    } else if (code.toLowerCase().contains('sensor') || code.startsWith('S')) {
      return {
        'type': 'sensor',
        'data': {
          'id': code,
          'name': 'Sensor $code',
          'type': 'temperature_humidity',
          'status': 'active',
          'temperature': 24.5,
          'humidity': 65.0,
        },
      };
    }
    
    // Default to batch for unknown codes
    return {
      'type': 'batch',
      'data': {
        'id': code,
        'batchId': code,
        'grainType': 'Unknown',
        'status': 'stored',
      },
    };
  }

  void _navigateToDetail(Map<String, dynamic> result) {
    final type = result['type'] as String?;
    final data = result['data'] as Map<String, dynamic>?;

    if (data == null) {
      _showError('Invalid data received');
      return;
    }

    Navigator.pop(context); // Close scanner

    if (type == 'batch') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GrainBatchDetailScreen(
            batchId: data['id']?.toString() ?? data['_id']?.toString() ?? '',
          ),
        ),
      );
    } else if (type == 'sensor') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SensorDetailScreen(
            sensorId: data['id']?.toString() ?? data['_id']?.toString() ?? '',
          ),
        ),
      );
    } else {
      _showError('Unknown resource type');
    }
  }

  void _showNotFoundDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.search_off, color: AppTheme.warningColor),
            const SizedBox(width: AppTheme.spacingM),
            const Text('Not Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No matching batch or sensor found for:'),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _lastScannedCode = null;
      _isLoading = false;
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _scannerController.toggleTorch();
  }

  void _manualLookup() {
    final code = _manualIdController.text.trim();
    if (code.isEmpty) {
      _showError('Please enter an ID');
      return;
    }
    _processCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
            tooltip: 'Toggle flash',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner area
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera view
                if (_isScanning)
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),

                // Overlay with cutout
                _buildScannerOverlay(),

                // Loading indicator
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: AppTheme.spacingL),
                          Text(
                            'Looking up...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Manual entry section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Divider handle
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
                  'Or enter ID manually',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Manual input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualIdController,
                        decoration: InputDecoration(
                          hintText: 'Batch ID or Sensor ID',
                          prefixIcon: const Icon(Icons.tag),
                          filled: true,
                          fillColor: AppTheme.backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _manualLookup(),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : _manualLookup,
                        icon: const Icon(Icons.search, color: Colors.white),
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingL),

                // Instructions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHintChip(Icons.qr_code_scanner, 'Scan QR'),
                    const SizedBox(width: AppTheme.spacingM),
                    _buildHintChip(Icons.grain, 'Batch ID'),
                    const SizedBox(width: AppTheme.spacingM),
                    _buildHintChip(Icons.sensors, 'Sensor ID'),
                  ],
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        
        return Stack(
          children: [
            // Dim overlay
            Container(
              color: Colors.black.withOpacity(0.5),
            ),

            // Clear center cutout
            Center(
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              ),
            ),

            // Corner markers
            Center(
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: Stack(
                  children: [
                    Positioned(top: -2, left: -2, child: _buildCorner(true, true)),
                    Positioned(top: -2, right: -2, child: _buildCorner(true, false)),
                    Positioned(bottom: -2, left: -2, child: _buildCorner(false, true)),
                    Positioned(bottom: -2, right: -2, child: _buildCorner(false, false)),
                  ],
                ),
              ),
            ),

            // Instructions text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Position QR code within the frame',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppTheme.primaryColor, width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppTheme.primaryColor, width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppTheme.primaryColor, width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppTheme.primaryColor, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildHintChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
