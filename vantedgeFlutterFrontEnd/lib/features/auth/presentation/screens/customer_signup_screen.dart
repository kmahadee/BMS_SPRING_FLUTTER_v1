import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/auth/data/dto/customer_registration_dto.dart';
import 'package:vantedge/features/auth/presentation/screens/employee_signup_screen.dart';
import 'package:vantedge/features/auth/presentation/widgets/personal_info_form.dart';
import '../widgets/signup_step_indicator.dart';
import '../widgets/contact_info_form.dart';
import '../widgets/credentials_form.dart';
import '../widgets/custom_button.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  final Map<String, dynamic> _formData = {
    'firstName': '',
    'lastName': '',
    'dateOfBirth': null,
    'email': '',
    'phone': '',
    'address': '',
    'city': '',
    'state': '',
    'zipCode': '',
    'username': '',
    'password': '',
    'confirmPassword': '',
  };

  final GlobalKey<State<PersonalInfoForm>> _personalFormKey = GlobalKey();
  final GlobalKey<State<ContactInfoForm>> _contactFormKey = GlobalKey();
  final GlobalKey<State<CredentialsForm>> _credentialsFormKey = GlobalKey();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    bool isValid = false;
    
    // Validate current step
    if (_currentStep == 0) {
      final personalState = _personalFormKey.currentState as dynamic;
      final errors = personalState?.validate() as Map<String, String>?;
      isValid = errors == null || errors.isEmpty;
      if (!isValid && errors.isNotEmpty) {
        _showErrorSnackBar(errors.values.first);
        return;
      }
    } else if (_currentStep == 1) {
      final contactState = _contactFormKey.currentState as dynamic;
      final errors = contactState?.validate() as Map<String, String>?;
      isValid = errors == null || errors.isEmpty;
      if (!isValid && errors.isNotEmpty) {
        _showErrorSnackBar(errors.values.first);
        return;
      }
    } else if (_currentStep == 2) {
      final credentialsState = _credentialsFormKey.currentState as dynamic;
      final errors = credentialsState?.validate() as Map<String, String>?;
      isValid = errors == null || errors.isEmpty;
      if (!isValid && errors.isNotEmpty) {
        _showErrorSnackBar(errors.values.first);
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  GlobalKey? _getCurrentFormKey() {
    switch (_currentStep) {
      case 0:
        return _personalFormKey;
      case 1:
        return _contactFormKey;
      case 2:
        return _credentialsFormKey;
      default:
        return null;
    }
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_formData['dateOfBirth'] == null) {
        _showErrorSnackBar('Please select your date of birth');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final registrationDto = CustomerRegistrationDTO(
        firstName: _formData['firstName'].toString().trim(),
        lastName: _formData['lastName'].toString().trim(),
        email: _formData['email'].toString().trim(),
        phone: _formData['phone'].toString().trim(),
        dateOfBirth: (_formData['dateOfBirth'] as DateTime)
            .toIso8601String()
            .split('T')[0], // Format as YYYY-MM-DD
        address: _formData['address'].toString().trim(),
        city: _formData['city'].toString().trim(),
        state: _formData['state'].toString().trim(),
        zipCode: _formData['zipCode'].toString().trim(),
        username: _formData['username'].toString().trim(),
        password: _formData['password'].toString(),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Use registerCustomer() instead of register()
      final success = await authProvider.registerCustomer(registrationDto);

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(
          authProvider.errorMessage ?? 'Registration failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 40,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registration Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your account has been created successfully. Please login to continue.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Go to Login',
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to login
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEmployeeSignup() {
    // Navigate to employee signup screen
    // Navigator.pushReplacementNamed(context, '/employee-signup');
    
    // Or if you want to use Navigator.push with a route:
    // Navigator.pushReplacement(
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployeeSignupScreen(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _previousStep,
        ),
        title: const Text(
          'Customer Signup',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // Employee signup button in app bar
          TextButton.icon(
            onPressed: _navigateToEmployeeSignup,
            icon: const Icon(
              Icons.business_center,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Employee',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Account type banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF1A237E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Creating Customer Account',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'For personal banking services',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _navigateToEmployeeSignup,
                    child: const Text('Switch to Employee'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Container(
              color: Colors.white,
              child: SignupStepIndicator(
                currentStep: _currentStep,
                totalSteps: 3,
                stepLabels: const ['Personal', 'Contact', 'Credentials'],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStepPage(
                    PersonalInfoForm(
                      key: _personalFormKey,
                      initialData: _formData,
                      onDataChanged: (data) {
                        setState(() {
                          _formData.addAll(data);
                        });
                      },
                    ),
                  ),
                  _buildStepPage(
                    ContactInfoForm(
                      key: _contactFormKey,
                      initialData: _formData,
                      onDataChanged: (data) {
                        setState(() {
                          _formData.addAll(data);
                        });
                      },
                    ),
                  ),
                  _buildStepPage(
                    CredentialsForm(
                      key: _credentialsFormKey,
                      initialData: _formData,
                      onDataChanged: (data) {
                        setState(() {
                          _formData.addAll(data);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPage(Widget form) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: form,
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Back',
                onPressed: _previousStep,
                isOutlined: true,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: CustomButton(
              text: _currentStep == 2 ? 'Create Account' : 'Next',
              icon: _currentStep == 2 ? Icons.check : Icons.arrow_forward,
              onPressed: _nextStep,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }
}