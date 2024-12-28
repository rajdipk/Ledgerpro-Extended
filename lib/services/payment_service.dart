import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/license_model.dart';
import '../config/config.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();
  final String _baseUrl = AppConfig.apiBaseUrl;

  PaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> startPayment(LicenseType type, String customerId, Function(String) onSuccess, Function(String) onError) async {
    try {
      // Create order on backend
      final response = await http.post(
        Uri.parse('$_baseUrl/customer/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': customerId,
          'licenseType': type.toString().split('.').last,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create order');
      }

      final orderData = jsonDecode(response.body);
      final options = {
        'key': AppConfig.razorpayKeyId,
        'amount': orderData['amount'],
        'name': 'LedgerPro',
        'order_id': orderData['id'],
        'description': '${type.toString().split('.').last} License',
        'timeout': 300, // in seconds
        'prefill': {
          'contact': '',
          'email': ''
        }
      };

      _razorpay.open(options);
    } catch (e) {
      onError(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Verify payment on backend
      final verifyResponse = await http.post(
        Uri.parse('$_baseUrl/customer/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_payment_id': response.paymentId,
          'razorpay_order_id': response.orderId,
          'razorpay_signature': response.signature,
        }),
      );

      if (verifyResponse.statusCode != 200) {
        throw Exception('Payment verification failed');
      }

      final data = jsonDecode(verifyResponse.body);
      _razorpay.clear(); // Clear all event listeners
    } catch (e) {
      print('Error in payment verification: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Error: ${response.code} - ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

  void dispose() {
    _razorpay.clear();
  }
}
