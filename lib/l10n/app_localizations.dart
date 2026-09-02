import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Sistema de Internacionalização (i18n) para Harmonia Studio.
/// Suporta Português (pt-BR), Inglês (en-US) e Espanhol (es-ES).
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('pt', 'BR'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      // App & Gerais
      'app_name': 'Harmonia Studio',
      'app_tagline': 'DAW Multi-pistas & Aulas Interativas de Música',
      'cancel': 'Cancelar',
      'save': 'Salvar',
      'confirm': 'Confirmar',
      'close': 'Fechar',
      'delete': 'Excluir',
      'error': 'Erro',
      'success': 'Sucesso',
      'loading': 'Carregando...',
      'language': 'Idioma',
      'portuguese': 'Português (Brasil)',
      'english': 'English (US)',
      'spanish': 'Español',

      // Autenticação
      'login_title': 'Bem-vindo ao Harmonia Studio',
      'login_subtitle': 'Entre para acessar suas faixas e aulas interativas',
      'username': 'Usuário',
      'password': 'Senha',
      'login_button': 'Entrar',
      'change_password': 'Alterar Senha',
      'current_password': 'Senha Atual',
      'new_password': 'Nova Senha',
      'confirm_new_password': 'Confirmar Nova Senha',
      'invalid_credentials': 'Usuário ou senha incorretos (padrão: admin / 123456)',
      'password_changed_success': 'Senha alterada com sucesso!',
      'password_mismatch': 'A nova senha e a confirmação não conferem',
      'password_too_short': 'A nova senha deve ter no mínimo 6 caracteres',
      'logout': 'Sair da Conta',

      // Navegação
      'nav_studio': 'Estúdio DAW',
      'nav_lessons': 'Aulas Interativas',
      'nav_settings': 'Configurações',

      // Módulo Estúdio DAW
      'daw_title': 'Estúdio de Gravação',
      'daw_bpm': 'BPM',
      'daw_metronome': 'Metrônomo',
      'daw_play': 'Reproduzir',
      'daw_stop': 'Parar',
      'daw_rec': 'Gravar (REC)',
      'daw_master_rec': 'Gravação Master',
      'daw_recording': 'GRAVANDO...',
      'daw_playing': 'REPRODUZINDO...',
      'daw_stopped': 'PARADO',
      'daw_tracks': 'Pistas',
      'daw_add_track': 'Adicionar Pista',
      'daw_export_mixdown': 'Exportar Mixdown',
      'daw_exporting': 'Renderizando Mixdown...',
      'daw_export_success': 'Mixdown estéreo renderizado com sucesso!',
      'daw_share_audio': 'Compartilhar Áudio',
      'daw_volume': 'Volume',
      'daw_mute': 'Mudo (M)',
      'daw_solo': 'Solo (S)',
      'daw_arm_rec': 'Armar REC',
      'daw_track_guitar': 'Pista 1 - Violão Acústico',
      'daw_track_piano': 'Pista 2 - Teclado / Sintetizador',
      'daw_track_vocals': 'Pista 3 - Voz Principal',
      'daw_track_drums': 'Pista 4 - Bateria & Beat',
      'daw_empty_track': 'Pista vazia (Toque em REC para gravar)',
      'daw_recorded_track': 'Áudio gravado pronto para mix',
      'daw_no_tracks_to_export': 'Grave ou adicione áudio em ao menos uma pista para exportar',
      'daw_clear_all': 'Limpar Projeto',
      'daw_time_format': 'Tempo: ',

      // Módulo Aulas Interativas
      'lessons_title': 'Aulas & Prática Inteligente',
      'lessons_subtitle': 'Aprenda acordes, dedilhados e escalas com detecção de áudio em tempo real',
      'lesson_category_guitar': 'Violão para Iniciantes',
      'lesson_category_keyboard': 'Teclado para Iniciantes',
      'lesson_chords_title': 'Aula 1: Primeiros Acordes (Dó Maior, Sol, Ré)',
      'lesson_fingerpicking_title': 'Aula 2: Dedilhado Padrão P-I-M-A',
      'lesson_scales_title': 'Aula 3: Escala Pentatônica & Levadas Pop',
      'lesson_listen_mic': 'Ouvindo Microfone...',
      'lesson_mic_permission_needed': 'Permissão de microfone necessária para detecção de pitch',
      'lesson_note_correct': '🎉 Nota Correta! Excelente afinação!',
      'lesson_note_sharp': 'Afinação alta (Sharp) ⬆️',
      'lesson_note_flat': 'Afinação baixa (Flat) ⬇️',
      'lesson_listening_prompt': 'Toque a nota no seu instrumento real ou no teclado virtual abaixo',
      'lesson_target_note': 'Nota Alvo',
      'lesson_detected_note': 'Nota Detectada',
      'lesson_frequency': 'Frequência',
      'lesson_accuracy': 'Precisão',
      'lesson_record_in_studio_btn': '🎙️ Gravar esta levada no Estúdio',
      'lesson_virtual_piano': 'Teclado Virtual Interativo (Toque para tocar)',
      'lesson_next_step': 'Próxima Nota / Acorde',
      'lesson_completed': 'Parabéns! Você completou este exercício com sucesso!',
      'lesson_start_mic': 'Ativar Afinador Inteligente',
      'lesson_stop_mic': 'Pausar Afinador',

      // Configurações
      'settings_title': 'Configurações & Perfil',
      'settings_user_logged': 'Usuário Conectado',
      'settings_audio_engine': 'Motor de Áudio',
      'settings_sample_rate': 'Taxa de Amostragem: 44.1 kHz / 16-bit PCM',
      'settings_buffer_size': 'Latência de Áudio: Baixa (Modo Estúdio)',
      'settings_dark_mode': 'Tema Escuro DAW (Ativo)',
      'settings_about': 'Sobre o Harmonia Studio v1.0.0',
    },
    'en': {
      // App & General
      'app_name': 'Harmonia Studio',
      'app_tagline': 'Multi-track DAW & Interactive Music Education',
      'cancel': 'Cancel',
      'save': 'Save',
      'confirm': 'Confirm',
      'close': 'Close',
      'delete': 'Delete',
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'language': 'Language',
      'portuguese': 'Português (Brasil)',
      'english': 'English (US)',
      'spanish': 'Español',

      // Auth
      'login_title': 'Welcome to Harmonia Studio',
      'login_subtitle': 'Sign in to access your DAW tracks and interactive lessons',
      'username': 'Username',
      'password': 'Password',
      'login_button': 'Sign In',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'invalid_credentials': 'Invalid username or password (default: admin / 123456)',
      'password_changed_success': 'Password changed successfully!',
      'password_mismatch': 'New password and confirmation do not match',
      'password_too_short': 'New password must be at least 6 characters long',
      'logout': 'Sign Out',

      // Navigation
      'nav_studio': 'DAW Studio',
      'nav_lessons': 'Interactive Lessons',
      'nav_settings': 'Settings',

      // DAW Module
      'daw_title': 'DAW Recording Studio',
      'daw_bpm': 'BPM',
      'daw_metronome': 'Metronome',
      'daw_play': 'Play',
      'daw_stop': 'Stop',
      'daw_rec': 'Record (REC)',
      'daw_master_rec': 'Master Record',
      'daw_recording': 'RECORDING...',
      'daw_playing': 'PLAYING...',
      'daw_stopped': 'STOPPED',
      'daw_tracks': 'Tracks',
      'daw_add_track': 'Add Track',
      'daw_export_mixdown': 'Export Mixdown',
      'daw_exporting': 'Rendering Mixdown...',
      'daw_export_success': 'Stereo mixdown exported successfully!',
      'daw_share_audio': 'Share Audio',
      'daw_volume': 'Volume',
      'daw_mute': 'Mute (M)',
      'daw_solo': 'Solo (S)',
      'daw_arm_rec': 'Arm REC',
      'daw_track_guitar': 'Track 1 - Acoustic Guitar',
      'daw_track_piano': 'Track 2 - Piano / Synth',
      'daw_track_vocals': 'Track 3 - Lead Vocals',
      'daw_track_drums': 'Track 4 - Drums & Beat',
      'daw_empty_track': 'Empty track (Tap REC to record)',
      'daw_recorded_track': 'Recorded audio ready for mixdown',
      'daw_no_tracks_to_export': 'Record audio on at least one track to export',
      'daw_clear_all': 'Clear Project',
      'daw_time_format': 'Time: ',

      // Interactive Lessons
      'lessons_title': 'Lessons & Smart Practice',
      'lessons_subtitle': 'Learn chords, fingerpicking, and scales with real-time audio pitch detection',
      'lesson_category_guitar': 'Guitar for Beginners',
      'lesson_category_keyboard': 'Keyboard for Beginners',
      'lesson_chords_title': 'Lesson 1: First Essential Chords (C, G, D, Am, Em)',
      'lesson_fingerpicking_title': 'Lesson 2: Standard Fingerpicking P-I-M-A',
      'lesson_scales_title': 'Lesson 3: Pentatonic Scale & Pop Grooves',
      'lesson_listen_mic': 'Listening to Microphone...',
      'lesson_mic_permission_needed': 'Microphone permission required for pitch detection',
      'lesson_note_correct': '🎉 Correct Note! Perfect pitch!',
      'lesson_note_sharp': 'Pitch too sharp ⬆️',
      'lesson_note_flat': 'Pitch too flat ⬇️',
      'lesson_listening_prompt': 'Play the note on your real instrument or the virtual keyboard below',
      'lesson_target_note': 'Target Note',
      'lesson_detected_note': 'Detected Note',
      'lesson_frequency': 'Frequency',
      'lesson_accuracy': 'Accuracy',
      'lesson_record_in_studio_btn': '🎙️ Record this groove in DAW Studio',
      'lesson_virtual_piano': 'Interactive Virtual Keyboard (Touch to play)',
      'lesson_next_step': 'Next Note / Chord',
      'lesson_completed': 'Congratulations! You mastered this exercise!',
      'lesson_start_mic': 'Start Smart Tuner',
      'lesson_stop_mic': 'Pause Tuner',

      // Settings
      'settings_title': 'Settings & Profile',
      'settings_user_logged': 'Logged in as',
      'settings_audio_engine': 'Audio Engine',
      'settings_sample_rate': 'Sample Rate: 44.1 kHz / 16-bit PCM',
      'settings_buffer_size': 'Audio Latency: Low Latency DAW Mode',
      'settings_dark_mode': 'DAW Dark Theme (Active)',
      'settings_about': 'About Harmonia Studio v1.0.0',
    },
    'es': {
      // App & General
      'app_name': 'Harmonia Studio',
      'app_tagline': 'DAW Multi-pistas y Lecciones Interactivas de Música',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'confirm': 'Confirmar',
      'close': 'Cerrar',
      'delete': 'Eliminar',
      'error': 'Error',
      'success': 'Éxito',
      'loading': 'Cargando...',
      'language': 'Idioma',
      'portuguese': 'Português (Brasil)',
      'english': 'English (US)',
      'spanish': 'Español',

      // Auth
      'login_title': 'Bienvenido a Harmonia Studio',
      'login_subtitle': 'Inicia sesión para acceder a tu DAW y lecciones interactivas',
      'username': 'Usuario',
      'password': 'Password',
      'login_button': 'Iniciar Sesión',
      'change_password': 'Cambiar Contraseña',
      'current_password': 'Contraseña Actual',
      'new_password': 'Nueva Contraseña',
      'confirm_new_password': 'Confirmar Nueva Contraseña',
      'invalid_credentials': 'Usuario o contraseña incorrectos (por defecto: admin / 123456)',
      'password_changed_success': '¡Contraseña cambiada con éxito!',
      'password_mismatch': 'La nueva contraseña y la confirmación no coinciden',
      'password_too_short': 'La contraseña debe tener al menos 6 caracteres',
      'logout': 'Cerrar Sesión',

      // Navigation
      'nav_studio': 'Estudio DAW',
      'nav_lessons': 'Lecciones',
      'nav_settings': 'Ajustes',

      // DAW Module
      'daw_title': 'Estudio de Grabación DAW',
      'daw_bpm': 'BPM',
      'daw_metronome': 'Metrónomo',
      'daw_play': 'Reproducir',
      'daw_stop': 'Detener',
      'daw_rec': 'Grabar (REC)',
      'daw_master_rec': 'Grabación Master',
      'daw_recording': 'GRABANDO...',
      'daw_playing': 'REPRODUCIENDO...',
      'daw_stopped': 'DETENIDO',
      'daw_tracks': 'Pistas',
      'daw_add_track': 'Añadir Pista',
      'daw_export_mixdown': 'Exportar Mixdown',
      'daw_exporting': 'Renderizando Mixdown...',
      'daw_export_success': '¡Mixdown estéreo exportado con éxito!',
      'daw_share_audio': 'Compartir Audio',
      'daw_volume': 'Volumen',
      'daw_mute': 'Mudo (M)',
      'daw_solo': 'Solo (S)',
      'daw_arm_rec': 'Armar REC',
      'daw_track_guitar': 'Pista 1 - Guitarra Acústica',
      'daw_track_piano': 'Pista 2 - Teclado / Sintetizador',
      'daw_track_vocals': 'Pista 3 - Voz Principal',
      'daw_track_drums': 'Pista 4 - Batería y Ritmo',
      'daw_empty_track': 'Pista vacía (Toca REC para grabar)',
      'daw_recorded_track': 'Audio grabado listo para mezcla',
      'daw_no_tracks_to_export': 'Graba audio en al menos una pista para exportar',
      'daw_clear_all': 'Limpiar Proyecto',
      'daw_time_format': 'Tiempo: ',

      // Interactive Lessons
      'lessons_title': 'Lecciones y Práctica Inteligente',
      'lessons_subtitle': 'Aprende acordes, arpegios y escalas con detección de audio en tiempo real',
      'lesson_category_guitar': 'Guitarra para Principiantes',
      'lesson_category_keyboard': 'Teclado para Principiantes',
      'lesson_chords_title': 'Lección 1: Primeros Acordes (Do, Sol, Re, Lam, Mim)',
      'lesson_fingerpicking_title': 'Lección 2: Arpegio Estándar P-I-M-A',
      'lesson_scales_title': 'Lección 3: Escala Pentatónica y Ritmos Pop',
      'lesson_listen_mic': 'Escuchando Micrófono...',
      'lesson_mic_permission_needed': 'Se necesita permiso de micrófono para la afinación',
      'lesson_note_correct': '🎉 ¡Nota Correcta! Excelente afinación!',
      'lesson_note_sharp': 'Afinación alta (Sostenido) ⬆️',
      'lesson_note_flat': 'Afinación baja (Bemol) ⬇️',
      'lesson_listening_prompt': 'Toca la nota en tu instrumento real o en el teclado virtual',
      'lesson_target_note': 'Nota Objetivo',
      'lesson_detected_note': 'Nota Detectada',
      'lesson_frequency': 'Frecuencia',
      'lesson_accuracy': 'Precisión',
      'lesson_record_in_studio_btn': '🎙️ Grabar este ritmo en el Estudio DAW',
      'lesson_virtual_piano': 'Teclado Virtual Interactivo (Toca para sonar)',
      'lesson_next_step': 'Siguiente Nota / Acorde',
      'lesson_completed': '¡Felicidades! ¡Has completado este ejercicio!',
      'lesson_start_mic': 'Iniciar Afinador Inteligente',
      'lesson_stop_mic': 'Pausar Afinador',

      // Settings
      'settings_title': 'Ajustes y Perfil',
      'settings_user_logged': 'Usuario Conectado',
      'settings_audio_engine': 'Motor de Audio',
      'settings_sample_rate': 'Muestreo: 44.1 kHz / 16-bit PCM',
      'settings_buffer_size': 'Latencia de Audio: Baja (Modo DAW)',
      'settings_dark_mode': 'Tema Oscuro DAW (Activo)',
      'settings_about': 'Acerca de Harmonia Studio v1.0.0',
    },
  };

  String translate(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['pt']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
