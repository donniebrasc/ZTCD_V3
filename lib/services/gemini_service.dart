import 'package:google_generative_ai/google_generative_ai.dart';
import 'settings_service.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  final _settings = SettingsService();

  Future<String> runDiagnostics(String obdDataPrompt) async {
    final apiKey = await _settings.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'No Gemini API key configured. Please add your API key in Settings.';
    }

    try {
      final model = GenerativeModel(
        model: await _settings.getGeminiModel(),
        apiKey: apiKey,
        systemInstruction: Content.text(
          'You are an expert automotive diagnostics AI. '
          'Analyse the provided OBD-II sensor data and give a concise, '
          'actionable report: identify any anomalies, likely causes, and '
          'recommended actions. Use plain English, avoid jargon, and keep '
          'the response under 300 words.',
        ),
      );

      final prompt = 'Please diagnose the following vehicle sensor readings:\n\n'
          '$obdDataPrompt';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No response received from Gemini.';
    } on GenerativeAIException catch (e) {
      return 'Gemini API error: ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  Future<String> getRouteRecommendation(String routeSummary) async {
    final apiKey = await _settings.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'No Gemini API key configured. Please add your API key in Settings.';
    }

    try {
      final model = GenerativeModel(
        model: await _settings.getGeminiModel(),
        apiKey: apiKey,
        systemInstruction: Content.text(
          'You are an automotive route optimisation AI. '
          'Given historical route data including damage scores and distances, '
          'recommend the best route and explain why briefly (under 150 words).',
        ),
      );

      final response = await model.generateContent([
        Content.text('Analyse these route options and recommend the best:\n\n$routeSummary'),
      ]);
      return response.text ?? 'No recommendation received.';
    } on GenerativeAIException catch (e) {
      return 'Gemini API error: ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }
}
