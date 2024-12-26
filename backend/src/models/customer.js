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
            enum: ['active', 'expired', 'suspended'],
            default: 'active'
        },
        startDate: {
            type: Date,
            default: Date.now
        },
        endDate: {
            type: Date,
            required: true
        }
    },
    downloads: [{
        platform: {
            type: String,
            required: true,
            enum: ['windows', 'android']
        },
        version: {
            type: String,
            required: true
        },
        downloadDate: {
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
    if (!this.license) return false;
    
    const now = new Date();
    return this.license.status === 'active' && 
           this.license.endDate > now;
};

customerSchema.methods.canDownload = function(platform) {
    if (!this.isLicenseValid()) return false;
    
    // Check if platform matches customer's registered platform
    return this.platform === platform;
};

// Statics
customerSchema.statics.findByLicenseKey = function(licenseKey) {
    return this.findOne({ 'license.key': licenseKey });
};

const Customer = mongoose.model('Customer', customerSchema);

module.exports = Customer;
