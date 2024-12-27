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
        enum: ['retail', 'wholesale', 'manufacturing', 'services', 'other']
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
    razorpayOrderId: {
        type: String,
        sparse: true
    },
    razorpayPaymentId: {
        type: String,
        sparse: true
    },
    razorpaySignature: {
        type: String,
        sparse: true
    },
    razorpayCustomerId: {
        type: String,
        sparse: true
    },
    license: {
        type: {
            type: String,
            enum: ['demo', 'professional', 'enterprise'],
            required: true
        },
        key: {
            type: String,
            unique: true,
            sparse: true
        },
        status: {
            type: String,
            enum: ['pending', 'active', 'expired', 'payment_failed', 'cancelled'],
            default: 'pending'
        },
        endDate: {
            type: Date
        },
        activationDate: {
            type: Date
        },
        lastVerified: {
            type: Date
        },
        startDate: {
            type: Date,
            default: Date.now
        }
    },
    downloads: [{
        platform: String,
        version: String,
        timestamp: {
            type: Date,
            default: Date.now
        },
        ip: String
    }],
    paymentHistory: [{
        orderId: String,
        paymentId: String,
        amount: Number,
        currency: String,
        status: String,
        timestamp: {
            type: Date,
            default: Date.now
        }
    }]
}, {
    timestamps: true
});

// Create compound index for email and license key
customerSchema.index({ email: 1, 'license.key': 1 });

// Methods
customerSchema.methods.isLicenseValid = function() {
    if (!this.license.key || this.license.status !== 'active') {
        return false;
    }

    if (this.license.type === 'demo') {
        return true;
    }

    return this.license.endDate && new Date() <= this.license.endDate;
};

customerSchema.methods.canDownload = function(platform) {
    return this.isLicenseValid() && this.platform === platform;
};

// Statics
customerSchema.statics.findByLicenseKey = async function(licenseKey) {
    return this.findOne({ 'license.key': licenseKey });
};

// Middleware
customerSchema.pre('save', function(next) {
    if (this.isModified('license.status') && this.license.status === 'active' && !this.license.activationDate) {
        this.license.activationDate = new Date();
    }
    next();
});

const Customer = mongoose.model('Customer', customerSchema);

module.exports = Customer;
