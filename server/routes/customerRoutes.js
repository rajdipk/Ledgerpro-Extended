const express = require('express');
const router = express.Router();
const Customer = require('../models/Customer');
const { generateLicenseKey } = require('../utils/licenseUtils');

router.post('/register', async (req, res) => {
    try {
        const {
            businessName,
            email,
            phone,
            industry,
            platform,
            businessNeeds,
            licenseType
        } = req.body;

        // Check if customer already exists
        const existingCustomer = await Customer.findOne({ email });
        if (existingCustomer) {
            return res.status(400).json({
                success: false,
                error: 'Email already registered'
            });
        }

        // Generate license key
        const licenseKey = generateLicenseKey();

        // Create new customer
        const customer = new Customer({
            businessName,
            email,
            phone,
            industry,
            platform,
            businessNeeds,
            licenseType,
            licenseKey,
            status: licenseType === 'demo' ? 'active' : 'pending'
        });

        await customer.save();

        // Prepare response based on license type
        const response = {
            success: true,
            data: {
                customer: {
                    id: customer._id,
                    businessName: customer.businessName,
                    email: customer.email,
                    licenseType: customer.licenseType,
                    licenseKey: customer.licenseKey
                }
            }
        };

        // Add payment config for professional license
        if (licenseType === 'professional') {
            response.data.paymentConfig = {
                // Add Razorpay payment configuration
                // ...payment details...
            };
        }

        res.status(201).json(response);

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            success: false,
            error: 'Registration failed. Please try again.'
        });
    }
});

module.exports = router;
