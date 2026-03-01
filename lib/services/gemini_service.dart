import 'package:google_generative_ai/google_generative_ai.dart';
import 'settings_service.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  final _settings = SettingsService();

  // ── Demo-mode responses (shown when no API key is configured) ─────────────

  static const String _demoDiagnostics = '''
⚠️  DEMO MODE – Add your Gemini API key in Settings for live AI analysis.

VEHICLE STATUS SUMMARY (Simulated)
────────────────────────────────────
• Engine RPM: Within normal operating range.
• Coolant Temperature: Normal. No overheating detected.
• Engine Load: Moderate. Consistent with city driving.
• Fuel Level: Adequate for current trip.
• Battery Voltage: Healthy charging system detected.

RECOMMENDATIONS
• Schedule routine oil change if mileage exceeds 5,000 km since last service.
• Check tyre pressures monthly for optimal fuel economy.
• No fault codes detected in this simulation session.

To enable real AI diagnostics, tap ⚙ Settings and enter your free
Google Gemini API key (1,500 free requests/day at ai.google.dev).
''';

  static const String _demoRouteRecommendation = '''
⚠️  DEMO MODE – Add your Gemini API key in Settings for live route analysis.

ROUTE ANALYSIS (Simulated)
────────────────────────────
Based on simulated trip data, Route A shows lower average damage scores,
suggesting smoother road surfaces and fewer harsh-braking events.

RECOMMENDATION
• Prefer routes with lower speed variance and fewer sharp turns.
• Avoid routes with high historical damage scores during peak hours.

Enable live AI route recommendations by adding your free Gemini API key
in ⚙ Settings.
''';

  // ─────────────────────────────────────────────────────────────────────────

  Future<String> runDiagnostics(String obdDataPrompt) async {
    final apiKey = await _settings.getGeminiApiKey();
    if (apiKey.isEmpty) return _demoDiagnostics;

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
    if (apiKey.isEmpty) return _demoRouteRecommendation;

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
