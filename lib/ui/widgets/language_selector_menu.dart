import 'package:flutter/material.dart';
import '../../l10n/language_provider.dart';
import '../../theme/app_theme.dart';

class LanguageSelectorMenu extends StatelessWidget {
  final LanguageProvider languageProvider;

  const LanguageSelectorMenu({super.key, required this.languageProvider});

  @override
  Widget build(BuildContext context) {
    final currentCode = languageProvider.currentLocale.languageCode;

    String currentFlag = '🇧🇷';
    String currentLabel = 'PT';
    if (currentCode == 'en') {
      currentFlag = '🇺🇸';
      currentLabel = 'EN';
    } else if (currentCode == 'es') {
      currentFlag = '🇪🇸';
      currentLabel = 'ES';
    }

    return PopupMenuButton<String>(
      tooltip: 'Alterar Idioma / Change Language',
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.dividerColor),
      ),
      offset: const Offset(0, 45),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentFlag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              currentLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
      onSelected: (String langCode) {
        languageProvider.setLanguage(langCode);
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'pt',
          child: Row(
            children: [
              Text('🇧🇷', style: TextStyle(fontSize: 18)),
              SizedBox(width: 12),
              Text('Português (Brasil)', style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              Text('🇺🇸', style: TextStyle(fontSize: 18)),
              SizedBox(width: 12),
              Text('English (US)', style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'es',
          child: Row(
            children: [
              Text('🇪🇸', style: TextStyle(fontSize: 18)),
              SizedBox(width: 12),
              Text('Español', style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
