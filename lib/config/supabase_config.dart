import 'package:flutter/foundation.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const _urlValue = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKeyValue = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static String get url => _urlValue.trim();
  static String get publishableKey => _publishableKeyValue.trim();

  static String? get configurationError {
    if (url.isEmpty || publishableKey.isEmpty) {
      return 'Authentication is unavailable. Set SUPABASE_URL to your project '
          'URL and SUPABASE_PUBLISHABLE_KEY to its publishable (or anon) key '
          'using the --dart-define flags, then restart ShifAI. See README for '
          'the exact command.';
    }

    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.host.isEmpty || parsed.userInfo.isNotEmpty) {
      return 'SUPABASE_URL is invalid. Set it to your Supabase project URL and '
          'restart ShifAI with both required --dart-define values.';
    }
    final secureTransport =
        parsed.scheme == 'https' ||
        (parsed.scheme == 'http' &&
            const {'localhost', '127.0.0.1', '::1'}.contains(parsed.host));
    if (!secureTransport) {
      return 'SUPABASE_URL must use HTTPS (HTTP is allowed only for localhost). '
          'Correct it and restart ShifAI.';
    }
    if (url.toUpperCase().contains('YOUR_') ||
        publishableKey.toUpperCase().contains('YOUR_')) {
      return 'Replace the Supabase URL and publishable-key placeholders with '
          'the real values from Supabase Project Settings, then restart ShifAI.';
    }
    return null;
  }

  static bool get isConfigured => configurationError == null;

  static String get authRedirectUrl =>
      kIsWeb ? Uri.base.origin : 'com.shifai.shifai://login-callback/';
}
