import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/sighting_provider.dart';
import '../services/connectivity_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'collection/collection_screen.dart';
import 'scan/scan_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/profile_screen.dart';

enum AppTab { home, collection, scan, leaderboard, profile }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = AppTabIndex.home;

  final List<Widget> _screens = const [
    HomeScreen(),
    CollectionScreen(),
    ScanScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final sightingProvider = context.read<SightingProvider>();
    await sightingProvider.initialize(user.id);

    // Listen for connectivity restored → sync
    final connectivity = context.read<ConnectivityService>();
    connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline && mounted) {
        sightingProvider.syncPendingSightings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
