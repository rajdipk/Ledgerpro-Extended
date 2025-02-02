const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');

// Error handler wrapper
const asyncHandler = fn => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// Debug middleware for license endpoints
router.use(['/verify-license', '/deactivate-license'], (req, res, next) => {
    console.log('License endpoint request:', {
        path: req.path,
        body: req.body,
        headers: req.headers,
        method: req.method
    });
    next();
});

// Public routes
router.post('/verify-license', customerController.verifyLicense);
router.post('/register', asyncHandler(customerController.register));
router.post('/activate-license', asyncHandler(customerController.activateLicense));
router.post('/verify-payment', asyncHandler(customerController.verifyPayment));
router.get('/payment-status/:orderId', asyncHandler(customerController.getPaymentStatus));
router.post('/deactivate-license', asyncHandler(customerController.deactivateLicense));

// Razorpay webhook
router.post('/webhook', customerController.handleWebhook);

// Download tracking
router.post('/track-download', customerController.trackDownload);

module.exports = router;
