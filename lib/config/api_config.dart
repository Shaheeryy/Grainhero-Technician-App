import 'dart:io';

class ApiConfig {
  // ============================================
  // CONFIGURATION: Choose your setup
  // ============================================
  
  /// Set to TRUE for deployed builds (Firebase App Distribution)
  /// Set to FALSE for local development with USB/WiFi
  static const bool useDeployedBackend = true;

  /// Deployed backend URL (Render)
  static const String deployedBaseUrl = 'https://grainhero.onrender.com';

  /// Local development IP (only used when useDeployedBackend = false)
  static const String? physicalDeviceIp = '192.168.100.160';

  // ============================================
  // BASE URLS (IMPORTANT: Auth uses NO /api prefix!)
  // ============================================

  /// Base URL WITHOUT /api for auth endpoints
  /// Auth routes: /auth/login, /auth/signup, etc.
  static String get authBaseUrl {
    if (useDeployedBackend) {
      return deployedBaseUrl;
    }

    // If physical device IP is set, use it
    if (physicalDeviceIp != null && physicalDeviceIp!.isNotEmpty) {
      return 'http://$physicalDeviceIp:5000';
    }

    // Otherwise use defaults based on platform
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:5000';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost directly
      return 'http://localhost:5000';
    }
    return 'http://localhost:5000';
  }

  /// Base URL WITH /api for other API endpoints
  /// API routes: /api/sensors, /api/grain-batches, etc.
  static String get apiBaseUrl {
    if (useDeployedBackend) {
      return '$deployedBaseUrl/api';
    }

    // If physical device IP is set, use it
    if (physicalDeviceIp != null && physicalDeviceIp!.isNotEmpty) {
      return 'http://$physicalDeviceIp:5000/api'; 
    }

    // Otherwise use defaults based on platform
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  // ============================================
  // AUTH ENDPOINTS (NO /api PREFIX!)
  // ============================================

  /// POST /auth/login
  /// Body: { "email": "string", "password": "string" }
  /// Response: { "token": "string", "id": "string", "role": "string", "name": "string", "email": "string", "phone": "string", "avatar": "string", "hasAccess": "string" }
  static String get login => '$authBaseUrl/auth/login';

  /// POST /auth/signup
  /// Body: { "name": "string", "email": "string", "phone": "string", "password": "string", "confirm_password": "string", "invitation_token": "string" (optional) }
  /// Response: { "token": "string", "id": "string", "role": "string", "name": "string", "email": "string", ... }
  static String get signup => '$authBaseUrl/auth/signup';

  /// POST /auth/forget-password
  /// Body: { "email": "string" }
  /// Response: { "message": "Password reset email sent", "resetLink": "string" }
  static String get forgetPassword => '$authBaseUrl/auth/forget-password';

  /// POST /auth/reset-password
  /// Body: { "token": "string", "newPassword": "string", "confirmPassword": "string" }
  /// Response: { "message": "Password reset successful" }
  static String get resetPassword => '$authBaseUrl/auth/reset-password';

  // Legacy OTP endpoints (if still needed)
  static String get sendOtp => '$authBaseUrl/auth/send-otp';
  static String get verifyOtp => '$authBaseUrl/auth/verify-otp';

  // ============================================
  // TECHNICIAN ENDPOINTS (WITH /api PREFIX)
  // ============================================

  /// GET /auth/me
  /// Get current technician profile
  static String get technicianProfile => '$authBaseUrl/auth/me';

  /// PATCH /auth/me
  /// Update current technician profile (and password if fields provided)
  static String get updateProfileSelf => '$authBaseUrl/auth/me';

  /// GET /dashboard
  /// Get technician dashboard stats
  static String get technicianDashboard => '$authBaseUrl/dashboard';

  // ============================================
  // ALERT ENDPOINTS
  // ============================================

  /// GET /api/alerts?assigned_to=me&limit=50
  /// Get alerts assigned to current technician
  static String get alerts => '$apiBaseUrl/alerts';

  /// PATCH /api/alerts/:id/acknowledge
  /// Acknowledge an alert
  static String acknowledgeAlert(String id) =>
      '$apiBaseUrl/alerts/$id/acknowledge';

  // ============================================
  // SENSOR ENDPOINTS
  // ============================================

  /// GET /api/sensors?limit=100
  /// Get all sensors (tenant-scoped)
  static String get sensors => '$apiBaseUrl/sensors';

  /// GET /api/sensors/:id
  /// Get sensor details
  static String sensorDetails(String id) => '$apiBaseUrl/sensors/$id';

  /// POST /api/sensors/:id/calibrate
  /// Calibrate sensor
  static String sensorCalibrate(String id) => '$apiBaseUrl/sensors/$id/calibrate';

  /// POST /api/sensors/:id/maintenance
  /// Log maintenance for sensor
  static String sensorMaintenance(String id) => '$apiBaseUrl/sensors/$id/maintenance';

  // ============================================
  // SILO ENDPOINTS
  // ============================================

  /// GET /api/silos
  /// Get all silos
  static String get silos => '$apiBaseUrl/silos';

  /// GET /api/silos/:id
  /// Get silodetails
  static String siloDetails(String id) => '$apiBaseUrl/silos/$id';

  /// POST /api/silos/:id/maintenance
  /// Log maintenance for silo
  static String siloMaintenance(String id) => '$apiBaseUrl/silos/$id/maintenance';

  // ============================================
  // GRAIN BATCH ENDPOINTS
  // ============================================

  /// GET /api/grain-batches?limit=50
  /// Get grain batches (tenant-scoped)
  static String get grainBatches => '$apiBaseUrl/grain-batches';

  /// GET /api/grain-batches/:id
  /// Get grain batch details
  static String grainBatchDetails(String id) => '$apiBaseUrl/grain-batches/$id';

  /// PATCH /api/grain-batches/:id
  /// Update grain batch status
  static String updateGrainBatch(String id) => '$apiBaseUrl/grain-batches/$id';

  // ============================================
  // SENSOR READINGS ENDPOINTS
  // ============================================

  /// GET /api/sensors/:id/readings
  /// Get sensor readings
  static String sensorReadings(String id) => '$apiBaseUrl/sensors/$id/readings';

  // ============================================
  // ALERT BY TECHNICIAN ENDPOINT
  // ============================================

  /// GET /api/alerts/by-technician/:userId
  /// Get alerts by technician
  static String alertsByTechnician(String userId) =>
      '$apiBaseUrl/alerts/by-technician/$userId';

  // ============================================
  // USER MANAGEMENT ENDPOINTS
  // ============================================

  /// PUT /api/user-management/users/:id
  /// Update user profile
  static String updateProfile(String id) =>
      '$apiBaseUrl/user-management/users/$id';

  /// PATCH /auth/change-password
  /// Change password (requires Bearer token)
  static String get changePassword => '$authBaseUrl/auth/change-password';

  /// POST /auth/logout
  /// Logout user
  static String get logout => '$authBaseUrl/auth/logout';

  // ============================================
  // ACTUATOR ENDPOINTS
  // ============================================

  /// GET /api/actuators
  /// Get all actuators (filtered by silo, type, status)
  static String get actuators => '$apiBaseUrl/actuators';

  /// POST /api/actuators/:id/control
  /// Control actuator (turn on/off)
  static String actuatorControl(String id) => '$apiBaseUrl/actuators/$id/control';

  /// GET /api/actuators/:id
  /// Get actuator details
  static String actuatorDetails(String id) => '$apiBaseUrl/actuators/$id';

  /// POST /api/actuators/:id/maintenance
  /// Log maintenance for actuator
  static String actuatorMaintenance(String id) => '$apiBaseUrl/actuators/$id/maintenance';

  // ============================================
  // QR / LOOKUP ENDPOINTS
  // ============================================

  /// GET /api/lookup/:code
  /// Lookup resource by QR code or ID
  static String lookupByQr(String code) => '$apiBaseUrl/lookup/$code';

  // ============================================
  // HEADERS HELPER
  // ============================================

  /// Get headers with optional authentication token
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ============================================
  // UPLOAD ENDPOINTS
  // ============================================

  /// POST /auth/upload-profilePic
  /// Upload profile picture
  static String get uploadProfilePic => '$authBaseUrl/auth/upload-profilePic';

  // ============================================
  // DEBUG HELPER
  // ============================================

  /// Print current API configuration (useful for debugging)
  static void printConfig() {
    print('📱 API Configuration:');
    print(
      '   Platform: ${Platform.isAndroid
          ? "Android"
          : Platform.isIOS
          ? "iOS"
          : "Other"}',
    );
    print(
      '   Physical Device IP: ${physicalDeviceIp ?? "Not set (using default)"}',
    );
    print('   Auth Base URL: $authBaseUrl');
    print('   API Base URL: $apiBaseUrl');
    print('   Login URL: $login');
    print('');
  }
}
