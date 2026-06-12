import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';
import 'package:wildland_companion_v2/core/models/cloud/organization_join_request.dart';
import 'package:wildland_companion_v2/core/repositories/organization_repository.dart';
import 'package:wildland_companion_v2/core/services/firebase/firebase_bootstrap.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isInitialized) {
      return const _AdminMessage(
        title: 'Admin Unavailable',
        message: 'Firebase is not configured for this build.',
      );
    }

    final user = context.watch<AppUser>();
    if (!user.canViewAdmin) {
      return const _AdminMessage(
        title: 'Admin Restricted',
        message: 'Your active organization role cannot manage admin tools.',
      );
    }

    final organizationId =
        user.organizationIds.isEmpty ? '' : user.organizationIds.first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TacticalCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Organization Admin',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminActionRow(
                  icon: Icons.people_outline,
                  title: 'Organization Users',
                  subtitle: 'View users, roles, and active status.',
                ),
                _AdminActionRow(
                  icon: Icons.key_outlined,
                  title: 'Access Codes',
                  subtitle: 'Create, disable, and review code usage.',
                ),
                _AdminActionRow(
                  icon: Icons.rule_folder_outlined,
                  title: 'Join Requests',
                  subtitle: 'Approve or deny pending organization access.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _JoinRequestsCard(organizationId: organizationId, user: user),
          const SizedBox(height: 14),
          const TacticalCard(
            icon: Icons.shield_outlined,
            title: 'Guardrails',
            child: Text(
              'Finance users cannot change roles. Members cannot access finance or admin pages. Admin actions are organization-scoped and finalized tickets remain read-only.',
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinRequestsCard extends StatelessWidget {
  final String organizationId;
  final AppUser user;

  const _JoinRequestsCard({
    required this.organizationId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    if (organizationId.isEmpty) {
      return const TacticalCard(
        icon: Icons.rule_folder_outlined,
        title: 'Join Requests',
        child: Text('No active organization selected.'),
      );
    }

    return FutureBuilder<List<OrganizationJoinRequest>>(
      future: OrganizationRepository().getPendingJoinRequests(organizationId),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const [];
        return TacticalCard(
          icon: Icons.rule_folder_outlined,
          title: 'Pending Join Requests',
          child: requests.isEmpty
              ? const Text('No pending organization requests.')
              : Column(
                  children: requests.map((request) {
                    return _JoinRequestRow(
                      organizationId: organizationId,
                      request: request,
                      reviewedBy: user.uid,
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

class _JoinRequestRow extends StatefulWidget {
  final String organizationId;
  final OrganizationJoinRequest request;
  final String reviewedBy;

  const _JoinRequestRow({
    required this.organizationId,
    required this.request,
    required this.reviewedBy,
  });

  @override
  State<_JoinRequestRow> createState() => _JoinRequestRowState();
}

class _JoinRequestRowState extends State<_JoinRequestRow> {
  bool _isSubmitting = false;

  Future<void> _approve() async {
    setState(() => _isSubmitting = true);
    try {
      await OrganizationRepository().approveJoinRequest(
        organizationId: widget.organizationId,
        requestId: widget.request.requestId,
        reviewedBy: widget.reviewedBy,
        workspaceId: '',
        requestedRole: widget.request.requestedRole,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deny() async {
    setState(() => _isSubmitting = true);
    try {
      await OrganizationRepository().denyJoinRequest(
        organizationId: widget.organizationId,
        requestId: widget.request.requestId,
        reviewedBy: widget.reviewedBy,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111611),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.request.displayName.isEmpty
                ? widget.request.email
                : widget.request.displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text('${widget.request.email} · ${widget.request.requestedRole}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _approve,
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
              ),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _deny,
                icon: const Icon(Icons.close),
                label: const Text('Deny'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdminActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primaryAccent),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _AdminMessage extends StatelessWidget {
  final String title;
  final String message;

  const _AdminMessage({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: TacticalCard(
            icon: Icons.lock_outline,
            title: title,
            child: Text(message),
          ),
        ),
      ),
    );
  }
}
