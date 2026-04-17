import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../../models/school_models.dart' hide Marquee;

class MarqueeNotice extends StatelessWidget {
  final List<Notice>? notices;
  final String? customText;

  const MarqueeNotice({super.key, this.notices, this.customText});

  @override
  Widget build(BuildContext context) {
    if (customText != null && customText!.isNotEmpty) {
      return _buildMarqueeContainer(customText!);
    }

    if (notices == null || notices!.isEmpty) {
      return _buildMarqueeContainer(
        'Welcome to Smart School! Stay tuned for the latest updates and announcements.',
      );
    }

    // Combine all notice titles into one scrolling string
    final marqueeText = notices!
        .map((n) => '• ${n.title}: ${n.content}')
        .join('   ');

    return _buildMarqueeContainer(marqueeText);
  }

  Widget _buildMarqueeContainer(String text) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'UPDATES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Marquee(
                text: text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3142),
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 100.0,
                velocity: 30.0,
                pauseAfterRound: const Duration(seconds: 2),
                accelerationDuration: const Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
