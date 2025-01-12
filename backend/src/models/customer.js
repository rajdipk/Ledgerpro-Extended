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
        lowercase: true,
        trim: true
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
    license: {
        type: {
            type: String,
            required: true,
            enum: ['demo', 'professional', 'enterprise']
        },
        key: String,
        status: {
            type: String,
            required: true,
            enum: ['active', 'pending', 'expired', 'cancelled'],
            default: 'pending'
        },
        endDate: Date
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Add indexes for better query performance
customerSchema.index({ email: 1 }, { unique: true });
customerSchema.index({ 'license.status': 1 });
customerSchema.index({ 'license.type': 1 });
customerSchema.index({ createdAt: -1 });

const Customer = mongoose.model('Customer', customerSchema);
module.exports = Customer;
