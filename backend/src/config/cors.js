const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:5000',
  'https://rajdipk.github.io',  // Your GitHub Pages domain
  process.env.RAZORPAY_WEBHOOK_SECRET // Your webhook URL
];

const corsOptions = {
  origin: function (origin, callback) {
    if (!origin || allowedOrigins.some(allowed => origin.startsWith(allowed))) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400 // 24 hours
};

module.exports = corsOptions;
