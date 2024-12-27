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

        console.log('Registration request:', { email, businessName, phone });

        // Check if email exists
        const existingCustomer = await Customer.findOne({ email: email.toLowerCase() });
        console.log('Existing customer check:', existingCustomer);

        if (existingCustomer) {
            return res.status(400).json({
                success: false,
                error: 'This email is already registered. Please use a different email address or contact support.'
            });
        }

        // Create customer in database
        const customer = new Customer({
            businessName,
            email: email.toLowerCase(),
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

            // Save order ID to customer
            customer.razorpayOrderId = order.id;
            await customer.save();

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
        res.status(500).json({
            success: false,
            error: error.message || 'Registration failed. Please try again.'
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

        console.log('Payment verification request:', { razorpay_order_id, razorpay_payment_id, razorpay_signature });

        // Verify payment signature
        const isValid = razorpayService.verifyPaymentSignature(
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature
        );

        console.log('Signature verification result:', isValid);

        if (!isValid) {
            return res.status(400).json({
                success: false,
                error: 'Invalid payment signature'
            });
        }

        // Find customer by order ID
        const customer = await Customer.findOne({ razorpayOrderId: razorpay_order_id });
        if (!customer) {
            return res.status(404).json({
                success: false,
                error: 'Order not found'
            });
        }

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
        res.status(500).json({
            success: false,
            error: error.message || 'Payment verification failed'
        });
    }
};

exports.verifyLicense = async (req, res) => {
    try {
        const { licenseKey } = req.body;

        console.log('License verification request:', { licenseKey });

        const customer = await Customer.findByLicenseKey(licenseKey);
        if (!customer) {
            return res.status(404).json({
                success: false,
                error: 'License key not found'
            });
        }

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
        console.error('License verification error:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'License verification failed'
        });
    }
};

exports.trackDownload = async (req, res) => {
    try {
        const { licenseKey, platform, version } = req.body;

        console.log('Download tracking request:', { licenseKey, platform, version });

        const customer = await Customer.findByLicenseKey(licenseKey);
        if (!customer) {
            return res.status(404).json({
                success: false,
                error: 'License key not found'
            });
        }

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
        console.error('Download tracking error:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'Download tracking failed'
        });
    }
};

exports.getPaymentStatus = async (req, res) => {
    try {
        const { orderId } = req.params;
        console.log('Checking payment status for order:', orderId);

        // Get order details from Razorpay
        const order = await razorpayService.getOrder(orderId);
        console.log('Order details:', order);

        // Get customer by order ID
        const customer = await Customer.findOne({ 'razorpayOrderId': orderId });
        if (!customer) {
            throw new Error('Customer not found');
        }

        let status;
        if (order.status === 'paid') {
            status = 'completed';
        } else if (order.status === 'attempted') {
            status = 'pending';
        } else {
            status = 'failed';
        }

        res.json({
            success: true,
            data: {
                status,
                customer: {
                    id: customer._id,
                    businessName: customer.businessName,
                    email: customer.email
                }
            }
        });
    } catch (error) {
        console.error('Error checking payment status:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'Payment status check failed'
        });
    }
};

exports.handleWebhook = async (req, res) => {
    try {
        const signature = req.headers['x-razorpay-signature'];
        console.log('Received webhook:', { 
            event: req.body.event,
            signature
        });

        // Verify webhook signature
        const isValidSignature = await razorpayService.verifyWebhookSignature(req.body, signature);
        if (!isValidSignature) {
            throw new Error('Invalid webhook signature');
        }

        const { payload } = req.body;
        const { payment } = payload;

        // Get payment details
        const paymentDetails = await razorpayService.getPayment(payment.entity.id);
        console.log('Payment details:', paymentDetails);

        // Find customer by order ID
        const customer = await Customer.findOne({ 'razorpayOrderId': payment.entity.order_id });
        if (!customer) {
            throw new Error('Customer not found');
        }

        switch (req.body.event) {
            case 'payment.captured':
                // Payment successful
                customer.license.key = licenseManager.generateLicenseKey(customer._id, 'professional');
                customer.license.status = 'active';
                customer.razorpayPaymentId = payment.entity.id;
                await customer.save();

                try {
                    await emailService.sendLicenseKeyEmail(customer);
                    console.log('License key email sent successfully');
                } catch (emailError) {
                    console.error('Failed to send license key email:', emailError);
                }
                break;

            case 'payment.failed':
                // Payment failed
                customer.license.status = 'payment_failed';
                customer.razorpayPaymentId = payment.entity.id;
                await customer.save();

                try {
                    await emailService.sendPaymentFailedEmail(customer);
                    console.log('Payment failed email sent successfully');
                } catch (emailError) {
                    console.error('Failed to send payment failed email:', emailError);
                }
                break;

            default:
                console.log('Unhandled webhook event:', req.body.event);
        }

        res.json({ success: true });
    } catch (error) {
        console.error('Webhook error:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'Webhook processing failed'
        });
    }
};
