class ApiConfig {
  static const String baseUrl = 'https://ledgerpro-extended.onrender.com';
  static const String adminToken = '3562';
  
  static String get verifyLicenseEndpoint => '$baseUrl/api/admin/verify-license';
}
