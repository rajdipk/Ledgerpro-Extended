const Razorpay = require('razorpay');

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
});

// Test Razorpay connection
const testRazorpayConnection = async () => {
    try {
        // Try to fetch payments (this will fail if credentials are invalid)
        await razorpay.payments.all();
        console.log('Razorpay connection successful!');
        return true;
    } catch (error) {
        console.error('Razorpay connection failed:', error.message);
        return false;
    }
};

module.exports = {
    razorpay,
    testRazorpayConnection
};
