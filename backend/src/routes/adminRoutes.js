const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');
const cors = require('cors');

// Enable CORS for admin routes
const corsOptions = {
    origin: ['http://localhost:3000', 'https://rajdipk.github.io', 'https://ledgerpro-extended.onrender.com'],
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'x-admin-token'],
    credentials: true
};

router.use(cors(corsOptions));

// Add OPTIONS handling for preflight requests
router.options('*', cors(corsOptions));

// Add error handling wrapper
const asyncHandler = fn => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Apply admin auth middleware to all admin routes
router.use(adminAuth);

// Wrap routes with error handler
router.get('/dashboard', asyncHandler(adminController.getDashboard));
router.get('/customers', asyncHandler(adminController.getCustomers));
router.post('/customers', asyncHandler(adminController.createCustomer));
router.post('/update-pricing', asyncHandler(adminController.updatePricing));

// Add health check endpoint
router.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

module.exports = router;
