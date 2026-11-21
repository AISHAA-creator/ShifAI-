import 'package:flutter/foundation.dart';

/// Debug-only switch to open the app without a Supabase account, to test the
/// scan and screens on a phone before cloud keys are available:
///
///   flutter run --dart-define=DEV_SKIP_AUTH=true
///
/// It does nothing in release builds, and nothing is faked: records stay
/// local-only on the device, exactly like a signed-out session.
class DevFlags {
  DevFlags._();

  static const _skipAuth = bool.fromEnvironment('DEV_SKIP_AUTH');

  static bool get skipAuth => !kReleaseMode && _skipAuth;
}
