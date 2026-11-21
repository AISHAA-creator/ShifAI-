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
    expect(
      LabOcrService.parseText('Glycémie 0.92').glucoseUnit,
      GlucoseUnit.gl,
    );
    expect(
      LabOcrService.parseText('Glucose 5.1').glucoseUnit,
      GlucoseUnit.mmoll,
    );
    expect(LabOcrService.parseText('Glucose 92').glucoseUnit, GlucoseUnit.mgdl);
  });

  test('detects pmol/L insulin', () {
    final r = LabOcrService.parseText('Insuline 60 pmol/L');
    expect(r.insulinValue, 60);
    expect(r.insulinUnit, InsulinUnit.pmoll);
  });

  test('text without any known test gives no values', () {
    final r = LabOcrService.parseText(
      'Cholestérol total 1,90 g/L\nCréatinine 8 mg/L',
    );
    expect(r.hasAnyValue, isFalse);
  });

  test('a test named but without a number is skipped', () {
    final r = LabOcrService.parseText('Glycémie à jeun\nInsuline 10 uUI/mL');
    expect(r.glucoseValue, isNull);
    expect(r.insulinValue, 10);
  });

  test('reads triglycerides and HDL in French, ignoring LDL and total', () {
    final r = LabOcrService.parseText(
      'Cholestérol total 1,33 g/l (Inférieur à 2)\n'
      'HDL-Cholestérol 0,40 g/l\n'
      'Cholestérol LDL 0,89 g/l (Inférieur à 1,6)\n'
      'Triglycérides 0,20 g/l (Inférieur à 1,5)',
    );
    expect(r.hdlValue, 0.40);
    expect(r.hdlUnit, LipidUnit.gl);
    expect(r.triglyceridesValue, 0.20);
    expect(r.triglyceridesUnit, LipidUnit.gl);
    expect(r.hdlMgdl, closeTo(40, 1e-9));
    expect(r.triglyceridesMgdl, closeTo(20, 1e-9));
  });

  test('lipid units: mmol/L converts, missing unit stays unknown', () {
    final mmol = LabOcrService.parseText('HDL 1,3 mmol/l\nTG 1,7 mmol/l');
    expect(mmol.hdlMgdl, closeTo(1.3 * 38.67, 1e-6));
    expect(mmol.triglyceridesMgdl, closeTo(1.7 * 88.57, 1e-6));

    final noUnit = LabOcrService.parseText('Triglycérides 1.4');
    expect(noUnit.triglyceridesValue, 1.4);
    expect(noUnit.triglyceridesUnit, isNull);
    expect(noUnit.triglyceridesMgdl, isNull);
  });

  test('a reference range in brackets is never read as the result', () {
    final r = LabOcrService.parseText('Glycémie à jeun (0,7 - 1,1) 0,83 g/l');
    expect(r.glucoseValue, 0.83);
    expect(r.glucoseUnit, GlucoseUnit.gl);
  });

  test(
    'French lab report 1 (lipids, glucose, HbA1c), text as one line each',
    () {
      final r = LabOcrService.parseText(
        'BIOCHIMIE SANGUINE\n'
        'Cholestérol total 1,33 g/l (Inférieur à 2)\n'
        'HDL-Cholestérol 0,40 g/l\n'
        'Absence de risque : > 0.55 g/l\n'
        'Triglycérides 0,20 g/l (Inférieur à 1,5)\n'
        'Glycémie à jeun 0,83 g/l (0,7 - 1,1)\n'
        '4,61 mmol/l (4,17 - 6,39)\n'
        'Hémoglobine glyquée : HBA1C 4,50 % (4,5 - 6,5)',
      );
      expect(r.glucoseValue, 0.83);
      expect(r.glucoseUnit, GlucoseUnit.gl);
      expect(r.hba1cPercent, 4.5);
      expect(r.hdlValue, 0.40);
      expect(r.triglyceridesValue, 0.20);
    },
  );

  test('French lab report 2 (insulin resistance index) matches the lab', () {
    final r = LabOcrService.parseText(
      "INDICE DE RESISTANCE A L'INSULINE\n"
      'Glycémie à jeun 0,83 g/l (0,75 - 1,1)\n'
      'Insulinémie Totale : 17,50 µU/mL (2,1 - 19)\n'
      'Indice IR 3,59 * (0,74 - 2,25)\n'
      '- supérieur à 2,4 : Insulinorésistance importante.',
    );
    expect(r.glucoseValue, 0.83);
    expect(r.insulinValue, 17.5);
    expect(r.insulinUnit, InsulinUnit.uiuml);
    // The lab's own index is 3.59: glucose 83 mg/dL x insulin 17.5 / 405.
    expect(83 * 17.5 / 405, closeTo(3.59, 0.005));
  });

  test('table layout: value in another column is joined to its test name', () {
    // Positions modelled on report 1: label on the left, value in a column in
    // the middle (slightly lower than the label), unit and range further right.
    const lines = [
      OcrLine('Triglycérides', 172, 451, 248, 464),
      OcrLine('Technique colorimétrique enzymatique', 190, 468, 320, 478),
      OcrLine('0,20', 517, 462, 545, 477),
      OcrLine('g/l', 568, 462, 585, 477),
      OcrLine('( Inférieur à 1,5 )', 640, 468, 722, 480),
      OcrLine('Glycémie à jeun', 170, 505, 270, 518),
      OcrLine('0,83', 517, 517, 545, 531),
      OcrLine('g/l', 570, 517, 586, 530),
      OcrLine('( 0,7 - 1,1 )', 640, 521, 695, 532),
      OcrLine('4,61', 515, 535, 545, 546),
      OcrLine('mmol/l', 568, 535, 605, 546),
      OcrLine('Hémoglobine glyquée : HBA1C', 157, 738, 360, 756),
      OcrLine('4,50', 505, 745, 532, 760),
      OcrLine('%', 566, 746, 576, 760),
      OcrLine('HDL-Cholestérol', 178, 342, 277, 355),
      OcrLine('0,40', 520, 349, 548, 365),
      OcrLine('g/l', 580, 349, 596, 363),
    ];
    final r = LabOcrService.parseText(LabOcrService.linesToText(lines));
    expect(r.triglyceridesValue, 0.20);
    expect(r.triglyceridesUnit, LipidUnit.gl);
    expect(r.glucoseValue, 0.83);
    expect(r.glucoseUnit, GlucoseUnit.gl);
    expect(r.hba1cPercent, 4.5);
    expect(r.hdlValue, 0.40);
    expect(r.hdlUnit, LipidUnit.gl);
  });
}
