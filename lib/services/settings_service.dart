import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _keyGeminiApiKey = 'gemini_api_key';
  static const _keyMapsApiKey = 'maps_api_key';
  static const _keyGeminiModel = 'gemini_model';

  /// Compile-time defaults – injected via:
  ///   flutter run --dart-define=GEMINI_API_KEY=AIza… --dart-define=MAPS_API_KEY=AIza…
  ///
  /// When building a release for end-users, bake the keys in so that
  /// non-technical users never have to visit the Settings screen.
  static const String _compiledGeminiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _compiledMapsKey =
      String.fromEnvironment('MAPS_API_KEY', defaultValue: '');

  Future<String> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyGeminiApiKey);
    // Return stored key if set, otherwise fall back to compile-time default.
    if (stored != null && stored.isNotEmpty) return stored;
    return _compiledGeminiKey;
  }

  Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApiKey, key);
  }

  Future<String> getMapsApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyMapsApiKey);
    if (stored != null && stored.isNotEmpty) return stored;
    return _compiledMapsKey;
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

  /// Returns true if the app has a usable Gemini key (compiled-in or stored).
  Future<bool> hasGeminiKey() async => (await getGeminiApiKey()).isNotEmpty;

  /// Returns true if using the compiled-in key (not user-entered).
  bool get usingCompiledKey => _compiledGeminiKey.isNotEmpty;
}
