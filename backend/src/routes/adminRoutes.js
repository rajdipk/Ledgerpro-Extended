const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');

// Add error handling wrapper
const asyncHandler = fn => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Handle CORS preflight requests
router.options('*', (req, res) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-admin-token');
    res.sendStatus(204);
});

// Add request logging
router.use((req, res, next) => {
    console.log('Admin route accessed:', req.method, req.path);
    next();
});

// Routes that don't need auth
router.post('/verify-license', asyncHandler(adminController.verifyLicense));

// Apply auth middleware for protected routes
router.use(adminAuth);

// Protected routes
router.get('/dashboard', asyncHandler(adminController.getDashboard));
router.get('/customers', asyncHandler(adminController.getCustomers));
router.post('/customers', asyncHandler(adminController.createCustomer));
router.post('/update-pricing', asyncHandler(adminController.updatePricing));

// Health check endpoint
router.get('/health', (req, res) => {
    res.json({ 
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV
    });
});

module.exports = router;
