import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.instance.login(email: _emailC.text.trim(), password: _passC.text);
    } catch (e) {
      setState(() => _error = _prettyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _prettyError(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) return raw.substring(11);
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cloud_sync, size: 64),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Email is required.';
                      if (!s.contains('@')) return 'Enter a valid email.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passC,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) {
                      final s = (v ?? '');
                      if (s.isEmpty) return 'Password is required.';
                      if (s.length < 6) return 'Min 6 characters.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                    child: const Text('Create an account'),
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
