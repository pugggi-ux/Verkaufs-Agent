import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registrieren = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Verkaufs-Agent',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Behalten oder verkaufen? Entscheide per Swipe.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-Mail'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Passwort'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                if (auth.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      auth.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                FilledButton(
                  onPressed: auth.loading
                      ? null
                      : () async {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;
                          final ok = _registrieren
                              ? await auth.signUp(email, password)
                              : await auth.signIn(email, password);
                          if (!context.mounted) return;
                          if (ok && _registrieren) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Konto erstellt. Falls Bestätigung nötig: E-Mail prüfen und danach einloggen.'),
                              ),
                            );
                          }
                        },
                  child: auth.loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_registrieren ? 'Registrieren' : 'Einloggen'),
                ),
                TextButton(
                  onPressed: () => setState(() => _registrieren = !_registrieren),
                  child: Text(_registrieren
                      ? 'Schon ein Konto? Einloggen'
                      : 'Noch kein Konto? Registrieren'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
