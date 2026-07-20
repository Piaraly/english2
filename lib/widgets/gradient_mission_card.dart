import 'package:flutter/material.dart';

class GradientMissionCard extends StatelessWidget {
  const GradientMissionCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5A52D9), Color(0xFF9257E6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A52D9).withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      );
}
