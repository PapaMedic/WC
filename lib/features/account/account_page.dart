import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';
import 'package:wildland_companion_v2/core/models/cloud/organization.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';
import 'package:wildland_companion_v2/core/repositories/organization_repository.dart';
import 'package:wildland_companion_v2/core/repositories/user_repository.dart';
import 'package:wildland_companion_v2/core/repositories/workspace_repository.dart';
import 'package:wildland_companion_v2/core/services/firebase/firebase_bootstrap.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/features/account/join_organization_card.dart';
import 'package:wildland_companion_v2/features/account/workspace_selector.dart';
import 'package:wildland_companion_v2/features/auth/services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<_AccountData>? _accountDataFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_accountDataFuture == null && FirebaseBootstrap.isInitialized) {
      _accountDataFuture = _loadAccountData();
    }
  }

  Future<_AccountData> _loadAccountData() async {
    final user = context.read<AppUser>();
    final organizationRepository = OrganizationRepository();
    final organizations =
        await organizationRepository.getOrganizations(user.organizationIds);
    final organizationWorkspaceIds =
        organizations.map((organization) => organization.workspaceId).toList();
    final workspaces = await WorkspaceRepository().getUserWorkspaces(
      personalWorkspaceId: user.personalWorkspaceId,
      organizationWorkspaceIds: organizationWorkspaceIds,
    );

    return _AccountData(
      organizations: organizations,
      workspaces: workspaces,
    );
  }

  Future<void> _switchWorkspace(Workspace workspace) async {
    final user = context.read<AppUser>();
    await UserRepository().updateActiveWorkspace(
      uid: user.uid,
      workspaceId: workspace.workspaceId,
      workspaceType: workspace.type.value,
    );
    if (mounted) {
      setState(() => _accountDataFuture = _loadAccountData());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isInitialized) {
      return const _FirebaseOfflineAccount();
    }

    final user = context.watch<AppUser>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _accountDataFuture = _loadAccountData());
          await _accountDataFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TacticalCard(
              icon: Icons.account_circle_outlined,
              title: 'Profile',
              trailing: _StatusPill(label: user.accountType),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLine(label: 'Name', value: user.displayName),
                  _InfoLine(label: 'Email', value: user.email),
                  _InfoLine(
                    label: 'Subscription',
                    value:
                        '${user.subscriptionPlan} / ${user.subscriptionStatus}',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => AuthService().signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<_AccountData>(
              future: _accountDataFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const TacticalCard(
                    icon: Icons.workspaces_outline,
                    title: 'Workspaces',
                    child: LinearProgressIndicator(),
                  );
                }

                return TacticalCard(
                  icon: Icons.workspaces_outline,
                  title: 'Active Workspace',
                  subtitle: user.activeWorkspaceType.value,
                  child: WorkspaceSelector(
                    workspaces: data?.workspaces ?? const [],
                    activeWorkspaceId: user.activeWorkspaceId,
                    onChanged: _switchWorkspace,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            FutureBuilder<_AccountData>(
              future: _accountDataFuture,
              builder: (context, snapshot) {
                final organizations = snapshot.data?.organizations ?? const [];
                return TacticalCard(
                  icon: Icons.groups_outlined,
                  title: 'Organizations',
                  child: organizations.isEmpty
                      ? const Text('No organization access yet.')
                      : Column(
                          children: organizations.map((organization) {
                            return _OrganizationRow(
                              organization: organization,
                              role: user.roleForOrganization(
                                organization.organizationId,
                              ),
                            );
                          }).toList(),
                        ),
                );
              },
            ),
            const SizedBox(height: 14),
            JoinOrganizationCard(user: user),
          ],
        ),
      ),
    );
  }
}

class _AccountData {
  final List<Organization> organizations;
  final List<Workspace> workspaces;

  const _AccountData({
    required this.organizations,
    required this.workspaces,
  });
}

class _OrganizationRow extends StatelessWidget {
  final Organization organization;
  final String role;

  const _OrganizationRow({
    required this.organization,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading:
          const Icon(Icons.business_outlined, color: AppColors.primaryAccent),
      title: Text(organization.name),
      subtitle: Text(organization.organizationType),
      trailing: _StatusPill(label: role),
    );
  }
}

class _FirebaseOfflineAccount extends StatelessWidget {
  const _FirebaseOfflineAccount();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: TacticalCard(
            icon: Icons.cloud_off_outlined,
            title: 'Account Unavailable',
            child: Text(
              'Firebase is not configured for this build. Local field tools remain available.',
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: ${value.isEmpty ? '-' : value}'),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.38),
        ),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
