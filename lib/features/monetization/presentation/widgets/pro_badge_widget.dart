import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Insignia visual oficial para destacar el estado y características de SubZero Pro.
class ProBadgeWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const ProBadgeWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.goldContainer,
          border: Border.all(color: AppTheme.goldAccent, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: AppTheme.goldAccent, size: 14),
            SizedBox(width: 4),
            Text(
              'PRO',
              style: TextStyle(
                color: AppTheme.goldAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
