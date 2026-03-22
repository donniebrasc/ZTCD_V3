import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

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
  bool _hasGeminiKey = false;

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
    final hasKey = await _settings.hasGeminiKey();
    if (mounted) {
      setState(() {
        // Only show stored user key in field (not compiled-in key for security).
        _geminiKeyCtrl.text = _settings.usingCompiledKey ? '' : geminiKey;
        _mapsKeyCtrl.text = mapsKey;
        _selectedModel = model;
        _hasGeminiKey = hasKey;
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
    final hasKey = await _settings.hasGeminiKey();
    if (mounted) {
      setState(() {
        _saving = false;
        _hasGeminiKey = hasKey;
      });
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: GoogleFonts.orbitron(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.racingRed,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── AI status banner ───────────────────────────────────
                _AiStatusBanner(hasKey: _hasGeminiKey,
                    usingCompiled: _settings.usingCompiledKey),
                const SizedBox(height: 16),

                // ── Gemini section ─────────────────────────────────────
                const _SectionHeader(title: 'GOOGLE GEMINI AI'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _geminiKeyCtrl,
                  obscureText: _geminiObscured,
                  style: GoogleFonts.rajdhani(
                      color: AppTheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: _settings.usingCompiledKey
                        ? '(using built-in key)'
                        : 'AIza…',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _geminiObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.onSurfaceDim,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _geminiObscured = !_geminiObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVar,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A38)),
                  ),
                  child: Text(
                    '💡 Free tier: 1,500 requests/day at ai.google.dev\n'
                    'Leave blank to use Demo Mode with pre-built responses.',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.onSurfaceDim,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedModel,
                  dropdownColor: AppTheme.surfaceVar,
                  style: GoogleFonts.rajdhani(
                      color: AppTheme.onSurface, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Gemini Model',
                    border: OutlineInputBorder(),
                  ),
                  items: _models
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedModel = v!),
                ),
                const SizedBox(height: 20),

                // ── Maps section ───────────────────────────────────────
                const _SectionHeader(title: 'GOOGLE MAPS'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _mapsKeyCtrl,
                  obscureText: _mapsObscured,
                  style: GoogleFonts.rajdhani(
                      color: AppTheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Maps API Key',
                    hintText: 'AIza…',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mapsObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.onSurfaceDim,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _mapsObscured = !_mapsObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The Maps key must also be set in '
                  'android/app/src/main/AndroidManifest.xml as '
                  'com.google.android.geo.API_KEY. '
                  'Build with --dart-define=MAPS_API_KEY=AIza… to embed it.',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurfaceDim,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Save ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      _saving ? 'SAVING…' : 'SAVE SETTINGS',
                      style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Build info ─────────────────────────────────────────
                const _SectionHeader(title: 'BUILD INFO'),
                const SizedBox(height: 10),
                _InfoRow(
                    label: 'VERSION',
                    value: '1.0.0',
                    icon: Icons.info_outline),
                _InfoRow(
                    label: 'OBD TRANSPORT',
                    value: 'BT / USB / SIM',
                    icon: Icons.cable_outlined),
                _InfoRow(
                    label: 'AI MODEL',
                    value: _selectedModel,
                    icon: Icons.smart_toy_outlined),
                _InfoRow(
                    label: 'AI MODE',
                    value: _hasGeminiKey ? 'LIVE' : 'DEMO',
                    icon: Icons.psychology_outlined,
                    valueColor: _hasGeminiKey
                        ? AppTheme.successGreen
                        : AppTheme.amber),
              ],
            ),
    );
  }
}

// ── AI status banner ──────────────────────────────────────────────────────────

class _AiStatusBanner extends StatelessWidget {
  final bool hasKey;
  final bool usingCompiled;

  const _AiStatusBanner({required this.hasKey, required this.usingCompiled});

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    final Color iconColor;
    final IconData icon;
    final String title;
    final String body;

    if (hasKey && usingCompiled) {
      borderColor = AppTheme.successGreen;
      bgColor = AppTheme.successGreen.withOpacity(0.08);
      iconColor = AppTheme.successGreen;
      icon = Icons.check_circle_outline;
      title = 'AI READY — BUILT-IN KEY';
      body = 'Your app ships with a built-in Gemini API key. '
          'AI diagnostics are available without any setup.';
    } else if (hasKey) {
      borderColor = AppTheme.successGreen;
      bgColor = AppTheme.successGreen.withOpacity(0.08);
      iconColor = AppTheme.successGreen;
      icon = Icons.check_circle_outline;
      title = 'AI READY — CUSTOM KEY';
      body = 'Using your Gemini API key. '
          'Full AI diagnostics and route analysis enabled.';
    } else {
      borderColor = AppTheme.amber;
      bgColor = AppTheme.amber.withOpacity(0.08);
      iconColor = AppTheme.amber;
      icon = Icons.info_outline;
      title = 'DEMO MODE';
      body = 'No Gemini API key detected. '
          'The app works with pre-built demo responses. '
          'Add a free key at ai.google.dev to unlock live AI analysis.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurfaceDim,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.racingRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.rajdhani(
            color: AppTheme.racingRed,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A38)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.onSurfaceDim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.rajdhani(
                color: AppTheme.onSurfaceDim,
                fontSize: 12,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              color: valueColor ?? AppTheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
