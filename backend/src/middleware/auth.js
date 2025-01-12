// Simple admin authentication middleware - replace with your actual auth logic
exports.requireAdmin = (req, res, next) => {
    // Get the admin token from header
    const adminToken = req.headers['x-admin-token'];

    // Check if token matches environment variable
    if (adminToken === process.env.ADMIN_TOKEN) {
        next();
    } else {
        res.status(401).json({ 
            success: false, 
            error: 'Unauthorized access' 
        });
    }
};

// Add other auth middleware as needed
