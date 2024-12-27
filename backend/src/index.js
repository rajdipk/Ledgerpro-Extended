const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const customerRoutes = require('./routes/customerRoutes');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 10000;

// CORS Configuration
const corsOptions = {
  origin: ['https://rajdipk.github.io', 'http://localhost:3000', 'http://localhost:5000'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  optionsSuccessStatus: 200
};

// Middleware
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} [${req.method}] ${req.url}`);
  next();
});

// Debug route to test basic functionality
app.get('/', (req, res) => {
  res.status(200).json({ message: 'Server is running' });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  console.log('Health check endpoint called');
  res.status(200).json({ 
    status: 'ok',
    message: 'Server is running',
    timestamp: new Date().toISOString(),
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
        console.log(`${Object.keys(handler.route.methods)} ${middleware.regexp} ${handler.route.path}`);
      }
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`${new Date().toISOString()} [ERROR]`, err.stack);
  res.status(500).json({ 
    status: 'error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// 404 handler
app.use((req, res) => {
  console.log(`${new Date().toISOString()} [404] ${req.url}`);
  res.status(404).json({ 
    status: 'error',
    message: 'Route not found'
  });
});

// MongoDB connection with retry logic
const connectWithRetry = () => {
  console.log('Attempting MongoDB connection...');
  mongoose.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
    retryWrites: true,
    w: 'majority'
  })
  .then(() => {
    console.log('Connected to MongoDB');
    // Only start server after successful MongoDB connection
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
    console.log('Retrying connection in 5 seconds...');
    setTimeout(connectWithRetry, 5000);
  });
};

// Initial connection attempt
connectWithRetry();
