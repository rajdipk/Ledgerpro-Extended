const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
    businessName: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        lowercase: true
    },
    phone: {
        type: String,
        required: true,
        trim: true
    },
    industry: {
        type: String,
        required: true,
        enum: ['retail', 'manufacturing', 'services', 'other']
    },
    platform: {
        type: String,
        required: true,
        enum: ['windows', 'android']
    },
    businessNeeds: {
        type: String,
        trim: true
    },
    licenseType: {
        type: String,
        required: true,
        enum: ['demo', 'professional', 'enterprise']
    },
    licenseKey: {
        type: String,
        unique: true
    },
    status: {
        type: String,
        enum: ['pending', 'active', 'suspended'],
        default: 'pending'
    },
    registrationDate: {
        type: Date,
        default: Date.now
    },
    lastLoginDate: Date,
    subscription: {
        orderId: String,
        paymentId: String,
        startDate: Date,
        endDate: Date,
        status: {
            type: String,
            enum: ['active', 'expired', 'cancelled'],
            default: 'active'
        }
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Customer', customerSchema);
