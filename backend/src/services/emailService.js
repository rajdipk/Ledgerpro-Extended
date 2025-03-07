const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            }
        });
    }

    async sendWelcomeEmail(customer) {
        try {
            const emailContent = `
                <h1>Welcome to LedgerPro!</h1>
                <p>Dear ${customer.businessName},</p>
                <p>Thank you for choosing LedgerPro. Here are your license details:</p>
                <ul>
                    <li>License Key: <strong>${customer.license.key}</strong></li>
                    <li>License Type: ${customer.license.type}</li>
                    <li>Expiry Date: ${customer.license.endDate.toLocaleDateString()}</li>
                </ul>
                <p>To get started:</p>
                <ol>
                    <li>Download LedgerPro for your platform (${customer.platform})</li>
                    <li>Install the application</li>
                    <li>Enter your license key when prompted</li>
                </ol>
                <p>If you need any assistance, please don't hesitate to contact our support team.</p>
                <p>Best regards,<br>The LedgerPro Team</p>
            `;

            await this.transporter.sendMail({
                from: process.env.SMTP_USER,
                to: customer.email,
                subject: 'Welcome to LedgerPro - Your License Key',
                html: emailContent
            });
            
            console.log('Welcome email sent successfully to:', customer.email);
        } catch (error) {
            console.error('Error sending welcome email:', error);
            throw new Error('Failed to send welcome email');
        }
    }

    async sendLicenseKeyEmail(customer) {
        try {
            const emailContent = `
                <h1>Your LedgerPro License Key</h1>
                <p>Dear ${customer.businessName},</p>
                <p>Thank you for your purchase. Here are your license details:</p>
                <ul>
                    <li>License Key: <strong>${customer.license.key}</strong></li>
                    <li>License Type: ${customer.license.type}</li>
                    <li>Expiry Date: ${customer.license.endDate.toLocaleDateString()}</li>
                </ul>
                <p>To activate your license:</p>
                <ol>
                    <li>Open LedgerPro</li>
                    <li>Go to Settings > License</li>
                    <li>Enter your license key</li>
                </ol>
                <p>For any assistance, please contact our support team.</p>
                <p>Best regards,<br>The LedgerPro Team</p>
            `;

            await this.transporter.sendMail({
                from: process.env.SMTP_USER,
                to: customer.email,
                subject: 'LedgerPro - Your License Key',
                html: emailContent
            });
            
            console.log('License key email sent successfully to:', customer.email);
        } catch (error) {
            console.error('Error sending license key email:', error);
            throw new Error('Failed to send license key email');
        }
    }

    async sendExpiryReminderEmail(customer) {
        const daysLeft = Math.ceil((customer.license.endDate - new Date()) / (1000 * 60 * 60 * 24));
        
        const emailContent = `
            <h1>LedgerPro License Expiry Reminder</h1>
            <p>Dear ${customer.businessName},</p>
            <p>Your LedgerPro license will expire in ${daysLeft} days.</p>
            <ul>
                <li>License Type: ${customer.license.type}</li>
                <li>Expiry Date: ${customer.license.endDate.toLocaleDateString()}</li>
            </ul>
            <p>To ensure uninterrupted service, please renew your license before the expiry date.</p>
            <p>Click here to renew: <a href="https://ledgerpro.com/renew">Renew License</a></p>
            <p>Best regards,<br>The LedgerPro Team</p>
        `;

        try {
            await this.transporter.sendMail({
                from: process.env.SMTP_USER,
                to: customer.email,
                subject: 'LedgerPro - License Expiry Reminder',
                html: emailContent
            });
            
            console.log('Expiry reminder email sent successfully to:', customer.email);
        } catch (error) {
            console.error('Error sending expiry reminder email:', error);
            throw new Error('Failed to send expiry reminder email');
        }
    }
}

module.exports = new EmailService();
