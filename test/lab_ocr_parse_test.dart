import 'package:flutter_test/flutter_test.dart';
import 'package:shifai/models/lab_record.dart';
import 'package:shifai/services/lab_ocr_service.dart';

void main() {
  test('reads an English report with units', () {
    final r = LabOcrService.parseText(
      'Glucose (Fasting) 92 mg/dL\nInsulin 9.0 uIU/mL\nHbA1c 5.4 %',
    );
    expect(r.glucoseValue, 92);
    expect(r.glucoseUnit, GlucoseUnit.mgdl);
    expect(r.insulinValue, 9.0);
    expect(r.insulinUnit, InsulinUnit.uiuml);
    expect(r.hba1cPercent, 5.4);
  });

  test('reads a French report with decimal commas', () {
    final r = LabOcrService.parseText(
      'Glycémie à jeun 0,95 g/L\nInsuline 12,5 µUI/mL\nHémoglobine glyquée (HbA1c) 5,6 %',
    );
    expect(r.glucoseValue, 0.95);
    expect(r.glucoseUnit, GlucoseUnit.gl);
    expect(r.insulinValue, 12.5);
    expect(r.hba1cPercent, 5.6);
  });

  test('the 1 in HbA1c is not mistaken for the result', () {
    final r = LabOcrService.parseText('HbA1c 6.1 %');
    expect(r.hba1cPercent, 6.1);
  });

  test('guesses the glucose unit from its size when none is printed', () {
    expect(LabOcrService.parseText('Glycémie 0.92').glucoseUnit, GlucoseUnit.gl);
    expect(LabOcrService.parseText('Glucose 5.1').glucoseUnit, GlucoseUnit.mmoll);
    expect(LabOcrService.parseText('Glucose 92').glucoseUnit, GlucoseUnit.mgdl);
  });

  test('detects pmol/L insulin', () {
    final r = LabOcrService.parseText('Insuline 60 pmol/L');
    expect(r.insulinValue, 60);
    expect(r.insulinUnit, InsulinUnit.pmoll);
  });

  test('text without any known test gives no values', () {
    final r = LabOcrService.parseText('Cholestérol total 1,90 g/L\nCréatinine 8 mg/L');
    expect(r.hasAnyValue, isFalse);
  });

  test('a test named but without a number is skipped', () {
    final r = LabOcrService.parseText('Glycémie à jeun\nInsuline 10 uUI/mL');
    expect(r.glucoseValue, isNull);
    expect(r.insulinValue, 10);
  });
}
