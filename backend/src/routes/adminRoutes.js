const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const auth = require('../middleware/auth');
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

// Protect all admin routes with authentication
router.use(auth.requireAdmin);

router.get('/dashboard', adminController.getDashboard);
router.get('/customers', adminController.getCustomers);
router.post('/customers', adminController.createCustomer);
router.post('/update-pricing', adminController.updatePricing);

module.exports = router;
