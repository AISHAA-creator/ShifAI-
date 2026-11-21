import 'package:flutter/material.dart';

import '../models/lab_record.dart';
import '../theme/app_colors.dart';

Color bandColor(HomaIrBand band) {
  switch (band) {
    case HomaIrBand.optimal:
    case HomaIrBand.normal:
      return AppColors.safe;
    case HomaIrBand.earlyResistance:
      return AppColors.warning;
    case HomaIrBand.significantResistance:
      return AppColors.danger;
  }
}

Color bandBackground(HomaIrBand band) {
  switch (band) {
    case HomaIrBand.optimal:
    case HomaIrBand.normal:
      return AppColors.safeBg;
    case HomaIrBand.earlyResistance:
      return AppColors.warningBg;
    case HomaIrBand.significantResistance:
      return AppColors.dangerBg;
  }
}

Color bandTextColor(HomaIrBand band) {
  switch (band) {
    case HomaIrBand.optimal:
    case HomaIrBand.normal:
      return AppColors.safeText;
    case HomaIrBand.earlyResistance:
      return AppColors.warningText;
    case HomaIrBand.significantResistance:
      return AppColors.dangerText;
  }
}

/// Plain-language reading of a HOMA-IR band. Never a diagnosis.
String bandExplanation(HomaIrBand band) {
  switch (band) {
    case HomaIrBand.optimal:
      return 'Your body is handling blood glucose with very little insulin. '
          'Keep up the habits that got you here.';
    case HomaIrBand.normal:
      return 'Your result is within the usual range. Regular walks and '
          'balanced meals help keep it there.';
    case HomaIrBand.earlyResistance:
      return 'Your body is producing more insulin than usual to manage blood '
          'glucose. The encouraging news: this stage often responds well to '
          'everyday lifestyle changes.';
    case HomaIrBand.significantResistance:
      return 'Your body needs a lot of insulin to manage blood glucose. This '
          'is worth discussing with your doctor. ShifAI cannot diagnose you, '
          'and this stage can still respond to lifestyle changes.';
  }
}

class BandChip extends StatelessWidget {
  final HomaIrBand band;
  const BandChip({super.key, required this.band});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bandBackground(band),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: bandColor(band),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            band.label,
            style: TextStyle(
              color: bandTextColor(band),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
