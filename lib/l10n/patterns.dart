import 'translator.dart';

/// Texts that contain a name or a number ("Welcome, Amina", "2 of 3 taken").
/// Each rule matches the English text and builds the French and Arabic one.
class _Rule {
  final RegExp pattern;
  final String Function(Match m) fr;
  final String Function(Match m) ar;
  _Rule(String source, this.fr, this.ar)
    : pattern = RegExp(source, dotAll: true);
}

final _rules = <_Rule>[
  _Rule(
    r'^Welcome, (.+)$',
    (m) => 'Bienvenue, ${m[1]}',
    (m) => 'مرحبًا، ${m[1]}',
  ),
  _Rule(
    r'^Morning, (.+)$',
    (m) => 'Bonjour, ${m[1]}',
    (m) => 'صباح الخير، ${m[1]}',
  ),
  _Rule(
    r'^Afternoon, (.+)$',
    (m) => 'Bon après-midi, ${m[1]}',
    (m) => 'مساء الخير، ${m[1]}',
  ),
  _Rule(
    r'^Evening, (.+)$',
    (m) => 'Bonsoir, ${m[1]}',
    (m) => 'مساء الخير، ${m[1]}',
  ),
  _Rule(
    r'^(\d+) of (\d+) taken$',
    (m) => '${m[1]} sur ${m[2]} pris',
    (m) => 'تم أخذ ${m[1]} من ${m[2]}',
  ),
  _Rule(r'^of (\d+) min$', (m) => 'sur ${m[1]} min', (m) => 'من ${m[1]} دقيقة'),
  _Rule(
    r'^(\d+) of (\d+) minutes this week$',
    (m) => '${m[1]} sur ${m[2]} minutes cette semaine',
    (m) => '${m[1]} من ${m[2]} دقيقة هذا الأسبوع',
  ),
  _Rule(
    r'^Today: (\d+) min$',
    (m) => "Aujourd'hui : ${m[1]} min",
    (m) => 'اليوم: ${m[1]} دقيقة',
  ),
  _Rule(r'^\+(\d+) min$', (m) => '+${m[1]} min', (m) => '+${m[1]} د'),
  _Rule(
    r'^Risk score (\d+)$',
    (m) => 'Score de risque ${m[1]}',
    (m) => 'درجة الخطر ${m[1]}',
  ),
  _Rule(
    r'^(\d+) lab checkups?$',
    (m) =>
        '${m[1]} bilan${m[1] == '1' ? '' : 's'} biologique${m[1] == '1' ? '' : 's'}',
    (m) => '${m[1]} تحاليل مخبرية',
  ),
  _Rule(
    r'^HOMA-IR, (.+)$',
    (m) => 'HOMA-IR, ${m[1]}',
    (m) => 'HOMA-IR، ${m[1]}',
  ),
  _Rule(
    r'^Test date: (.+)$',
    (m) => 'Date du test : ${m[1]}',
    (m) => 'تاريخ التحليل: ${m[1]}',
  ),
  _Rule(
    r'^Result of (.+)$',
    (m) => 'Résultat du ${m[1]}',
    (m) => 'نتيجة ${m[1]}',
  ),
  _Rule(
    r'^(.+) since (.+)$',
    (m) => '${m[1]} depuis ${m[2]}',
    (m) => '${m[1]} منذ ${m[2]}',
  ),
  _Rule(r'^In (.+)$', (m) => 'À ${m[1]}', (m) => 'في ${m[1]}'),
  _Rule(
    r'^(\d+) endocrinologists in (.+)$',
    (m) => '${m[1]} endocrinologues à ${m[2]}',
    (m) => '${m[1]} أخصائيين في الغدد الصماء في ${m[2]}',
  ),
  _Rule(
    r'^Doctors are being added in (.+)$',
    (m) => 'Des médecins seront bientôt ajoutés à ${m[1]}',
    (m) => 'سيتم إضافة أطباء قريبًا في ${m[1]}',
  ),
  _Rule(
    r'^No (.+) is listed in (.+) yet\. Doctors will be added city by city\. Try a bigger city nearby\.$',
    (m) =>
        'Aucun médecin (${_t(m[1]!, 'fr')}) n’est encore listé à ${m[2]}. Les médecins seront ajoutés ville par ville. Essayez une grande ville proche.',
    (m) =>
        'لا يوجد بعد طبيب (${_t(m[1]!, 'ar')}) مسجل في ${m[2]}. ستتم إضافة الأطباء مدينة بعد مدينة. جرّب مدينة أكبر قريبة.',
  ),
  _Rule(
    r'^Added by (.+)$',
    (m) => 'Ajouté par ${_t(m[1]!, 'fr')}',
    (m) => 'أضافه ${_t(m[1]!, 'ar')}',
  ),
  _Rule(
    r'^Call (.+)$',
    (m) => 'Appeler ${_t(m[1]!, 'fr')}',
    (m) => 'اتصل بـ ${_t(m[1]!, 'ar')}',
  ),
  _Rule(
    r'^Book (.+)$',
    (m) => 'Réserver ${_t(m[1]!, 'fr')}',
    (m) => 'احجز ${_t(m[1]!, 'ar')}',
  ),
  _Rule(
    r'^Appointment with (.+)$',
    (m) => 'Rendez-vous avec ${_t(m[1]!, 'fr')}',
    (m) => 'موعد مع ${_t(m[1]!, 'ar')}',
  ),
  _Rule(
    r'^Mainly because of: (.+)\.$',
    (m) => 'Principalement à cause de : ${_list(m[1]!, 'fr')}.',
    (m) => 'السبب الرئيسي: ${_list(m[1]!, 'ar')}.',
  ),
  _Rule(
    r'^Chance that your HOMA-IR is 2\.5 or higher\. Mainly because of: (.+)\.$',
    (m) =>
        'Probabilité que votre HOMA-IR soit de 2,5 ou plus. Principalement à cause de : ${_list(m[1]!, 'fr')}.',
    (m) =>
        'احتمال أن يكون HOMA-IR لديك 2.5 أو أعلى. السبب الرئيسي: ${_list(m[1]!, 'ar')}.',
  ),
  _Rule(
    r'^(.+) at (\d.*)$',
    (m) => '${m[1]} à ${m[2]}',
    (m) => '${m[1]} الساعة ${m[2]}',
  ),
  _Rule(
    r'^(Down|Up) (\d+)%$',
    (m) => '${m[1] == 'Up' ? 'Hausse' : 'Baisse'} ${m[2]} %',
    (m) => '${m[1] == 'Up' ? 'ارتفاع' : 'انخفاض'} ${m[2]}%',
  ),
  _Rule(
    r'^About (\d+) minutes after them your energy averages ([\d.]+) out of 5, against ([\d.]+) after light meals \((\d+) sweet or fried meals, (\d+) light meals\)\. Try a lighter version and a short walk afterwards\.$',
    (m) =>
        'Environ ${m[1]} minutes après, votre énergie est en moyenne de ${m[2]} sur 5, contre ${m[3]} après les repas légers (${m[4]} repas sucrés ou frits, ${m[5]} repas légers). Essayez une version plus légère et une courte marche ensuite.',
    (m) =>
        'بعد حوالي ${m[1]} دقيقة منها يبلغ متوسط طاقتك ${m[2]} من 5، مقابل ${m[3]} بعد الوجبات الخفيفة (${m[4]} وجبات حلوة أو مقلية، ${m[5]} وجبات خفيفة). جرّب نسخة أخف ومشيًا قصيرًا بعدها.',
  ),
  _Rule(
    r'^Your energy is at least as good after them \(([\d.]+) against ([\d.]+)\) \((\d+) sweet or fried meals, (\d+) light meals\)\. Your blood tests still matter more than how you feel\.$',
    (m) =>
        'Votre énergie est au moins aussi bonne après ces repas (${m[1]} contre ${m[2]}) (${m[3]} repas sucrés ou frits, ${m[4]} repas légers). Vos analyses de sang comptent toujours plus que votre ressenti.',
    (m) =>
        'طاقتك بعدها جيدة على الأقل مثل غيرها (${m[1]} مقابل ${m[2]}) (${m[3]} وجبات حلوة أو مقلية، ${m[4]} وجبات خفيفة). تحاليل الدم تظل أهم من إحساسك.',
  ),
  _Rule(
    r'^Your energy is similar after light and sweet or fried meals \((\d+) sweet or fried meals, (\d+) light meals\)\. Keep logging to see if a pattern appears\.$',
    (m) =>
        'Votre énergie est similaire après les repas légers et les repas sucrés ou frits (${m[1]} repas sucrés ou frits, ${m[2]} repas légers). Continuez à noter pour voir si un schéma apparaît.',
    (m) =>
        'طاقتك متشابهة بعد الوجبات الخفيفة والحلوة أو المقلية (${m[1]} وجبات حلوة أو مقلية، ${m[2]} وجبات خفيفة). واصل التسجيل لترى إن ظهر نمط.',
  ),
  _Rule(
    r'^You wanted something sweet after (\d+)% of them, against (\d+)% after light meals\.$',
    (m) =>
        'Vous aviez envie de sucré après ${m[1]} % d’entre eux, contre ${m[2]} % après les repas légers.',
    (m) =>
        'اشتهيت شيئًا حلوًا بعد ${m[1]}% منها، مقابل ${m[2]}% بعد الوجبات الخفيفة.',
  ),
  _Rule(
    r'^Your energy is lowest after (.+)$',
    (m) => 'Votre énergie est au plus bas après le ${_t(m[1]!, 'fr')}',
    (m) => 'طاقتك في أدنى مستوياتها بعد ${_t(m[1]!, 'ar')}',
  ),
  _Rule(
    r'^It averages ([\d.]+) out of 5, against ([\d.]+) after (.+)\.$',
    (m) =>
        'Elle est en moyenne de ${m[1]} sur 5, contre ${m[2]} après le ${_t(m[3]!, 'fr')}.',
    (m) => 'متوسطها ${m[1]} من 5، مقابل ${m[2]} بعد ${_t(m[3]!, 'ar')}.',
  ),
  _Rule(
    r'^Log a meal, then check your energy about 90 minutes later\. ShifAI needs at least (\d+) light and (\d+) sweet or fried meals with an energy check to find a pattern\. So far: (\d+) meals? matched\.$',
    (m) =>
        'Notez un repas, puis vérifiez votre énergie environ 90 minutes plus tard. ShifAI a besoin d’au moins ${m[1]} repas légers et ${m[2]} repas sucrés ou frits avec un point d’énergie pour trouver un schéma. Pour l’instant : ${m[3]} repas associé${m[3] == '1' ? '' : 's'}.',
    (m) =>
        'سجّل وجبة ثم تحقق من طاقتك بعد حوالي 90 دقيقة. يحتاج ShifAI إلى ${m[1]} وجبات خفيفة و${m[2]} وجبات حلوة أو مقلية على الأقل مع تقييم للطاقة ليجد نمطًا. حتى الآن: ${m[3]} وجبة مرتبطة.',
  ),
  _Rule(
    r'^(.+), (.+)$',
    (m) => '${_t(m[1]!, 'fr')}, ${_t(m[2]!, 'fr')}',
    (m) => '${_t(m[1]!, 'ar')}، ${_t(m[2]!, 'ar')}',
  ),
  _Rule(
    r'^(.+) is due$',
    (m) => '${m[1]} : à prendre',
    (m) => 'حان موعد ${m[1]}',
  ),
  _Rule(
    r'^planned at (.+)$',
    (m) => 'prévu à ${m[1]}',
    (m) => 'مقرر في ${m[1]}',
  ),
  _Rule(
    r'^Remove (.+)\?$',
    (m) => 'Supprimer ${m[1]} ?',
    (m) => 'حذف ${m[1]}؟',
  ),
  _Rule(
    r'^Your last result is (\d+) days old\.$',
    (m) => 'Votre dernier résultat date de ${m[1]} jours.',
    (m) => 'عمر آخر نتيجة لديك ${m[1]} يومًا.',
  ),
  _Rule(
    r'^Notifications, (\d+) new$',
    (m) => 'Notifications, ${m[1]} nouvelle${m[1] == '1' ? '' : 's'}',
    (m) => 'الإشعارات، ${m[1]} جديد',
  ),
  _Rule(
    r'^Enter (\d+).(\d+) (.+)$',
    (m) => 'Entrez ${m[1]}–${m[2]} ${m[3]}',
    (m) => 'أدخل ${m[1]}–${m[2]} ${m[3]}',
  ),
  _Rule(
    r'^Enter a positive (.+) value\.$',
    (m) => 'Entrez une valeur positive pour ${_t(m[1]!, 'fr')}.',
    (m) => 'أدخل قيمة موجبة لـ ${_t(m[1]!, 'ar')}.',
  ),
  _Rule(
    r'^Follow the link sent to (.*)\.$',
    (m) => 'Suivez le lien envoyé à ${m[1]}.',
    (m) => 'اتبع الرابط المرسل إلى ${m[1]}.',
  ),
  _Rule(
    r'^How is your energy after (.+)\?$',
    (m) =>
        'Comment est votre énergie après le ${_t(_cap(m[1]!), 'fr').toLowerCase()} ?',
    (m) => 'كيف طاقتك بعد ${_t(_cap(m[1]!), 'ar')}؟',
  ),
  _Rule(
    r'^Energy: (.+)$',
    (m) => 'Énergie : ${_energy(m[1]!, 'fr')}',
    (m) => 'الطاقة: ${_energy(m[1]!, 'ar')}',
  ),
  _Rule(
    r'^Energy (\d), (.+)$',
    (m) => 'Énergie ${m[1]}, ${_t(m[2]!, 'fr')}',
    (m) => 'الطاقة ${m[1]}، ${_t(m[2]!, 'ar')}',
  ),
  _Rule(
    r'^Add (\d+) to my schedule$',
    (m) => 'Ajouter ${m[1]} à mon programme',
    (m) => 'أضف ${m[1]} إلى جدولي',
  ),
  _Rule(
    r'^(\d+) reminders? added\.$',
    (m) =>
        '${m[1]} rappel${m[1] == '1' ? '' : 's'} ajouté${m[1] == '1' ? '' : 's'}.',
    (m) => 'تمت إضافة ${m[1]} تذكير.',
  ),
  _Rule(
    r'^(\d+) local results? will be copied to this signed-in account\. Existing account records will not be replaced\.$',
    (m) =>
        '${m[1]} résultat(s) local(aux) seront copiés dans ce compte. Les données existantes du compte ne seront pas remplacées.',
    (m) =>
        'سيتم نسخ ${m[1]} من النتائج المحلية إلى هذا الحساب. لن يتم استبدال سجلات الحساب الحالية.',
  ),
  _Rule(
    r'^(\d+) results? synced to this account\.$',
    (m) => '${m[1]} résultat(s) synchronisé(s) avec ce compte.',
    (m) => 'تمت مزامنة ${m[1]} من النتائج مع هذا الحساب.',
  ),
  _Rule(
    r'^Could not open the dialer\. Call (.+)\.$',
    (m) => 'Impossible d’ouvrir le clavier téléphonique. Appelez le ${m[1]}.',
    (m) => 'تعذر فتح تطبيق الاتصال. اتصل بالرقم ${m[1]}.',
  ),
  _Rule(
    r'^No match for "(.+)"\.$',
    (m) => 'Aucun résultat pour « ${m[1]} ».',
    (m) => 'لا توجد نتائج لـ «${m[1]}».',
  ),
  _Rule(
    r'^Clear (.+)$',
    (m) => 'Effacer ${_t(m[1]!, 'fr')}',
    (m) => 'مسح ${_t(m[1]!, 'ar')}',
  ),
];

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _t(String s, String code) => L10n.tr(s, code);

String _list(String items, String code) =>
    items.split(', ').map((e) => _t(e, code)).join(code == 'ar' ? '، ' : ', ');

String _energy(String text, String code) {
  // "low, craving sweets" -> level and craving
  final parts = text.split(', ');
  final level = _t(_cap(parts.first), code).toLowerCase();
  if (parts.length > 1) {
    return '$level, ${_t(parts.sublist(1).join(', '), code)}';
  }
  return level;
}

String? translateDynamic(String text, String code) {
  for (final r in _rules) {
    final m = r.pattern.firstMatch(text);
    if (m != null) {
      final out = code == 'fr' ? r.fr(m) : r.ar(m);
      return out == text ? null : out;
    }
  }
  return null;
}
