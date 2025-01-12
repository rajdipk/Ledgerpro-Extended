const cors = require('cors');

const corsOptions = {
    origin: function (origin, callback) {
        const allowedOrigins = [
            'http://localhost:3000',
            'http://localhost:5500',
            'https://ledgerpro-extended.onrender.com',
            'https://rajdipk.github.io'
        ];
        
        // Allow all origins in development
        if (process.env.NODE_ENV === 'development') {
            callback(null, true);
            return;
        }
        
        if (!origin || allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'x-admin-token', 'Authorization'],
    exposedHeaders: ['Content-Range', 'X-Content-Range']
};

module.exports = cors(corsOptions);
