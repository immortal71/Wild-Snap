import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'auth/login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _letters = ['W', 'I', 'L', 'D', 'S', 'N', 'A', 'P'];
  final List<Animation<double>> _letterAnimations = [];
  late Animation<double> _taglineAnim;
  late Animation<double> _onboardingAnim;

  bool _showOnboarding = false;
  int _onboardingPage = 0;

  final List<_OnboardingData> _onboardingPages = [
    _OnboardingData(
      emoji: '📷',
      title: 'Snap Wildlife',
      subtitle: 'Photograph animals in the wild using your phone camera and let AI identify them instantly.',
    ),
    _OnboardingData(
      emoji: '🏆',
      title: 'Earn Points',
      subtitle: 'Rare species earn more points. Build streaks, climb the global leaderboard.',
    ),
    _OnboardingData(
      emoji: '🌿',
      title: 'Save the Planet',
      subtitle: 'Your sightings contribute to real wildlife conservation data worldwide.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Staggered letter animations
    for (int i = 0; i < _letters.length; i++) {
      final start = 0.05 * i;
      final end = start + 0.15;
      _letterAnimations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.elasticOut),
          ),
        ),
      );
    }

    _taglineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _showOnboarding = true);
        }
      });
    });

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppColors.accentPrimary.withOpacity(0.05),
                  AppColors.bgPrimary,
                ],
              ),
            ),
          ),
          if (!_showOnboarding) _buildLogoScreen(),
          if (_showOnboarding) _buildOnboardingScreen(),
        ],
      ),
    );
  }

  Widget _buildLogoScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _letters.asMap().entries.map((e) {
              return AnimatedBuilder(
                animation: _letterAnimations[e.key],
                builder: (context, _) {
                  return Opacity(
                    opacity: _letterAnimations[e.key].value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _letterAnimations[e.key].value)),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 72,
                          color: e.key < 4 ? AppColors.accentPrimary : AppColors.textPrimary,
                          letterSpacing: 4,
                          height: 1,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _taglineAnim,
            child: Text(
              'CATCH THE WILD. SAVE THE PLANET.',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          _buildOnboardingCard(),
          const Spacer(),
          _buildOnboardingControls(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOnboardingCard() {
    final page = _onboardingPages[_onboardingPage];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Padding(
        key: ValueKey(_onboardingPage),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Text(page.emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text(
              page.title,
              style: GoogleFonts.dmSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              page.subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingControls() {
    final isLast = _onboardingPage == _onboardingPages.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_onboardingPages.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _onboardingPage ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _onboardingPage
                      ? AppColors.accentPrimary
                      : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isLast) {
                  _navigate();
                } else {
                  setState(() => _onboardingPage++);
                }
              },
              child: Text(isLast ? 'Get Started' : 'Next'),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _navigate,
              child: Text(
                'Skip',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}
