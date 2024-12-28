import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  late SharedPreferences _prefs;

  StorageService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveValue(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<String?> getValue(String key) async {
    return _prefs.getString(key);
  }

  Future<void> removeValue(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // Convenience methods for specific data types
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  Future<void> saveDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    return _prefs.getDouble(key);
  }

  Future<void> saveStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    return _prefs.getStringList(key);
  }

  // Check if a key exists
  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }
}
