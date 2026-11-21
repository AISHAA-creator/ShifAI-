import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider()
    : this._(SupabaseConfig.isConfigured ? Supabase.instance.client : null);

  AuthProvider._(this._client) {
    _user = _client?.auth.currentUser;
    if (_client != null) {
      _authSubscription = _client.auth.onAuthStateChange.listen((state) {
        _user = state.session?.user;
        _recoveryPending = state.event == AuthChangeEvent.passwordRecovery;
        notifyListeners();
      });
    }
  }

  final SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;
  User? _user;
  bool _busy = false;
  bool _recoveryPending = false;

  bool get isConfigured => _client != null;
  bool get isSignedIn => _user != null;
  bool get busy => _busy;
  bool get recoveryPending => _recoveryPending;
  User? get user => _user;
  String? get email => _user?.email;
  String get displayName {
    final name = _user?.userMetadata?['display_name'];
    return name is String && name.trim().isNotEmpty
        ? name.trim()
        : 'ShifAI member';
  }

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    _setBusy(true);
    try {
      return await client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: SupabaseConfig.authRedirectUrl,
        data: {'display_name': name.trim()},
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    _setBusy(true);
    try {
      return await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final client = _requireClient();
    _setBusy(true);
    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: SupabaseConfig.authRedirectUrl,
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> resendVerification(String email) async {
    final client = _requireClient();
    _setBusy(true);
    try {
      await client.auth.resend(type: OtpType.signup, email: email.trim());
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updatePassword(String password) async {
    final client = _requireClient();
    _setBusy(true);
    try {
      await client.auth.updateUser(UserAttributes(password: password));
      _recoveryPending = false;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    final client = _requireClient();
    _setBusy(true);
    try {
      await client.auth.signOut();
    } finally {
      _setBusy(false);
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        SupabaseConfig.configurationError ?? 'Supabase is not configured.',
      );
    }
    return client;
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
