import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/dev_flags.dart';
import '../providers/auth_provider.dart';
import 'app_shell.dart';
import 'auth_screen.dart';
import 'welcome_screen.dart';

class AppRootGate extends StatelessWidget {
  const AppRootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.recoveryPending) return const PasswordRecoveryScreen();
    if (auth.isSignedIn || DevFlags.skipAuth) return const AppShell();
    return const WelcomeScreen();
  }
}
