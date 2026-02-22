import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_text_field.dart';

class PersonalInfoForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const PersonalInfoForm({
    super.key,
    required this.initialData,
    required this.onDataChanged,
  });

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dobController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.initialData['firstName'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.initialData['lastName'] ?? '',
    );
    _dobController = TextEditingController(
      text: widget.initialData['dateOfBirth'] != null
          ? DateFormat('MM/dd/yyyy').format(widget.initialData['dateOfBirth'])
          : '',
    );
    _selectedDate = widget.initialData['dateOfBirth'];

    _firstNameController.addListener(_notifyDataChanged);
    _lastNameController.addListener(_notifyDataChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    widget.onDataChanged({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'dateOfBirth': _selectedDate,
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final hundredTwentyYearsAgo = DateTime(now.year - 120, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: hundredTwentyYearsAgo,
      lastDate: eighteenYearsAgo,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
      _notifyDataChanged();
    }
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'First name must not exceed 50 characters';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Last name must not exceed 50 characters';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (_selectedDate == null) {
      return 'Date of birth is required';
    }

    final now = DateTime.now();
    final age = now.year - _selectedDate!.year;
    final hasHadBirthdayThisYear = now.month > _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day >= _selectedDate!.day);
    final actualAge = hasHadBirthdayThisYear ? age : age - 1;

    if (_selectedDate!.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }
    if (actualAge < 18) {
      return 'You must be at least 18 years old';
    }
    if (actualAge > 120) {
      return 'Invalid date of birth';
    }

    return null;
  }

  Map<String, String>? validate() {
    if (_formKey.currentState?.validate() ?? false) {
      return null;
    }

    final errors = <String, String>{};
    final firstNameError = _validateFirstName(_firstNameController.text);
    final lastNameError = _validateLastName(_lastNameController.text);
    final dobError = _validateDateOfBirth(_dobController.text);

    if (firstNameError != null) errors['firstName'] = firstNameError;
    if (lastNameError != null) errors['lastName'] = lastNameError;
    if (dobError != null) errors['dateOfBirth'] = dobError;

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
            'Personal Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A237E),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your basic personal details',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _firstNameController,
            label: 'First Name',
            hintText: 'Enter your first name',
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: _validateFirstName,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _lastNameController,
            label: 'Last Name',
            hintText: 'Enter your last name',
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: _validateLastName,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _dobController,
            label: 'Date of Birth',
            hintText: 'MM/DD/YYYY',
            prefixIcon: Icons.calendar_today,
            readOnly: true,
            validator: _validateDateOfBirth,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _selectDate(context),
            ),
            onChanged: (_) {},
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You must be at least 18 years old to register',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}