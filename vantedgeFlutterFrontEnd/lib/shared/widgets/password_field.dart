import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import 'custom_text_field.dart';

class PasswordField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool showStrengthIndicator;
  final bool showValidationRules;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;

  const PasswordField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.showStrengthIndicator = false,
    this.showValidationRules = false,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updatePasswordStrength);
    super.dispose();
  }

  void _updatePasswordStrength() {
    if (widget.showStrengthIndicator && widget.controller != null) {
      setState(() {
        _passwordStrength = Validators.getPasswordStrength(
          widget.controller!.text,
        );
      });
    }
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: widget.label ?? 'Password',
          hint: widget.hint,
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscureText,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            ),
            onPressed: _toggleVisibility,
            tooltip: _obscureText ? 'Show password' : 'Hide password',
          ),
        ),
        if (widget.showStrengthIndicator && widget.controller != null) ...[
          const SizedBox(height: 8),
          _PasswordStrengthIndicator(strength: _passwordStrength),
        ],
        if (widget.showValidationRules) ...[
          const SizedBox(height: 12),
          _PasswordValidationRules(
            password: widget.controller?.text ?? '',
          ),
        ],
      ],
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final int strength;

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final strengthLabels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final strengthColors = [
      colorScheme.error,
      Colors.orange,
      Colors.yellow.shade700,
      Colors.lightGreen,
      Colors.green,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < strength
                      ? strengthColors[strength]
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strength > 0 ? strengthLabels[strength - 1] : 'Enter password',
          style: theme.textTheme.bodySmall?.copyWith(
            color: strength > 0
                ? strengthColors[strength - 1]
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PasswordValidationRules extends StatelessWidget {
  final String password;

  const _PasswordValidationRules({required this.password});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final rules = [
      _ValidationRule(
        'At least 8 characters',
        password.length >= 8,
      ),
      _ValidationRule(
        'Contains uppercase letter',
        password.contains(RegExp(r'[A-Z]')),
      ),
      _ValidationRule(
        'Contains lowercase letter',
        password.contains(RegExp(r'[a-z]')),
      ),
      _ValidationRule(
        'Contains number',
        password.contains(RegExp(r'[0-9]')),
      ),
      _ValidationRule(
        'Contains special character',
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...rules.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      rule.isValid
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: rule.isValid
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rule.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: rule.isValid
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ValidationRule {
  final String text;
  final bool isValid;

  _ValidationRule(this.text, this.isValid);
}