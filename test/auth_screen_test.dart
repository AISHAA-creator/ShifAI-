import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shifai/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets(
    'unconfigured launch shows real sign-in and configuration error',
    (tester) async {
      await tester.pumpWidget(const ShifAiApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('auth-email')), findsOneWidget);
      expect(find.byKey(const Key('auth-password')), findsOneWidget);
      expect(find.textContaining('SUPABASE_URL'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
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
      await tester.ensureVisible(find.text('Sign in'));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.textContaining('SUPABASE_URL'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('password visibility can be toggled', (tester) async {
    await tester.pumpWidget(const ShifAiApp());
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
    await tester.pumpWidget(const ShifAiApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final createLink = find.text('New to ShifAI? Create an account');
    await tester.ensureVisible(createLink);
    await tester.tap(createLink);
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth-name')), 'Test User');
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'person@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'valid-password',
    );
    await tester.enterText(
      find.byKey(const Key('auth-confirm-password')),
      'valid-password',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    final signInLink = find.text('Already have an account? Sign in');
    await tester.ensureVisible(signInLink);
    await tester.tap(signInLink);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'person@example.com',
    );
    await tester.ensureVisible(find.text('Send reset link'));
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
