const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const auth = require('../middleware/auth');

// Protect all admin routes with authentication
router.use(auth.requireAdmin);

router.get('/dashboard', adminController.getDashboard);
router.get('/customers', adminController.getCustomers);
router.post('/customers', adminController.createCustomer); // Add this line
router.post('/update-pricing', adminController.updatePricing);

module.exports = router;
