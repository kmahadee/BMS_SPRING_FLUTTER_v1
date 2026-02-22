import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantedge/core/routes/app_routes.dart';
import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';
import 'package:vantedge/features/auth/domain/entities/user_entity.dart';
import 'package:vantedge/features/auth/domain/entities/user_role.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _minDelayPassed = false;
  bool _navigated = false;
  
  // Debug flags
  bool _animationControllerInitialized = false;
  bool _widgetBuilt = false;
  String _buildLocation = '';

  @override
  void initState() {
    super.initState();
    print('🔷 [SplashScreen] initState started');
    _initializeAnimations();
    
    print('🔷 [SplashScreen] Setting 2-second delay');
    Future.delayed(const Duration(seconds: 2), () {
      print('🔷 [SplashScreen] 2-second delay completed');
      if (mounted) {
        print('🔷 [SplashScreen] Setting _minDelayPassed = true');
        setState(() {
          _minDelayPassed = true;
          print('🔷 [SplashScreen] State updated, _minDelayPassed = $_minDelayPassed');
        });
        print('🔷 [SplashScreen] Calling _tryNavigate from delay');
        _tryNavigate();
      } else {
        print('🔴 [SplashScreen] Widget not mounted after delay');
      }
    });
    
    print('🔷 [SplashScreen] initState completed');
  }

  void _initializeAnimations() {
    print('🔷 [SplashScreen] Initializing animations');
    try {
      _animationController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward();
      _animationControllerInitialized = true;
      print('✅ [SplashScreen] Animations initialized and started');
      
      // Add listener to track animation status
      _animationController.addStatusListener((status) {
        print('🔷 [SplashScreen] Animation status: $status');
      });
      
    } catch (e) {
      print('🔴 [SplashScreen] Error initializing animations: $e');
    }
  }

  void _tryNavigate() async {
    print('🔷 [SplashScreen] _tryNavigate called');
    print('  - _navigated: $_navigated');
    print('  - _minDelayPassed: $_minDelayPassed');
    
    if (_navigated) {
      print('🔷 [SplashScreen] Already navigated, returning');
      return;
    }
    if (!_minDelayPassed) {
      print('🔷 [SplashScreen] Minimum delay not passed, returning');
      return;
    }

    print('🔷 [SplashScreen] Getting AuthProvider');
    final authProvider = context.read<AuthProvider>();
    print('  - authProvider.isLoading: ${authProvider.isLoading}');
    print('  - authProvider.isAuthenticated: ${authProvider.isAuthenticated}');

    if (authProvider.isLoading) {
      print('🔷 [SplashScreen] AuthProvider still loading, waiting for next state change');
      return;
    }

    print('🔷 [SplashScreen] Conditions met, proceeding with navigation');
    _navigated = true;
    print('✅ [SplashScreen] Set _navigated = true');

    print('🔷 [SplashScreen] Getting SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
    print('  - hasCompletedOnboarding: $hasCompletedOnboarding');

    if (!mounted) {
      print('🔴 [SplashScreen] Widget not mounted before navigation');
      return;
    }

    if (!hasCompletedOnboarding) {
      print('🔷 [SplashScreen] Navigating to onboarding');
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    if (authProvider.isAuthenticated && authProvider.user != null) {
      print('🔷 [SplashScreen] User authenticated, navigating to home for role: ${authProvider.user!.role}');
      _navigateToHomeBasedOnRole(authProvider.user!);
    } else {
      print('🔷 [SplashScreen] Not authenticated, navigating to login');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _navigateToHomeBasedOnRole(UserEntity user) {
    String route;
    print('🔷 [SplashScreen] Navigating based on role: ${user.role}');
    switch (user.role) {
      case UserRole.customer:
        route = AppRoutes.customerHome;
        break;
      case UserRole.employee:
        route = AppRoutes.employeeHome;
        break;
      case UserRole.admin:
        route = AppRoutes.adminHome;
        break;
      case UserRole.branchManager:
        route = AppRoutes.branchManagerHome;
        break;
      case UserRole.loanOfficer:
        route = AppRoutes.loanOfficerHome;
        break;
      case UserRole.cardOfficer:
        route = AppRoutes.cardOfficerHome;
        break;
      case UserRole.superAdmin:
        route = AppRoutes.superAdminHome;
        break;
    }
    print('🔷 [SplashScreen] Route: $route');
    Navigator.pushReplacementNamed(context, route, arguments: user);
  }

  @override
  void dispose() {
    print('🔷 [SplashScreen] dispose called');
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔷 [SplashScreen] didChangeDependencies called');
    print('  - mounted: $mounted');
    print('  - _minDelayPassed: $_minDelayPassed');
    print('  - _navigated: $_navigated');
  }

  @override
  Widget build(BuildContext context) {
    _widgetBuilt = true;
    _buildLocation = 'Consumer builder';
    print('\n🔷 [SplashScreen] 🔨 BUILD METHOD CALLED 🔨');
    print('  - mounted: $mounted');
    print('  - _minDelayPassed: $_minDelayPassed');
    print('  - _navigated: $_navigated');
    print('  - AnimationController initialized: $_animationControllerInitialized');
    
    if (_animationController == null) {
      print('🔴 [SplashScreen] AnimationController is null!');
    } else {
      print('  - AnimationController.value: ${_animationController.value}');
      print('  - AnimationController.status: ${_animationController.status}');
    }

    // Listen to auth state changes reactively — no initState provider access
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('🔷 [SplashScreen] Consumer builder called');
        print('  - authProvider.isLoading: ${authProvider.isLoading}');
        print('  - authProvider.isAuthenticated: ${authProvider.isAuthenticated}');
        print('  - authProvider.user: ${authProvider.user?.email ?? 'null'}');
        
        if (_minDelayPassed && !_navigated && !authProvider.isLoading) {
          print('✅ [SplashScreen] Navigation conditions met in Consumer!');
          print('  Scheduling navigation in post-frame callback');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('🔷 [SplashScreen] Post-frame callback executing');
            _tryNavigate();
          });
        } else {
          print('🔷 [SplashScreen] Navigation conditions NOT met in Consumer:');
          print('  - _minDelayPassed: $_minDelayPassed (${!_minDelayPassed ? '❌' : '✅'})');
          print('  - !_navigated: ${!_navigated} (${_navigated ? '❌' : '✅'})');
          print('  - !authProvider.isLoading: ${!authProvider.isLoading} (${authProvider.isLoading ? '❌' : '✅'})');
        }
        
        return child!;
      },
      child: Scaffold(
        body: Builder(
          builder: (context) {
            print('🔷 [SplashScreen] Scaffold body builder called');
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A237E),
                    Color(0xFF0D47A1),
                    Color(0xFF01579B),
                  ],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              // print('🔷 [SplashScreen] AnimatedBuilder rebuilding, scale: ${_scaleAnimation.value}, fade: ${_fadeAnimation.value}');
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.account_balance,
                                  size: 60,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                const Text(
                                  'VantEdge',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your Banking Partner',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8),
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          // Add a debug text to verify content is rendering
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            child: Text(
                              'Debug: UI Rendering',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Center(
                          child: Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}