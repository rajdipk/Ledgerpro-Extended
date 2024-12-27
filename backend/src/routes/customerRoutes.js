const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');

// Customer registration
router.post('/register', customerController.register);

// Payment verification
router.post('/verify-payment', customerController.verifyPayment);

// Payment status check
router.get('/payment-status/:orderId', customerController.getPaymentStatus);

// Razorpay webhook
router.post('/webhook', customerController.handleWebhook);

// License verification
router.post('/verify-license', customerController.verifyLicense);

// Download tracking
router.post('/track-download', customerController.trackDownload);

module.exports = router;
