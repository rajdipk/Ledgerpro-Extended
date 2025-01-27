const ADMIN_TOKEN = process.env.ADMIN_TOKEN || '3562';

const adminAuth = (req, res, next) => {
    const token = req.headers['x-admin-token'];
    
    if (!token || token !== ADMIN_TOKEN) {
        return res.status(401).json({
            success: false,
            error: 'Unauthorized access'
        });
    }
    next();
};

module.exports = adminAuth;
