import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification preferences
  bool _notifyRareNearby = true;
  bool _notifyDailyChallenge = true;
  bool _notifyLeaderboard = true;

  // Privacy
  String _locationSharing = 'while_using'; // always | while_using | never

  // Data
  bool _wifiOnly = false;
  bool _offlineMode = false;

  bool _isLoading = true;

  static const _keyRareNearby = 'pref_notify_rare_nearby';
  static const _keyDailyChallenge = 'pref_notify_daily_challenge';
  static const _keyLeaderboard = 'pref_notify_leaderboard';
  static const _keyLocationSharing = 'pref_location_sharing';
  static const _keyWifiOnly = 'pref_wifi_only';
  static const _keyOfflineMode = 'pref_offline_mode';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyRareNearby = prefs.getBool(_keyRareNearby) ?? true;
      _notifyDailyChallenge = prefs.getBool(_keyDailyChallenge) ?? true;
      _notifyLeaderboard = prefs.getBool(_keyLeaderboard) ?? true;
      _locationSharing = prefs.getString(_keyLocationSharing) ?? 'while_using';
      _wifiOnly = prefs.getBool(_keyWifiOnly) ?? false;
      _offlineMode = prefs.getBool(_keyOfflineMode) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSection('Account', [
                  _buildNavTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update name, username, avatar',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildNavTile(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildNavTile(
                    icon: Icons.link_rounded,
                    title: 'Linked Accounts',
                    subtitle: 'Google · Apple',
                    onTap: () => _showComingSoon(context),
                  ),
                ]),
                _buildSection('Notifications', [
                  _buildSwitchTile(
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.colorRare,
                    title: 'Rare Alert Nearby',
                    subtitle: 'When a rare animal is spotted near you',
                    value: _notifyRareNearby,
                    onChanged: (v) {
                      setState(() => _notifyRareNearby = v);
                      _savePreference(_keyRareNearby, v);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.today_outlined,
                    iconColor: AppColors.accentPrimary,
                    title: 'Daily Challenge',
                    subtitle: 'Reminder when a new challenge is available',
                    value: _notifyDailyChallenge,
                    onChanged: (v) {
                      setState(() => _notifyDailyChallenge = v);
                      _savePreference(_keyDailyChallenge, v);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.leaderboard_outlined,
                    iconColor: AppColors.accentSecondary,
                    title: 'Leaderboard Changes',
                    subtitle: 'When your rank changes',
                    value: _notifyLeaderboard,
                    onChanged: (v) {
                      setState(() => _notifyLeaderboard = v);
                      _savePreference(_keyLeaderboard, v);
                    },
                  ),
                ]),
                _buildSection('Privacy', [
                  _buildDropdownTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location Sharing',
                    value: _locationSharing,
                    options: const {
                      'always': 'Always',
                      'while_using': 'While Using App',
                      'never': 'Never',
                    },
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _locationSharing = v);
                        _savePreference(_keyLocationSharing, v);
                      }
                    },
                  ),
                ]),
                _buildSection('Data & Storage', [
                  _buildSwitchTile(
                    icon: Icons.wifi_outlined,
                    iconColor: AppColors.accentTertiary,
                    title: 'WiFi Only Uploads',
                    subtitle: 'Only sync photos over WiFi',
                    value: _wifiOnly,
                    onChanged: (v) {
                      setState(() => _wifiOnly = v);
                      _savePreference(_keyWifiOnly, v);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.cloud_off_outlined,
                    iconColor: AppColors.textSecondary,
                    title: 'Offline Mode',
                    subtitle: 'Disable all network requests',
                    value: _offlineMode,
                    onChanged: (v) {
                      setState(() => _offlineMode = v);
                      _savePreference(_keyOfflineMode, v);
                    },
                  ),
                  _buildNavTile(
                    icon: Icons.download_outlined,
                    title: 'Export My Data',
                    subtitle: 'Download your sightings as CSV',
                    onTap: () => _showComingSoon(context),
                  ),
                ]),
                _buildSection('About', [
                  _buildNavTile(
                    icon: Icons.info_outline,
                    title: 'About WildSnap',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAbout(context),
                  ),
                  _buildNavTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildNavTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildNavTile(
                    icon: Icons.open_source_response_rounded,
                    title: 'Open Source Licenses',
                    onTap: () => showLicensePage(context: context),
                  ),
                ]),
                _buildSection('Account Actions', [
                  _buildDangerTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    onTap: () => _confirmSignOut(context),
                  ),
                  _buildDangerTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Delete Account',
                    onTap: () => _showComingSoon(context),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accentPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.bgSecondary,
        underline: const SizedBox.shrink(),
        style: GoogleFonts.dmSans(
          fontSize: 13,
          color: AppColors.accentPrimary,
          fontWeight: FontWeight.w600,
        ),
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.danger, size: 20),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.danger,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(
          'Sign Out',
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coming soon!',
          style: GoogleFonts.dmSans(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.bgSecondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'WildSnap',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 WildSnap. Catch the Wild. Save the Planet.',
    );
  }
}
