const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');

// Error handler wrapper
const asyncHandler = fn => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Debug middleware for license verification
router.use('/verify-license', (req, res, next) => {
    console.log('License verification request:', {
        body: req.body,
        headers: req.headers
    });
    next();
});

// Public routes
router.post('/verify-license', asyncHandler(customerController.verifyLicense));  // Update verify-license endpoint to handle both activation and verification
router.post('/register', asyncHandler(customerController.register));
router.post('/activate-license', asyncHandler(customerController.activateLicense));
router.post('/verify-payment', asyncHandler(customerController.verifyPayment));
router.get('/payment-status/:orderId', asyncHandler(customerController.getPaymentStatus));

// Razorpay webhook
router.post('/webhook', customerController.handleWebhook);

// Download tracking
router.post('/track-download', customerController.trackDownload);

module.exports = router;
