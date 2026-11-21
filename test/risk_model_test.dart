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
  final fixtures = jsonDecode(
    File('test/fixtures/risk_cases.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  group('matches scikit-learn exactly', () {
    for (final entry in {
      'basic': RiskBasis.body,
      'lab': RiskBasis.labs,
    }.entries) {
      test('${entry.key}: logistic regression, neural network and average', () {
        final set = model.setFor(entry.value);
        final cases = (fixtures[entry.key] as List)
            .cast<Map<String, dynamic>>();
        expect(cases, isNotEmpty);
        for (final c in cases) {
          final inputs = (c['inputs'] as Map<String, dynamic>);
          final raw = [
            for (final f in set.features) (inputs[f] as num).toDouble(),
          ];
          expect(set.logistic(raw), closeTo((c['lr'] as num).toDouble(), 1e-6));
          expect(set.network(raw), closeTo((c['mlp'] as num).toDouble(), 1e-6));
          expect(
            set.probability(raw),
            closeTo((c['both'] as num).toDouble(), 1e-6),
          );
        }
      });
    }
  });

  group('behaviour', () {
    const woman = UserProfile(
      age: 45,
      female: true,
      heightCm: 165,
      weightKg: 74.9,
      waistCm: 90.75,
    );
    const lean = UserProfile(
      age: 25,
      female: false,
      heightCm: 180,
      weightKg: 68,
      waistCm: 76,
    );
    const heavy = UserProfile(
      age: 55,
      female: false,
      heightCm: 170,
      weightKg: 105,
      waistCm: 118,
    );

    test('a larger waist and BMI raise the body estimate', () {
      final a = model.assessBody(lean).probability;
      final b = model.assessBody(woman).probability;
      final c = model.assessBody(heavy).probability;
      expect(a, lessThan(b));
      expect(b, lessThan(c));
    });

    test('bands follow the 25% and 50% cut-offs', () {
      expect(const RiskAssessment(0.10).band, RiskBand.low);
      expect(const RiskAssessment(0.30).band, RiskBand.moderate);
      expect(const RiskAssessment(0.50).band, RiskBand.high);
      expect(const RiskAssessment(0.384).percent, 38);
    });

    test('lab values move the estimate the right way', () {
      const good = LabInputs(
        glucoseMgdl: 82,
        hba1cPercent: 5.0,
        triglyceridesMgdl: 70,
        hdlMgdl: 62,
      );
      const poor = LabInputs(
        glucoseMgdl: 118,
        hba1cPercent: 6.2,
        triglyceridesMgdl: 240,
        hdlMgdl: 34,
      );
      final low = model.assessLabs(woman, good);
      final high = model.assessLabs(woman, poor);
      expect(low.basis, RiskBasis.labs);
      expect(low.probability, lessThan(0.25));
      expect(high.probability, greaterThan(0.5));
    });

    test('the main reasons are the inputs that push the estimate up', () {
      const poor = LabInputs(
        glucoseMgdl: 118,
        hba1cPercent: 6.2,
        triglyceridesMgdl: 240,
        hdlMgdl: 34,
      );
      final reasons = model.assessLabs(woman, poor).topFactors(max: 3);
      expect(reasons, isNotEmpty);
      expect(reasons.every((r) => r.contribution > 0), isTrue);
      // sorted largest first
      for (var i = 1; i < reasons.length; i++) {
        expect(reasons[i - 1].contribution >= reasons[i].contribution, isTrue);
      }
    });

    test('absurd inputs are clamped and still give a valid probability', () {
      const absurd = UserProfile(
        age: 90,
        female: true,
        heightCm: 230,
        weightKg: 250,
        waistCm: 200,
      );
      final p = model.assessBody(absurd).probability;
      expect(p, inInclusiveRange(0.0, 1.0));
      const labs = LabInputs(
        glucoseMgdl: 900,
        hba1cPercent: 20,
        triglyceridesMgdl: 5000,
        hdlMgdl: 5,
      );
      expect(
        model.assessLabs(absurd, labs).probability,
        inInclusiveRange(0.0, 1.0),
      );
    });
  });
}
