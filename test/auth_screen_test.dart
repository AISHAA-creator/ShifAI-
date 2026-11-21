import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shifai/main.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // The test font (Ahem) is about twice as wide as a real font, so scale the
  // text to make widths realistic.
  tester.platformDispatcher.textScaleFactorTestValue = 0.55;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('launch shows the welcome screen, then a real sign-in', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(const ShifAiApp());
    await tester.pumpAndSettle();

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome\nback'), findsOneWidget);
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
    expect(find.byKey(const Key('auth-password')), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Preview in local-only mode'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'person@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'valid-password',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    phone(tester);
    await tester.pumpWidget(const ShifAiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    EditableText passwordField() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('auth-password')),
        matching: find.byType(EditableText),
      ),
    );

    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
  });

  testWidgets('create account and password reset report missing config', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(const ShifAiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Create\naccount'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth-name')), 'Test User');
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'person@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'valid-password',
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Already a member? Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your\npassword'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'person@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
