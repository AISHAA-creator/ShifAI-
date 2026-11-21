import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../models/user_profile.dart';

enum RiskBand { low, moderate, high }

extension RiskBandLabel on RiskBand {
  String get label {
    switch (this) {
      case RiskBand.low:
        return 'Low risk';
      case RiskBand.moderate:
        return 'Moderate risk';
      case RiskBand.high:
        return 'High risk';
    }
  }
}

class RiskAssessment {
  /// Estimated chance (0..1) that this person's HOMA-IR is 2.9 or higher.
  final double probability;
  const RiskAssessment(this.probability);

  int get percent => (probability * 100).round();

  RiskBand get band {
    if (probability < 0.25) return RiskBand.low;
    if (probability < 0.50) return RiskBand.moderate;
    return RiskBand.high;
  }
}

/// Logistic regression trained offline on NHANES (see ml/train_risk_model.py),
/// evaluated here on-device. No network, no data leaves the phone.
class RiskModel {
  final List<String> features;
  final List<double> mean;
  final List<double> scale;
  final List<double> coef;
  final double intercept;
  final int trainedOn;
  final double heldoutAuc;

  const RiskModel({
    required this.features,
    required this.mean,
    required this.scale,
    required this.coef,
    required this.intercept,
    required this.trainedOn,
    required this.heldoutAuc,
  });

  factory RiskModel.fromJson(Map<String, dynamic> json) {
    List<double> nums(String key) =>
        (json[key] as List).map((e) => (e as num).toDouble()).toList();
    return RiskModel(
      features: (json['features'] as List).cast<String>(),
      mean: nums('mean'),
      scale: nums('scale'),
      coef: nums('coef'),
      intercept: (json['intercept'] as num).toDouble(),
      trainedOn: (json['n'] as num).toInt(),
      heldoutAuc: (json['heldout_auc'] as num).toDouble(),
    );
  }

  static Future<RiskModel> loadAsset() async {
    final raw = await rootBundle.loadString('assets/ml/risk_model.json');
    return RiskModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Inputs are clamped to the range the model was trained on, so an odd
  /// measurement can't push the estimate outside what it has actually seen.
  double probability({
    required int age,
    required bool female,
    required double bmi,
    required double whtr,
  }) {
    final raw = <String, double>{
      'age': age.clamp(18, 80).toDouble(),
      'female': female ? 1.0 : 0.0,
      'bmi': bmi.clamp(14.0, 60.0),
      'whtr': whtr.clamp(0.3, 1.0),
    };
    var z = intercept;
    for (var i = 0; i < features.length; i++) {
      z += coef[i] * ((raw[features[i]]! - mean[i]) / scale[i]);
    }
    return 1 / (1 + math.exp(-z));
  }

  RiskAssessment assess(UserProfile p) => RiskAssessment(
    probability(
      age: p.age,
      female: p.female,
      bmi: p.bmi,
      whtr: p.waistToHeight,
    ),
  );
}
