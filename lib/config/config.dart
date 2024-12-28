class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api';
  
  // Razorpay Configuration
  static const String razorpayKeyId = 'rzp_test_your_key_id'; // Replace with your test key
  
  // License Configuration
  static const Map<String, Map<String, int>> maxLimits = {
    'demo': {
      'max_customers': 10,
      'max_inventory_items': 50,
      'max_invoices': 20,
    },
    'professional': {
      'max_customers': 1000,
      'max_inventory_items': 5000,
      'max_invoices': 1000,
    },
    'enterprise': {
      'max_customers': -1, // unlimited
      'max_inventory_items': -1, // unlimited
      'max_invoices': -1, // unlimited
    },
  };

  static const Map<String, List<String>> licenseFeatures = {
    'demo': [
      'basic_inventory',
      'basic_customers',
      'basic_invoicing',
    ],
    'professional': [
      'advanced_inventory',
      'advanced_customers',
      'advanced_invoicing',
      'pdf_export',
      'barcode_scanning',
      'purchase_orders',
      'inventory_movements',
      'basic_reports',
    ],
    'enterprise': [
      'advanced_inventory',
      'advanced_customers',
      'advanced_invoicing',
      'pdf_export',
      'barcode_scanning',
      'purchase_orders',
      'inventory_movements',
      'advanced_reports',
      'custom_branding',
      'api_access',
      'multi_business',
      'priority_support',
    ],
  };
}
