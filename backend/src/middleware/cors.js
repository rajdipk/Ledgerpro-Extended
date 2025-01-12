const cors = require('cors');

const corsOptions = {
    origin: function (origin, callback) {
        const allowedOrigins = [
            'http://localhost:3000',
            'http://localhost:5500',
            'https://ledgerpro-extended.onrender.com',
            'https://rajdipk.github.io'
        ];
        
        // Allow requests with no origin (like mobile apps or curl requests)
        if (!origin) return callback(null, true);
        
        if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
        'Content-Type',
        'x-admin-token',
        'Authorization',
        'Access-Control-Allow-Headers',
        'Origin',
        'Accept'
    ],
    credentials: true,
    optionsSuccessStatus: 200
};

module.exports = cors(corsOptions);
