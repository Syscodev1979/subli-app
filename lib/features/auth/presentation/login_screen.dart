import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../data/auth_providers.dart';
import '../../../core/widgets/error_notice.dart';
import 'auth_error_message.dart';
import 'auth_frame.dart';
import 'auth_validators.dart';
import 'password_field.dart';

/// E-mail és jelszó belépés.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  var _submitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _message = null;
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

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      screenKey: const Key('login-screen'),
      title: AppInfo.clubName,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('login-email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: validateEmail,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              PasswordField(
                key: const Key('login-password'),
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: 'Jelszó',
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline),
                validator: validatePassword,
                onFieldSubmitted: (_) => _signIn(),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                ErrorNotice(_message!),
              ],
              const SizedBox(height: 16),
              AuthPrimaryButton(
                key: const Key('login-submit'),
                label: 'Belépés',
                busy: _submitting,
                onPressed: _signIn,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => context.push(AppRoutes.resetPassword),
                child: const Text('Elfelejtett jelszó?'),
              ),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => context.push(AppRoutes.register),
                child: const Text('Regisztráció'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
