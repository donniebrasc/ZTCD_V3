import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = SettingsService();
  final _geminiKeyCtrl = TextEditingController();
  final _mapsKeyCtrl = TextEditingController();
  bool _geminiObscured = true;
  bool _mapsObscured = true;
  bool _loading = true;
  String _selectedModel = 'gemini-2.5-pro-preview-05-06';
  bool _saving = false;

  static const List<String> _models = [
    'gemini-2.5-pro-preview-05-06',
    'gemini-2.0-flash',
    'gemini-1.5-pro',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final geminiKey = await _settings.getGeminiApiKey();
    final mapsKey = await _settings.getMapsApiKey();
    final model = await _settings.getGeminiModel();
    if (mounted) {
      setState(() {
        _geminiKeyCtrl.text = geminiKey ?? '';
        _mapsKeyCtrl.text = mapsKey ?? '';
        _selectedModel = model;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.wait([
      _settings.setGeminiApiKey(_geminiKeyCtrl.text.trim()),
      _settings.setMapsApiKey(_mapsKeyCtrl.text.trim()),
      _settings.setGeminiModel(_selectedModel),
    ]);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved.')),
      );
    }
  }

  @override
  void dispose() {
    _geminiKeyCtrl.dispose();
    _mapsKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Gemini section ───────────────────────────────────────
                _SectionHeader(title: 'Google Gemini AI'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _geminiKeyCtrl,
                  obscureText: _geminiObscured,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIza…',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_geminiObscured
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _geminiObscured = !_geminiObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedModel,
                  decoration: const InputDecoration(
                    labelText: 'Gemini Model',
                    border: OutlineInputBorder(),
                  ),
                  items: _models
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedModel = v!),
                ),
                const SizedBox(height: 16),

                // ── Maps section ─────────────────────────────────────────
                _SectionHeader(title: 'Google Maps'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mapsKeyCtrl,
                  obscureText: _mapsObscured,
                  decoration: InputDecoration(
                    labelText: 'Maps API Key',
                    hintText: 'AIza…',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_mapsObscured
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _mapsObscured = !_mapsObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The Maps API key must also be added to android/app/src/main/AndroidManifest.xml '
                  'as a meta-data value for com.google.android.geo.API_KEY.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // ── Save ─────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving…' : 'Save Settings'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
