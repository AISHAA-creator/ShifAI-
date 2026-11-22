import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifai/l10n/translator.dart';
import 'package:shifai/l10n/tx.dart';

void main() {
  test('English is the default and unknown text stays as it is', () {
    expect(L10n.tr('Home', 'en'), 'Home');
    expect(
      L10n.tr('A sentence nobody translated yet', 'fr'),
      'A sentence nobody translated yet',
    );
    expect(L10n.tr('', 'ar'), '');
  });

  test('fixed texts are translated', () {
    expect(L10n.tr('Home', 'fr'), 'Accueil');
    expect(L10n.tr('Home', 'ar'), 'الرئيسية');
    expect(L10n.tr('Sign in', 'fr'), 'Se connecter');
    expect(L10n.tr('Fès', 'ar'), 'فاس');
  });

  test('texts with a name or a number are translated', () {
    expect(L10n.tr('Welcome, Amina', 'fr'), 'Bienvenue, Amina');
    expect(L10n.tr('2 of 3 taken', 'fr'), '2 sur 3 pris');
    expect(L10n.tr('Tue, 10:30', 'fr'), 'Mar, 10:30');
    expect(
      L10n.tr('Mainly because of: age, fasting glucose.', 'fr'),
      'Principalement à cause de : âge, glycémie à jeun.',
    );
    expect(L10n.tr(' of 150 min', 'fr'), ' sur 150 min');
  });

  test('every language has every shared text', () {
    // Both dictionaries must cover the same texts.
    for (final text in ['Scan', 'Trends', 'Emergency', 'Reminders']) {
      expect(L10n.tr(text, 'fr'), isNot(text));
      expect(L10n.tr(text, 'ar'), isNot(text));
    }
  });

  test('two-line titles keep their line break', () {
    expect(L10n.title('Your', 'trends', 'en'), ('Your', 'trends'));
    expect(L10n.title('Your', 'trends', 'fr'), ('Votre', 'évolution'));
  });

  testWidgets('Tx follows the language of its scope', (tester) async {
    Widget app(String code) => MaterialApp(
      home: LangScope(code: code, child: const Tx('Home')),
    );
    await tester.pumpWidget(app('en'));
    expect(find.text('Home'), findsOneWidget);
    await tester.pumpWidget(app('fr'));
    expect(find.text('Accueil'), findsOneWidget);
    await tester.pumpWidget(app('ar'));
    expect(find.text('الرئيسية'), findsOneWidget);
  });
}
