import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

/// Handle background/terminated FCM messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op for background messages; foreground handled in WildSnapApp.
}

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
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    firebaseInitialized = true;
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
      child: WildSnapApp(firebaseInitialized: firebaseInitialized, apiService: apiService),
    ),
  );
}

class WildSnapApp extends StatefulWidget {
  final bool firebaseInitialized;
  final ApiService apiService;

  const WildSnapApp({
    super.key,
    required this.firebaseInitialized,
    required this.apiService,
  });

  @override
  State<WildSnapApp> createState() => _WildSnapAppState();
}

class _WildSnapAppState extends State<WildSnapApp> {
  @override
  void initState() {
    super.initState();
    if (widget.firebaseInitialized) {
      _initFcm();
    }
  }

  Future<void> _initFcm() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS requires explicit request)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register token with our backend when it is available/refreshed
    messaging.getToken().then((token) {
      if (token != null) _registerToken(token);
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Handle foreground messages as in-app banners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.body}'),
            backgroundColor: const Color(0xFF111A14),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      await widget.apiService.registerFcmToken(token);
    } catch (_) {
      // Non-fatal: server may not be reachable at this moment
    }
  }

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
