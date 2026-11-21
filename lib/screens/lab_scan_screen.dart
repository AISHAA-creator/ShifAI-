import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/lab_ocr_service.dart';
import '../theme/app_colors.dart';
import '../widgets/step_header.dart';
import 'lab_entry_form_screen.dart';

/// Step 1 of the scan flow: photo capture + on-device OCR of a printed lab
/// report. Camera and OCR (Google ML Kit) only exist on Android/iOS, so this
/// screen is only opened there (see utils/open_add_result.dart).
class LabScanScreen extends StatefulWidget {
  const LabScanScreen({super.key});

  @override
  State<LabScanScreen> createState() => _LabScanScreenState();
}

class _LabScanScreenState extends State<LabScanScreen> {
  final _picker = ImagePicker();
  final _ocr = LabOcrService();

  File? _image;
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    setState(() => _error = null);
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _processing = true;
    });

    try {
      final result = await _ocr.extractFromImage(_image!);
      if (!mounted) return;
      setState(() => _processing = false);

      if (!result.hasAnyValue) {
        setState(
          () => _error =
              "Couldn't find glucose, insulin or HbA1c in this photo. Try a "
              'clearer, well-lit photo, or enter the values manually.',
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LabEntryFormScreen(
            fromScan: true,
            initialGlucose: result.glucoseValue,
            initialGlucoseUnit: result.glucoseUnit,
            initialInsulin: result.insulinValue,
            initialInsulinUnit: result.insulinUnit,
            initialHba1c: result.hba1cPercent,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'Could not read this image. Please try again or enter values manually.';
      });
    }
  }

  void _enterManually() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LabEntryFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Lab Results')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            children: [
              const StepHeader(current: 0),
              const SizedBox(height: 14),
              Expanded(child: _viewfinder()),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.dangerText),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.pastel,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.buttonBlue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hold your phone flat above the page. ShifAI reads your '
                        'results on this device — nothing is uploaded.',
                        style: TextStyle(
                          color: AppColors.text,
                          height: 1.35,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewfinder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14507F), Color(0xFF082C4A)],
          ),
        ),
        child: Stack(
          children: [
            if (_image != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.85,
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: CustomPaint(painter: _FramePainter()),
              ),
            ),
            Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Center(
                child: _pill(
                  'Processed on your device',
                  icon: Icons.lock_outline,
                ),
              ),
            ),
            Center(
              child: _processing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : (_image == null
                        ? _pill('Align printed paper in frame')
                        : const SizedBox.shrink()),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _roundButton(
                    Icons.edit_note_rounded,
                    'Enter values manually',
                    _enterManually,
                  ),
                  _captureButton(),
                  _roundButton(
                    Icons.photo_library_outlined,
                    'Choose from gallery',
                    _processing ? null : () => _capture(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.buttonBlue),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _captureButton() {
    return Tooltip(
      message: 'Take a photo',
      child: InkWell(
        onTap: _processing ? null : () => _capture(ImageSource.camera),
        customBorder: const CircleBorder(),
        child: Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 4,
            ),
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 32,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CCBFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const len = 38.0;
    const r = 14.0;
    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, h - len)
        ..lineTo(w, h - r)
        ..quadraticBezierTo(w, h, w - r, h)
        ..lineTo(w - len, h),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(len, h)
        ..lineTo(r, h)
        ..quadraticBezierTo(0, h, 0, h - r)
        ..lineTo(0, h - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
