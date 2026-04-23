import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Tab index constants (mirrors AppTab enum order)
class AppTabIndex {
  static const int home = 0;
  static const int collection = 1;
  static const int scan = 2;
  static const int leaderboard = 3;
  static const int profile = 4;
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              index: AppTabIndex.home,
              currentIndex: currentIndex,
              onTap: () => onTabSelected(AppTabIndex.home),
            ),
            _NavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              label: 'Collection',
              index: AppTabIndex.collection,
              currentIndex: currentIndex,
              onTap: () => onTabSelected(AppTabIndex.collection),
            ),
            _ScanButton(
              isActive: currentIndex == AppTabIndex.scan,
              onTap: () => onTabSelected(AppTabIndex.scan),
            ),
            _NavItem(
              icon: Icons.leaderboard_outlined,
              activeIcon: Icons.leaderboard_rounded,
              label: 'Ranks',
              index: AppTabIndex.leaderboard,
              currentIndex: currentIndex,
              onTap: () => onTabSelected(AppTabIndex.leaderboard),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              index: AppTabIndex.profile,
              currentIndex: currentIndex,
              onTap: () => onTabSelected(AppTabIndex.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? AppColors.accentPrimary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.accentPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _ScanButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentPrimary,
                    Color(0xFF1FA855),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPrimary.withOpacity(isActive ? 0.6 : 0.35),
                    blurRadius: isActive ? 20 : 12,
                    spreadRadius: isActive ? 2 : 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.bgPrimary,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
