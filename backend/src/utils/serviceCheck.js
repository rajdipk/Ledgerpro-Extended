const mongoose = require('mongoose');

function checkServices() {
  // Check MongoDB connection
  const mongoStatus = mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected';
  console.log('MongoDB Status:', mongoStatus);

  // Check environment variables
  const requiredEnvVars = [
    'MONGODB_URI',
    'RAZORPAY_KEY_ID',
    'SMTP_USER'
  ];

  console.log('\nEnvironment Variables Check:');
  requiredEnvVars.forEach(varName => {
    console.log(`${varName}: ${process.env[varName] ? 'Set' : 'Not Set'}`);
  });
}

module.exports = checkServices;
