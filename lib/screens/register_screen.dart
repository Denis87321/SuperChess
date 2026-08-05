import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppStrings.of(context);
    if (_password.text != _confirm.text) {
      setState(() => _error = s.passwordsMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.register(
        username: _username.text.trim(),
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      setState(() {
        _error = switch (e.statusCode) {
          503 => s.authUnavailable,
          409 => s.usernameTaken,
          400 => e.message.contains('Username')
              ? s.usernameRules
              : s.passwordRules,
          _ => e.message,
        };
      });
    } catch (_) {
      setState(() => _error = s.connectFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.register,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              s.usernameRules,
              style: BalatroTheme.statusStyle.copyWith(
                fontSize: 12,
                color: BalatroTheme.cream.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _username,
              autofillHints: const [AutofillHints.newUsername],
              style: BalatroTheme.statusStyle,
              decoration: InputDecoration(
                labelText: s.username,
                labelStyle: BalatroTheme.statusStyle.copyWith(
                  color: BalatroTheme.cream.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: BalatroTheme.felt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              style: BalatroTheme.statusStyle,
              decoration: InputDecoration(
                labelText: s.password,
                labelStyle: BalatroTheme.statusStyle.copyWith(
                  color: BalatroTheme.cream.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: BalatroTheme.felt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: true,
              style: BalatroTheme.statusStyle,
              decoration: InputDecoration(
                labelText: s.passwordConfirm,
                labelStyle: BalatroTheme.statusStyle.copyWith(
                  color: BalatroTheme.cream.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: BalatroTheme.felt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (_) => _busy ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: BalatroTheme.statusStyle.copyWith(
                  color: const Color(0xFFE57373),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: BalatroTheme.gold,
                foregroundColor: BalatroTheme.felt,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      s.createAccount,
                      style: BalatroTheme.statusStyle.copyWith(
                        color: BalatroTheme.felt,
                      ),
                    ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => LoginScreen(auth: widget.auth),
                        ),
                      );
                    },
              child: Text(
                s.alreadyHaveAccount,
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 13,
                  color: BalatroTheme.gold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
