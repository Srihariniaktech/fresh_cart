/*
 * ============================================================
 * FRESHCART BACKEND - MAIN SERVER FILE
 * ============================================================
 *
 * This is the entry point of the backend API server.
 * Every step is explained in comments below.
 *
 * FLOW:
 *   1. Load environment variables (.env file)
 *   2. Import required libraries (express, cors, firebase-admin)
 *   3. Initialize Firebase Admin SDK with service account
 *   4. Set up Express middleware (CORS, JSON parser)
 *   5. Define API routes
 *   6. Start the server
 *
 * HOW TO RUN:
 *   cd backend
 *   npm install        # Install all dependencies
 *   npm start          # Start the server (runs on port 3000)
 */

// ============================================================
// STEP 1: REQUIRE ENVIRONMENT VARIABLES
// ============================================================
// dotenv loads variables from .env file
// This keeps sensitive config out of code
// .env file contains: PORT=3000, NODE_ENV=development
require('dotenv').config();

// ============================================================
// STEP 2: REQUIRE LIBRARIES
// ============================================================
const express = require('express');       // Web framework for API
const cors = require('cors');             // Cross-origin resource sharing
const admin = require('firebase-admin'); // Firebase Admin SDK for backend

// ============================================================
// STEP 3: IMPORT ROUTES AND MIDDLEWARE
// ============================================================
// Routes handle specific API endpoints
// Middleware functions run before reaching the route handler
const authRoutes = require('./routes/auth');

// ============================================================
// STEP 4: INITIALIZE FIREBASE ADMIN SDK
// ============================================================
//
// BEFORE RUNNING:
// You must download service-account.json from Firebase Console:
//   1. Go to https://console.firebase.google.com
//   2. Select your project
//   3. Project Settings → Service Accounts
//   4. Click "Generate new private key"
//   5. Save as: backend/config/service-account.json
//
// The service account contains:
//   - project_id: Your Firebase project ID
//   - private_key: Secret key to verify tokens
//   - client_email: Service account email
//
// Firebase Admin SDK allows backend to:
//   - Verify Firebase ID tokens (JWT)
//   - Access Firestore database
//   - Access Firebase Auth user data
//   - Send notifications
//
const serviceAccount = require('../config/service-account.json');

// Initialize Firebase Admin with service account credentials
// This gives the backend permission to verify tokens
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// ============================================================
// STEP 5: CREATE EXPRESS APP
// ============================================================
const app = express();

// ============================================================
// STEP 6: SET UP MIDDLEWARE
// ============================================================
//
// MIDDLEWARE = Code that runs between request and response
// They process incoming requests before they reach routes
//

// CORS Middleware
// -------------
// CORS = Cross-Origin Resource Sharing
// This allows your Flutter app (running on different port/origin)
// to make requests to this backend API
//
// Without CORS, browser would block requests from different origins
// For development: allows all origins
// For production: specify allowed origins
app.use(cors({
  origin: '*', // Allow all origins (change to your Flutter app URL in production)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'], // Allowed HTTP methods
  allowedHeaders: ['Content-Type', 'Authorization'], // Allowed headers
}));

// JSON Parser Middleware
// ----------------------
// Express needs to read JSON data from incoming requests
// This middleware parses JSON body and makes it available in req.body
app.use(express.json());

// ============================================================
// STEP 7: MAKE FIREBASE ADMIN AVAILABLE TO ROUTES
// ============================================================
//
// We store admin instance in app.set so routes can access it
// This avoids importing firebase-admin in every route file
//
app.set('admin', admin);

// ============================================================
// STEP 8: DEFINE API ROUTES
// ============================================================
//
// ROUTE = An endpoint URL that handles specific requests
// Format: app.METHOD('path', handler_function)
//
// Methods:
//   GET  - Retrieve data
//   POST - Create new data
//   PUT  - Update data
//   DELETE - Remove data
//

// Health check route
// This tests if server is running
// Access: GET http://localhost:3000/health
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'FreshCart API is running',
    timestamp: new Date().toISOString(),
  });
});

// Auth routes - handles login verification
// All auth routes start with /api/auth
//   - POST /api/auth/verify   - Verify Firebase token
//   - POST /api/auth/refresh  - Refresh session
//   - GET  /api/auth/session  - Check session validity
app.use('/api/auth', authRoutes);

// ============================================================
// STEP 9: ERROR HANDLING MIDDLEWARE
// ============================================================
//
// This catches any errors thrown in route handlers
// Always keep this at the end, after all routes
//
app.use((err, req, res, next) => {
  console.error('=== SERVER ERROR ===');
  console.error('Message:', err.message);
  console.error('Stack:', err.stack);
  console.error('====================');

  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Internal Server Error',
  });
});

// ============================================================
// STEP 10: START THE SERVER
// ============================================================
//
// Get port from environment variable, default to 3000
// NODE_ENV=production when deployed
// NODE_ENV=development when running locally
//
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log('╔═══════════════════════════════════════════════════╗');
  console.log('║         FRESHCART API SERVER STARTED                 ║');
  console.log('╠═══════════════════════════════════════════════════╣');
  console.log(`║  Local:   http://localhost:${PORT}                      ║`);
  console.log(`║  Health:  http://localhost:${PORT}/health                ║`);
  console.log(`║  Auth:    http://localhost:${PORT}/api/auth              ║`);
  console.log('╠═══════════════════════════════════════════════════╣');
  console.log('║  Waiting for incoming requests...                   ║');
  console.log('╚═══════════════════════════════════════════════════╝');
});
