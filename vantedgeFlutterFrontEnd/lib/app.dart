// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vantedge/core/di/service_locator.dart';
// import 'package:vantedge/core/routes/app_routes.dart';
// import 'package:vantedge/core/routes/route_generator.dart';
// import 'package:vantedge/core/theme/app_theme.dart';
// import 'package:vantedge/features/auth/presentation/providers/auth_provider.dart';

// /// Main application widget
// /// 
// /// Sets up providers, theme, and routing configuration
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         // Auth Provider - Check auth status on startup
//         ChangeNotifierProvider(
//           create: (_) => sl<AuthProvider>()..checkAuthStatus(),
//         ),
        
//         // Add other providers here as needed
//         // Example:
//         // ChangeNotifierProvider(create: (_) => sl<ThemeProvider>()),
//         // ChangeNotifierProvider(create: (_) => sl<AccountProvider>()),
//       ],
//       child: Consumer<AuthProvider>(
//         builder: (context, authProvider, child) {
//           return MaterialApp(
//             // App Configuration
//             title: 'VantEdge Banking',
//             debugShowCheckedModeBanner: false,

//             // Theme Configuration
//             theme: AppTheme.lightTheme,
//             darkTheme: AppTheme.darkTheme,
//             themeMode: ThemeMode.system, // Follow system theme

//             // Routing Configuration
//             initialRoute: AppRoutes.splash,
//             onGenerateRoute: RouteGenerator.generateRoute,
//             onUnknownRoute: RouteGenerator.onUnknownRoute,

//             // Localization Configuration (Future)
//             // locale: const Locale('en', 'US'),
//             // supportedLocales: const [
//             //   Locale('en', 'US'),
//             //   Locale('bn', 'BD'),
//             // ],
//             // localizationsDelegates: const [
//             //   GlobalMaterialLocalizations.delegate,
//             //   GlobalWidgetsLocalizations.delegate,
//             //   GlobalCupertinoLocalizations.delegate,
//             // ],

//             // Builder for global app configuration
//             builder: (context, child) {
//               return MediaQuery(
//                 // Ensure text scaling doesn't exceed reasonable limits
//                 data: MediaQuery.of(context).copyWith(
//                   textScaler: TextScaler.linear(MediaQuery.of(context)
//                       .textScaleFactor
//                       .clamp(0.8, 1.4)),
//                 ),
//                 child: child!,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// } 