import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:shifai/providers/auth_provider.dart';
import 'package:shifai/providers/coaching_provider.dart';
import 'package:shifai/providers/lab_records_provider.dart';
import 'package:shifai/providers/nav_provider.dart';
import 'package:shifai/screens/app_shell.dart';
import 'package:shifai/screens/lab_entry_form_screen.dart';
import 'package:shifai/screens/lab_scan_screen.dart';
import 'package:shifai/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> openAppShell(
    WidgetTester tester, {
    AuthProvider? authProvider,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => authProvider ?? AuthProvider(),
          ),
          ChangeNotifierProvider(create: (_) => LabRecordsProvider()),
          ChangeNotifierProvider(create: (_) => CoachingProvider()),
          ChangeNotifierProvider(create: (_) => NavProvider()),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const AppShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home shows the welcome state and the four-item bar', (
    tester,
  ) async {
    await openAppShell(tester);

    expect(find.text('Welcome to ShifAI'), findsOneWidget);
    for (final label in ['Home', 'Scan', 'Trends', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('signed-in home footer wraps on a phone-width screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(350, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openAppShell(tester, authProvider: _SignedInAuthProvider());
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-storage-footer')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(const Key('home-storage-footer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trends and profile tabs open', (tester) async {
    await openAppShell(tester);

    await tester.tap(find.text('Trends'));
    await tester.pumpAndSettle();
    expect(find.text('No results yet'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Local-only storage'), findsOneWidget);
  });

  testWidgets('adding a result computes HOMA-IR and opens Trends', (
    tester,
  ) async {
    await openAppShell(tester);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();

    // glucose 0.95 g/L = 95 mg/dL, insulin 9 uIU/mL -> 95 * 9 / 405 = 2.11
    await tester.enterText(find.byType(TextFormField).at(0), '0.95');
    await tester.enterText(find.byType(TextFormField).at(1), '9');
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & calculate'));
    await tester.pumpAndSettle();

    expect(find.text('Metabolic Trends'), findsOneWidget);
    expect(find.text('2.11'), findsWidgets);
    expect(find.text('Borderline'), findsWidgets);
  });

  testWidgets('scan screen lays out without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LabScanScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('1. Scan Sheet'), findsOneWidget);
    expect(find.text('Align printed paper in frame'), findsOneWidget);
  });

  testWidgets('adding and dismissing a lab marker disposes fields safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LabEntryFormScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Missing Lab Marker'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(4), 'Vitamin D');
    await tester.enterText(find.byType(TextFormField).at(5), '30');
    await tester.enterText(find.byType(TextFormField).at(6), 'ng/mL');
    await tester.tap(find.text('Add marker'));
    await tester.pumpAndSettle();

    expect(find.text('Vitamin D'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Add Missing Lab Marker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Vitamin D'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SignedInAuthProvider extends AuthProvider {
  @override
  bool get isSignedIn => true;
}
