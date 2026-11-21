import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/lab_records_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/app_shell.dart';
import 'services/risk_model.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ShifAiApp());
}

class ShifAiApp extends StatelessWidget {
  /// Optional pre-loaded risk model (tests); normally loaded from assets.
  final RiskModel? riskModel;
  const ShifAiApp({super.key, this.riskModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LabRecordsProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider(model: riskModel)),
      ],
      child: MaterialApp(
        title: 'ShifAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      ),
    );
  }
}
