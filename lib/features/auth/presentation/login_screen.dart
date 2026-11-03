import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/club_config.dart';
import '../../../app/constants.dart';
import '../../../app/emulator.dart';
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
    if (ref.read(emulatorOfflineProvider)) {
      setState(() => _message = emulatorOfflineMessage);
      return;
    }
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
    final offline = ref.watch(emulatorOfflineProvider);
    final notice = offline ? emulatorOfflineMessage : _message;
    return AuthFrame(
      screenKey: const Key('login-screen'),
      heading: const LoginHeading(),
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
              if (notice != null) ...[
                const SizedBox(height: 12),
                ErrorNotice(notice),
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
              const LoginCredit(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A logó alatti cím és a támogatói sor. Null értékű sor nem jelenik meg.
class LoginHeading extends StatelessWidget {
  const LoginHeading({
    this.title = ClubConfig.loginTitle,
    this.sponsorText = ClubConfig.loginSponsorText,
    this.sponsorUrl = ClubConfig.loginSponsorUrl,
    super.key,
  });

  final String? title;
  final String? sponsorText;
  final String? sponsorUrl;

  @override
  Widget build(BuildContext context) {
    final titleText = _present(title);
    final sponsor = _present(sponsorText);
    if (titleText == null && sponsor == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      children: [
        if (titleText != null)
          Text(
            titleText,
            key: const Key('login-title'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        if (titleText != null && sponsor != null) const SizedBox(height: 4),
        if (sponsor != null)
          LoginSponsorLine(text: sponsor, url: _present(sponsorUrl)),
      ],
    );
  }
}

/// A regisztráció alatti kredit. Null esetén üres.
class LoginCredit extends StatelessWidget {
  const LoginCredit({this.text = ClubConfig.loginCredit, super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final credit = _present(text);
    if (credit == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        credit,
        key: const Key('login-credit'),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(color: _muted(theme)),
      ),
    );
  }
}

/// A támogatói mondat. A webcím hosztneve, ha benne van a szövegben, link.
class LoginSponsorLine extends StatelessWidget {
  const LoginSponsorLine({required this.text, this.url, super.key});

  final String text;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: _muted(theme));
    final linkStyle = muted?.copyWith(color: AppColors.primary);
    final host = _linkLabel(text, url);
    if (host == null || url == null) {
      return Text(
        text,
        key: const Key('login-sponsor'),
        textAlign: TextAlign.center,
        style: muted,
      );
    }
    final index = text.indexOf(host);
    final before = index < 0 ? '' : text.substring(0, index);
    final after = index < 0 ? '' : text.substring(index + host.length);
    final linked = index < 0 ? text : host;
    return Text.rich(
      TextSpan(
        style: muted,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              key: const Key('login-sponsor-link'),
              onTap: () => _openSponsor(url!),
              child: Text(linked, style: linkStyle),
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      key: const Key('login-sponsor'),
      textAlign: TextAlign.center,
    );
  }
}

String? _present(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value;
}

/// Halvány felirat. A téma `onSurfaceVariant` színe, ha az külön van
/// megadva, különben a szövegszín halványítva.
Color _muted(ThemeData theme) {
  final scheme = theme.colorScheme;
  final variant = scheme.onSurfaceVariant;
  if (variant != scheme.onSurface) return variant;
  return scheme.onSurface.withValues(alpha: 0.62);
}

/// A linkként jelölt rész: a cím hosztneve, ha a mondat tartalmazza.
String? _linkLabel(String text, String? url) {
  if (url == null) return null;
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return text;
  if (text.contains(host)) return host;
  return text;
}

Future<void> _openSponsor(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
