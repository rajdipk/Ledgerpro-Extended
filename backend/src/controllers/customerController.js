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
    let customer;
    try {
        console.log('Registration request received:', req.body);
        
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
        customer = new Customer({
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
            console.log('Customer saved successfully:', customer._id);

            try {
                // Attempt to send welcome email
                await emailService.sendWelcomeEmail(customer);
                console.log('Welcome email sent successfully');
            } catch (emailError) {
                console.error('Failed to send welcome email:', emailError);
                // Continue with registration even if email fails
            }

            return res.status(201).json({
                success: true,
                data: {
                    customer: {
                        id: customer._id,
                        businessName: customer.businessName,
                        email: customer.email,
                        licenseKey: customer.license.key
                    },
                    downloadUrl: getDownloadUrl(customer.platform)
                },
                message: 'Registration successful. Please check your email for the license key.'
            });
        } else if (licenseType === 'professional') {
            await customer.save();
            console.log('Customer saved successfully:', customer._id);

            // Create Razorpay order
            const order = await razorpayService.createOrder(customer._id);
            console.log('Razorpay order created:', order.id);

            return res.status(201).json({
                success: true,
                data: {
                    customer: {
                        id: customer._id,
                        businessName: customer.businessName,
                        email: customer.email
                    },
                    paymentConfig: {
                        key: process.env.RAZORPAY_KEY_ID,
                        amount: order.amount,
                        currency: order.currency,
                        name: 'LedgerPro',
                        description: 'Professional License',
                        order_id: order.id,
                        prefill: {
                            name: customer.businessName,
                            email: customer.email,
                            contact: customer.phone
                        }
                    }
                },
                message: 'Please complete the payment to receive your license key.'
            });
        } else {
            // Enterprise license
            await customer.save();
            console.log('Enterprise customer saved successfully:', customer._id);

            try {
                // Attempt to send notification email
                await emailService.sendEnterpriseNotificationEmail(customer);
                console.log('Enterprise notification email sent successfully');
            } catch (emailError) {
                console.error('Failed to send enterprise notification email:', emailError);
            }

            return res.status(201).json({
                success: true,
                data: {
                    customer: {
                        id: customer._id,
                        businessName: customer.businessName,
                        email: customer.email
                    }
                },
                message: 'Thank you for your interest. Our sales team will contact you shortly.'
            });
        }
    } catch (error) {
        console.error('Registration error:', error);
        
        // If customer was created but there was another error, clean up
        if (customer && customer._id) {
            try {
                await Customer.findByIdAndDelete(customer._id);
                console.log('Cleaned up customer record after error:', customer._id);
            } catch (cleanupError) {
                console.error('Failed to clean up customer record:', cleanupError);
            }
        }

        return res.status(400).json({
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

        try {
            // Attempt to send license key email
            await emailService.sendLicenseKeyEmail(customer);
            console.log('License key email sent successfully');
        } catch (emailError) {
            console.error('Failed to send license key email:', emailError);
            // Continue with payment verification even if email fails
        }

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
