import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shifai/main.dart';
import 'package:shifai/screens/lab_scan_screen.dart';
import 'package:shifai/services/risk_model.dart';
import 'package:shifai/theme/app_theme.dart';


final testModel = RiskModel.fromJson(
  jsonDecode(File('assets/ml/risk_model.json').readAsStringSync())
      as Map<String, dynamic>,
);

Future<void> pumpAppWithModel(WidgetTester tester) async {
  await tester.pumpWidget(ShifAiApp(riskModel: testModel));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home shows the welcome state and the four-item bar', (tester) async {
    await tester.pumpWidget(const ShifAiApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to ShifAI'), findsOneWidget);
    for (final label in ['Home', 'Scan', 'Trends', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('trends and profile tabs open', (tester) async {
    await tester.pumpWidget(const ShifAiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();
    expect(find.text('No results yet'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Private and on-device'), findsOneWidget);
  });

  testWidgets('adding a result computes HOMA-IR and opens Trends', (tester) async {
    await tester.pumpWidget(const ShifAiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    // glucose 0.95 g/L = 95 mg/dL, insulin 9 uIU/mL -> 95 * 9 / 405 = 2.11
    await tester.enterText(find.byType(TextFormField).at(0), '0.95');
    await tester.enterText(find.byType(TextFormField).at(1), '9');
    await tester.tap(find.text('Save & calculate'));
    await tester.pumpAndSettle();

    expect(find.text('Metabolic Trends'), findsOneWidget);
    expect(find.text('2.11'), findsWidgets);
    expect(find.text('Borderline'), findsWidgets);
  });

  testWidgets('measurements give a risk estimate on the dashboard', (tester) async {
    await pumpAppWithModel(tester);

    expect(find.text('Add my measurements'), findsOneWidget);
    await tester.tap(find.text('Add my measurements'));
    await tester.pumpAndSettle();

    // 45-year-old woman, BMI 27.5, waist-to-height 0.55 -> about 21%
    await tester.enterText(find.byType(TextFormField).at(0), '45');
    await tester.enterText(find.byType(TextFormField).at(1), '165');
    await tester.enterText(find.byType(TextFormField).at(2), '74.9');
    await tester.enterText(find.byType(TextFormField).at(3), '90.75');
    await tester.ensureVisible(find.text('Save & see my estimate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & see my estimate'));
    await tester.pumpAndSettle();

    expect(find.text('21%'), findsOneWidget);
    expect(find.text('Low risk'), findsOneWidget);
  });

  testWidgets('form rejects an out-of-range height', (tester) async {
    await pumpAppWithModel(tester);

    await tester.tap(find.text('Add my measurements'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '45');
    await tester.enterText(find.byType(TextFormField).at(1), '16');
    await tester.enterText(find.byType(TextFormField).at(2), '70');
    await tester.enterText(find.byType(TextFormField).at(3), '80');
    await tester.ensureVisible(find.text('Save & see my estimate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & see my estimate'));
    await tester.pumpAndSettle();

    expect(find.text('Enter 120–230 cm'), findsOneWidget);
  });

  testWidgets('scan screen lays out without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LabScanScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. Scan Sheet'), findsOneWidget);
    expect(find.text('Align printed paper in frame'), findsOneWidget);
  });
}
