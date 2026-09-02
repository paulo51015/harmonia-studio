import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_provider.dart';
import '../../services/auth_service.dart';
import '../../services/pitch_service.dart';
import '../../services/studio_audio_engine.dart';
import '../../theme/app_theme.dart';
import '../widgets/language_selector_menu.dart';
import 'interactive_lesson_screen.dart';
import 'settings_screen.dart';
import 'studio_screen.dart';

class HomeNavigationScreen extends StatefulWidget {
  final AuthService authService;
  final StudioAudioEngine audioEngine;
  final PitchService pitchService;
  final LanguageProvider languageProvider;

  const HomeNavigationScreen({
    super.key,
    required this.authService,
    required this.audioEngine,
    required this.pitchService,
    required this.languageProvider,
  });

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  int _currentIndex = 0;

  void _navigateToStudio() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final List<Widget> screens = [
      StudioScreen(audioEngine: widget.audioEngine),
      InteractiveLessonScreen(
        pitchService: widget.pitchService,
        audioEngine: widget.audioEngine,
        onNavigateToStudio: _navigateToStudio,
      ),
      SettingsScreen(
        authService: widget.authService,
        languageProvider: widget.languageProvider,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.graphic_eq, color: AppTheme.cyan, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              loc.translate('app_name'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: LanguageSelectorMenu(languageProvider: widget.languageProvider),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Se estiver saindo da tela de aulas, pausa a escuta do microfone
            if (_currentIndex == 1 && index != 1) {
              widget.pitchService.stopListening();
            }
            setState(() => _currentIndex = index);
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.album_outlined),
              activeIcon: const Icon(Icons.album, color: AppTheme.cyan),
              label: loc.translate('nav_studio'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.school_outlined),
              activeIcon: const Icon(Icons.school, color: AppTheme.cyan),
              label: loc.translate('nav_lessons'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings, color: AppTheme.cyan),
              label: loc.translate('nav_settings'),
            ),
          ],
        ),
      ),
    );
  }
}
