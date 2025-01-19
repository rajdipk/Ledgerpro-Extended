const Customer = require('../models/customer');
const razorpayService = require('../services/razorpayService');

exports.getDashboard = async (req, res) => {
    try {
        const customerCount = await Customer.countDocuments();
        const activeCustomers = await Customer.countDocuments({ 'license.status': 'active' });
        const paidCustomers = await Customer.countDocuments({ 'license.type': 'professional' });
        
        const pricing = {
            professional: razorpayService.prices.professional,
            enterprise: razorpayService.prices.enterprise
        };

        res.json({
            success: true,
            data: {
                stats: {
                    total: customerCount,
                    active: activeCustomers,
                    paid: paidCustomers
                },
                pricing
            }
        });
    } catch (error) {
        console.error('Admin dashboard error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getCustomers = async (req, res) => {
    try {
        console.log('Getting customers list, auth token:', req.headers['x-admin-token']);
        
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        console.log('Query parameters:', { page, limit, skip });

        const customers = await Customer.find()
            .select('businessName email license.type license.status license.key license.endDate createdAt')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await Customer.countDocuments();

        console.log('Found customers:', {
            count: customers.length,
            total,
            pages: Math.ceil(total / limit)
        });

        res.json({
            success: true,
            data: {
                customers,
                pagination: {
                    total,
                    pages: Math.ceil(total / limit),
                    current: page,
                    limit
                }
            }
        });
    } catch (error) {
        console.error('Get customers error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.updatePricing = async (req, res) => {
    try {
        const { professional, enterprise } = req.body;
        
        if (typeof professional !== 'number' || professional < 0) {
            throw new Error('Invalid professional price');
        }

        if (typeof enterprise !== 'number' || enterprise < 0) {
            throw new Error('Invalid enterprise price');
        }

        razorpayService.updatePricing(professional, enterprise);
        
        // Broadcast price update to all connected clients
        if (global.wss) {
            const priceUpdate = {
                type: 'PRICE_UPDATE',
                data: { professional, enterprise }
            };
            global.wss.clients.forEach(client => {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(JSON.stringify(priceUpdate));
                }
            });
        }

        res.json({
            success: true,
            message: 'Pricing updated successfully',
            data: { professional, enterprise }
        });
    } catch (error) {
        console.error('Update pricing error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.createCustomer = async (req, res) => {
    try {
        console.log('Creating customer with data:', req.body);

        const {
            businessName,
            email,
            phone,
            industry,
            platform,
            licenseType
        } = req.body;

        // Enhanced validation
        const validationErrors = [];
        if (!businessName?.trim()) validationErrors.push('Business name is required');
        if (!email?.trim()) validationErrors.push('Email is required');
        if (!phone?.trim()) validationErrors.push('Phone is required');
        if (!['retail', 'manufacturing', 'services', 'other'].includes(industry)) {
            validationErrors.push('Invalid industry');
        }
        if (!['windows', 'android'].includes(platform)) {
            validationErrors.push('Invalid platform');
        }
        if (!['demo', 'professional', 'enterprise'].includes(licenseType)) {
            validationErrors.push('Invalid license type');
        }

        if (validationErrors.length > 0) {
            return res.status(400).json({
                success: false,
                error: 'Validation failed',
                validationErrors
            });
        }

        // Check if email exists
        const existingCustomer = await Customer.findOne({ email: email.toLowerCase() });
        if (existingCustomer) {
            return res.status(400).json({
                success: false,
                error: 'Email already registered'
            });
        }

        // Create new customer with proper license settings
        const customer = new Customer({
            businessName: businessName.trim(),
            email: email.toLowerCase().trim(),
            phone: phone.trim(),
            industry,
            platform,
            license: {
                type: licenseType,
                status: licenseType === 'demo' ? 'active' : 'pending',
                key: licenseType === 'demo' ? require('../utils/license').generateLicenseKey() : null,
                endDate: licenseType === 'demo' ? 
                    new Date(Date.now() + (30 * 24 * 60 * 60 * 1000)) : // 30 days for demo
                    null
            }
        });

        await customer.save();
        console.log('Customer created successfully:', customer);

        res.status(201).json({
            success: true,
            message: 'Customer created successfully',
            data: customer
        });
    } catch (error) {
        console.error('Create customer error:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'Failed to create customer'
        });
    }
};
