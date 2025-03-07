const express = require('express');
const http = require('node:http'); // Use node: prefix for built-in modules
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const mongoose = require('mongoose'); // Add mongoose import
const webSocketService = require('./services/websocketService');

// Import routes
const customerRoutes = require('./routes/customerRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();
const server = http.createServer(app);

// Initialize WebSocket service
webSocketService.initialize(server);
global.webSocketService = webSocketService;

// Initialize prices in global scope
global.prices = {
    professional: 599,
    enterprise: 999
};

// Middleware setup
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS configuration
const corsOptions = {
    origin: ['https://rajdipk.github.io', 'http://localhost:3000'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Accept', 'x-admin-token', 'Authorization'],
    exposedHeaders: ['Content-Length', 'Content-Type'],
    credentials: true,
    maxAge: 86400 // 24 hours
};

app.use(cors(corsOptions));

// Add preflight handlers for specific routes
app.options('/api/admin/*', cors(corsOptions));
app.options('/api/customers/*', cors(corsOptions));

// Add specific handling for admin routes
app.use('/api/admin', (req, res, next) => {
    res.header('Access-Control-Allow-Headers', 'x-admin-token, Content-Type, Accept');
    next();
});

// WebSocket upgrade handling
server.on('upgrade', (request, socket, head) => {
    const origin = request.headers.origin;
    if (corsOptions.origin.includes(origin)) {
        webSocketService.wss.handleUpgrade(request, socket, head, (ws) => {
            webSocketService.wss.emit('connection', ws, request);
        });
    } else {
        socket.destroy();
    }
});

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
    
    // Notify connected clients about errors if needed
    if (err.shouldBroadcast) {
        webSocketService.broadcastMessage({
            type: 'ERROR',
            message: err.message
        });
    }

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

module.exports = { app, server, webSocketService };
