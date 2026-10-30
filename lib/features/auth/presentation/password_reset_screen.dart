import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_providers.dart';
import 'auth_error_message.dart';
import 'auth_frame.dart';
import 'auth_validators.dart';

/// Jelszó-visszaállító levél. Nem árulja el, hogy a cím létezik-e.
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  var _submitting = false;
  String? _message;
  var _messageIsError = true;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_emailController.text);
      if (mounted) _showSent();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'user-not-found') {
        _showSent();
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

  void _showSent() {
    setState(() {
      _messageIsError = false;
      _message =
          'Ha az e-mail-cím szerepel a rendszerben, elküldtük a visszaállító levelet.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthFrame(
      title: 'Elfelejtett jelszó',
      subtitle: 'A visszaállító levelet erre a címre küldjük.',
      onBack: _submitting ? null : () => context.pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('reset-email'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: validateEmail,
              onFieldSubmitted: (_) => _send(),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
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
            AuthPrimaryButton(
              label: 'Visszaállító e-mail küldése',
              busy: _submitting,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
