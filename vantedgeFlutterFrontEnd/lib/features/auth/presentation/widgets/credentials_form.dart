import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/custom_text_field.dart';

class CredentialsForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const CredentialsForm({
    super.key,
    required this.initialData,
    required this.onDataChanged,
  });

  @override
  State<CredentialsForm> createState() => _CredentialsFormState();
}

class _CredentialsFormState extends State<CredentialsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _selectedImage;
  String? _imageBase64;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.initialData['username'] ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.initialData['password'] ?? '',
    );
    _confirmPasswordController = TextEditingController(
      text: widget.initialData['confirmPassword'] ?? '',
    );
    _imageBase64 = widget.initialData['image'];

    _usernameController.addListener(_notifyDataChanged);
    _passwordController.addListener(() {
      _checkPasswordStrength(_passwordController.text);
      _notifyDataChanged();
    });
    _confirmPasswordController.addListener(_notifyDataChanged);

    if (_passwordController.text.isNotEmpty) {
      _checkPasswordStrength(_passwordController.text);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    widget.onDataChanged({
      'username': _usernameController.text,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'image': _imageBase64,
    });
  }

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() => _passwordStrength = PasswordStrength.weak);
      return;
    }

    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    setState(() {
      if (score <= 2) {
        _passwordStrength = PasswordStrength.weak;
      } else if (score <= 4) {
        _passwordStrength = PasswordStrength.medium;
      } else {
        _passwordStrength = PasswordStrength.strong;
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // TODO: Convert to base64 if needed
        // final bytes = await _selectedImage!.readAsBytes();
        // _imageBase64 = base64Encode(bytes);
        _notifyDataChanged();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 4) {
      return 'Username must be at least 4 characters';
    }
    if (value.trim().length > 50) {
      return 'Username must not exceed 50 characters';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9._]{4,50}$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, dots, and underscores';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Map<String, String>? validate() {
    if (_formKey.currentState?.validate() ?? false) {
      return null;
    }

    final errors = <String, String>{};
    final usernameError = _validateUsername(_usernameController.text);
    final passwordError = _validatePassword(_passwordController.text);
    final confirmError = _validateConfirmPassword(_confirmPasswordController.text);

    if (usernameError != null) errors['username'] = usernameError;
    if (passwordError != null) errors['password'] = passwordError;
    if (confirmError != null) errors['confirmPassword'] = confirmError;

    return errors.isEmpty ? null : errors;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Credentials',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your login credentials',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            hintText: 'Choose a unique username',
            prefixIcon: Icons.person_outline,
            validator: _validateUsername,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Letters, numbers, dots, and underscores only',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Create a strong password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildPasswordStrengthIndicator(),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            validator: _validateConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Profile Picture (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _buildImagePicker(),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _passwordStrength.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _passwordStrength.index >= 1
                      ? _passwordStrength.color
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _passwordStrength.index >= 2
                      ? _passwordStrength.color
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Password strength: ${_passwordStrength.label}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _passwordStrength.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getPasswordHint(),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getPasswordHint() {
    switch (_passwordStrength) {
      case PasswordStrength.weak:
        return 'Add uppercase, numbers, and special characters';
      case PasswordStrength.medium:
        return 'Good! Add more characters for better security';
      case PasswordStrength.strong:
        return 'Excellent! Your password is strong';
    }
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload profile picture',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum PasswordStrength {
  weak,
  medium,
  strong;

  Color get color {
    switch (this) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}