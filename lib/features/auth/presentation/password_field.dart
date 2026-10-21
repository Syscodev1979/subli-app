import 'package:flutter/material.dart';

/// Jelszómező láthatóság-kapcsolóval.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    this.validator,
    this.textInputAction = TextInputAction.done,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Jelszó mutatása' : 'Jelszó elrejtése',
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: widget.validator,
    );
  }
}
