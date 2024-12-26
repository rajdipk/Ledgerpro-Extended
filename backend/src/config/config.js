require('dotenv').config();

module.exports = {
    mongodb: {
        uri: process.env.MONGODB_URI
    },
    jwt: {
        secret: process.env.JWT_SECRET,
        expiresIn: process.env.JWT_EXPIRES_IN || '30d'
    },
    razorpay: {
        keyId: process.env.RAZORPAY_KEY_ID,
        keySecret: process.env.RAZORPAY_KEY_SECRET,
        webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET
    },
    smtp: {
        host: process.env.SMTP_HOST || 'smtp.gmail.com',
        port: process.env.SMTP_PORT || 587,
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
    },
    license: {
        secret: process.env.LICENSE_KEY_SECRET,
        demoPeriodDays: process.env.DEMO_PERIOD_DAYS || 30
    },
    server: {
        port: process.env.PORT || 3000,
        env: process.env.NODE_ENV || 'development'
    }
};
