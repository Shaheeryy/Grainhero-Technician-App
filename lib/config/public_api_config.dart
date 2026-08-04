import 'dart:io' show Platform;

/// Base config for the new TanStack backend's public REST API.
/// Per the backend team: this backend does not use Supabase Edge Functions
/// for app-facing logic — everything goes through `/api/public/v1`.
class PublicApiConfig {
  // ============================================
  // CONFIGURATION: Choose your setup
  // ============================================

  /// Set to TRUE to hit the deployed Lovable backend.
  /// Set to FALSE to hit your local backend dev server (physical device over
  /// USB/WiFi, or an emulator/simulator).
  static const bool useDeployedBackend = false;

  static const String deployedBaseUrl =
      'https://grainheroo.lovable.app/api/public/v1';

  /// Your machine's LAN IP, for testing on a physical device connected via
  /// USB/WiFi against the local backend. Same IP as ApiConfig.physicalDeviceIp
  /// (same dev machine) — update both together if it changes.
  static const String? physicalDeviceIp = '10.10.10.150';

  /// Port your local backend dev server runs on.
  static const int localPort = 8080;

  static String get baseUrl {
    if (useDeployedBackend) return deployedBaseUrl;

    // If a physical device IP is set, use it.
    if (physicalDeviceIp != null && physicalDeviceIp!.isNotEmpty) {
      return 'http://$physicalDeviceIp:$localPort/api/public/v1';
    }

    // Otherwise fall back to emulator/simulator defaults.
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to reach the host machine's localhost.
      return 'http://10.0.2.2:$localPort/api/public/v1';
    }
    return 'http://localhost:$localPort/api/public/v1';
  }

  /// POST — { email, code } -> { data: { valid: true } } or 400 invalid_invitation.
  /// No Authorization header required (called before any session exists).
  static String get validateInvitation => '$baseUrl/auth/validate-invitation';

  /// POST — { email, code } -> { data: { accepted: true } } or 400 invalid_invitation.
  /// Called after supabase.auth.signUp() succeeds, to confirm the email and
  /// consume the invitation code. No Authorization header required.
  static String get acceptInvite => '$baseUrl/auth/accept-invite';
}
