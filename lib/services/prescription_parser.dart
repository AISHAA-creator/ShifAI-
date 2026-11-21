/// Turns the text read from a printed prescription into medicine suggestions.
/// It only suggests: the person always checks and edits every line before
/// anything is added to the schedule (handwriting is not supported).
class MedicineCandidate {
  final String name;
  final String dose;
  final List<String> times; // "HH:mm"
  final String note;
  final bool timesGuessed;

  const MedicineCandidate({
    required this.name,
    required this.dose,
    required this.times,
    required this.note,
    required this.timesGuessed,
  });
}

class PrescriptionParser {
  PrescriptionParser._();

  static final _dose = RegExp(
    r'(\d{1,3}(?:[  ]\d{3})+|\d+(?:[.,]\d+)?)\s*(mg|mcg|µg|ug|g|ml|ui|iu)\b',
    caseSensitive: false,
  );
  static final _form = RegExp(
    r'\b(comprim[ée]s?|cp|g[ée]lules?|sachets?|sirop|ampoules?|stylo|gouttes?|tablets?|capsules?)\b',
    caseSensitive: false,
  );
  static final _perDay = RegExp(
    r'(\d)\s*(?:fois|x|/)\s*(?:par\s*|/\s*)?(?:jour|j\b|day)',
    caseSensitive: false,
  );
  static final _leading = RegExp(r'^[\s\d\.\)\-–•*]+');

  static const _morning = '08:00';
  static const _noon = '13:00';
  static const _evening = '20:00';

  static List<String>? _timesFromText(String text) {
    final t = text.toLowerCase();
    final morning = t.contains('matin') || t.contains('morning');
    final noon =
        t.contains('midi') || t.contains('noon') || t.contains('lunch');
    final evening =
        t.contains('soir') || t.contains('evening') || t.contains('night');
    if (morning || noon || evening) {
      return [if (morning) _morning, if (noon) _noon, if (evening) _evening];
    }
    var n = 0;
    final m = _perDay.firstMatch(t);
    if (m != null) n = int.parse(m.group(1)!);
    if (n == 0) {
      if (t.contains('three times') || t.contains('3 times')) n = 3;
      if (t.contains('twice') || t.contains('2 times')) n = 2;
      if (t.contains('once daily') || t.contains('once a day')) n = 1;
    }
    switch (n) {
      case 0:
        return null;
      case 1:
        return [_morning];
      case 2:
        return [_morning, _evening];
      case 3:
        return [_morning, _noon, _evening];
      default:
        return [_morning, '12:00', '16:00', _evening];
    }
  }

  static String _note(String text) {
    final t = text.toLowerCase();
    if (t.contains('avant') && t.contains('repas')) return 'before meals';
    if (t.contains('pendant') && t.contains('repas')) return 'with meals';
    if (t.contains('apr') && t.contains('repas')) return 'after meals';
    if (t.contains('with meal') || t.contains('with food')) return 'with meals';
    if (t.contains('before meal')) return 'before meals';
    if (t.contains('after meal')) return 'after meals';
    return '';
  }

  static List<MedicineCandidate> parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final out = <MedicineCandidate>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final dose = _dose.firstMatch(line);
      if (dose == null) continue;

      var name = line
          .substring(0, dose.start)
          .replaceFirst(_leading, '')
          .replaceAll(RegExp(r'[:,\-–]+\s*$'), '')
          .trim();
      if (name.isEmpty || RegExp(r'^\d+$').hasMatch(name)) continue;

      // Frequency: on this line after the dose, or on the line below when that
      // line has no medicine of its own.
      var rest = line.substring(dose.end);
      if (i + 1 < lines.length && !_dose.hasMatch(lines[i + 1])) {
        final next = lines[i + 1];
        if (_timesFromText(next) != null || _form.hasMatch(next)) {
          rest = '$rest $next';
        }
      }
      final times = _timesFromText(rest);
      out.add(
        MedicineCandidate(
          name: name,
          dose: dose.group(0)!.replaceAll(' ', ' ').trim(),
          times: times ?? const [_morning],
          note: _note(rest),
          timesGuessed: times == null,
        ),
      );
    }
    return out;
  }
}
