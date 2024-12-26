const crypto = require('crypto');

class LicenseManager {
    constructor(secret) {
        this.secret = secret;
    }

    generateLicenseKey(customerId, licenseType) {
        // Create a unique identifier combining customer ID and timestamp
        const uniqueId = `${customerId}-${Date.now()}`;
        
        // Create HMAC using the secret
        const hmac = crypto.createHmac('sha256', this.secret);
        hmac.update(uniqueId);
        
        // Generate the license key
        const hash = hmac.digest('hex');
        
        // Format the license key in a readable format (XXXX-XXXX-XXXX-XXXX)
        return hash.match(/.{4}/g).slice(0, 4).join('-').toUpperCase();
    }

    calculateExpiryDate(licenseType) {
        const now = new Date();
        
        switch(licenseType) {
            case 'demo':
                // Demo license expires in 30 days
                return new Date(now.setDate(now.getDate() + 30));
            
            case 'professional':
                // Professional license expires in 30 days (monthly subscription)
                return new Date(now.setDate(now.getDate() + 30));
            
            case 'enterprise':
                // Enterprise license expires in 365 days (yearly)
                return new Date(now.setDate(now.getDate() + 365));
            
            default:
                throw new Error('Invalid license type');
        }
    }

    verifyLicenseKey(licenseKey, customerId) {
        // Implementation for verifying license key authenticity
        // This would involve checking the HMAC signature
        try {
            // Split the license key back into its components
            const parts = licenseKey.split('-');
            if (parts.length !== 4) return false;

            // Additional verification logic can be added here
            return true;
        } catch (error) {
            return false;
        }
    }

    getLicenseFeatures(licenseType) {
        const features = {
            demo: [
                'Basic inventory management',
                'Billing system',
                'Customer management',
                'Single business profile',
                'Community support'
            ],
            professional: [
                'Advanced inventory management',
                'Multiple business profiles',
                'Detailed analytics',
                'Priority support',
                'Free updates'
            ],
            enterprise: [
                'All Professional features',
                'Custom integration support',
                'Dedicated support',
                'Training sessions',
                'Custom features on request'
            ]
        };

        return features[licenseType] || [];
    }
}

module.exports = LicenseManager;
