const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');

// Error handler wrapper
const asyncHandler = fn => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Auth middleware for all admin routes
router.use(adminAuth);

// Protected routes
router.get('/dashboard', asyncHandler(adminController.getDashboard));
router.get('/customers', asyncHandler(adminController.getCustomers));
router.post('/customers', asyncHandler(adminController.createCustomer));
router.post('/update-pricing', asyncHandler(adminController.updatePricing));

module.exports = router;
