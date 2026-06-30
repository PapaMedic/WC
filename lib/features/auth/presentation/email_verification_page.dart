import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/features/auth/data/auth_repository.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isRefreshing = false;
  bool _isSending = false;
  String? _message;

  Future<void> _refreshVerificationStatus() async {
    setState(() {
      _isRefreshing = true;
      _message = null;
    });

    try {
      final user = await context.read<AuthRepository>().reloadCurrentUser();
      if (mounted && user?.emailVerified != true) {
        setState(() => _message = 'Email is not verified yet.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _message = error.message ?? 'Could not refresh verification.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      await context.read<AuthRepository>().sendEmailVerification();
      if (mounted) {
        setState(() => _message = 'Verification email sent.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () =>
              _message = error.message ?? 'Could not send verification email.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WildlandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.mark_email_unread_outlined,
                          color: AppColors.primaryAccent,
                          size: 44,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Verify your email',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'A verification link was sent to ${widget.email}. '
                          'Open that link, then return here and refresh.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.statusAmber,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed:
                              _isRefreshing ? null : _refreshVerificationStatus,
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text('I verified my email'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed:
                              _isSending ? null : _resendVerificationEmail,
                          icon: const Icon(Icons.outgoing_mail),
                          label: const Text('Resend verification email'),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.read<AuthRepository>().signOut(),
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out'),
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
    );
  }
}
