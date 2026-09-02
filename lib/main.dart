import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'l10n/language_provider.dart';
import 'services/auth_service.dart';
import 'services/pitch_service.dart';
import 'services/studio_audio_engine.dart';
import 'services/synth_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_navigation_screen.dart';
import 'ui/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloqueia orientação ou configura estilo de barra de status
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundSecondary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializa serviços centrais
  final authService = AuthService();
  final audioEngine = StudioAudioEngine();
  final pitchService = PitchService();
  final languageProvider = LanguageProvider();
  SynthService().init();

  runApp(HarmoniaStudioApp(
    authService: authService,
    audioEngine: audioEngine,
    pitchService: pitchService,
    languageProvider: languageProvider,
  ));
}

class HarmoniaStudioApp extends StatelessWidget {
  final AuthService authService;
  final StudioAudioEngine audioEngine;
  final PitchService pitchService;
  final LanguageProvider languageProvider;

  const HarmoniaStudioApp({
    super.key,
    required this.authService,
    required this.audioEngine,
    required this.pitchService,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageProvider,
      builder: (context, _) {
        return ListenableBuilder(
          listenable: authService,
          builder: (context, _) {
            return MaterialApp(
              title: 'Harmonia Studio',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
              locale: languageProvider.currentLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: !authService.isInitialized
                  ? const _SplashScreen()
                  : (authService.isAuthenticated
                      ? HomeNavigationScreen(
                          authService: authService,
                          audioEngine: audioEngine,
                          pitchService: pitchService,
                          languageProvider: languageProvider,
                        )
                      : LoginScreen(
                          authService: authService,
                          languageProvider: languageProvider,
                        )),
            );
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.cyan, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.cyan.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: AppTheme.cyan,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'HARMONIA STUDIO',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'DAW Multi-pista & Educação Musical Inteligente',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
