import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../features/auth/presentation/auth_theme.dart';

/// Reusable password field with optional eye toggle and standard styling.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool showToggle;
  final bool autofocus;

  const PasswordField({
    required this.controller,
    required this.label,
    this.validator,
    this.showToggle = true,
    this.autofocus = false,
    super.key,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: modernInput(widget.label).copyWith(
        suffixIcon: widget.showToggle
            ? IconButton(
                icon: Icon(obscure ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye, color: Colors.orange),
                onPressed: () => setState(() => obscure = !obscure),
              )
            : null,
      ),
      obscureText: obscure,
      enableSuggestions: false,
      autocorrect: false,
      autofocus: widget.autofocus,
      validator: widget.validator,
    );
  }
}
