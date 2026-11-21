import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' show ClientException;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

enum _AuthMode { signIn, createAccount, forgotPassword, verifyEmail }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  String? _message;
  bool _acceptedTerms = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _changeMode(_AuthMode mode, {String? message}) {
    setState(() {
      _mode = mode;
      _message = message;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  Future<void> _submit() async {
    if (_mode == _AuthMode.verifyEmail) {
      await _resendVerification();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _message = null);
    if (!auth.isConfigured) {
      setState(() => _message = SupabaseConfig.configurationError);
      return;
    }

    try {
      switch (_mode) {
        case _AuthMode.signIn:
          await auth.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          break;
        case _AuthMode.createAccount:
          if (!_acceptedTerms) {
            setState(
              () => _message = 'Review and accept the privacy and health-use notices to continue.',
            );
            return;
          }
          final response = await auth.signUp(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
          if (response.session == null && mounted) {
            _changeMode(
              _AuthMode.verifyEmail,
              message: 'Check your email for the Supabase verification link before signing in.',
            );
          }
          break;
        case _AuthMode.forgotPassword:
          await auth.sendPasswordReset(_emailController.text);
          if (mounted) {
            setState(
              () => _message = 'If an account exists for this address, a password reset link has been sent.',
            );
          }
          break;
        case _AuthMode.verifyEmail:
          break;
      }
    } on AuthRetryableFetchException {
      if (mounted) {
        setState(
          () => _message =
              'Could not reach Supabase. Check your connection and try again.',
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _message =
              'The request timed out. Check your connection and try again.',
        );
      }
    } on AuthApiException catch (error) {
      if (!mounted) return;
      if (_mode == _AuthMode.signIn &&
          (error.code == 'email_not_confirmed' ||
              error.message.toLowerCase().contains('email not confirmed'))) {
        _changeMode(
          _AuthMode.verifyEmail,
          message: 'Verify your email before signing in. You can request a new verification link below.',
        );
      } else if (_mode == _AuthMode.signIn &&
          (error.code == 'invalid_credentials' ||
              error.message.toLowerCase().contains(
                'invalid login credentials',
              ))) {
        setState(() => _message = 'The email or password is incorrect.');
      } else {
        setState(() => _message = error.message);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on ClientException {
      if (mounted) {
        setState(
          () => _message =
              'Could not reach Supabase. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> _resendVerification() async {
    final auth = context.read<AuthProvider>();
    setState(() => _message = null);
    if (!auth.isConfigured) {
      setState(() => _message = SupabaseConfig.configurationError);
      return;
    }
    try {
      await auth.resendVerification(_emailController.text);
      if (mounted) {
        setState(
          () => _message = 'A new verification email has been requested.',
        );
      }
    } on AuthRetryableFetchException {
      if (mounted) {
        setState(
          () => _message =
              'Could not reach Supabase. Check your connection and try again.',
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _message =
              'The request timed out. Check your connection and try again.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on ClientException {
      if (mounted) {
        setState(
          () => _message =
              'Could not reach Supabase. Check your connection and try again.',
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 8) return 'Use at least 8 characters.';
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCreate = _mode == _AuthMode.createAccount;
    final isReset = _mode == _AuthMode.forgotPassword;
    final isVerify = _mode == _AuthMode.verifyEmail;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/shifai_logo.png',
                    width: 144,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isVerify
                      ? 'Verify your email'
                      : isReset
                      ? 'Reset your password'
                      : isCreate
                      ? 'Create your account'
                      : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  isVerify
                      ? 'Follow the link sent to ${_emailController.text}.'
                      : 'Sign in to access your ShifAI health dashboard.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                if (!isVerify)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (isCreate) ...[
                          TextFormField(
                            key: const Key('auth-name'),
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true)
                                ? 'Enter your name.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          key: const Key('auth-email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        if (!isReset) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('auth-password'),
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            autofillHints: isCreate
                                ? const [AutofillHints.newPassword]
                                : const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _passwordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () => setState(
                                  () => _passwordVisible = !_passwordVisible,
                                ),
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: isCreate ? _validatePassword : null,
                          ),
                        ],
                        if (isCreate) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('auth-confirm-password'),
                            controller: _confirmController,
                            obscureText: !_confirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                tooltip: _confirmPasswordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () => setState(
                                  () => _confirmPasswordVisible =
                                      !_confirmPasswordVisible,
                                ),
                                icon: Icon(
                                  _confirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: _validateConfirmation,
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _acceptedTerms,
                            onChanged: (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Wrap(
                              children: [
                                const Text('I accept the '),
                                InkWell(
                                  onTap: () => _showNotice(
                                    context,
                                    'Privacy notice',
                                    'ShifAI stores your account profile and '
                                        'confirmed lab values in your configured '
                                        'Supabase project. Row-Level Security is '
                                        'required on every user table. OCR runs '
                                        'on-device; report images are not uploaded. '
                                        'Do not enter data until your project and '
                                        'policies have been reviewed.',
                                  ),
                                  child: const Text(
                                    'privacy notice',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const Text(' and '),
                                InkWell(
                                  onTap: () => _showNotice(
                                    context,
                                    'Terms of use',
                                    'ShifAI is a screening and awareness tool, '
                                        'not a diagnostic device or a substitute '
                                        'for professional medical advice. Confirm '
                                        'results and treatment decisions with a '
                                        'licensed clinician.',
                                  ),
                                  child: const Text(
                                    'terms of use',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const Text('.'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _message!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.onSurface),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: auth.busy ? null : _submit,
                  child: auth.busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isVerify
                              ? 'Resend verification email'
                              : isReset
                              ? 'Send reset link'
                              : isCreate
                              ? 'Create account'
                              : 'Sign in',
                        ),
                ),
                const SizedBox(height: 8),
                if (_mode == _AuthMode.signIn)
                  TextButton(
                    onPressed: () => _changeMode(_AuthMode.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                TextButton(
                  onPressed: () => _changeMode(
                    isCreate ? _AuthMode.signIn : _AuthMode.createAccount,
                  ),
                  child: Text(
                    isCreate
                        ? 'Already have an account? Sign in'
                        : 'New to ShifAI? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotice(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_passwordController.text.length < 8 ||
        _passwordController.text != _confirmController.text) {
      setState(
        () => _message =
            'Use at least 8 characters and make sure both passwords match.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await context.read<AuthProvider>().updatePassword(
        _passwordController.text,
      );
    } on AuthRetryableFetchException {
      if (mounted) {
        setState(
          () => _message =
              'Could not reach Supabase. Check your connection and try again.',
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _message =
              'The request timed out. Check your connection and try again.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on ClientException {
      if (mounted) {
        setState(
          () => _message =
              'Could not reach Supabase. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a new password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: const TextStyle(color: AppColors.dangerText),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const CircularProgressIndicator()
                  : const Text('Update password'),
            ),
          ],
        ),
      ),
    );
  }
}
