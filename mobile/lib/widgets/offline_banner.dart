import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.accentSecondary.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accentSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — photos will sync when connected',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.accentSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: AppColors.accentSecondary,
          ),
        ],
      ),
    );
  }
}
