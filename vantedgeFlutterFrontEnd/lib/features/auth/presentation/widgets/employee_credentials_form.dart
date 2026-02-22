import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/password_field.dart';

class EmployeeCredentialsForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const EmployeeCredentialsForm({
    super.key,
    required this.initialData,
    required this.onDataChanged,
  });

  @override
  State<EmployeeCredentialsForm> createState() => EmployeeCredentialsFormState();
}

class EmployeeCredentialsFormState extends State<EmployeeCredentialsForm> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _branchCodeController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.initialData['username'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialData['email'] ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.initialData['password'] ?? '',
    );
    _confirmPasswordController = TextEditingController(
      text: widget.initialData['confirmPassword'] ?? '',
    );
    _branchCodeController = TextEditingController(
      text: widget.initialData['branchCode'] ?? '',
    );

    _usernameController.addListener(_notifyParent);
    _emailController.addListener(_notifyParent);
    _passwordController.addListener(_notifyParent);
    _confirmPasswordController.addListener(_notifyParent);
    _branchCodeController.addListener(_notifyParent);
  }

  void _notifyParent() {
    widget.onDataChanged({
      'username': _usernameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'branchCode': _branchCodeController.text,
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _branchCodeController.dispose();
    super.dispose();
  }

  Map<String, String>? validate() {
    Map<String, String> errors = {};

    if (_usernameController.text.trim().isEmpty) {
      errors['username'] = 'Username is required';
    } else if (_usernameController.text.trim().length < 4) {
      errors['username'] = 'Username must be at least 4 characters';
    }

    if (_emailController.text.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      errors['email'] = 'Please enter a valid email';
    }

    if (_passwordController.text.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (_passwordController.text.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }

    if (_confirmPasswordController.text != _passwordController.text) {
      errors['confirmPassword'] = 'Passwords do not match';
    }

    if (_branchCodeController.text.trim().isEmpty) {
      errors['branchCode'] = 'Branch code is required for employees';
    }

    return errors.isEmpty ? null : errors;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Username',
          hint: 'Choose a username',
          controller: _usernameController,
          prefixIcon: const Icon(Icons.person_outline),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Email',
          hint: 'Enter your email',
          controller: _emailController,
          prefixIcon: const Icon(Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Branch Code',
          hint: 'Enter your branch code',
          controller: _branchCodeController,
          prefixIcon: const Icon(Icons.business),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        PasswordField(
          label: 'Password',
          hint: 'Create a password',
          controller: _passwordController,
          showStrengthIndicator: true,
        ),
        const SizedBox(height: 16),
        PasswordField(
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          controller: _confirmPasswordController,
        ),
      ],
    );
  }
}