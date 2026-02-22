import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/auth/domain/entities/user_entity.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _biometricAvailable = false;

  // Debug tracking
  int _buildCount = 0;
  DateTime? _initTime;

  @override
  void initState() {
    super.initState();
    _initTime = DateTime.now();
    print('🔐 [LoginScreen] initState started at ${_initTime!.toIso8601String()}');
    
    print('🔐 [LoginScreen] Checking biometric availability');
    _checkBiometricAvailability();
    
    print('🔐 [LoginScreen] Loading remembered credentials');
    _loadRememberedCredentials();
    
    print('🔐 [LoginScreen] initState completed');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔐 [LoginScreen] didChangeDependencies called (build #$_buildCount)');
    
    // Check if AuthProvider is available
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('🔐 [LoginScreen] AuthProvider available in context');
      print('  - isLoading: ${authProvider.isLoading}');
      print('  - isAuthenticated: ${authProvider.isAuthenticated}');
      print('  - user: ${authProvider.user?.email ?? 'null'}');
      print('  - errorMessage: ${authProvider.errorMessage}');
    } catch (e) {
      print('🔐 [LoginScreen] ⚠️ AuthProvider NOT available in context: $e');
    }
  }

  @override
  void dispose() {
    print('🔐 [LoginScreen] dispose called');
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    print('🔐 [LoginScreen] _checkBiometricAvailability started');
    try {
      print('  - Checking canCheckBiometrics');
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('  - canCheckBiometrics: $canCheckBiometrics');
      
      print('  - Checking isDeviceSupported');
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      print('  - isDeviceSupported: $isDeviceSupported');
      
      final available = canCheckBiometrics && isDeviceSupported;
      print('  - Biometric available: $available');
      
      setState(() {
        _biometricAvailable = available;
      });
      print('✅ [LoginScreen] Biometric availability set to $_biometricAvailable');
    } catch (e) {
      print('❌ [LoginScreen] Error checking biometric availability: $e');
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  Future<void> _loadRememberedCredentials() async {
    print('🔐 [LoginScreen] _loadRememberedCredentials started');
    // TODO: Load from secure storage if remember me was checked
    // final storage = FlutterSecureStorage();
    // final savedUsername = await storage.read(key: 'remembered_username');
    // if (savedUsername != null) {
    //   print('  - Found saved username: $savedUsername');
    //   _usernameController.text = savedUsername;
    //   setState(() {
    //     _rememberMe = true;
    //   });
    //   print('✅ [LoginScreen] Loaded remembered credentials');
    // } else {
    //   print('  - No saved credentials found');
    // }
    print('  - No saved credentials found (TODO)');
    print('✅ [LoginScreen] _loadRememberedCredentials completed');
  }

  Future<void> _saveCredentials() async {
    print('🔐 [LoginScreen] _saveCredentials started (rememberMe: $_rememberMe)');
    if (_rememberMe) {
      print('  - Saving username: ${_usernameController.text}');
      // TODO: Save username to secure storage
      // final storage = FlutterSecureStorage();
      // await storage.write(key: 'remembered_username', value: _usernameController.text);
      print('✅ [LoginScreen] Credentials saved (TODO)');
    } else {
      print('  - Clearing saved credentials');
      // TODO: Clear saved credentials
      // final storage = FlutterSecureStorage();
      // await storage.delete(key: 'remembered_username');
      print('✅ [LoginScreen] Credentials cleared (TODO)');
    }
  }

  Future<void> _login() async {
    print('\n🔐 [LoginScreen] ===== LOGIN ATTEMPT STARTED =====');
    print('  - Username: ${_usernameController.text}');
    print('  - Password length: ${_passwordController.text.length} characters');
    print('  - Form valid: ${_formKey.currentState?.validate()}');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [LoginScreen] Form validation failed');
      return;
    }

    print('✅ [LoginScreen] Form validation passed');
    
    setState(() {
      _isLoading = true;
    });
    print('  - Loading state set to true');

    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authProvider = context.read<AuthProvider>();
    print('  - AuthProvider obtained from context');

    try {
      print('  - Calling authProvider.login()');
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      print('  - Login result: ${success ? 'SUCCESS' : 'FAILURE'}');

      if (!mounted) {
        print('⚠️ [LoginScreen] Widget not mounted after login attempt');
        return;
      }

      if (success) {
        print('✅ [LoginScreen] Login successful!');
        print('  - User: ${authProvider.user?.email}');
        print('  - Role: ${authProvider.user?.role}');
        print('  - Saving credentials...');
        await _saveCredentials();
        print('  - Navigating to home screen');
        _navigateToHome(authProvider.user!);
      } else {
        print('❌ [LoginScreen] Login failed');
        print('  - Error message: ${authProvider.errorMessage}');
        _showErrorSnackBar(
          authProvider.errorMessage ?? 'Login failed. Please try again.',
        );
        _passwordController.clear();
        print('  - Password cleared');
        _usernameFocusNode.requestFocus();
        print('  - Focus set to username field');
      }
    } catch (e, stackTrace) {
      print('❌ [LoginScreen] Exception during login: $e');
      print('  - Stack trace: $stackTrace');
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
        _passwordController.clear();
        _usernameFocusNode.requestFocus();
      }
    } finally {
      if (mounted) {
        print('  - Setting loading state to false');
        setState(() {
          _isLoading = false;
        });
      }
      print('🔐 [LoginScreen] ===== LOGIN ATTEMPT ENDED =====\n');
    }
  }

  Future<void> _biometricLogin() async {
    print('\n🔐 [LoginScreen] ===== BIOMETRIC LOGIN ATTEMPT =====');
    print('  - Biometric available: $_biometricAvailable');
    
    if (!_biometricAvailable) {
      print('❌ [LoginScreen] Biometric authentication not available');
      _showErrorSnackBar('Biometric authentication is not available.');
      return;
    }

    try {
      print('  - Requesting biometric authentication');
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to login to VantEdge',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      print('  - Authentication result: ${authenticated ? 'SUCCESS' : 'FAILURE'}');

      if (!authenticated) {
        print('  - User canceled or authentication failed');
        return;
      }

      print('✅ [LoginScreen] Biometric authentication successful');
      print('  - TODO: Get stored credentials from secure storage');
      _showErrorSnackBar(
        'Please login with username/password first and enable biometric login.',
      );
      
      // Future implementation:
      // final storage = FlutterSecureStorage();
      // final savedUsername = await storage.read(key: 'biometric_username');
      // final savedPassword = await storage.read(key: 'biometric_password');
      // 
      // if (savedUsername != null && savedPassword != null) {
      //   _usernameController.text = savedUsername;
      //   _passwordController.text = savedPassword;
      //   await _login();
      // }
    } catch (e, stackTrace) {
      print('❌ [LoginScreen] Biometric authentication error: $e');
      print('  - Stack trace: $stackTrace');
      _showErrorSnackBar('Biometric authentication failed.');
    }
    print('🔐 [LoginScreen] ===== BIOMETRIC LOGIN ENDED =====\n');
  }

  void _navigateToHome(UserEntity user) {
    print('\n🔐 [LoginScreen] ===== NAVIGATING TO HOME =====');
    print('  - User role: ${user.role}');
    
    String route;
    switch (user.role) {
      case UserRole.customer:
        route = AppRoutes.customerHome;
        print('  - Route: customerHome ($route)');
        break;
      case UserRole.employee:
        route = AppRoutes.employeeHome;
        print('  - Route: employeeHome ($route)');
        break;
      case UserRole.admin:
        route = AppRoutes.adminHome;
        print('  - Route: adminHome ($route)');
        break;
      case UserRole.branchManager:
        route = AppRoutes.branchManagerHome;
        print('  - Route: branchManagerHome ($route)');
        break;
      case UserRole.loanOfficer:
        route = AppRoutes.loanOfficerHome;
        print('  - Route: loanOfficerHome ($route)');
        break;
      case UserRole.cardOfficer:
        route = AppRoutes.cardOfficerHome;
        print('  - Route: cardOfficerHome ($route)');
        break;
      case UserRole.superAdmin:
        route = AppRoutes.superAdminHome;
        print('  - Route: superAdminHome ($route)');
        break;
    }
    
    print('  - Pushing replacement named route');
    Navigator.pushReplacementNamed(context, route, arguments: user);
    print('✅ [LoginScreen] Navigation called');
  }

  void _navigateToSignup() {
    print('🔐 [LoginScreen] Navigating to signup');
    Navigator.pushNamed(context, '/signup');
  }

  void _navigateToForgotPassword() {
    print('🔐 [LoginScreen] Navigating to forgot password');
    Navigator.pushNamed(context, '/forgot-password');
  }

  void _showErrorSnackBar(String message) {
    print('🔐 [LoginScreen] Showing error snackbar: "$message"');
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

  String? _validateUsername(String? value) {
    print('🔐 [LoginScreen] Validating username: "${value ?? 'null'}"');
    if (value == null || value.trim().isEmpty) {
      print('  - Validation failed: username is empty');
      return 'Username is required';
    }
    if (value.trim().length < 4) {
      print('  - Validation failed: username too short');
      return 'Username must be at least 4 characters';
    }
    print('  - Validation passed');
    return null;
  }

  String? _validatePassword(String? value) {
    print('🔐 [LoginScreen] Validating password (length: ${value?.length ?? 0})');
    if (value == null || value.isEmpty) {
      print('  - Validation failed: password is empty');
      return 'Password is required';
    }
    if (value.length < 6) {
      print('  - Validation failed: password too short');
      return 'Password must be at least 6 characters';
    }
    print('  - Validation passed');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final elapsed = _initTime != null 
        ? DateTime.now().difference(_initTime!).inMilliseconds 
        : 0;
    
    print('\n🔐 [LoginScreen] 🔨 BUILD METHOD CALLED (build #$_buildCount)');
    print('  - Time since init: ${elapsed}ms');
    print('  - Widget mounted: $mounted');
    print('  - isLoading: $_isLoading');
    print('  - biometricAvailable: $_biometricAvailable');
    print('  - rememberMe: $_rememberMe');
    print('  - obscurePassword: $_obscurePassword');
    print('  - username: "${_usernameController.text}"');
    print('  - password length: ${_passwordController.text.length}');

    final size = MediaQuery.of(context).size;
    print('  - Screen size: ${size.width} x ${size.height}');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    print('🔐 [LoginScreen] Building header');
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to your account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    print('🔐 [LoginScreen] Building login form');
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            label: 'Username',
            hintText: 'Enter your username',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.none,
            validator: _validateUsername,
            onSubmitted: (_) {
              print('🔐 [LoginScreen] Username field submitted');
              _passwordFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                print('🔐 [LoginScreen] Toggle password visibility: ${!_obscurePassword}');
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            onSubmitted: (_) {
              print('🔐 [LoginScreen] Password field submitted, triggering login');
              _login();
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        print('🔐 [LoginScreen] Remember me changed to: $value');
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _navigateToForgotPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Login',
            onPressed: _login,
            isLoading: _isLoading,
          ),
          if (_biometricAvailable) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Login with Biometrics',
              icon: Icons.fingerprint,
              onPressed: _biometricLogin,
              isOutlined: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    print('🔐 [LoginScreen] Building footer');
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            TextButton(
              onPressed: _navigateToSignup,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}