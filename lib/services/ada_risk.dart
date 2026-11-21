/// Self-assessment of the risk of prediabetes / type 2 diabetes from a short
/// list of questions, after the American Diabetes Association risk test
/// (Bang et al., Annals of Internal Medicine, 2009). A score of 5 or more
/// means a higher risk and a blood test is worth doing.
///
/// This is a questionnaire, not a diagnosis and not an image analysis.
class AdaRiskInput {
  final int age;
  final bool female;
  final double bmi;
  final bool gestationalDiabetes;
  final bool familyHistory;
  final bool highBloodPressure;
  final bool physicallyActive;

  const AdaRiskInput({
    required this.age,
    required this.female,
    required this.bmi,
    required this.gestationalDiabetes,
    required this.familyHistory,
    required this.highBloodPressure,
    required this.physicallyActive,
  });
}

class AdaRisk {
  AdaRisk._();

  static const highThreshold = 5;

  static int score(AdaRiskInput i) {
    var points = 0;
    if (i.age >= 60) {
      points += 3;
    } else if (i.age >= 50) {
      points += 2;
    } else if (i.age >= 40) {
      points += 1;
    }
    if (!i.female) points += 1;
    if (i.female && i.gestationalDiabetes) points += 1;
    if (i.familyHistory) points += 1;
    if (i.highBloodPressure) points += 1;
    if (!i.physicallyActive) points += 1;
    if (i.bmi >= 40) {
      points += 3;
    } else if (i.bmi >= 30) {
      points += 2;
    } else if (i.bmi >= 25) {
      points += 1;
    }
    return points;
  }

  static bool isHigh(int score) => score >= highThreshold;
}
