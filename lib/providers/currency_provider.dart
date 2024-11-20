import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _currencyCodeKey = 'currency_code';
  
  String _currencySymbol = '₹'; // Default to Rupee symbol
  String _currencyCode = 'INR'; // Default to Indian Rupee code

  CurrencyProvider() {
    _loadPreferences();
  }

  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString(_currencySymbolKey) ?? '₹';
    _currencyCode = prefs.getString(_currencyCodeKey) ?? 'INR';
    notifyListeners();
  }

  Future<void> updateCurrencySymbol(String newSymbol) async {
    if (newSymbol.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencySymbolKey, newSymbol);
    _currencySymbol = newSymbol;
    notifyListeners();
  }

  Future<void> updateCurrencyCode(String newCode) async {
    if (newCode.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, newCode);
    _currencyCode = newCode;
    notifyListeners();
  }
}
