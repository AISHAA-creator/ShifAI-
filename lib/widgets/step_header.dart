import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// "1. Scan Sheet  |  2. Review Data" switcher from the Stitch design.
class StepHeader extends StatelessWidget {
  /// 0 = scan, 1 = review.
  final int current;
  const StepHeader({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.pastel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Step(
              icon: Icons.document_scanner_outlined,
              label: '1. Scan Sheet',
              active: current == 0,
            ),
          ),
          Expanded(
            child: _Step(
              icon: Icons.fact_check_outlined,
              label: '2. Review Data',
              active: current == 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _Step({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.gray;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: active ? AppColors.buttonBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}
