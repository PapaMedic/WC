import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_companion_wordmark.dart';
import 'package:wildland_companion_v2/features/auth/services/auth_service.dart';

class AccountSetupPage extends StatefulWidget {
  final firebase_auth.User firebaseUser;

  const AccountSetupPage({
    super.key,
    required this.firebaseUser,
  });

  @override
  State<AccountSetupPage> createState() => _AccountSetupPageState();
}

class _AccountSetupPageState extends State<AccountSetupPage> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _message;
  bool _showCodeEntry = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _continueSolo() async {
    await _runSetup(() {
      return AuthService().createSoloProfile(
        uid: widget.firebaseUser.uid,
        displayName: widget.firebaseUser.displayName ?? '',
        email: widget.firebaseUser.email ?? '',
      );
    });
  }

  Future<void> _joinOrganization() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _message = 'Enter an organization access code.');
      return;
    }

    await _runSetup(() async {
      final result = await AuthService().createProfileWithOrganizationCode(
        uid: widget.firebaseUser.uid,
        displayName: widget.firebaseUser.displayName ?? '',
        email: widget.firebaseUser.email ?? '',
        code: code,
      );
      if (mounted && result.pendingApproval) {
        setState(() => _message = result.message);
      }
    });
  }

  Future<void> _runSetup(Future<void> Function() action) async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
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
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WildlandCompanionWordmark(),
                  const SizedBox(height: 22),
                  TacticalCard(
                    icon: Icons.workspaces_outline,
                    title: 'Account Setup',
                    subtitle: 'How do you want to use Wildland Companion?',
                    child: Column(
                      children: [
                        _SetupOption(
                          icon: Icons.person_outline,
                          title: 'Continue as Solo User',
                          subtitle:
                              'Use Wildland Companion independently and keep your records under your own account.',
                          onTap: _isSubmitting ? null : _continueSolo,
                        ),
                        const SizedBox(height: 12),
                        _SetupOption(
                          icon: Icons.groups_outlined,
                          title: 'Join an Organization',
                          subtitle:
                              'Enter an organization access code to connect with your agency, crew, or company.',
                          onTap: _isSubmitting
                              ? null
                              : () {
                                  setState(() => _showCodeEntry = true);
                                },
                        ),
                        if (_showCodeEntry) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Organization access code',
                              prefixIcon: Icon(Icons.key_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _isSubmitting ? null : _joinOrganization,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Continue'),
                            ),
                          ),
                        ],
                        if (_isSubmitting) ...[
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(),
                        ],
                        if (_message != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _message!,
                            style: const TextStyle(
                              color: AppColors.statusAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
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

class _SetupOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SetupOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111611),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryAccent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
