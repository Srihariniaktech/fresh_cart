/*
 * ============================================================
 * AUTH MIDDLEWARE - Token Verification
 * ============================================================
 *
 * This middleware runs BEFORE any protected route handler.
 * Its job is to:
 *   1. Extract the Firebase ID token from the request header
 *   2. Verify the token using Firebase Admin SDK
 *   3. If valid, attach user data to the request object
 *   4. If invalid, return 401 Unauthorized error
 *
 * HOW IT WORKS:
 *
 *   Flutter App                              Backend
 *      │                                        │
 *      │  1. User logs in with Firebase        │
 *      │──────────────────────────────────────►│
 *      │                                        │
 *      │  2. Firebase returns ID Token         │
 *      │◄───────────────────────────────────────│
 *      │                                        │
 *      │  3. Flutter sends API request with     │
 *      │     Authorization: Bearer <token>      │
 *      │──────────────────────────────────────►│
 *      │                                        │
 *      │  4. Middleware intercepts request      │
 *      │     and verifies token                 │
 *      │                                        │
 *      │  5. Token valid?                       │
 *      │     YES → Allow request to proceed    │
 *      │     NO  → Return 401 error            │
 *      │                                        │
 *
 * REQUEST FORMAT EXPECTED:
 *
 *   GET /api/auth/session
 *   Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
 *   Content-Type: application/json
 *
 * USAGE IN ROUTES:
 *
 *   const { verifyToken } = require('../middleware/auth');
 *
 *   // This route is protected - token required
 *   router.post('/verify', verifyToken, (req, res) => {
 *     // req.user contains the verified user's data
 *     res.json({ uid: req.user.uid, email: req.user.email });
 *   });
 *
 *   // This route is NOT protected - token optional
 *   router.get('/public-data', (req, res) => {
 *     res.json({ data: 'public' });
 *   });
 */

const admin = require('firebase-admin');

/**
 * STEP 1: Define the verifyToken middleware function
 *
 * This is an async function because token verification
 * involves network calls to Firebase
 *
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function (calls next middleware/route)
 */
const verifyToken = async (req, res, next) => {
  // ============================================================
  // STEP 2: EXTRACT TOKEN FROM AUTHORIZATION HEADER
  // ============================================================
  //
  // The Authorization header format is:
  //   Authorization: Bearer <token>
  //
  // We use .startsWith('Bearer ') to check if header exists
  // and has the correct format
  //
  const authHeader = req.headers.authorization;

  // Check if Authorization header exists
  if (!authHeader) {
    console.log('[Auth] No Authorization header found');
    return res.status(401).json({
      success: false,
      error: 'Missing Authorization header. Include: Authorization: Bearer <token>',
    });
  }

  // Check if it starts with "Bearer " (note the space)
  if (!authHeader.startsWith('Bearer ')) {
    console.log('[Auth] Invalid Authorization format');
    return res.status(401).json({
      success: false,
      error: 'Invalid Authorization format. Use: Bearer <token>',
    });
  }

  // ============================================================
  // STEP 3: EXTRACT THE TOKEN STRING
  // ============================================================
  //
  // Split by "Bearer " and take the second part (the token)
  // "Bearer abc123xyz" → ["Bearer", "abc123xyz"] → "abc123xyz"
  //
  const token = authHeader.split('Bearer ')[1];

  // Extra safety check - ensure token is not empty
  if (!token) {
    console.log('[Auth] Empty token after Bearer');
    return res.status(401).json({
      success: false,
      error: 'No token provided after Bearer',
    });
  }

  // ============================================================
  // STEP 4: VERIFY TOKEN WITH FIREBASE ADMIN SDK
  // ============================================================
  //
  // Firebase Admin SDK method: admin.auth().verifyIdToken(token)
  //
  // This method:
  //   1. Checks if token is properly signed (using Firebase's private key)
  //   2. Checks if token is not expired
  //   3. Checks if token has not been revoked
  //   4. Returns the decoded token payload (user data)
  //
  // If token is invalid, it throws an error with specific codes:
  //   - auth/id-token-expired: Token has expired
  //   - auth/id-token-revoked: Token was revoked
  //   - auth/invalid-id-token: Token is malformed
  //
  try {
    console.log('[Auth] Verifying token with Firebase...');

    // Verify the token - this is an async network call
    const decodedToken = await admin.auth().verifyIdToken(token);

    // ============================================================
    // STEP 5: TOKEN VERIFIED SUCCESSFULLY
    // ============================================================
    //
    // decodedToken contains:
    //   {
    //     uid: "Firebase_UID",
    //     email: "user@example.com",
    //     email_verified: true,
    //     auth_time: 1234567890,
    //     exp: 1234567890,  // Expiration time
    //     iat: 1234567890,  // Issued at time
    //     ...
    //   }
    //
    console.log('[Auth] Token verified for user:', decodedToken.uid);

    // Attach user data to request object
    // This makes user data available in route handlers
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      email_verified: decodedToken.email_verified,
      auth_time: decodedToken.auth_time,
    };

    // Call next() to allow request to proceed to route handler
    next();

  } catch (error) {
    // ============================================================
    // STEP 6: TOKEN VERIFICATION FAILED
    // ============================================================
    //
    // Error handling for various token issues
    //
    console.log('[Auth] Token verification failed:', error.code);

    // Handle specific error codes
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({
        success: false,
        error: 'Token has expired. Please login again.',
        code: 'TOKEN_EXPIRED',
      });
    }

    if (error.code === 'auth/id-token-revoked') {
      return res.status(401).json({
        success: false,
        error: 'Token has been revoked. Please login again.',
        code: 'TOKEN_REVOKED',
      });
    }

    if (error.code === 'auth/invalid-id-token') {
      return res.status(401).json({
        success: false,
        error: 'Token is invalid or malformed.',
        code: 'TOKEN_INVALID',
      });
    }

    // Generic error for any other case
    return res.status(401).json({
      success: false,
      error: 'Invalid authentication token',
      code: 'AUTH_FAILED',
    });
  }
};

// ============================================================
// STEP 7: EXPORT THE MIDDLEWARE
// ============================================================
//
// Export so routes can use this middleware
// Usage in routes: router.post('/endpoint', verifyToken, handler)
//
module.exports = { verifyToken };
