const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');

// Error handler wrapper
const asyncHandler = fn => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Debug middleware
router.use((req, res, next) => {
    console.log('Admin route accessed:', {
        path: req.path,
        method: req.method,
        body: req.body,
        headers: req.headers
    });
    next();
});

// Public routes (no auth needed)
router.post('/verify-license', asyncHandler(adminController.verifyLicense));

// Auth middleware for protected routes
router.use((req, res, next) => {
    if (req.path === '/verify-license' && req.method === 'POST') {
        return next();
    }
    adminAuth(req, res, next);
});

// Protected routes
router.get('/dashboard', asyncHandler(adminController.getDashboard));
router.get('/customers', asyncHandler(adminController.getCustomers));
router.post('/customers', asyncHandler(adminController.createCustomer));
router.post('/update-pricing', asyncHandler(adminController.updatePricing));

module.exports = router;
