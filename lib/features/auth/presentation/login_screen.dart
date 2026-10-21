import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../data/auth_providers.dart';
import 'auth_error_message.dart';
import 'auth_validators.dart';
import 'password_field.dart';

/// E-mail és jelszó belépés, valamint jelszó-visszaállító levél.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _submitting = false;
  String? _message;
  var _messageIsError = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _message = null;
      _messageIsError = true;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (validateEmail(email) != null) {
      setState(() {
        _message = 'Add meg az e-mail-címet a visszaállításhoz.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (mounted) _showResetSent();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      // Nem áruljuk el, hogy létezik-e a cím.
      if (error.code == 'user-not-found') {
        _showResetSent();
      } else {
        setState(() {
          _messageIsError = true;
          _message = authErrorMessage(error);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _messageIsError = true;
          _message = authErrorMessage(error);
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showResetSent() {
    setState(() {
      _messageIsError = false;
      _message = 'Ha az e-mail-cím szerepel a rendszerben, elküldtük a visszaállító levelet.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppInfo.clubName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bejelentkezés',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 12),
                    PasswordField(
                      controller: _passwordController,
                      label: 'Jelszó',
                      validator: validatePassword,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting ? null : _sendPasswordReset,
                        child: const Text('Elfelejtett jelszó'),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _messageIsError
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting ? null : _signIn,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Bejelentkezés'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => context.push(AppRoutes.register),
                      child: const Text('Nincs még fiókod? Regisztráció'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
