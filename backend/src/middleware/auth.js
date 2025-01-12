// Simple admin authentication middleware - replace with your actual auth logic
exports.requireAdmin = (req, res, next) => {
    try {
        const adminToken = req.headers['x-admin-token'];
        
        console.log('Auth check:', {
            receivedToken: adminToken,
            expectedToken: process.env.ADMIN_TOKEN,
            headers: req.headers
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

        // Set admin flag on request
        req.isAdmin = true;
        next();
    } catch (error) {
        console.error('Auth middleware error:', error);
        res.status(500).json({
            success: false,
            error: 'Authentication failed'
        });
    }
};

// Add other auth middleware as needed
