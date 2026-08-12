import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';

enum _AuthMode { signIn, signUp }

/// Shown whenever there's no signed-in Supabase session. Email/password
/// only — see AppState.signInWithPassword / signUpWithPassword.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  _AuthMode mode = _AuthMode.signIn;
  bool submitting = false;
  bool passwordVisible = false;
  String? message;
  bool messageIsError = false;

  AppState? _appState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (!identical(_appState, state)) {
      _appState?.removeListener(_onAppStateChanged);
      _appState = state;
      _appState!.addListener(_onAppStateChanged);
      // Pick up a locked-account message that arrived before this ran —
      // deferred a frame since we're still inside the build phase here.
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAppStateChanged());
    }
  }

  /// Shows a snackbar when AppState signs us back out because the account
  /// isn't active — this screen isn't wrapped by the in-app toast overlay,
  /// so that path can't use `showToast` and reach the user otherwise.
  void _onAppStateChanged() {
    final msg = _appState?.accountLockedMessage;
    if (msg == null) return;
    _appState!.accountLockedMessage = null; // one-shot: consume so it only shows once
    if (mounted) _showErrorSnackBar(msg);
  }

  @override
  void dispose() {
    _appState?.removeListener(_onAppStateChanged);
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final emailValue = email.text.trim();
    final passwordValue = password.text;
    if (emailValue.isEmpty || passwordValue.isEmpty) {
      setState(() {
        message = 'Enter both your email and password.';
        messageIsError = true;
      });
      return;
    }

    setState(() {
      submitting = true;
      message = null;
    });

    final isSignIn = mode == _AuthMode.signIn;
    final result = isSignIn
        ? await state.signInWithPassword(emailValue, passwordValue)
        : await state.signUpWithPassword(emailValue, passwordValue);

    if (!mounted) return;
    setState(() => submitting = false);

    if (isSignIn && !result.success) {
      // Invalid login: a snackbar reads as a transient alert, distinct
      // from the sign-up flow's inline info ("check your email") message.
      _showErrorSnackBar(result.message ?? 'Invalid email or password.');
      return;
    }

    setState(() {
      message = result.message;
      messageIsError = !result.success;
    });
  }

  void _showErrorSnackBar(String text) {
    final colors = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.red,
          content: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSignIn = mode == _AuthMode.signIn;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(AppRadius.panel),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: colors.green, borderRadius: BorderRadius.circular(11)),
                        child: const Text('₱', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Text('ProfitPilot', style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800, fontSize: 17)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    isSignIn ? 'Sign in to your business' : 'Create your account',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colors.ink, letterSpacing: -0.02),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSignIn ? 'Your products, sales and expenses, synced to the cloud.' : 'Takes a minute — no card required.',
                    style: TextStyle(fontSize: 12.5, color: colors.muted),
                  ),
                  const SizedBox(height: 22),
                  _Field(
                    label: 'Email',
                    child: TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoration(colors),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 13),
                  _Field(
                    label: 'Password',
                    child: TextField(
                      controller: password,
                      obscureText: !passwordVisible,
                      autofillHints: [isSignIn ? AutofillHints.password : AutofillHints.newPassword],
                      decoration: _decoration(
                        colors,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => passwordVisible = !passwordVisible),
                          icon: Icon(
                            passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 19,
                            color: colors.muted,
                          ),
                          tooltip: passwordVisible ? 'Hide password' : 'Show password',
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: messageIsError ? colors.redSoft : colors.greenSoft,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      child: Text(
                        message!,
                        style: TextStyle(fontSize: 12.5, color: messageIsError ? colors.red : colors.greenInk),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.hover,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                      ),
                      child: submitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.8)),
                            )
                          : Text(isSignIn ? 'Sign in' : 'Create account', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: submitting
                          ? null
                          : () => setState(() {
                                mode = isSignIn ? _AuthMode.signUp : _AuthMode.signIn;
                                message = null;
                              }),
                      child: Text(
                        isSignIn ? "Don't have an account? Sign up" : 'Already have an account? Sign in',
                        style: TextStyle(color: colors.ink2, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(AppColors colors, {Widget? suffixIcon}) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field), borderSide: BorderSide(color: colors.line)),
        suffixIcon: suffixIcon,
      );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.ink2)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
