import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/language_selector_menu.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final LanguageProvider languageProvider;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.languageProvider,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      final loc = AppLocalizations.of(context);
      setState(() {
        _isLoading = false;
        _errorMessage = loc.translate('invalid_credentials');
      });
    }
  }

  void _showChangePasswordDialog() {
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
                    final res = await widget.authService.changePassword(
                      oldPassController.text,
                      newPassController.text,
                      confirmPassController.text,
                    );

                    if (!mounted) return;

                    if (res.success) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.successGreen,
                          content: Text(
                            loc.translate('password_changed_success'),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LanguageSelectorMenu(languageProvider: widget.languageProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo e Ícone Estilizado do Harmonia Studio
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surface,
                        border: Border.all(color: AppTheme.cyan.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.cyan.withOpacity(0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.graphic_eq,
                        color: AppTheme.cyan,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título e Subtítulo
                  Text(
                    loc.translate('app_name'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.translate('login_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mensagem de Erro
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.recRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.recRed),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.recRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.recRed, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Campo Usuário
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: loc.translate('username'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Senha
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: loc.translate('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botão de Login
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                          )
                        : Text(
                            loc.translate('login_button'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Botão Alterar Senha
                  TextButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.key, size: 18, color: AppTheme.cyan),
                    label: Text(
                      loc.translate('change_password'),
                      style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dica de credenciais padrão
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔑 Credenciais padrão: admin / 123456',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
