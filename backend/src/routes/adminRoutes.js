const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');

// Add basic route logging
router.use((req, res, next) => {
    console.log(`Admin route accessed: ${req.method} ${req.path}`);
    next();
});

// Handle OPTIONS requests
router.options('*', (req, res) => {
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-admin-token');
    res.status(204).send();
});

// Apply admin auth middleware (except for OPTIONS requests)
router.use((req, res, next) => {
    if (req.method === 'OPTIONS') {
        return next();
    }
    adminAuth(req, res, next);
});

// Admin routes
router.get('/dashboard', adminController.getDashboard);
router.get('/customers', adminController.getCustomers);
router.post('/customers', adminController.createCustomer);
router.post('/update-pricing', adminController.updatePricing);

// Health check endpoint
router.get('/health', (req, res) => {
    res.json({ 
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV
    });
});

module.exports = router;
