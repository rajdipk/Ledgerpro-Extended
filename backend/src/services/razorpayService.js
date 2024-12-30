const Razorpay = require('razorpay');
const crypto = require('crypto');

class RazorpayService {
    constructor() {
        console.log('Initializing Razorpay with key:', process.env.RAZORPAY_KEY_ID);
        this.instance = new Razorpay({
            key_id: process.env.RAZORPAY_KEY_ID,
            key_secret: process.env.RAZORPAY_KEY_SECRET
        });

        this.prices = {
            professional: 599, // ₹599 INR
            enterprise: 0 // Custom pricing
        };
    }

    async createOrder(customerId) {
        console.log('Creating Razorpay order for customer:', customerId);
        
        const options = {
            amount: this.prices.professional * 100, // Convert to smallest currency unit (paise)
            currency: 'INR',
            receipt: `order_${customerId}`,
            notes: {
                customerId,
                licenseType: 'professional'
            },
            payment_capture: 1
        };

        try {
            const order = await this.instance.orders.create(options);
            console.log('Razorpay order created:', order);
            return order;
        } catch (error) {
            console.error('Error creating Razorpay order:', error);
            throw new Error('Failed to create payment order: ' + error.message);
        }
    }

    verifyPaymentSignature(orderId, paymentId, signature) {
        console.log('Verifying payment signature:', { orderId, paymentId, signature });
        
        try {
            const body = orderId + "|" + paymentId;
            const expectedSignature = crypto
                .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
                .update(body.toString())
                .digest("hex");

            const isValid = expectedSignature === signature;
            console.log('Signature verification:', {
                expected: expectedSignature,
                received: signature,
                isValid
            });
            return isValid;
        } catch (error) {
            console.error('Error verifying payment signature:', error);
            return false;
        }
    }

    verifyWebhookSignature(body, signature) {
        try {
            const webhook_secret = process.env.RAZORPAY_WEBHOOK_SECRET;
            const generated_signature = crypto
                .createHmac('sha256', webhook_secret)
                .update(JSON.stringify(body))
                .digest('hex');

            return generated_signature === signature;
        } catch (error) {
            console.error('Error verifying webhook signature:', error);
            return false;
        }
    }

    async getOrder(orderId) {
        try {
            return await this.instance.orders.fetch(orderId);
        } catch (error) {
            console.error('Error fetching Razorpay order:', error);
            throw new Error('Failed to fetch payment order');
        }
    }

    async getPayment(paymentId) {
        try {
            return await this.instance.payments.fetch(paymentId);
        } catch (error) {
            console.error('Error fetching Razorpay payment:', error);
            throw new Error('Failed to fetch payment details');
        }
    }
}

module.exports = new RazorpayService();
