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
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Add request logging before CORS
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} [${req.method}] ${req.url}`);
    console.log('Headers:', req.headers);
    next();
});

// Update CORS options
const corsOptions = {
    origin: '*', // Allow all origins temporarily for testing
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Accept', 'x-admin-token'],
    credentials: false
};

// Apply CORS middleware
app.use(cors(corsOptions));

// Add headers middleware
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Credentials', true);
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, x-admin-token');
    next();
});

// Add better request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} [${req.method}] ${req.path}`, {
        headers: req.headers,
        body: req.body,
        query: req.query
    });
    next();
});

// Add mongoose connection status check middleware
app.use((req, res, next) => {
    if (!mongoose.connection.readyState) {
        return res.status(503).json({
            success: false,
            error: 'Database connection not established'
        });
    }
    next();
});

// Update static file serving
app.use(express.static(path.join(__dirname, '../../docs'), {
    setHeaders: (res, path) => {
        res.set('Access-Control-Allow-Origin', '*');
    }
}));

// Routes
app.use('/api/customers', customerRoutes);
app.use('/api/admin', adminRoutes); // Make sure this comes after CORS

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error occurred:', err);
    res.status(err.status || 500).json({
        success: false,
        error: process.env.NODE_ENV === 'production' 
            ? 'Internal server error' 
            : err.message,
        details: process.env.NODE_ENV === 'development' ? err.stack : undefined
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
const PORT = process.env.PORT || 10000; // Change default port to 10000
server.listen(PORT, () => {
    console.log(`Starting server in ${process.env.NODE_ENV} mode on port ${PORT}`);
});

module.exports = { app, server, wss };
