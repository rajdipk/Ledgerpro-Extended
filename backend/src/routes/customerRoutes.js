const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');

// Customer registration and license management
router.post('/register', customerController.register);
router.post('/verify-payment', customerController.verifyPayment);
router.post('/verify-license', customerController.verifyLicense);
router.post('/track-download', customerController.trackDownload);

module.exports = router;
