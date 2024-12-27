const Customer = require('../models/customer');
const LicenseManager = require('../utils/license');
const emailService = require('../services/emailService');
const razorpayService = require('../services/razorpayService');
const config = require('../config/config');

const licenseManager = new LicenseManager(process.env.LICENSE_KEY_SECRET);

// Helper function to get latest release download URL
const getDownloadUrl = (platform, version = 'latest') => {
    const baseUrl = `https://github.com/rajdipk/LedgerPro/releases/download`;
    const fileName = platform === 'windows' ? 'LedgerPro-Setup.exe' : 'LedgerPro.apk';
    return `${baseUrl}/${version}/${fileName}`;
};

exports.register = async (req, res) => {
    try {
        const {
            businessName,
            email,
            industry,
            platform,
            businessNeeds,
            licenseType,
            phone
        } = req.body;

        // Create customer in database
        const customer = new Customer({
            businessName,
            email,
            phone,
            industry,
            platform,
            businessNeeds,
            license: {
                type: licenseType,
                endDate: licenseManager.calculateExpiryDate(licenseType)
            }
        });

        if (licenseType === 'demo') {
            // Generate license key for demo version
            customer.license.key = licenseManager.generateLicenseKey(customer._id, licenseType);
            await customer.save();

            // Send welcome email with license key
            await emailService.sendWelcomeEmail(customer);

            return res.status(201).json({
                success: true,
                data: {
                    licenseKey: customer.license.key,
                    expiryDate: customer.license.endDate,
                    downloadUrl: getDownloadUrl(customer.platform)
                }
            });
        }

        // For paid licenses, create Razorpay order
        const order = await razorpayService.createOrder(licenseType, customer._id);
        
        // Save customer with pending status
        customer.razorpayCustomerId = order.id;
        await customer.save();

        // Generate payment configuration for frontend
        const paymentConfig = razorpayService.generatePaymentConfig(
            order.id,
            order.amount,
            email,
            phone
        );

        res.status(201).json({
            success: true,
            data: {
                orderId: order.id,
                paymentConfig
            }
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
};

exports.verifyPayment = async (req, res) => {
    try {
        const {
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature
        } = req.body;

        // Verify payment signature
        const isValid = razorpayService.verifyPaymentSignature(
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature
        );

        if (!isValid) {
            throw new Error('Invalid payment signature');
        }

        // Find customer by order ID
        const customer = await Customer.findOne({ razorpayCustomerId: razorpay_order_id });
        if (!customer) throw new Error('Customer not found');

        // Fetch payment details
        const payment = await razorpayService.fetchPaymentById(razorpay_payment_id);
        
        // Verify payment status
        if (payment.status !== 'captured') {
            throw new Error('Payment not captured');
        }

        // Generate and save license key
        customer.license.key = licenseManager.generateLicenseKey(customer._id, customer.license.type);
        customer.license.status = 'active';
        await customer.save();

        // Send license key email
        await emailService.sendLicenseKeyEmail(customer);

        res.json({
            success: true,
            data: {
                licenseKey: customer.license.key,
                expiryDate: customer.license.endDate,
                downloadUrl: getDownloadUrl(customer.platform)
            }
        });

    } catch (error) {
        console.error('Payment verification error:', error);
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
};

exports.verifyLicense = async (req, res) => {
    try {
        const { licenseKey } = req.body;

        const customer = await Customer.findByLicenseKey(licenseKey);
        if (!customer) throw new Error('Invalid license key');

        const isValid = customer.isLicenseValid();
        
        res.json({
            success: true,
            data: {
                isValid,
                licenseType: customer.license.type,
                expiryDate: customer.license.endDate,
                features: licenseManager.getLicenseFeatures(customer.license.type)
            }
        });

    } catch (error) {
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
};

exports.trackDownload = async (req, res) => {
    try {
        const { licenseKey, platform, version } = req.body;

        const customer = await Customer.findByLicenseKey(licenseKey);
        if (!customer) throw new Error('Invalid license key');

        if (!customer.canDownload(platform)) {
            throw new Error('Download not allowed for this platform');
        }

        // Record the download
        customer.downloads.push({ platform, version });
        await customer.save();

        res.json({
            success: true,
            message: 'Download tracked successfully'
        });

    } catch (error) {
        res.status(400).json({
            success: false,
            error: error.message
        });
    }
};
