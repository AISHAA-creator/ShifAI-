import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/coaching_provider.dart';
import 'providers/lab_records_provider.dart';
import 'providers/nav_provider.dart';
import 'services/lab_cloud_service.dart';
import 'services/secure_supabase_storage.dart';
import 'screens/app_root_gate.dart';
import 'theme/app_theme.dart';

import 'package:device_preview/device_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSupabaseLocalStorage(),
        pkceAsyncStorage: SecureSupabasePkceStorage(),
      ),
    );
  }
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ShifAiApp(),
    ),
  );
}

class ShifAiApp extends StatelessWidget {
  const ShifAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, LabRecordsProvider>(
          create: (_) => LabRecordsProvider(
            cloud: SupabaseConfig.isConfigured
                ? LabCloudService(Supabase.instance.client)
                : null,
          ),
          update: (_, auth, records) {
            records!.setAccount(auth.user?.id);
            return records;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CoachingProvider>(
          create: (_) => CoachingProvider(
            client: SupabaseConfig.isConfigured
                ? Supabase.instance.client
                : null,
          ),
          update: (_, auth, coaching) {
            coaching!.setAccount(auth.user?.id);
            return coaching;
          },
        ),
        ChangeNotifierProvider(create: (_) => NavProvider()),
      ],
      child: MaterialApp(
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        title: 'ShifAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppRootGate(),
      ),
    );
  }
}
