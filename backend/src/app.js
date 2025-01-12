const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

// Import routes
const customerRoutes = require('./routes/customerRoutes');
const adminRoutes = require('./routes/adminRoutes');
const corsMiddleware = require('./middleware/cors');

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

// Middleware
app.use(helmet());
app.use(corsMiddleware);
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Add request logging middleware
app.use((req, res, next) => {
    console.log(`${req.method} ${req.url}`, {
        body: req.body,
        headers: req.headers
    });
    next();
});

// Serve static files from docs directory
app.use(express.static(path.join(__dirname, '../../docs')));

// API Routes
app.use('/api/customers', customerRoutes);
app.use('/api/admin', adminRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    if (res.headersSent) {
        return next(err);
    }
    res.status(err.status || 500).json({
        success: false,
        error: err.message || 'Something went wrong!'
    });
});

// Handle 404
app.use((req, res) => {
    res.status(404).json({ 
        success: false, 
        error: 'Route not found' 
    });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

module.exports = { app, server, wss };
