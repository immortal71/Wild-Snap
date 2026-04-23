import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/local_db_service.dart';
import 'services/connectivity_service.dart';
import 'providers/auth_provider.dart';
import 'providers/sighting_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF111A14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Firebase initialization — gracefully handle missing google-services.json
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured — auth will fall back to email/password only
  }

  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Build service graph
  final apiService = ApiService();
  final authService = AuthService(apiService);
  final localDbService = LocalDbService();

  runApp(
    MultiProvider(
      providers: [
        // Expose connectivity so screens can watch it for offline UI
        ChangeNotifierProvider<ConnectivityService>.value(value: connectivityService),

        // Auth
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),

        // Sightings
        ChangeNotifierProvider(
          create: (_) => SightingProvider(apiService, localDbService, connectivityService),
        ),

        // Collection
        ChangeNotifierProvider(
          create: (_) => CollectionProvider(apiService, localDbService, connectivityService),
        ),

        // Leaderboard
        ChangeNotifierProvider(
          create: (_) => LeaderboardProvider(apiService, connectivityService),
        ),
      ],
      child: const WildSnapApp(),
    ),
  );
}

class WildSnapApp extends StatelessWidget {
  const WildSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WildSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
