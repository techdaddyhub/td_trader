// Copyright (c) 2026 TechDaddy. All rights reserved.
// TD TRADER - TechDaddy Official Logo & Monogram Widget (Binance Gold Edition)
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
          center: Alignment(-0.25, -0.25),
          colors: [
            Color(0xFF262D38),
            Color(0xFF181A20),
            Color(0xFF0B0E11),
          ],
        ),
        border: Border.all(
          color: AppColors.binanceGold,
          width: size * 0.045,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.binanceGold.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.04,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: size * 0.2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle Binance diamond geometric watermark
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: size * 0.62,
              height: size * 0.62,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.binanceGold.withValues(alpha: 0.20),
                  width: 1.2,
                ),
              ),
            ),
          ),
          // Inner hairline gold ring
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.binanceGoldLight.withValues(alpha: 0.45),
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
                    color: AppColors.binanceGold,
                    shadows: [
                      Shadow(
                        color: AppColors.binanceGold.withValues(alpha: 0.8),
                        blurRadius: 8,
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
                    color: AppColors.binanceGoldLight,
                    shadows: [
                      Shadow(
                        color:
                            AppColors.binanceGoldLight.withValues(alpha: 0.9),
                        blurRadius: 8,
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
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.binanceGold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'TECHDADDY',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.binanceGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'TD TRADER ECOSYSTEM',
            style: TextStyle(
              color: AppColors.binanceGold,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.8,
            ),
          ),
        ],
        if (showCopyright) ...[
          const SizedBox(height: 6),
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
