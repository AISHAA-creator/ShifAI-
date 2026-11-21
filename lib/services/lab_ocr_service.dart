import 'dart:io';
import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/lab_record.dart';

/// Best-effort extraction of glucose / insulin / HbA1c / triglycerides / HDL
/// values from a photo of a printed lab report. Handles English and French lab
/// terminology (glycémie, insuline, hémoglobine glyquée, triglycérides,
/// HDL-cholestérol) since Moroccan lab reports are commonly French-language.
/// Always shown to the user for confirmation before being saved — OCR on a
/// real-world printed report is not perfect.
class LabOcrResult {
  final double? glucoseValue;
  final GlucoseUnit? glucoseUnit;
  final double? insulinValue;
  final InsulinUnit? insulinUnit;
  final double? hba1cPercent;
  final double? triglyceridesValue;
  final LipidUnit? triglyceridesUnit;
  final double? hdlValue;
  final LipidUnit? hdlUnit;
  final String rawText;

  LabOcrResult({
    this.glucoseValue,
    this.glucoseUnit,
    this.insulinValue,
    this.insulinUnit,
    this.hba1cPercent,
    this.triglyceridesValue,
    this.triglyceridesUnit,
    this.hdlValue,
    this.hdlUnit,
    required this.rawText,
  });

  bool get hasAnyValue =>
      glucoseValue != null ||
      insulinValue != null ||
      hba1cPercent != null ||
      triglyceridesValue != null ||
      hdlValue != null;

  /// Triglycerides in mg/dL, or null when missing or the unit is unknown
  /// (the user must then confirm the unit).
  double? get triglyceridesMgdl =>
      LabOcrService.triglyceridesToMgdl(triglyceridesValue, triglyceridesUnit);

  /// HDL cholesterol in mg/dL, or null when missing or the unit is unknown.
  double? get hdlMgdl => LabOcrService.hdlToMgdl(hdlValue, hdlUnit);
}

/// One recognised line of text with its position on the photo.
class OcrLine {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrLine(this.text, this.left, this.top, this.right, this.bottom);

  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}

class LabOcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static final _numberPattern = RegExp(r'(\d+[.,]?\d*)');
  static final _parenthesesPattern = RegExp(r'\([^)]*\)');

  static final _glucosePattern = RegExp(
    r'glyc[ée]mie|glucose',
    caseSensitive: false,
  );
  static final _insulinPattern = RegExp(r'insulin[ei]?', caseSensitive: false);
  static final _hba1cPattern = RegExp(
    r'hba1c|h[ée]moglobine\s*glyqu[ée]e|hemoglobine glycosylee',
    caseSensitive: false,
  );
  static final _triglyceridesPattern = RegExp(
    r'triglyc[ée]rid[^\s\d]*|\btg\b',
    caseSensitive: false,
  );
  static final _hdlPattern = RegExp(
    r'hdl[\s\-]*chol[^\s\d]*|\bhdl\b',
    caseSensitive: false,
  );

  Future<LabOcrResult> extractFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final recognized = await _recognizer.processImage(inputImage);
    final lines = <OcrLine>[
      for (final block in recognized.blocks)
        for (final line in block.lines)
          OcrLine(
            line.text,
            line.boundingBox.left,
            line.boundingBox.top,
            line.boundingBox.right,
            line.boundingBox.bottom,
          ),
    ];
    final text = lines.isEmpty ? recognized.text : linesToText(lines);
    return parseText(text);
  }

  /// Lab reports are tables: the test name sits on the left and its value in
  /// another column, and the recogniser often returns them as separate lines.
  /// This rebuilds one text line per test name by appending the pieces of text
  /// that sit to its right at about the same height (left to right), so the
  /// value follows the name. The original lines are kept too.
  static String linesToText(List<OcrLine> lines) {
    final sorted = [...lines]..sort((a, b) => a.top.compareTo(b.top));
    final out = <String>[];
    for (final line in sorted) {
      final neighbours = sorted.where((other) {
        if (identical(other, line)) return false;
        final sameRow =
            (other.centerY - line.centerY).abs() <=
            1.2 * math.max(line.height, other.height);
        return sameRow && other.left >= line.right - 0.3 * line.height;
      }).toList()..sort((a, b) => a.left.compareTo(b.left));
      out.add(
        [line.text.trim(), ...neighbours.map((n) => n.text.trim())].join(' '),
      );
    }
    return out.join('\n');
  }

  /// Turns the raw OCR text into values. Line by line: a line that names a
  /// test (by keyword) gives that test's number and unit; the first line that
  /// matches wins for each test.
  static LabOcrResult parseText(String text) {
    double? glucoseValue;
    GlucoseUnit? glucoseUnit;
    double? insulinValue;
    InsulinUnit? insulinUnit;
    double? hba1c;
    double? triglycerides;
    LipidUnit? triglyceridesUnit;
    double? hdl;
    LipidUnit? hdlUnit;

    for (final line in text.split('\n')) {
      final lower = line.toLowerCase();

      if (glucoseValue == null && _glucosePattern.hasMatch(lower)) {
        final n = _numberOnLine(lower, _glucosePattern);
        if (n != null) {
          glucoseValue = n;
          glucoseUnit = _detectGlucoseUnit(lower) ?? _guessGlucoseUnit(n);
        }
      }

      if (insulinValue == null && _insulinPattern.hasMatch(lower)) {
        final n = _numberOnLine(lower, _insulinPattern);
        if (n != null) {
          insulinValue = n;
          insulinUnit = _detectInsulinUnit(lower) ?? InsulinUnit.uiuml;
        }
      }

      if (hba1c == null && _hba1cPattern.hasMatch(lower)) {
        final n = _numberOnLine(lower, _hba1cPattern);
        if (n != null) hba1c = n;
      }

      if (triglycerides == null && _triglyceridesPattern.hasMatch(lower)) {
        final n = _numberOnLine(lower, _triglyceridesPattern);
        if (n != null) {
          triglycerides = n;
          triglyceridesUnit = _detectLipidUnit(lower);
        }
      }

      if (hdl == null && _hdlPattern.hasMatch(lower)) {
        final n = _numberOnLine(lower, _hdlPattern);
        if (n != null) {
          hdl = n;
          hdlUnit = _detectLipidUnit(lower);
        }
      }
    }

    return LabOcrResult(
      glucoseValue: glucoseValue,
      glucoseUnit: glucoseUnit,
      insulinValue: insulinValue,
      insulinUnit: insulinUnit,
      hba1cPercent: hba1c,
      triglyceridesValue: triglycerides,
      triglyceridesUnit: triglyceridesUnit,
      hdlValue: hdl,
      hdlUnit: hdlUnit,
      rawText: text,
    );
  }

  /// First number on the line once the test's own name and any reference
  /// range in brackets are removed, so the "1" inside "HbA1c" and a range like
  /// "(0,7 - 1,1)" are never mistaken for the result.
  static double? _numberOnLine(String lowerLine, RegExp keyword) {
    final withoutName = lowerLine.replaceAll(keyword, ' ');
    final withoutRange = withoutName.replaceAll(_parenthesesPattern, ' ');
    final match = _numberPattern.firstMatch(withoutRange);
    if (match == null) return null;
    return double.tryParse(match.group(1)!.replaceAll(',', '.'));
  }

  static GlucoseUnit? _detectGlucoseUnit(String lowerLine) {
    if (lowerLine.contains('g/l')) return GlucoseUnit.gl;
    if (lowerLine.contains('mmol')) return GlucoseUnit.mmoll;
    if (lowerLine.contains('mg/dl')) return GlucoseUnit.mgdl;
    return null;
  }

  /// When no unit is printed next to the number, guess from the typical
  /// physiological range: g/L values look like 0.7–1.3, mg/dL like 70–130,
  /// mmol/L like 4–8.
  static GlucoseUnit _guessGlucoseUnit(double value) {
    if (value < 3) return GlucoseUnit.gl;
    if (value < 15) return GlucoseUnit.mmoll;
    return GlucoseUnit.mgdl;
  }

  static InsulinUnit? _detectInsulinUnit(String lowerLine) {
    if (lowerLine.contains('pmol')) return InsulinUnit.pmoll;
    if (lowerLine.contains('uiu') ||
        lowerLine.contains('µiu') ||
        lowerLine.contains('miu') ||
        lowerLine.contains('ui/ml') ||
        lowerLine.contains('µu/ml') ||
        lowerLine.contains('uu/ml')) {
      return InsulinUnit.uiuml;
    }
    return null;
  }

  /// Triglycerides and HDL are printed as g/L, mmol/L or mg/dL. No guessing
  /// when the unit is missing: g/L and mmol/L values overlap, so the user
  /// confirms it instead.
  static LipidUnit? _detectLipidUnit(String lowerLine) {
    if (lowerLine.contains('g/l') && !lowerLine.contains('mg/l')) {
      return LipidUnit.gl;
    }
    if (lowerLine.contains('mmol')) return LipidUnit.mmoll;
    if (lowerLine.contains('mg/dl')) return LipidUnit.mgdl;
    return null;
  }

  /// Triglycerides to mg/dL (g/L x 100, mmol/L x 88.57).
  static double? triglyceridesToMgdl(double? value, LipidUnit? unit) {
    if (value == null || unit == null) return null;
    return switch (unit) {
      LipidUnit.gl => value * 100,
      LipidUnit.mmoll => value * 88.57,
      LipidUnit.mgdl => value,
    };
  }

  /// HDL cholesterol to mg/dL (g/L x 100, mmol/L x 38.67).
  static double? hdlToMgdl(double? value, LipidUnit? unit) {
    if (value == null || unit == null) return null;
    return switch (unit) {
      LipidUnit.gl => value * 100,
      LipidUnit.mmoll => value * 38.67,
      LipidUnit.mgdl => value,
    };
  }

  void dispose() {
    _recognizer.close();
  }
}
