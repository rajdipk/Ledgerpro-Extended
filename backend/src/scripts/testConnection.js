require('dotenv').config();
const connectDB = require('../config/database');

async function testConnection() {
    try {
        console.log('Testing MongoDB connection...');
        await connectDB();
        console.log('Connection successful!');
        process.exit(0);
    } catch (error) {
        console.error('Connection failed:', error);
        process.exit(1);
    }
}

testConnection();
