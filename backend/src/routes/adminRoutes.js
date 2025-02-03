const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');

// Debug middleware
router.use((req, res, next) => {
    console.log('Admin request:', {
        path: req.path,
        method: req.method,
        token: req.headers['x-admin-token']
    });
    next();
});

// Auth middleware for all admin routes
router.use(adminAuth);

// Protected routes
router.get('/dashboard', adminController.getDashboard);
router.get('/customers', adminController.getCustomers);
router.post('/customers', adminController.createCustomer);
router.post('/update-pricing', adminController.updatePricing);

module.exports = router;
