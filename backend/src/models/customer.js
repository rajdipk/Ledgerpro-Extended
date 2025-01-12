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
        unique: true, // This already creates an index
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
    razorpayOrderId: String,
    razorpayPaymentId: String,
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Add only necessary indexes (email is already indexed due to unique: true)
customerSchema.index({ 'license.status': 1 });
customerSchema.index({ 'license.type': 1 });
customerSchema.index({ createdAt: -1 });

// Add methods
customerSchema.methods.isLicenseValid = function() {
    if (this.license.status !== 'active') return false;
    if (!this.license.endDate) return true;
    return new Date() < this.license.endDate;
};

customerSchema.methods.canDownload = function(platform) {
    return this.platform === platform && this.isLicenseValid();
};

// Static methods
customerSchema.statics.findByLicenseKey = function(licenseKey) {
    return this.findOne({ 'license.key': licenseKey });
};

const Customer = mongoose.model('Customer', customerSchema);
module.exports = Customer;
