import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _keyGeminiApiKey = 'gemini_api_key';
  static const _keyMapsApiKey = 'maps_api_key';
  static const _keyGeminiModel = 'gemini_model';

  Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey);
  }

  Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApiKey, key);
  }

  Future<String?> getMapsApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMapsApiKey);
  }

  Future<void> setMapsApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMapsApiKey, key);
  }

  Future<String> getGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiModel) ?? 'gemini-2.5-pro-preview-05-06';
  }

  Future<void> setGeminiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiModel, model);
  }
}
