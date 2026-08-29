import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_theme.dart';
import '../../config/grainhero_colors.dart';
import '../../widgets/common/app_toast.dart';
import '../grain_batches/grain_batch_detail_screen.dart';
import '../sensors/sensor_detail_screen.dart';

enum QrScanMode { any, batch, sensor }

@immutable
class QrScanResult {
  const QrScanResult({
    required this.value,
    required this.mode,
    required this.wasEnteredManually,
  });

  final String value;
  final QrScanMode mode;
  final bool wasEnteredManually;
}

enum _ResultAction { useCode, scanAgain }

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.liveCameraEnabled = true});

  /// Test and desktop-preview seam; production routes leave this enabled.
  final bool liveCameraEnabled;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _manualController = TextEditingController();
  final FocusNode _manualFocusNode = FocusNode();
  MobileScannerController? _scannerController;
  late final AnimationController _scanLineController;
  late final AnimationController _modeSlideController;
  late Animation<Offset> _modeSlideAnimation;
  QrScanMode _mode = QrScanMode.any;
  String? _manualError;
  bool _isHandlingCode = false;
  bool _isLoading = false;
  String? _lastScannedCode;
  Future<void> _cameraTransition = Future<void>.value();
  bool _cameraShouldRun = true;
  Timer? _cameraRetryTimer;
  int _cameraStartAttempt = 0;

  bool get _supportsLiveCamera {
    if (!widget.liveCameraEnabled) return false;
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _modeSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _modeSlideAnimation = const AlwaysStoppedAnimation<Offset>(Offset.zero);

    if (_supportsLiveCamera) {
      _scannerController = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
        returnImage: false,
        autoZoom: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_startCameraAfterViewMounted());
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final MobileScannerController? controller = _scannerController;
    if (controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (_mode == QrScanMode.any) {
          unawaited(_startCameraAfterViewMounted());
        }
      case AppLifecycleState.inactive:
        unawaited(_setCameraRunning(false));
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _setCameraRunning(bool shouldRun) {
    _cameraShouldRun = shouldRun;
    if (!shouldRun) {
      _cameraRetryTimer?.cancel();
      _cameraRetryTimer = null;
      _cameraStartAttempt = 0;
    }
    _cameraTransition = _cameraTransition
        .then((_) async {
          final MobileScannerController? controller = _scannerController;
          if (controller == null) return;

          if (_cameraShouldRun && mounted && _mode == QrScanMode.any) {
            if (!controller.value.isRunning && !controller.value.isStarting) {
              await controller.start();
              _cameraStartAttempt = 0;
            }
          } else if (controller.value.isRunning) {
            await controller.stop();
          }
        })
        .catchError((Object _) {
          if (!_cameraShouldRun || !mounted || _mode != QrScanMode.any) {
            return;
          }
          if (_cameraStartAttempt >= 3) return;

          _cameraStartAttempt += 1;
          _cameraRetryTimer?.cancel();
          _cameraRetryTimer = Timer(
            Duration(milliseconds: 220 * _cameraStartAttempt),
            () => unawaited(_startCameraAfterViewMounted(resetAttempts: false)),
          );
        });
    return _cameraTransition;
  }

  Future<void> _startCameraAfterViewMounted({bool resetAttempts = true}) async {
    if (!_supportsLiveCamera || _mode != QrScanMode.any || !mounted) return;
    if (resetAttempts) _cameraStartAttempt = 0;

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || _mode != QrScanMode.any) return;
    await _setCameraRunning(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraRetryTimer?.cancel();
    _scanLineController.dispose();
    _modeSlideController.dispose();
    _manualController.dispose();
    _manualFocusNode.dispose();
    final MobileScannerController? controller = _scannerController;
    _scannerController = null;
    super.dispose();
    if (controller != null) unawaited(controller.dispose());
  }

  Future<void> _toggleTorch() async {
    final MobileScannerController? controller = _scannerController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.toggleTorch();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Flash is not available on this camera.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }
  }

  Future<void> _retryCamera() async {
    if (_mode != QrScanMode.any) return;
    await _startCameraAfterViewMounted();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isHandlingCode || _isLoading) return;
    String? value;
    for (final Barcode barcode in capture.barcodes) {
      final String candidate = barcode.rawValue?.trim() ?? '';
      if (candidate.isNotEmpty && candidate != _lastScannedCode) {
        value = candidate;
        break;
      }
    }
    if (value == null) return;
    _lastScannedCode = value;
    unawaited(_handleCode(value, wasEnteredManually: false));
  }

  Future<void> _submitManualId() async {
    final String value = _manualController.text.trim();
    if (value.isEmpty) {
      final String type = _mode == QrScanMode.batch ? 'batch' : 'sensor';
      setState(() => _manualError = 'Enter a $type ID to continue.');
      _manualFocusNode.requestFocus();
      return;
    }
    if (value.length < 4) {
      setState(() => _manualError = 'Use at least 4 characters.');
      _manualFocusNode.requestFocus();
      return;
    }
    setState(() => _manualError = null);
    _manualFocusNode.unfocus();
    await _handleCode(value, wasEnteredManually: true);
  }

  Future<void> _handleCode(
    String value, {
    required bool wasEnteredManually,
  }) async {
    if (_isHandlingCode) return;
    _isHandlingCode = true;
    unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));

    await _setCameraRunning(false);
    if (!mounted) return;

    final QrScanMode resolvedMode = _resolveMode(value);
    final _ResultAction? action = await showModalBottomSheet<_ResultAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ScanResultSheet(
        value: value,
        mode: resolvedMode,
        wasEnteredManually: wasEnteredManually,
      ),
    );
    if (!mounted) return;

    if (action == _ResultAction.useCode) {
      await _processCode(value);
      return;
    }

    _isHandlingCode = false;
    _lastScannedCode = null;
    if (_scannerController != null && _supportsLiveCamera) {
      await _retryCamera();
    }
  }

  QrScanMode _resolveMode(String value) {
    if (_mode != QrScanMode.any) return _mode;
    final String normalized = value.toUpperCase();
    if (normalized.contains('SENSOR') ||
        normalized.contains('GH-SN') ||
        normalized.startsWith('SN-')) {
      return QrScanMode.sensor;
    }
    if (normalized.contains('BATCH') ||
        normalized.contains('GH-BT') ||
        normalized.startsWith('BT-')) {
      return QrScanMode.batch;
    }
    return QrScanMode.any;
  }

  // ----------------------------------------------------
  // BACKEND LOOKUP & NAVIGATION LOGIC (UNTOUCHED BEHAVIOR)
  // ----------------------------------------------------
  Future<void> _processCode(String rawCode) async {
    setState(() {
      _isLoading = true;
    });

    String codeToLookup = rawCode;
    if (rawCode.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(rawCode);
        if (decoded is Map<String, dynamic>) {
          codeToLookup = decoded['batch_id']?.toString() ??
              decoded['qr_code']?.toString() ??
              decoded['id']?.toString() ??
              rawCode;
        }
      } catch (e) {
        debugPrint('Failed to parse QR JSON: $e');
      }
    }

    try {
      final result = await _lookupCode(codeToLookup);

      if (!mounted) return;

      if (result != null) {
        _navigateToDetail(result);
      } else {
        _showNotFoundDialog(codeToLookup);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to lookup: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isHandlingCode = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _lookupCode(String code) async {
    try {
      final supabase = Supabase.instance.client;

      // Try grain batch lookup by qr_code, batch_id, or id
      try {
        final batch = await supabase
            .from('grain_batches')
            .select('*, silos(id, name, silo_id)')
            .or('qr_code.eq.$code,batch_id.eq.$code,id.eq.$code')
            .limit(1)
            .maybeSingle();

        if (batch != null) {
          return {
            'type': 'batch',
            'data': batch,
          };
        }
      } catch (e) {
        debugPrint('Batch lookup failed: $e');
      }

      // Try sensor lookup by device_id or id
      try {
        final sensor = await supabase
            .from('sensor_devices')
            .select('*')
            .or('device_id.eq.$code,id.eq.$code')
            .limit(1)
            .maybeSingle();

        if (sensor != null) {
          return {
            'type': 'sensor',
            'data': sensor,
          };
        }
      } catch (e) {
        debugPrint('Sensor lookup failed: $e');
      }

      return null;
    } catch (e) {
      debugPrint('Lookup error: $e');
      throw Exception('Failed to lookup code: $e');
    }
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
            batchId: data['id']?.toString() ?? '',
          ),
        ),
      );
    } else if (type == 'sensor') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SensorDetailScreen(
            sensorId: data['id']?.toString() ?? '',
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
        title: const Row(
          children: [
            Icon(Icons.search_off, color: GrainHeroColors.warning),
            SizedBox(width: AppTheme.spacingM),
            Text('Not Found'),
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
                color: GrainHeroColors.tonedEggshell,
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
    AppToast.show(context, message, isError: true);
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _lastScannedCode = null;
      _isLoading = false;
      _isHandlingCode = false;
    });
    if (_mode == QrScanMode.any && _supportsLiveCamera) {
      _retryCamera();
    }
  }

  Future<void> _changeMode(QrScanMode mode) async {
    if (mode == _mode) return;
    final bool movesForward = mode.index > _mode.index;
    _manualFocusNode.unfocus();
    setState(() {
      _mode = mode;
      _manualError = null;
      _manualController.clear();
      _modeSlideAnimation =
          Tween<Offset>(
            begin: Offset(movesForward ? 0.16 : -0.16, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _modeSlideController,
              curve: Curves.easeOutCubic,
            ),
          );
    });
    _modeSlideController.forward(from: 0);

    if (mode == QrScanMode.any) {
      _scanLineController.repeat(reverse: true);
      if (_supportsLiveCamera) await _startCameraAfterViewMounted();
    } else {
      _scanLineController.stop();
      await _setCameraRunning(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrainHeroColors.brandDark,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              _ScannerTopBar(
                controller: _scannerController,
                showTorch: _mode == QrScanMode.any,
                onBack: () => Navigator.of(context).maybePop(),
                onToggleTorch: _toggleTorch,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: SlideTransition(
                    position: _modeSlideAnimation,
                    child: _mode == QrScanMode.any
                        ? KeyedSubtree(
                            key: const ValueKey('qr-camera-mode'),
                            child: _buildCameraStage(),
                          )
                        : _ManualEntryStage(
                            key: ValueKey('qr-manual-${_mode.name}'),
                            controller: _manualController,
                            focusNode: _manualFocusNode,
                            mode: _mode,
                            errorText: _manualError,
                            onChanged: (_) {
                              if (_manualError != null) {
                                setState(() => _manualError = null);
                              }
                            },
                            onSubmitted: _submitManualId,
                          ),
                  ),
                ),
              ),
              _ModeSelectorPanel(
                mode: _mode,
                backgroundColor: _mode == QrScanMode.any
                    ? GrainHeroColors.brandDark
                    : GrainHeroColors.tonedEggshell,
                onModeChanged: _changeMode,
              ),
            ],
          ),
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
    );
  }

  Widget _buildCameraStage() {
    final MobileScannerController? controller = _scannerController;
    return LayoutBuilder(
      builder: (context, constraints) {
        final Rect frame = _scanFrameFor(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_supportsLiveCamera && controller != null)
              MobileScanner(
                controller: controller,
                fit: BoxFit.cover,
                tapToFocus: true,
                onDetect: _onDetect,
                placeholderBuilder: (context) => const _CameraLoadingView(),
                errorBuilder: (context, exception) => _CameraUnavailableView(
                  permissionDenied:
                      exception.errorCode ==
                      MobileScannerErrorCode.permissionDenied,
                  unsupported:
                      exception.errorCode == MobileScannerErrorCode.unsupported,
                  onRetry: _retryCamera,
                ),
              )
            else
              const _DesktopCameraFallback(),
            AnimatedBuilder(
              animation: _scanLineController,
              builder: (context, _) => IgnorePointer(
                child: CustomPaint(
                  painter: _ScannerOverlayPainter(
                    frame: frame,
                    progress: _scanLineController.value,
                  ),
                ),
              ),
            ),
            if (constraints.maxHeight > 210)
              Positioned(
                left: 24,
                right: 24,
                top: math.min(frame.bottom + 18, constraints.maxHeight - 55),
                child: const _PositioningHint(),
              ),
          ],
        );
      },
    );
  }
}

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({
    required this.controller,
    required this.showTorch,
    required this.onBack,
    required this.onToggleTorch,
  });

  final MobileScannerController? controller;
  final bool showTorch;
  final VoidCallback onBack;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(12, topPadding + 6, 16, 20),
      decoration: const BoxDecoration(color: GrainHeroColors.brandDark),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('qr-scanner-back-button'),
            onPressed: onBack,
            tooltip: 'Back',
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Batch and sensor pairing',
                  style: TextStyle(
                    color: GrainHeroColors.onDarkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!showTorch)
            const SizedBox(width: 48)
          else if (controller == null)
            IconButton(
              key: const ValueKey('qr-torch-button'),
              onPressed: null,
              tooltip: 'Flash unavailable',
              color: Colors.white,
              disabledColor: GrainHeroColors.onDarkMuted,
              icon: const Icon(Icons.flash_off_rounded),
            )
          else
            AnimatedBuilder(
              animation: controller!,
              builder: (context, _) {
                final MobileScannerState state = controller!.value;
                final bool isOn = state.torchState == TorchState.on;
                return IconButton(
                  key: const ValueKey('qr-torch-button'),
                  onPressed: state.isInitialized ? onToggleTorch : null,
                  tooltip: isOn ? 'Turn flash off' : 'Turn flash on',
                  style: IconButton.styleFrom(
                    fixedSize: const Size(44, 44),
                    foregroundColor: isOn
                        ? GrainHeroColors.brandDark
                        : Colors.white,
                    disabledForegroundColor: GrainHeroColors.onDarkMuted,
                    backgroundColor: isOn
                        ? GrainHeroColors.primaryBright
                        : Colors.white.withValues(alpha: 0.09),
                    shape: const CircleBorder(),
                  ),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      key: ValueKey(isOn),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ManualEntryStage extends StatelessWidget {
  const _ManualEntryStage({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.mode,
    required this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final QrScanMode mode;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final bool isBatch = mode == QrScanMode.batch;
    final String type = isBatch ? 'Batch' : 'Sensor';
    return ColoredBox(
      color: GrainHeroColors.tonedEggshell,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: GrainHeroColors.primary,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Icon(
                  isBatch ? Icons.inventory_2_rounded : Icons.sensors_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Find a $type',
                style: const TextStyle(
                  color: GrainHeroColors.mainText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the ${type.toLowerCase()} ID exactly as shown on its label.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: GrainHeroColors.mutedText),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('qr-manual-id-field'),
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmitted(),
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLength: 64,
                      style: const TextStyle(
                        color: GrainHeroColors.mainText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: '$type ID',
                        hintText: isBatch ? 'e.g. GH-BT-104' : 'e.g. GH-SN-204',
                        errorText: errorText,
                        errorMaxLines: 2,
                        prefixIcon: const Icon(Icons.tag_rounded),
                        filled: true,
                        fillColor: GrainHeroColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: const BorderSide(
                            color: GrainHeroColors.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: const BorderSide(
                            color: GrainHeroColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    key: const ValueKey('qr-manual-submit-button'),
                    onPressed: onSubmitted,
                    tooltip: 'Find ${type.toLowerCase()}',
                    style: IconButton.styleFrom(
                      fixedSize: const Size(54, 54),
                      backgroundColor: GrainHeroColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelectorPanel extends StatelessWidget {
  const _ModeSelectorPanel({
    required this.mode,
    required this.backgroundColor,
    required this.onModeChanged,
  });

  final QrScanMode mode;
  final Color backgroundColor;
  final ValueChanged<QrScanMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: GrainHeroColors.brandDark),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: _ScanModeSelector(selected: mode, onSelected: onModeChanged),
          ),
        ),
      ),
    );
  }
}

class _ScanModeSelector extends StatelessWidget {
  const _ScanModeSelector({required this.selected, required this.onSelected});

  final QrScanMode selected;
  final ValueChanged<QrScanMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A453C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = constraints.maxWidth / 3;
          return Stack(
            children: [
              AnimatedPositioned(
                key: const ValueKey('qr-mode-sliding-indicator'),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: segmentWidth * selected.index,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: GrainHeroColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: QrScanMode.values
                    .map((mode) {
                      final bool isSelected = selected == mode;
                      return Expanded(
                        child: Semantics(
                          selected: isSelected,
                          button: true,
                          child: InkWell(
                            key: ValueKey('qr-mode-${mode.name}'),
                            onTap: () => onSelected(mode),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _modeIcon(mode),
                                    size: 16,
                                    color: isSelected
                                        ? GrainHeroColors.primary
                                        : GrainHeroColors.onDarkMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _modeLabel(mode),
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: isSelected
                                              ? GrainHeroColors.brandDark
                                              : GrainHeroColors.onDarkMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _modeLabel(QrScanMode mode) => switch (mode) {
    QrScanMode.any => 'Scan QR',
    QrScanMode.batch => 'Batch ID',
    QrScanMode.sensor => 'Sensor ID',
  };

  static IconData _modeIcon(QrScanMode mode) => switch (mode) {
    QrScanMode.any => Icons.qr_code_scanner_rounded,
    QrScanMode.batch => Icons.inventory_2_rounded,
    QrScanMode.sensor => Icons.sensors_rounded,
  };
}

class _CameraLoadingView extends StatelessWidget {
  const _CameraLoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: GrainHeroColors.cameraBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: GrainHeroColors.primaryBright,
                strokeWidth: 2.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Starting camera…',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraUnavailableView extends StatelessWidget {
  const _CameraUnavailableView({
    required this.permissionDenied,
    required this.unsupported,
    required this.onRetry,
  });

  final bool permissionDenied;
  final bool unsupported;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final String title = permissionDenied
        ? 'Camera access needed'
        : unsupported
        ? 'Camera scanning unavailable'
        : 'Camera could not start';
    final String message = permissionDenied
        ? 'Allow camera access, then try again. Manual ID entry remains available.'
        : 'Try the camera again or enter the batch or sensor ID below.';
    return ColoredBox(
      color: GrainHeroColors.cameraBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 285),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  permissionDenied
                      ? Icons.no_photography_rounded
                      : Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('qr-camera-retry-button'),
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopCameraFallback extends StatelessWidget {
  const _DesktopCameraFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GrainHeroColors.cameraBackground,
      child: CustomPaint(
        painter: _CameraTexturePainter(),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.desktop_windows_rounded,
                  color: Colors.white54,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Live scanning is available on mobile and web',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PositioningHint extends StatelessWidget {
  const _PositioningHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: GrainHeroColors.brandDark.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.center_focus_strong_rounded,
              color: GrainHeroColors.primaryBright,
              size: 17,
            ),
            SizedBox(width: 7),
            Flexible(
              child: Text(
                'Position QR code within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({
    required this.value,
    required this.mode,
    required this.wasEnteredManually,
  });

  final String value;
  final QrScanMode mode;
  final bool wasEnteredManually;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        10,
        22,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: GrainHeroColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: GrainHeroColors.outline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: GrainHeroColors.successContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: GrainHeroColors.primaryDark,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              wasEnteredManually ? 'ID ready' : 'QR code found',
              style: const TextStyle(
                color: GrainHeroColors.mainText,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_resultModeLabel(mode)} · ${wasEnteredManually ? 'Manual entry' : 'Camera scan'}',
              style: const TextStyle(
                color: GrainHeroColors.mutedText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GrainHeroColors.tonedEggshell,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: GrainHeroColors.outline),
              ),
              child: SelectableText(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GrainHeroColors.mainText,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('use-scanned-code-button'),
                onPressed: () =>
                    Navigator.of(context).pop(_ResultAction.useCode),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: GrainHeroColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Use this ID'),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('scan-again-button'),
              onPressed: () =>
                  Navigator.of(context).pop(_ResultAction.scanAgain),
              style: TextButton.styleFrom(
                foregroundColor: GrainHeroColors.primaryDark,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(wasEnteredManually ? 'Edit ID' : 'Scan again'),
            ),
          ],
        ),
      ),
    );
  }

  static String _resultModeLabel(QrScanMode mode) => switch (mode) {
    QrScanMode.any => 'Unclassified ID',
    QrScanMode.batch => 'Batch ID',
    QrScanMode.sensor => 'Sensor ID',
  };
}

Rect _scanFrameFor(Size size) {
  final double availableWidth = math.max(120, size.width - 52);
  final double availableHeight = math.max(120, size.height - 112);
  final double side = math.min(300, math.min(availableWidth, availableHeight));
  final double centerY = size.height * 0.44;
  return Rect.fromCenter(
    center: Offset(size.width / 2, centerY),
    width: side,
    height: side,
  );
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({required this.frame, required this.progress});

  final Rect frame;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect frameShape = RRect.fromRectAndRadius(
      frame,
      const Radius.circular(24),
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.53),
    );
    canvas.drawRRect(frameShape, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    canvas.drawRRect(
      frameShape,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final double lineY = frame.top + 18 + (frame.height - 36) * progress;
    final Rect lineRect = Rect.fromLTWH(
      frame.left + 18,
      lineY,
      frame.width - 36,
      2.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Colors.transparent,
            GrainHeroColors.primaryBright,
            GrainHeroColors.primaryBright,
            Colors.transparent,
          ],
        ).createShader(lineRect),
    );

    final Paint cornerPaint = Paint()
      ..color = GrainHeroColors.primaryBright
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const double length = 34;
    const double inset = 2;

    final Path corners = Path()
      ..moveTo(frame.left + inset, frame.top + length)
      ..lineTo(frame.left + inset, frame.top + 12)
      ..quadraticBezierTo(
        frame.left + inset,
        frame.top + inset,
        frame.left + 12,
        frame.top + inset,
      )
      ..lineTo(frame.left + length, frame.top + inset)
      ..moveTo(frame.right - length, frame.top + inset)
      ..lineTo(frame.right - 12, frame.top + inset)
      ..quadraticBezierTo(
        frame.right - inset,
        frame.top + inset,
        frame.right - inset,
        frame.top + 12,
      )
      ..lineTo(frame.right - inset, frame.top + length)
      ..moveTo(frame.right - inset, frame.bottom - length)
      ..lineTo(frame.right - inset, frame.bottom - 12)
      ..quadraticBezierTo(
        frame.right - inset,
        frame.bottom - inset,
        frame.right - 12,
        frame.bottom - inset,
      )
      ..lineTo(frame.right - length, frame.bottom - inset)
      ..moveTo(frame.left + length, frame.bottom - inset)
      ..lineTo(frame.left + 12, frame.bottom - inset)
      ..quadraticBezierTo(
        frame.left + inset,
        frame.bottom - inset,
        frame.left + inset,
        frame.bottom - 12,
      )
      ..lineTo(frame.left + inset, frame.bottom - length);
    canvas.drawPath(corners, cornerPaint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.frame != frame;
}

class _CameraTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    const double spacing = 28;
    for (double y = 14; y < size.height; y += spacing) {
      for (double x = 14; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CameraTexturePainter oldDelegate) => false;
}
