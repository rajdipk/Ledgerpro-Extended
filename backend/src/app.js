const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const mongoose = require('mongoose'); // Add mongoose import

// Import routes
const customerRoutes = require('./routes/customerRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
const server = http.createServer(app);

// Initialize WebSocket server
const wss = new WebSocket.Server({ server });

// Store WebSocket instance globally
global.wss = wss;

// WebSocket connection handling
wss.on('connection', (ws) => {
    console.log('New WebSocket client connected');
    ws.on('error', console.error);
});

// Middleware setup
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS configuration
const corsOptions = {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-admin-token'],
    credentials: false
};

app.use(cors(corsOptions));

// Debug middleware to log all requests
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} [${req.method}] ${req.path}`);
    console.log('Headers:', req.headers);
    console.log('Body:', req.body);
    next();
});

// Register routes
app.use('/api/admin', adminRoutes);
app.use('/api/customers', customerRoutes);

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        success: false,
        error: err.message || 'Internal server error'
    });
});

// Catch-all handler for 404s
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Route not found',
        path: req.path,
        method: req.method
    });
});

// Start server
const PORT = process.env.PORT || 10000; // Change default port to 10000
server.listen(PORT, () => {
    console.log(`Starting server in ${process.env.NODE_ENV} mode on port ${PORT}`);
});

module.exports = { app, server, wss };
