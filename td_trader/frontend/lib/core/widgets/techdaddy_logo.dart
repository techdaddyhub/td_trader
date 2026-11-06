// Copyright (c) 2026 TechDaddy. All rights reserved.
// TD TRADER - TechDaddy Official Logo & Monogram Widget
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TechDaddyLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showCopyright;

  const TechDaddyLogo({
    super.key,
    this.size = 48.0,
    this.showText = true,
    this.showCopyright = false,
  });

  @override
  Widget build(BuildContext context) {
    final emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.2),
          colors: [
            Color(0xFF1E2B3E),
            Color(0xFF0F1722),
            Color(0xFF070B10),
          ],
        ),
        border: Border.all(
          color: AppColors.primaryCyan,
          width: size * 0.045,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.35),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.05,
          ),
          BoxShadow(
            color: AppColors.goldAccent.withOpacity(0.15),
            blurRadius: size * 0.2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer subtle glow ring
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.goldAccent.withOpacity(0.4),
                width: 1.0,
              ),
            ),
          ),
          // Stylized "TD" Monogram
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'T',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.44,
                    letterSpacing: -1.0,
                    color: AppColors.primaryCyan,
                    shadows: [
                      Shadow(
                        color: AppColors.primaryCyan.withOpacity(0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'D',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.44,
                    letterSpacing: -1.0,
                    color: AppColors.goldAccent,
                    shadows: [
                      Shadow(
                        color: AppColors.goldAccent.withOpacity(0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!showText && !showCopyright) {
      return emblem;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        if (showText) ...[
          const SizedBox(height: 8),
          const Text(
            'TECHDADDY',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2.0,
            ),
          ),
          const Text(
            'TD TRADER ECOSYSTEM',
            style: TextStyle(
              color: AppColors.primaryCyan,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
        if (showCopyright) ...[
          const SizedBox(height: 4),
          const Text(
            'Copyright © 2026 TechDaddy. All rights reserved.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

