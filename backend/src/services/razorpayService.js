const Razorpay = require('razorpay');
const crypto = require('crypto');

class RazorpayService {
    constructor() {
        this.instance = new Razorpay({
            key_id: process.env.RAZORPAY_KEY_ID,
            key_secret: process.env.RAZORPAY_KEY_SECRET
        });

        this.prices = {
            professional: 79900, // ₹799 in paise
            enterprise: 0 // Custom pricing
        };
    }

    async createOrder(licenseType, customerId) {
        const amount = this.prices[licenseType];
        if (!amount && licenseType !== 'enterprise') {
            throw new Error('Invalid license type');
        }

        const options = {
            amount,
            currency: 'INR',
            receipt: `order_${customerId}`,
            notes: {
                customerId,
                licenseType
            }
        };

        return await this.instance.orders.create(options);
    }

    verifyPaymentSignature(orderId, paymentId, signature) {
        const text = `${orderId}|${paymentId}`;
        const generated_signature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(text)
            .digest('hex');

        return generated_signature === signature;
    }

    async verifyWebhookSignature(body, signature) {
        const webhook_secret = process.env.RAZORPAY_WEBHOOK_SECRET;
        const shasum = crypto.createHmac('sha256', webhook_secret);
        shasum.update(JSON.stringify(body));
        const digest = shasum.digest('hex');

        return digest === signature;
    }

    async fetchPaymentById(paymentId) {
        return await this.instance.payments.fetch(paymentId);
    }

    generatePaymentConfig(orderId, amount, customerEmail, customerPhone) {
        return {
            key: process.env.RAZORPAY_KEY_ID,
            amount,
            currency: 'INR',
            name: 'LedgerPro',
            description: 'LedgerPro License Purchase',
            order_id: orderId,
            prefill: {
                email: customerEmail,
                contact: customerPhone
            },
            notes: {
                address: 'LedgerPro Corporate Office'
            },
            theme: {
                color: '#009688'
            }
        };
    }
}

module.exports = new RazorpayService();
