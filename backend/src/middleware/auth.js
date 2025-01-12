// Simple admin authentication middleware - replace with your actual auth logic
exports.requireAdmin = (req, res, next) => {
    const adminToken = req.headers['x-admin-token'];
    
    console.log('Auth check:', {
        receivedToken: adminToken,
        expectedToken: process.env.ADMIN_TOKEN,
        headersSent: JSON.stringify(req.headers)
    });

    if (!adminToken) {
        return res.status(401).json({
            success: false,
            error: 'No admin token provided'
        });
    }

    if (adminToken !== process.env.ADMIN_TOKEN) {
        return res.status(401).json({
            success: false,
            error: 'Invalid admin token'
        });
    }

    next();
};

// Add other auth middleware as needed
