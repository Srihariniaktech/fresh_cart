/*
 * ============================================================
 * AUTH ROUTES - API Endpoints for Authentication
 * ============================================================
 *
 * These routes handle authentication-related API calls.
 * They are prefixed with /api/auth in index.js
 *
 * AVAILABLE ENDPOINTS:
 *
 *   POST /api/auth/verify
 *     → Verify Firebase token and get user info
 *     → Requires: Authorization header with Bearer token
 *     ← Returns: { success: true, user: { uid, email, ... } }
 *
 *   POST /api/auth/refresh
 *     → Generate a new custom token for backend session
 *     → Requires: Authorization header with Bearer token
 *     ← Returns: { success: true, customToken: "..." }
 *
 *   GET /api/auth/session
 *     → Check if current session/token is valid
 *     → Requires: Authorization header with Bearer token
 *     ← Returns: { success: true, session: { uid, email, ... } }
 *
 * HOW ROUTES ARE LOADED:
 *
 *   In index.js:
 *   const authRoutes = require('./routes/auth');
 *   app.use('/api/auth', authRoutes);
 *
 *   This means:
 *   './routes/auth' → '/api/auth'
 *   './routes/auth' + '/verify' → '/api/auth/verify'
 *
 * REQUEST/RESPONSE FLOW:
 *
 *   Flutter App                                          Backend
 *      │                                                    │
 *      │  POST /api/auth/verify                            │
 *      │  Authorization: Bearer <firebase_id_token>      │
 *      │  Content-Type: application/json                   │
 *      │─────────────────────────────────────────────────►│
 *      │                                                    │
 *      │  1. Middleware verifies Firebase token           │
 *      │                                                    │
 *      │  2. Route handler runs (after middleware passes)│
 *      │                                                    │
 *      │  3. Use admin.auth().getUser(uid) to get        │
 *      │     additional user details from Firebase        │
 *      │                                                    │
 *      │  4. Return user data to Flutter                 │
 *      │◄─────────────────────────────────────────────────│
 *      │  { success: true, user: { uid, email, ... } }   │
 *
 * PROTECTED vs PUBLIC ROUTES:
 *
 *   Protected (require token):
 *     - /api/auth/verify    ← needs verifyToken middleware
 *     - /api/auth/refresh  ← needs verifyToken middleware
 *     - /api/auth/session  ← needs verifyToken middleware
 *
 *   Public (no token needed):
 *     - (none in this file currently)
 *
 */

const express = require('express');

// Create a new router instance
// Router is like a mini-app that handles specific routes
const router = express.Router();

// Import the verifyToken middleware
// This protects routes that need authentication
const { verifyToken } = require('../middleware/auth');


// ============================================================
// ROUTE 1: POST /api/auth/verify
// ============================================================
//
// PURPOSE:
//   Primary endpoint for Flutter app to verify that a user
//   has successfully logged in with Firebase
//
// WHAT IT DOES:
//   1. Receives the Firebase ID token from Flutter
//   2. (Already verified by middleware) Gets the user's UID
//   3. Fetches full user profile from Firebase Admin SDK
//   4. Returns user data to Flutter
//
// FLUTTER SIDE:
//   After Firebase login, Flutter calls this endpoint to:
//   - Confirm login was successful on backend
//   - Get additional user info (displayName, photoURL)
//   - Establish backend session
//
// REQUEST:
//   POST /api/auth/verify
//   Authorization: Bearer <firebase_id_token>
//   Body: (empty or {})
//
// RESPONSE:
//   Success (200):
//     {
//       "success": true,
//       "user": {
//         "uid": "abc123xyz",
//         "email": "user@example.com",
//         "displayName": "John Doe",
//         "photoURL": "https://...",
//         "emailVerified": true,
//         "createdAt": "2024-01-15T10:30:00.000Z"
//       }
//     }
//
//   Error (401):
//     { "success": false, "error": "Invalid token" }
//
router.post('/verify', verifyToken, async (req, res) => {
  // At this point, verifyToken middleware has already:
  // - Verified the Firebase ID token
  // - Attached decoded user data to req.user
  // - Called next() to allow execution to reach here

  try {
    // Get Firebase Admin instance (set in index.js)
    const admin = req.app.get('admin');

    // Fetch full user record from Firebase Auth
    // admin.auth().getUser(uid) returns UserRecord object
    // This contains more details than the token payload
    const user = await admin.auth().getUser(req.user.uid);

    // ============================================================
    // SEND SUCCESS RESPONSE TO FLUTTER
    // ============================================================
    res.json({
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName || null,
        photoURL: user.photoURL || null,
        emailVerified: user.emailVerified,
        createdAt: user.metadata.creationTime,
      },
    });

    console.log(`[Auth] User verified: ${user.email}`);

  } catch (error) {
    // If fetching user fails, return error
    console.error('[Auth] Error fetching user:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user data from Firebase',
    });
  }
});


// ============================================================
// ROUTE 2: POST /api/auth/refresh
// ============================================================
//
// PURPOSE:
//   Generate a custom backend session token
//   This is useful if you want to:
//   - Track sessions in your own database
//   - Implement additional auth logic
//   - Create a separate backend-only authentication
//
// WHAT IT DOES:
//   1. Verifies the Firebase ID token (via middleware)
//   2. Creates a custom token using Firebase Admin
//   3. Returns the custom token to Flutter
//
// CUSTOM TOKEN vs ID TOKEN:
//
//   Firebase ID Token:
//     - Generated by Firebase when user logs in
//     - Short-lived (1 hour expiration)
//     - Contains basic user info
//     - Standard JWT, verifiable by any server
//
//   Custom Token:
//     - Generated by YOUR backend using Admin SDK
//     - Used for your own session management
//     - Can contain additional custom claims
//     - Useful for linking Firebase to your own DB
//
// REQUEST:
//   POST /api/auth/refresh
//   Authorization: Bearer <firebase_id_token>
//
// RESPONSE:
//   Success (200):
//     {
//       "success": true,
//       "customToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6...",
//       "expiresIn": 3600
//     }
//
router.post('/refresh', verifyToken, async (req, res) => {
  try {
    const admin = req.app.get('admin');

    // Create custom token using Firebase Admin SDK
    // This token can be used for your own auth system
    // We pass req.user.uid so it contains the user's Firebase UID
    const customToken = await admin.auth().createCustomToken(req.user.uid);

    // Return custom token to Flutter
    res.json({
      success: true,
      customToken: customToken,
      expiresIn: 3600, // Token expires in 1 hour (3600 seconds)
    });

    console.log(`[Auth] Custom token created for: ${req.user.uid}`);

  } catch (error) {
    console.error('[Auth] Error creating custom token:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to create custom token',
    });
  }
});


// ============================================================
// ROUTE 3: GET /api/auth/session
// ============================================================
//
// PURPOSE:
//   Check if the user's current session is still valid
//   Flutter can call this periodically to verify still logged in
//
// WHAT IT DOES:
//   1. Verifies the Firebase ID token (via middleware)
//   2. Returns basic session info from the token
//
// USE CASES:
//   - Before making sensitive API calls
//   - On app resume (when user comes back to app)
//   - Periodic session validation
//
// REQUEST:
//   GET /api/auth/session
//   Authorization: Bearer <firebase_id_token>
//
// RESPONSE:
//   Success (200):
//     {
//       "success": true,
//       "session": {
//         "uid": "abc123xyz",
//         "email": "user@example.com",
//         "isEmailVerified": true
//       }
//     }
//
router.get('/session', verifyToken, (req, res) => {
  // At this point, req.user contains verified token data
  // We return the session information

  res.json({
    success: true,
    session: {
      uid: req.user.uid,
      email: req.user.email,
      isEmailVerified: req.user.email_verified,
    },
  });
});


// ============================================================
// EXPORT THE ROUTER
// ============================================================
//
// Export the router so it can be used in index.js
// The router will be mounted at /api/auth
//
module.exports = router;
