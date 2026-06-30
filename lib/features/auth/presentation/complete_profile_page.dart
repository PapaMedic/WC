import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/features/auth/data/auth_repository.dart';
import 'package:wildland_companion_v2/features/auth/presentation/auth_error_messages.dart';

class CompleteProfilePage extends StatefulWidget {
  final VoidCallback onProfileCompleted;

  const CompleteProfilePage({
    super.key,
    required this.onProfileCompleted,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_normalizeUsername);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_normalizeUsername);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _normalizeUsername() {
    final normalized = _usernameController.text.trim().toLowerCase();
    if (_usernameController.text == normalized) return;

    _usernameController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      await context.read<AuthRepository>().completeCurrentUserProfile(
            profile: SignUpProfileInput(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              username: _usernameController.text.trim().toLowerCase(),
            ),
          );
      if (mounted) {
        widget.onProfileCompleted();
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _message = authUserMessage(error));
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _message = profileUserMessage(error));
      }
    } on UsernameAlreadyTakenException catch (error) {
      if (mounted) {
        setState(() => _message = usernameUserMessage(error));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Unable to create your profile. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.account_circle_outlined,
                            color: AppColors.primaryAccent,
                            size: 44,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Complete your profile',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Your account was created. Add your profile details to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _firstNameController,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: const InputDecoration(
                              labelText: 'First name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'First name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _lastNameController,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.familyName],
                            decoration: const InputDecoration(
                              labelText: 'Last name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Last name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.username],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                            validator: (value) {
                              final username =
                                  value?.trim().toLowerCase() ?? '';
                              final validUsername =
                                  RegExp(r'^[a-z0-9_]{3,24}$');
                              if (username.isEmpty) {
                                return 'Username is required.';
                              }
                              if (!validUsername.hasMatch(username)) {
                                return 'Use 3-24 letters, numbers, or underscores.';
                              }
                              return null;
                            },
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _ProfileMessage(message: _message!),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Save profile'),
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
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  final String message;

  const _ProfileMessage({required this.message});

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
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
