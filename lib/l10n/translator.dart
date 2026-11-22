import 'package:flutter/material.dart';

import 'ar.dart';
import 'fr.dart';
import 'patterns.dart';

/// Looks up the French or Arabic version of a piece of English text.
///
/// English is the source: anything without a translation stays in English, so
/// a missing entry can never break a screen. Short fixed texts are matched
/// exactly; texts with a name or a number in them go through `patterns.dart`.
class L10n {
  L10n._();

  static const supported = ['en', 'fr', 'ar'];
  static const names = {'en': 'English', 'fr': 'Français', 'ar': 'العربية'};

  /// The language in use. Set by SettingsProvider; widgets read the language
  /// from [LangScope] so they rebuild when it changes.
  static String code = 'en';

  static bool get isArabic => code == 'ar';

  static Locale localeOf(String code) =>
      Locale(supported.contains(code) ? code : 'en');

  static Map<String, String> _map(String code) =>
      code == 'fr' ? frStrings : arStrings;

  static String tr(String text, [String? lang]) {
    final c = lang ?? code;
    if (c == 'en' || text.isEmpty) return text;
    final map = _map(c);
    final exact = map[text];
    if (exact != null) return exact;
    // Keep spaces around the text: ' of 150 min' stays padded.
    final core = text.trim();
    if (core.isNotEmpty && core != text) {
      final hit = tr(core, c);
      return hit == core ? text : text.replaceFirst(core, hit);
    }
    // 'age' -> 'Age' -> 'âge' (lower-case words inside sentences).
    if (core.isNotEmpty && core[0].toLowerCase() == core[0]) {
      final up = core[0].toUpperCase() + core.substring(1);
      final hit = map[up];
      if (hit != null && hit.isNotEmpty) {
        final low = c == 'ar' ? hit : hit[0].toLowerCase() + hit.substring(1);
        return text.replaceFirst(core, low);
      }
    }
    return translateDynamic(text, c) ?? text;
  }

  /// Two-line titles ('Your' / 'trends'). The translation of "first second"
  /// is written 'line one|line two' so the grammar can differ from English.
  static (String, String) title(String first, String second, [String? lang]) {
    final c = lang ?? code;
    if (c == 'en') return (first, second);
    final whole = _map(c)['title:$first $second'];
    if (whole != null && whole.contains('|')) {
      final i = whole.indexOf('|');
      return (whole.substring(0, i), whole.substring(i + 1));
    }
    return (tr(first, c), tr(second, c));
  }
}

/// Tells widgets which language is on, and rebuilds them when it changes.
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.code, required super.child});
  final String code;

  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.code ??
      L10n.code;

  @override
  bool updateShouldNotify(LangScope old) => old.code != code;
}

/// Wraps a form validator so its error message is shown in the chosen language.
FormFieldValidator<String>? trValidator(FormFieldValidator<String>? v) =>
    v == null
    ? null
    : (value) {
        final message = v(value);
        return message == null ? null : L10n.tr(message);
      };

/// Translate [text] for the language of [context].
String trOf(BuildContext context, String text) =>
    L10n.tr(text, LangScope.of(context));
