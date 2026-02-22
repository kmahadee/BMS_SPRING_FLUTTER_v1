// import 'package:flutter/material.dart';
// import 'package:vantedge/features/auth/presentation/screens/splash_screen.dart';
// import 'package:vantedge/features/auth/presentation/screens/onboarding_screen.dart';
// import 'package:vantedge/features/auth/presentation/screens/login_screen.dart';
// import 'package:vantedge/features/auth/presentation/screens/customer_signup_screen.dart';
// import 'app_routes.dart';

// /// Route generator for the application
// /// Handles all route generation, transitions, and navigation guards
// class RouteGenerator {
//   RouteGenerator._();

//   /// Generate route based on RouteSettings
//   /// Includes authentication checks and role-based routing
//   static Route<dynamic> generateRoute(RouteSettings settings) {
//     // Extract route name and arguments
//     final routeName = settings.name ?? AppRoutes.splash;
//     final arguments = settings.arguments;

//     // Log navigation for debugging
//     debugPrint('🔀 Navigating to: $routeName');

//     // Generate appropriate route
//     switch (routeName) {
//       // Authentication Routes
//       case AppRoutes.splash:
//         return _fadeTransition(
//           settings: settings,
//           builder: (_) => const SplashScreen(),
//         );

//       case AppRoutes.onboarding:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => const OnboardingScreen(),
//         );

//       case AppRoutes.login:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => const LoginScreen(),
//         );

//       case AppRoutes.signup:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => const CustomerSignupScreen(),
//         );

//       case AppRoutes.forgotPassword:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: 'Forgot Password',
//             message: 'Forgot Password screen coming soon',
//           ),
//         );

//       // Home Routes
//       case AppRoutes.home:
//       case AppRoutes.customerHome:
//       case AppRoutes.employeeHome:
//       case AppRoutes.adminHome:
//       case AppRoutes.branchManagerHome:
//       case AppRoutes.loanOfficerHome:
//       case AppRoutes.cardOfficerHome:
//       case AppRoutes.superAdminHome:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: AppRoutes.getDisplayName(routeName),
//             message: 'Dashboard screen coming soon',
//           ),
//         );

//       // Customer Routes
//       case AppRoutes.accounts:
//       case AppRoutes.accountDetails:
//       case AppRoutes.transactions:
//       case AppRoutes.transactionDetails:
//       case AppRoutes.transfer:
//       case AppRoutes.deposit:
//       case AppRoutes.withdrawal:
//       case AppRoutes.cards:
//       case AppRoutes.cardDetails:
//       case AppRoutes.loans:
//       case AppRoutes.loanDetails:
//       case AppRoutes.loanApplication:
//       case AppRoutes.dps:
//       case AppRoutes.dpsDetails:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: AppRoutes.getDisplayName(routeName),
//             message: 'Feature coming soon',
//           ),
//         );

//       // Profile & Settings Routes
//       case AppRoutes.profile:
//       case AppRoutes.settings:
//       case AppRoutes.editProfile:
//       case AppRoutes.changePassword:
//       case AppRoutes.notifications:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: AppRoutes.getDisplayName(routeName),
//             message: 'Feature coming soon',
//           ),
//         );

//       // Employee Routes
//       case AppRoutes.customerManagement:
//       case AppRoutes.customerDetails:
//       case AppRoutes.accountManagement:
//       case AppRoutes.transactionManagement:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: AppRoutes.getDisplayName(routeName),
//             message: 'Management feature coming soon',
//           ),
//         );

//       // Admin Routes
//       case AppRoutes.userManagement:
//       case AppRoutes.branchManagement:
//       case AppRoutes.reports:
//       case AppRoutes.analytics:
//       case AppRoutes.systemSettings:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: AppRoutes.getDisplayName(routeName),
//             message: 'Admin feature coming soon',
//           ),
//         );

//       // Loan Officer Routes
//       case AppRoutes.loanApplications:
//       case AppRoutes.loanApproval:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: AppRoutes.getDisplayName(routeName),
//             message: 'Loan management coming soon',
//           ),
//         );

//       // Card Officer Routes
//       case AppRoutes.cardApplications:
//       case AppRoutes.cardManagement:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: AppRoutes.getDisplayName(routeName),
//             message: 'Card management coming soon',
//           ),
//         );

//       // Support Routes
//       case AppRoutes.help:
//       case AppRoutes.faq:
//       case AppRoutes.contactSupport:
//       case AppRoutes.termsAndConditions:
//       case AppRoutes.privacyPolicy:
//         return _slideTransition(
//           settings: settings,
//           builder: (_) => _placeholderScreen(
//             title: AppRoutes.getDisplayName(routeName),
//             message: 'Information page coming soon',
//           ),
//         );

//       // Error Routes
//       case AppRoutes.error404:
//         return _fadeTransition(
//           settings: settings,
//           builder: (_) => _errorScreen(
//             errorCode: '404',
//             title: 'Page Not Found',
//             message: 'The page you are looking for does not exist.',
//           ),
//         );

//       // Unknown Route - 404
//       default:
//         return _fadeTransition(
//           settings: settings,
//           builder: (_) => _errorScreen(
//             errorCode: '404',
//             title: 'Page Not Found',
//             message: 'Route "$routeName" not found.',
//           ),
//         );
//     }
//   }

//   /// Fade transition for routes
//   static Route<dynamic> _fadeTransition({
//     required RouteSettings settings,
//     required WidgetBuilder builder,
//   }) {
//     return PageRouteBuilder(
//       settings: settings,
//       pageBuilder: (context, animation, secondaryAnimation) => builder(context),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return FadeTransition(
//           opacity: animation,
//           child: child,
//         );
//       },
//       transitionDuration: const Duration(milliseconds: 300),
//     );
//   }

//   /// Slide transition for routes
//   static Route<dynamic> _slideTransition({
//     required RouteSettings settings,
//     required WidgetBuilder builder,
//   }) {
//     return PageRouteBuilder(
//       settings: settings,
//       pageBuilder: (context, animation, secondaryAnimation) => builder(context),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         const begin = Offset(1.0, 0.0);
//         const end = Offset.zero;
//         const curve = Curves.easeInOut;

//         var tween = Tween(begin: begin, end: end).chain(
//           CurveTween(curve: curve),
//         );

//         return SlideTransition(
//           position: animation.drive(tween),
//           child: child,
//         );
//       },
//       transitionDuration: const Duration(milliseconds: 300),
//     );
//   }

//   /// Scale transition for routes
//   static Route<dynamic> _scaleTransition({
//     required RouteSettings settings,
//     required WidgetBuilder builder,
//   }) {
//     return PageRouteBuilder(
//       settings: settings,
//       pageBuilder: (context, animation, secondaryAnimation) => builder(context),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         const curve = Curves.easeInOut;

//         var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
//           CurveTween(curve: curve),
//         );

//         var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
//           CurveTween(curve: curve),
//         );

//         return ScaleTransition(
//           scale: animation.drive(scaleTween),
//           child: FadeTransition(
//             opacity: animation.drive(fadeTween),
//             child: child,
//           ),
//         );
//       },
//       transitionDuration: const Duration(milliseconds: 300),
//     );
//   }

//   /// Placeholder screen for routes not yet implemented
//   static Widget _placeholderScreen({
//     required String title,
//     required String message,
//   }) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.construction,
//                 size: 64,
//                 color: Colors.grey[400],
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 message,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 32),
//               ElevatedButton.icon(
//                 onPressed: () {},
//                 icon: const Icon(Icons.arrow_back),
//                 label: const Text('Go Back'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Error screen for 404 and other errors
//   static Widget _errorScreen({
//     required String errorCode,
//     required String title,
//     required String message,
//   }) {
//     return Scaffold(
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 errorCode,
//                 style: TextStyle(
//                   fontSize: 72,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[300],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Icon(
//                 Icons.error_outline,
//                 size: 64,
//                 color: Colors.red[400],
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 message,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 32),
//               ElevatedButton.icon(
//                 onPressed: () {},
//                 icon: const Icon(Icons.home),
//                 label: const Text('Go to Home'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Handle unknown route
//   static Route<dynamic> onUnknownRoute(RouteSettings settings) {
//     debugPrint('❌ Unknown route: ${settings.name}');
//     return generateRoute(
//       RouteSettings(
//         name: AppRoutes.error404,
//         arguments: settings.name,
//       ),
//     );
//   }
// }