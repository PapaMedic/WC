import 'package:flutter/material.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';
import 'package:wildland_companion_v2/core/repositories/organization_repository.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

class JoinOrganizationCard extends StatefulWidget {
  final AppUser user;

  const JoinOrganizationCard({
    super.key,
    required this.user,
  });

  @override
  State<JoinOrganizationCard> createState() => _JoinOrganizationCardState();
}

class _JoinOrganizationCardState extends State<JoinOrganizationCard> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _message = 'Enter an organization access code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final result = await OrganizationRepository().joinWithCode(
        user: widget.user,
        enteredCode: code,
        switchWorkspace: false,
      );
      if (!mounted) return;
      setState(() {
        _message = result.joined && result.workspaceId != null
            ? '${result.message} Switch workspace from the selector above.'
            : result.message;
        _codeController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      icon: Icons.key_outlined,
      title: 'Join Organization',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Organization access code',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Request Access'),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
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
    );
  }
}
