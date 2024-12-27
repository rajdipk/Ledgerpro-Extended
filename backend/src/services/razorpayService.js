const Razorpay = require('razorpay');
const crypto = require('crypto');

class RazorpayService {
    constructor() {
        this.instance = new Razorpay({
            key_id: process.env.RAZORPAY_KEY_ID,
            key_secret: process.env.RAZORPAY_KEY_SECRET
        });

        this.prices = {
            professional: 10, // $10 USD
            enterprise: 0 // Custom pricing
        };
    }

    async createOrder(customerId) {
        console.log('Creating Razorpay order for customer:', customerId);
        
        const options = {
            amount: this.prices.professional * 100, // Convert to smallest currency unit (cents)
            currency: 'USD',
            receipt: `order_${customerId}`,
            notes: {
                customerId,
                licenseType: 'professional'
            }
        };

        try {
            const order = await this.instance.orders.create(options);
            console.log('Razorpay order created:', order.id);
            return order;
        } catch (error) {
            console.error('Error creating Razorpay order:', error);
            throw new Error('Failed to create payment order');
        }
    }

    verifyPaymentSignature(orderId, paymentId, signature) {
        console.log('Verifying payment signature:', { orderId, paymentId });
        
        try {
            const text = `${orderId}|${paymentId}`;
            const generated_signature = crypto
                .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
                .update(text)
                .digest('hex');

            const isValid = generated_signature === signature;
            console.log('Signature verification result:', isValid);
            return isValid;
        } catch (error) {
            console.error('Error verifying payment signature:', error);
            return false;
        }
    }

    async verifyWebhookSignature(body, signature) {
        console.log('Verifying webhook signature');
        
        try {
            const webhook_secret = process.env.RAZORPAY_WEBHOOK_SECRET;
            const shasum = crypto.createHmac('sha256', webhook_secret);
            shasum.update(JSON.stringify(body));
            const digest = shasum.digest('hex');

            const isValid = digest === signature;
            console.log('Webhook signature verification result:', isValid);
            return isValid;
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
