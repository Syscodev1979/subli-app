import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/hungarian_date.dart';
import '../data/auth_providers.dart';
import '../domain/age.dart';
import '../domain/child_request.dart';
import '../domain/user_role.dart';
import 'auth_error_message.dart';
import 'auth_validators.dart';
import 'password_field.dart';

/// Regisztráció sportolóként vagy szülőként. A fiók mindig jóváhagyásra vár.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _ChildDraft {
  _ChildDraft() : name = TextEditingController();

  final TextEditingController name;
  DateTime? birthDate;

  void dispose() => name.dispose();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _children = <_ChildDraft>[_ChildDraft()];

  UserRole _role = UserRole.athlete;
  DateTime? _birthDate;
  var _acceptedPrivacy = false;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
    try {
      await ref
          .read(accountRegistrarProvider)
          .register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            role: _role,
            birthDate: _role == UserRole.athlete ? _birthDate : null,
            childRequests: _role == UserRole.parent
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
    if (_role == UserRole.athlete && _birthDate == null) {
      return 'A sportolónál a születési dátum kötelező.';
    }
    if (_role == UserRole.parent) {
      for (final child in _children) {
        if (child.name.text.trim().isEmpty || child.birthDate == null) {
          return 'Minden gyermeknél add meg a nevet és a születési dátumot.';
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
    final under18 = _birthDate != null && isUnder18(_birthDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regisztráció'),
        leading: IconButton(
          tooltip: 'Vissza a bejelentkezéshez',
          onPressed: _submitting ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Teljes név',
                      ),
                      validator: validateName,
                    ),
                    const SizedBox(height: 12),
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
                      textInputAction: TextInputAction.next,
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 12),
                    PasswordField(
                      controller: _confirmController,
                      label: 'Jelszó újra',
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'A két jelszó nem egyezik.';
                        }
                        return validatePassword(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Ki vagy?', style: theme.textTheme.titleSmall),
                    RadioGroup<UserRole>(
                      groupValue: _role,
                      onChanged: (role) {
                        if (_submitting || role == null) return;
                        setState(() => _role = role);
                      },
                      child: const Column(
                        children: [
                          RadioListTile<UserRole>(
                            value: UserRole.athlete,
                            title: Text('Sportoló vagyok'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<UserRole>(
                            value: UserRole.parent,
                            title: Text('Szülő vagyok'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    if (_role == UserRole.athlete) ...[
                      const SizedBox(height: 8),
                      _DateField(
                        label: 'Születési dátum',
                        value: _birthDate,
                        onTap: _submitting
                            ? null
                            : () => _pickDate(
                                current: _birthDate,
                                onPicked: (date) =>
                                    setState(() => _birthDate = date),
                              ),
                      ),
                      if (under18)
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
                    if (_role == UserRole.parent) ...[
                      const SizedBox(height: 8),
                      Text('Gyermekek', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      for (var index = 0; index < _children.length; index++)
                        _ChildFields(
                          index: index,
                          draft: _children[index],
                          canRemove: _children.length > 1 && !_submitting,
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
                                    setState(
                                      () => _children[index].birthDate = date,
                                    );
                                  },
                                ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _submitting
                              ? null
                              : () => setState(
                                  () => _children.add(_ChildDraft()),
                                ),
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
                          : (value) => setState(
                              () => _acceptedPrivacy = value ?? false,
                            ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Elfogadom az adatkezelési tájékoztatót.',
                      ),
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
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Regisztráció'),
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
    required this.onRemove,
    required this.onPickDate,
  });

  final int index;
  final _ChildDraft draft;
  final bool canRemove;
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
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Teljes név'),
            validator: validateName,
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
