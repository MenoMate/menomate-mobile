import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/offline_mode_provider.dart';
import '../widgets/menomate_logo.dart';

/// Custom-scheme redirect for Supabase email confirmation links, so tapping
/// the confirmation email re-opens the Android app instead of localhost.
const _emailRedirectTo = 'com.menomate.menomate_mobile://auth-callback';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _infoMessage = null;
    });
  }

  void _backToSignIn() {
    setState(() {
      _isLoginMode = true;
      _errorMessage = null;
      // Keep _infoMessage so the email-confirmation guidance stays visible.
    });
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = 'Please enter both your email and password.',
      );
      return;
    }

    if (!_isLoginMode) {
      if (password.length < 6) {
        setState(
          () => _errorMessage = 'Password must be at least 6 characters long.',
        );
        return;
      }
      if (password != confirmPassword) {
        setState(
          () => _errorMessage = 'Passwords do not match. Please recheck.',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      if (_isLoginMode) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: _emailRedirectTo,
        );
        // No active session means email confirmation is required: surface
        // this as an info state, not an error.
        if (response.session == null && response.user != null) {
          if (mounted) {
            setState(() {
              _infoMessage = 'Account created! Please check your email and tap the confirmation link to verify your address, then sign in.';
            });
            _passwordController.clear();
            _confirmPasswordController.clear();
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = 'An unexpected connection error occurred.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- App Branding Header ---
                  const Center(child: MenoMateLogo(size: 68)),
                  const SizedBox(height: 16),
                  Text(
                    'MenoMate',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLoginMode
                        ? 'Welcome back! Sign in to your wellness space.'
                        : 'Create your account for personalized cycle & thermal care.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.secondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Auth Card (radius 18: same card family as Home) ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.outline, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Confirmation info banner (success, not an error)
                        if (_infoMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? MenoMateTheme.starrySage
                                  : MenoMateTheme.sakuraSage,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (theme.brightness == Brightness.dark
                                            ? MenoMateTheme.starrySageInk
                                            : MenoMateTheme.sakuraSageInk)
                                        .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.mark_email_read_outlined,
                                      color: theme.brightness == Brightness.dark
                                          ? MenoMateTheme.starrySageInk
                                          : MenoMateTheme.sakuraSageInk,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _infoMessage!,
                                        style: TextStyle(
                                          color:
                                              theme.brightness ==
                                                  Brightness.dark
                                              ? MenoMateTheme.starrySageInk
                                              : MenoMateTheme.sakuraSageInk,
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_isLoginMode) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _backToSignIn,
                                    icon: const Icon(
                                      Icons.login_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Back to Sign In'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Error message banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: colorScheme.secondary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: _isLoginMode
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onSubmitted: _isLoginMode ? (_) => _submit() : null,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: colorScheme.secondary,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: colorScheme.secondary,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),

                        // Confirm Password (Registration mode only)
                        if (!_isLoginMode) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(
                                Icons.lock_reset_outlined,
                                color: colorScheme.secondary,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: colorScheme.secondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLoginMode ? 'Sign In' : 'Create Account',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Way back for local-only users who opened sign-in from
                  // Settings and changed their mind. Shown only in offline
                  // mode; the authenticated flow is untouched.
                  if (ref.watch(isOfflineTrackingProvider))
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => context.pop(),
                        child: const Text('Not now — continue offline'),
                      ),
                    ),

                  // Mode Toggle Button
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                          ),
                          children: [
                            TextSpan(
                              text: _isLoginMode
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                            ),
                            TextSpan(
                              text: _isLoginMode ? "Create Account" : "Sign In",
                              style: TextStyle(
                                // Mode-switch link: interaction indigo, same
                                // role as nav/focus/secondary actions.
                                color: MenoMateTheme.interactionColor(
                                  theme.brightness == Brightness.dark,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
}
