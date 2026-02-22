import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_text_field.dart';

class ContactInfoForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ContactInfoForm({
    super.key,
    required this.initialData,
    required this.onDataChanged,
  });

  @override
  State<ContactInfoForm> createState() => _ContactInfoFormState();
}

class _ContactInfoFormState extends State<ContactInfoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialData['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialData['phone'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialData['address'] ?? '',
    );
    _cityController = TextEditingController(
      text: widget.initialData['city'] ?? '',
    );
    _stateController = TextEditingController(
      text: widget.initialData['state'] ?? '',
    );
    _zipCodeController = TextEditingController(
      text: widget.initialData['zipCode'] ?? '',
    );

    _emailController.addListener(_notifyDataChanged);
    _phoneController.addListener(_notifyDataChanged);
    _addressController.addListener(_notifyDataChanged);
    _cityController.addListener(_notifyDataChanged);
    _stateController.addListener(_notifyDataChanged);
    _zipCodeController.addListener(_notifyDataChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    widget.onDataChanged({
      'email': _emailController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'zipCode': _zipCodeController.text,
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      return 'Invalid phone format (use +1234567890)';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length > 255) {
      return 'Address must not exceed 255 characters';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length > 50) {
      return 'City must not exceed 50 characters';
    }
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    if (value.trim().length > 50) {
      return 'State must not exceed 50 characters';
    }
    return null;
  }

  String? _validateZipCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Zip code is required';
    }
    final zipRegex = RegExp(r'^\d{3,10}$');
    if (!zipRegex.hasMatch(value.trim())) {
      return 'Zip code must be 3-10 digits';
    }
    return null;
  }

  Map<String, String>? validate() {
    if (_formKey.currentState?.validate() ?? false) {
      return null;
    }

    final errors = <String, String>{};
    final emailError = _validateEmail(_emailController.text);
    final phoneError = _validatePhone(_phoneController.text);
    final addressError = _validateAddress(_addressController.text);
    final cityError = _validateCity(_cityController.text);
    final stateError = _validateState(_stateController.text);
    final zipError = _validateZipCode(_zipCodeController.text);

    if (emailError != null) errors['email'] = emailError;
    if (phoneError != null) errors['phone'] = phoneError;
    if (addressError != null) errors['address'] = addressError;
    if (cityError != null) errors['city'] = cityError;
    if (stateError != null) errors['state'] = stateError;
    if (zipError != null) errors['zipCode'] = zipError;

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
            'Contact Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your contact and address details',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hintText: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hintText: '+1234567890',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use international format: +1234567890',
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
            controller: _addressController,
            label: 'Street Address',
            hintText: '123 Main Street',
            prefixIcon: Icons.home_outlined,
            textCapitalization: TextCapitalization.words,
            validator: _validateAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cityController,
                  label: 'City',
                  hintText: 'New York',
                  prefixIcon: Icons.location_city_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateCity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _stateController,
                  label: 'State',
                  hintText: 'NY',
                  prefixIcon: Icons.map_outlined,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(2),
                    UpperCaseTextFormatter(),
                  ],
                  validator: _validateState,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _zipCodeController,
            label: 'Zip Code',
            hintText: '10001',
            prefixIcon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: _validateZipCode,
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}