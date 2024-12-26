require('dotenv').config();
const { testRazorpayConnection } = require('../config/razorpay');

async function testConnection() {
    try {
        console.log('Testing Razorpay connection...');
        const success = await testRazorpayConnection();
        if (success) {
            console.log('Razorpay connection successful!');
            process.exit(0);
        } else {
            console.error('Razorpay connection failed!');
            process.exit(1);
        }
    } catch (error) {
        console.error('Test failed:', error);
        process.exit(1);
    }
}

testConnection();
