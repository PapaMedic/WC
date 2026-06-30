import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/features/auth/data/auth_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isCreatingAccount = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    final authRepository = context.read<AuthRepository>();

    try {
      if (_isCreatingAccount) {
        await authRepository.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await authRepository.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = _friendlyAuthMessage(error));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Authentication failed. Check your connection.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = 'Enter your email address first.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      await context.read<AuthRepository>().sendPasswordResetEmail(email);
      if (mounted) {
        setState(() => _message = 'Password reset email sent.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = _friendlyAuthMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 720;
    final title = _isCreatingAccount ? 'Create account' : 'Sign in';
    final primaryAction = _isCreatingAccount ? 'Create account' : 'Sign in';

    return WildlandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? AppSpacing.md : AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _AuthHeader(),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            key: const ValueKey('auth-email-field'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Email is required.';
                              }
                              if (!email.contains('@')) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            key: const ValueKey('auth-password-field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return 'Password is required.';
                              }
                              if (_isCreatingAccount && password.length < 6) {
                                return 'Use at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _AuthMessage(message: _message!),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            key: const ValueKey('auth-submit-button'),
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(primaryAction),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _isCreatingAccount = !_isCreatingAccount;
                                      _message = null;
                                    });
                                  },
                            child: Text(
                              _isCreatingAccount
                                  ? 'Use an existing account'
                                  : 'Create a new account',
                            ),
                          ),
                          TextButton(
                            onPressed: _isSubmitting || _isCreatingAccount
                                ? null
                                : _sendPasswordReset,
                            child: const Text('Reset password'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'An account already exists for this email.',
      'invalid-email' => 'Enter a valid email address.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' =>
        'Email or password is incorrect.',
      'weak-password' => 'Use a stronger password.',
      'network-request-failed' => 'Network unavailable. Try again online.',
      _ => error.message ?? 'Authentication failed. Try again.',
    };
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.30),
            ),
          ),
          child: const Icon(
            Icons.local_fire_department,
            color: AppColors.primaryAccent,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WILDLAND',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                'COMPANION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: AppColors.secondaryAccent,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthMessage extends StatelessWidget {
  final String message;

  const _AuthMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.statusAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.statusAmber.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.statusAmber,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
