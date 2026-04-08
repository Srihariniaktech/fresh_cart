/*
 * ============================================================
 * API CONFIG - Backend API Configuration
 * ============================================================
 *
 * This file contains the base URL and endpoint paths
 * for connecting Flutter frontend to the backend API.
 *
 * HOW TO SET THE BASE URL:
 *
 *   LOCAL DEVELOPMENT:
 *   -----------------
 *   1. Start backend: cd backend && npm start
 *   2. Backend runs on: http://localhost:3000
 *
 *   Flutter on Android Emulator:
 *   → Use: http://10.0.2.2:3000/api
 *   (Android emulator has a special IP 10.0.2.2 that maps to host localhost)
 *
 *   Flutter on iOS Simulator:
 *   → Use: http://localhost:3000/api
 *
 *   Flutter on Web:
 *   → Use: http://localhost:3000/api
 *   (May need to enable CORS in backend)
 *
 *   REAL DEVICE (same network):
 *   → Use: http://YOUR_COMPUTER_IP:3000/api
 *   (Find IP: ipconfig on Windows, ifconfig on Mac/Linux)
 *
 *   DEPLOYED BACKEND:
 *   -----------------
 *   → Use: https://your-backend-url.railway.app/api
 *   or
 *   → Use: https://us-central1-your-project.cloudfunctions.net/api
 *
 */

class ApiConfig {
  // ============================================================
  // STEP 1: SET YOUR BACKEND BASE URL HERE
  // ============================================================
  //
  // Change this to match your backend server location
  //
  // Local (Android emulator):  http://10.0.2.2:3000
  // Local (iOS simulator):     http://localhost:3000
  // Local (web):                http://localhost:3000
  // Deployed:                   https://your-url.com
  //
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // ============================================================
  // STEP 2: API ENDPOINTS
  // ============================================================
  //
  // These are the specific API routes available
  // Each endpoint is relative to baseUrl
  //
  // Usage in code:
  //   Uri.parse(ApiConfig.verifyToken)
  //   Uri.parse(ApiConfig.session)
  //

  /// POST /api/auth/verify
  /// Verify Firebase token and get user info
  /// Requires: Authorization header with Bearer token
  /// Returns: { success: true, user: { uid, email, ... } }
  static const String verifyToken = '$baseUrl/auth/verify';

  /// POST /api/auth/refresh
  /// Generate custom session token
  /// Requires: Authorization header with Bearer token
  /// Returns: { success: true, customToken: "..." }
  static const String refreshToken = '$baseUrl/auth/refresh';

  /// GET /api/auth/session
  /// Check if session is valid
  /// Requires: Authorization header with Bearer token
  /// Returns: { success: true, session: { uid, email, ... } }
  static const String session = '$baseUrl/auth/session';
}
