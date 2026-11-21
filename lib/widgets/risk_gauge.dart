import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/risk_model.dart';
import '../theme/app_colors.dart';

Color riskColor(RiskBand band) {
  switch (band) {
    case RiskBand.low:
      return AppColors.safe;
    case RiskBand.moderate:
      return AppColors.warning;
    case RiskBand.high:
      return AppColors.danger;
  }
}

Color riskBackground(RiskBand band) {
  switch (band) {
    case RiskBand.low:
      return AppColors.safeBg;
    case RiskBand.moderate:
      return AppColors.warningBg;
    case RiskBand.high:
      return AppColors.dangerBg;
  }
}

Color riskTextColor(RiskBand band) {
  switch (band) {
    case RiskBand.low:
      return AppColors.safeText;
    case RiskBand.moderate:
      return AppColors.warningText;
    case RiskBand.high:
      return AppColors.dangerText;
  }
}

class RiskChip extends StatelessWidget {
  final RiskBand band;
  const RiskChip({super.key, required this.band});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: riskBackground(band),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: riskColor(band),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            band.label,
            style: TextStyle(
              color: riskTextColor(band),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular gauge showing the estimated chance as a percentage.
class RiskGauge extends StatelessWidget {
  final RiskAssessment assessment;
  final double size;
  const RiskGauge({super.key, required this.assessment, this.size = 104});

  @override
  Widget build(BuildContext context) {
    final color = riskColor(assessment.band);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _ArcPainter(assessment.probability.clamp(0.0, 1.0), color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${assessment.percent}%',
                style: TextStyle(
                  fontSize: size * 0.27,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'chance',
                style: TextStyle(fontSize: 11.5, color: AppColors.gray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _ArcPainter(this.fraction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..color = AppColors.pastel
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.fraction != fraction || old.color != color;
}
