import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/auth/data/dto/user_registration_dto.dart';
import '../widgets/employee_credentials_form.dart';
import '../widgets/custom_button.dart';

class EmployeeSignupScreen extends StatefulWidget {
  const EmployeeSignupScreen({super.key});

  @override
  State<EmployeeSignupScreen> createState() => _EmployeeSignupScreenState();
}

class _EmployeeSignupScreenState extends State<EmployeeSignupScreen> {
  bool _isLoading = false;

  final Map<String, dynamic> _formData = {
    'username': '',
    'email': '',
    'password': '',
    'confirmPassword': '',
    'branchCode': '',
  };

  final GlobalKey<State<EmployeeCredentialsForm>> _credentialsFormKey = GlobalKey();

  Future<void> _submitRegistration() async {
    // Validate form
    final credentialsState = _credentialsFormKey.currentState as dynamic;
    final errors = credentialsState?.validate() as Map<String, String>?;
    
    if (errors != null && errors.isNotEmpty) {
      _showErrorSnackBar(errors.values.first);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user registration DTO for employee
      final registrationDto = UserRegistrationDTO.employee(
        username: _formData['username'].toString().trim(),
        password: _formData['password'].toString(),
        email: _formData['email'].toString().trim(),
        branchCode: _formData['branchCode'].toString().trim(),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Use registerEmployee() method which hits /auth/register endpoint
      final success = await authProvider.registerEmployee(registrationDto);

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
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pending_actions,
                size: 40,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registration Submitted!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your employee account registration has been submitted successfully. '
          'Please wait for admin approval before you can login.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Back to Login',
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

  void _navigateToCustomerSignup() {
    Navigator.pushReplacementNamed(context, '/customer-signup');
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Employee Signup',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _navigateToCustomerSignup,
            icon: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
            label: const Text(
              'Customer',
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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business_center,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Creating Employee Account',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Requires admin approval',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _navigateToCustomerSignup,
                    child: const Text('Switch to Customer'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Info banner
            Container(
              color: Colors.orange[50],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.orange[800],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Simplified registration for bank employees. Full profile setup after approval.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: EmployeeCredentialsForm(
                  key: _credentialsFormKey,
                  initialData: _formData,
                  onDataChanged: (data) {
                    setState(() {
                      _formData.addAll(data);
                    });
                  },
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
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
      child: CustomButton(
        text: 'Submit for Approval',
        icon: Icons.send,
        onPressed: _submitRegistration,
        isLoading: _isLoading,
      ),
    );
  }
}