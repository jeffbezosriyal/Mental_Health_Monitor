import 'package:flutter/material.dart';
import 'package:stress_detection_app/core/theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = AppTheme.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration.copyWith(
          color: const Color(0xFFE0F2F1), // Very light teal tint
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTheme.labelStyle),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.headingStyle.copyWith(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}