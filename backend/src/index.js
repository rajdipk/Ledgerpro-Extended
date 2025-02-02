const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const customerRoutes = require('./routes/customerRoutes');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 10000; // Use environment port or default to 10000

console.log('Starting server with configuration:');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('PORT:', PORT);
console.log('MONGODB_URI:', process.env.MONGODB_URI ? 'Set' : 'Not set');

// CORS Configuration
const corsOptions = {
  origin: [
    'https://rajdipk.github.io',
    'http://localhost:3000',
    'http://localhost:5000',
    'http://localhost:10000',
    'https://ledgerpro-extended.onrender.com'
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
  credentials: true,
  optionsSuccessStatus: 200,
  preflightContinue: false,
  maxAge: 86400 // 24 hours
};

// Middleware
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.options('*', cors(corsOptions)); // Enable pre-flight for all routes

// Additional CORS headers for extra security
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', req.headers.origin);
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, Origin, X-Requested-With');
  res.header('Access-Control-Allow-Credentials', 'true');
  next();
});

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} [${req.method}] ${req.url}`);
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);
  next();
});

// Debug route to test basic functionality
app.get('/', (req, res) => {
  res.status(200).json({ 
    message: 'Server is running',
    env: process.env.NODE_ENV,
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  console.log('Health check endpoint called');
  res.status(200).json({ 
    status: 'healthy',
    time: new Date().toISOString(),
    env: process.env.NODE_ENV,
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// Mount API routes
console.log('Mounting customer routes at /api/customers');
app.use('/api/customers', customerRoutes);

// List all registered routes
console.log('Registered routes:');
app._router.stack.forEach(middleware => {
  if (middleware.route) {
    console.log(`${Object.keys(middleware.route.methods)} ${middleware.route.path}`);
  } else if (middleware.name === 'router') {
    middleware.handle.stack.forEach(handler => {
      if (handler.route) {
        const methods = Object.keys(handler.route.methods).join(',');
        const path = handler.route.path;
        console.log(`${methods} ${middleware.regexp} ${path}`);
      }
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`${new Date().toISOString()} [ERROR]`, err.stack);
  res.status(500).json({ 
    status: 'error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  console.log(`${new Date().toISOString()} [404] ${req.url}`);
  res.status(404).json({ 
    status: 'error',
    message: 'Route not found',
    path: req.url,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

// MongoDB connection with retry logic
const connectWithRetry = async () => {
  console.log('Attempting MongoDB connection...');
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      family: 4,
      maxPoolSize: 10,
      minPoolSize: 1,
      maxIdleTimeMS: 30000,
      retryWrites: true,
      w: 'majority'
    });
    
    console.log('Connected to MongoDB');
    
    // Only start server after successful MongoDB connection
    const server = app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
      // Log server address info
      const addr = server.address();
      console.log(`Server listening on ${typeof addr === 'string' ? addr : `${addr.address}:${addr.port}`}`);
    });
  } catch (error) {
    console.error('MongoDB connection error:', error);
    console.log('Retrying connection in 5 seconds...');
    setTimeout(connectWithRetry, 5000);
  }
};

// Initial connection attempt
connectWithRetry();
