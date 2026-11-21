import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifai/models/user_profile.dart';
import 'package:shifai/services/risk_model.dart';

void main() {
  final model = RiskModel.fromJson(
    jsonDecode(File('assets/ml/risk_model.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('matches the Python (scikit-learn) model on fixed cases', () {
    final cases =
        jsonDecode(File('test/fixtures/risk_cases.json').readAsStringSync()) as List;
    expect(cases, isNotEmpty);
    for (final c in cases) {
      final p = model.probability(
        age: (c['age'] as num).toInt(),
        female: (c['female'] as num) == 1,
        bmi: (c['bmi'] as num).toDouble(),
        whtr: (c['whtr'] as num).toDouble(),
      );
      expect(p, closeTo((c['probability'] as num).toDouble(), 1e-9));
    }
  });

  test('a larger waist raises the estimate, all else equal', () {
    double at(double whtr) =>
        model.probability(age: 45, female: false, bmi: 27, whtr: whtr);
    expect(at(0.60), greaterThan(at(0.50)));
  });

  test('extreme inputs are clamped and stay a valid probability', () {
    final p = model.probability(age: 5, female: true, bmi: 400, whtr: 9);
    expect(p, inInclusiveRange(0.0, 1.0));
    expect(p.isNaN, isFalse);
  });

  test('risk bands', () {
    expect(const RiskAssessment(0.10).band, RiskBand.low);
    expect(const RiskAssessment(0.30).band, RiskBand.moderate);
    expect(const RiskAssessment(0.60).band, RiskBand.high);
    expect(const RiskAssessment(0.209).percent, 21);
  });

  test('profile derives BMI and waist-to-height', () {
    const p = UserProfile(
      age: 40,
      female: true,
      heightCm: 160,
      weightKg: 64,
      waistCm: 80,
    );
    expect(p.bmi, closeTo(25.0, 1e-9));
    expect(p.waistToHeight, closeTo(0.5, 1e-9));
  });
}
