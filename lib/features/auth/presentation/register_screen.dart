import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/club_config.dart';
import '../../../core/utils/hungarian_date.dart';
import '../data/auth_providers.dart';
import '../domain/age.dart';
import '../domain/child_request.dart';
import '../domain/registration_policy.dart';
import '../domain/user_role.dart';
import '../../../core/widgets/error_notice.dart';
import 'auth_error_message.dart';
import 'auth_frame.dart';
import 'auth_validators.dart';
import 'password_field.dart';

/// Regisztráció sportolóként vagy szülőként. A fiók mindig jóváhagyásra vár.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.debugBirthDate});

  /// A widgetteszt ezzel állít be születési dátumot a dátumválasztó nélkül.
  final DateTime? debugBirthDate;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

enum _RegistrationKind { athlete, parent, coach }

class _ChildDraft {
  _ChildDraft() : name = TextEditingController(), focus = FocusNode();

  final TextEditingController name;
  final FocusNode focus;
  DateTime? birthDate;

  void dispose() {
    name.dispose();
    focus.dispose();
  }
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _children = <_ChildDraft>[_ChildDraft()];

  _RegistrationKind _kind = _RegistrationKind.athlete;
  DateTime? _birthDate;
  var _acceptedPrivacy = false;
  var _submitting = false;
  String? _error;

  bool get _adultsOnly => ClubConfig.enforceAdultsOnly;

  @override
  void initState() {
    super.initState();
    _birthDate = widget.debugBirthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    for (final child in _children) {
      child.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 10, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Születési dátum',
      cancelText: 'Mégse',
      confirmText: 'Rendben',
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final formOk = _formKey.currentState?.validate() ?? false;
    final extraError = _extraError();
    if (!formOk || extraError != null) {
      setState(() => _error = extraError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final asParent = !_adultsOnly && _kind == _RegistrationKind.parent;
    try {
      await ref
          .read(accountRegistrarProvider)
          .register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            role: asParent ? UserRole.parent : UserRole.athlete,
            birthDate: asParent ? null : _birthDate,
            requestedRole: _kind == _RegistrationKind.coach ? 'coach' : null,
            childRequests: asParent
                ? [
                    for (final child in _children)
                      ChildRequest(
                        name: child.name.text.trim(),
                        birthDate: child.birthDate!,
                      ),
                  ]
                : const [],
          );
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _extraError() {
    if (_adultsOnly) {
      final ageError = adultsOnlyBirthDateError(_birthDate);
      if (ageError != null) return ageError;
    } else {
      if (_kind != _RegistrationKind.parent && _birthDate == null) {
        return 'A sportolónál a születési dátum kötelező.';
      }
      if (_kind == _RegistrationKind.parent) {
        for (final child in _children) {
          if (child.name.text.trim().isEmpty || child.birthDate == null) {
            return 'Minden gyermeknél add meg a nevet és a születési dátumot.';
          }
        }
      }
    }
    if (!_acceptedPrivacy) {
      return 'Az adatkezelési tájékoztató elfogadása kötelező.';
    }
    return null;
  }

  void _showPrivacyNotice() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adatkezelési tájékoztató'),
          content: const Text(
            'A tájékoztató szövege később kerül ide. A regisztrációhoz a jelölőnégyzet bejelölése kötelező. A klub a megadott adatokat a tagság és az edzések szervezéséhez használja.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bezárás'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final under18 =
        _kind == _RegistrationKind.athlete &&
        _birthDate != null &&
        isUnder18(_birthDate!);

    return AuthFrame(
      title: 'Regisztráció',
      onBack: _submitting ? null : () => context.pop(),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Teljes név',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: validateName,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
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
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: 'Jelszó',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: const Icon(Icons.lock_outline),
                validator: validatePassword,
                onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirmController,
                focusNode: _confirmFocus,
                label: 'Jelszó újra',
                textInputAction: _kind == _RegistrationKind.parent
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                prefixIcon: const Icon(Icons.lock_outline),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'A két jelszó nem egyezik.';
                  }
                  return validatePassword(value);
                },
                onFieldSubmitted: (_) {
                  if (_kind == _RegistrationKind.parent) {
                    _children.first.focus.requestFocus();
                  } else {
                    _submit();
                  }
                },
              ),
              const SizedBox(height: 16),
              Text('Ki vagy?', style: theme.textTheme.titleSmall),
              RadioGroup<_RegistrationKind>(
                groupValue: _kind,
                onChanged: (kind) {
                  if (_submitting || kind == null) return;
                  setState(() => _kind = kind);
                },
                child: Column(
                  children: [
                    const RadioListTile<_RegistrationKind>(
                      value: _RegistrationKind.athlete,
                      title: Text('Sportoló vagyok'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!_adultsOnly)
                      const RadioListTile<_RegistrationKind>(
                        value: _RegistrationKind.parent,
                        title: Text('Szülő vagyok'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    const RadioListTile<_RegistrationKind>(
                      value: _RegistrationKind.coach,
                      title: Text('Edző vagyok'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              if (_kind != _RegistrationKind.parent) ...[
                const SizedBox(height: 8),
                _DateField(
                  label: 'Születési dátum',
                  value: _birthDate,
                  onTap: _submitting
                      ? null
                      : () => _pickDate(
                          current: _birthDate,
                          onPicked: (date) => setState(() => _birthDate = date),
                        ),
                ),
                if (!_adultsOnly && under18)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Mivel még nem vagy 18 éves, a fiókot szülői jóváhagyás után aktiválja az edző.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
              if (!_adultsOnly && _kind == _RegistrationKind.parent) ...[
                const SizedBox(height: 8),
                Text('Gyermekek', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (var index = 0; index < _children.length; index++)
                  _ChildFields(
                    index: index,
                    draft: _children[index],
                    canRemove: _children.length > 1 && !_submitting,
                    isLast: index == _children.length - 1,
                    onSubmitted: () {
                      if (index == _children.length - 1) {
                        _submit();
                      } else {
                        _children[index + 1].focus.requestFocus();
                      }
                    },
                    onRemove: () {
                      setState(() {
                        _children.removeAt(index).dispose();
                      });
                    },
                    onPickDate: _submitting
                        ? null
                        : () => _pickDate(
                            current: _children[index].birthDate,
                            onPicked: (date) {
                              setState(() => _children[index].birthDate = date);
                            },
                          ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _children.add(_ChildDraft())),
                    icon: const Icon(Icons.add),
                    label: const Text('Gyermek hozzáadása'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _acceptedPrivacy,
                onChanged: _submitting
                    ? null
                    : (value) =>
                          setState(() => _acceptedPrivacy = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Elfogadom az adatkezelési tájékoztatót.'),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showPrivacyNotice,
                    child: const Text('Tájékoztató megnyitása'),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                ErrorNotice(_error!),
              ],
              const SizedBox(height: 16),
              AuthPrimaryButton(
                label: 'Regisztráció',
                busy: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null ? 'Válassz dátumot' : formatHungarianDate(value!),
        ),
      ),
    );
  }
}

class _ChildFields extends StatelessWidget {
  const _ChildFields({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.isLast,
    required this.onSubmitted,
    required this.onRemove,
    required this.onPickDate,
  });

  final int index;
  final _ChildDraft draft;
  final bool canRemove;
  final bool isLast;
  final VoidCallback onSubmitted;
  final VoidCallback onRemove;
  final VoidCallback? onPickDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. gyermek',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: 'Gyermek törlése',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          TextFormField(
            controller: draft.name,
            focusNode: draft.focus,
            textInputAction: isLast
                ? TextInputAction.done
                : TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Teljes név'),
            validator: validateName,
            onFieldSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 8),
          _DateField(
            label: 'Születési dátum',
            value: draft.birthDate,
            onTap: onPickDate,
          ),
        ],
      ),
    );
  }
}
