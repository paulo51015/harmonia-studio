import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final AuthService authService;
  final LanguageProvider languageProvider;

  const SettingsScreen({
    super.key,
    required this.authService,
    required this.languageProvider,
  });

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final loc = AppLocalizations.of(context);

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Row(
                children: [
                  const Icon(Icons.lock_reset, color: AppTheme.cyan),
                  const SizedBox(width: 10),
                  Text(
                    loc.translate('change_password'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.recRed.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.recRed),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(color: AppTheme.recRed, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: oldPassController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.translate('current_password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPassController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.translate('new_password'),
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.translate('confirm_new_password'),
                        prefixIcon: const Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    loc.translate('cancel'),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final res = await authService.changePassword(
                      oldPassController.text,
                      newPassController.text,
                      confirmPassController.text,
                    );

                    if (res.success) {
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.successGreen,
                            content: Text(
                              loc.translate('password_changed_success'),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                    } else {
                      setDialogState(() {
                        dialogError = loc.translate(res.messageKey ?? 'error');
                      });
                    }
                  },
                  child: Text(loc.translate('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = authService.currentUser;
    final currentLang = languageProvider.currentLocale.languageCode;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Cartão do Usuário
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.cyan.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppTheme.cyan, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Admin Producer',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user?.username ?? 'admin'} • ${user?.role ?? 'Producer'}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.cyan),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Idioma & Localização
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: AppTheme.cyan),
                  title: Text(loc.translate('language')),
                  subtitle: Text(
                    currentLang == 'en'
                        ? 'English (US)'
                        : (currentLang == 'es' ? 'Español' : 'Português (Brasil)'),
                  ),
                  trailing: DropdownButton<String>(
                    value: currentLang,
                    dropdownColor: AppTheme.surface,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'pt', child: Text('🇧🇷 PT')),
                      DropdownMenuItem(value: 'en', child: Text('🇺🇸 EN')),
                      DropdownMenuItem(value: 'es', child: Text('🇪🇸 ES')),
                    ],
                    onChanged: (val) {
                      if (val != null) languageProvider.setLanguage(val);
                    },
                  ),
                ),
                const Divider(height: 1, color: AppTheme.dividerColor),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppTheme.cyan),
                  title: Text(loc.translate('change_password')),
                  subtitle: const Text('Atualizar credenciais de acesso local'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showChangePasswordDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Especificações do Motor de Áudio DAW
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.developer_board, color: AppTheme.cyan, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Motor de Áudio & Configurações DAW',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _specRow(Icons.graphic_eq, 'Taxa de Amostragem', '44.1 kHz / 16-bit PCM'),
                  const SizedBox(height: 8),
                  _specRow(Icons.speed, 'Latência do Buffer', 'Modo Baixa Latência (DAW)'),
                  const SizedBox(height: 8),
                  _specRow(Icons.waves, 'Algoritmo de Pitch', 'YIN & FFT com autocorrelação'),
                  const SizedBox(height: 8),
                  _specRow(Icons.brush, 'Tema da Interface', 'Harmonia Dark DAW (#121212)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Botão de Logout
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              foregroundColor: AppTheme.recRed,
              side: const BorderSide(color: AppTheme.recRed),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => authService.logout(),
            icon: const Icon(Icons.logout, size: 18, color: AppTheme.recRed),
            label: Text(
              loc.translate('logout'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }
}
