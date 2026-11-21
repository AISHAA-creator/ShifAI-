import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'app_shell.dart';
import 'auth_screen.dart';

class AppRootGate extends StatelessWidget {
  const AppRootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.recoveryPending) return const PasswordRecoveryScreen();
    return auth.isSignedIn ? const AppShell() : const AuthScreen();
  }
}
