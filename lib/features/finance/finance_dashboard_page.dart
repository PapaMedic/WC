import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';
import 'package:wildland_companion_v2/core/models/cloud/finalized_ticket_record.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';
import 'package:wildland_companion_v2/core/repositories/cloud_ticket_repository.dart';
import 'package:wildland_companion_v2/core/services/firebase/firebase_bootstrap.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/features/tickets/state/tickets_state.dart';

class FinanceDashboardPage extends StatelessWidget {
  const FinanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FirebaseBootstrap.isInitialized) {
      return const _LocalFinanceView();
    }

    final user = context.watch<AppUser>();
    if (!user.canViewFinance) {
      return const _RestrictedFinanceView();
    }

    return FutureBuilder<List<FinalizedTicketRecord>>(
      future:
          CloudTicketRepository().getFinalizedTickets(user.activeWorkspaceId),
      builder: (context, snapshot) {
        final records = snapshot.data ?? const [];
        return _FinanceContent(records: records, isLoading: !snapshot.hasData);
      },
    );
  }
}

class _FinanceContent extends StatelessWidget {
  final List<FinalizedTicketRecord> records;
  final bool isLoading;

  const _FinanceContent({
    required this.records,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final totalPersonnelHours = records.fold<double>(
      0,
      (sum, record) => sum + record.totalPersonnelHours,
    );
    final totalApparatusHours = records.fold<double>(
      0,
      (sum, record) => sum + record.totalApparatusHours,
    );
    final pendingSyncCount =
        records.where((record) => record.syncStatus != 'synced').length;
    final activeIncidents = records.map((record) => record.incidentId).toSet();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isLoading) const LinearProgressIndicator(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: 'Finalized Tickets',
                  value: records.length.toString(),
                  icon: Icons.verified_outlined,
                ),
                _MetricCard(
                  label: 'OF-297 PDFs',
                  value: records
                      .fold<int>(
                        0,
                        (sum, record) => sum + record.pdfStoragePaths.length,
                      )
                      .toString(),
                  icon: Icons.picture_as_pdf_outlined,
                ),
                const _MetricCard(
                  label: 'CTR PDFs',
                  value: '0',
                  icon: Icons.description_outlined,
                ),
                _MetricCard(
                  label: 'Personnel Hours',
                  value: totalPersonnelHours.toStringAsFixed(1),
                  icon: Icons.groups_outlined,
                ),
                _MetricCard(
                  label: 'Apparatus Hours',
                  value: totalApparatusHours.toStringAsFixed(1),
                  icon: Icons.fire_truck,
                ),
                _MetricCard(
                  label: 'Active Incidents',
                  value: activeIncidents.length.toString(),
                  icon: Icons.warning_amber_outlined,
                ),
                _MetricCard(
                  label: 'This Week',
                  value: records
                      .where((record) => record.finalizedAt.isAfter(weekStart))
                      .length
                      .toString(),
                  icon: Icons.date_range_outlined,
                ),
                _MetricCard(
                  label: 'This Month',
                  value: records
                      .where((record) => record.finalizedAt.isAfter(monthStart))
                      .length
                      .toString(),
                  icon: Icons.calendar_month_outlined,
                ),
                _MetricCard(
                  label: 'Pending Sync',
                  value: pendingSyncCount.toString(),
                  icon: Icons.sync_outlined,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _FilterCard(),
            const SizedBox(height: 14),
            TacticalCard(
              icon: Icons.receipt_long_outlined,
              title: 'Finalized Tickets',
              child: records.isEmpty
                  ? const Text('No finalized ticket metadata synced yet.')
                  : Column(
                      children: records
                          .map((record) => _FinanceTicketRow(record: record))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalFinanceView extends StatelessWidget {
  const _LocalFinanceView();

  @override
  Widget build(BuildContext context) {
    final ticketsState = context.watch<TicketsState>();
    final finalized =
        ticketsState.tickets.where((ticket) => ticket.isFinalized).toList();
    final records = finalized.map((ticket) {
      return FinalizedTicketRecord.fromTicket(
        ticket: ticket,
        workspaceId: 'local',
        workspaceType:
            _maybeUser(context)?.activeWorkspaceType ?? WorkspaceType.personal,
        ownerUid: 'local',
        createdByName: 'Local user',
        pdfStoragePaths: ticketsState
            .pdfRecordsForTicket(ticket.id)
            .map((record) => record.filePath)
            .toList(),
        syncStatus: 'local_only',
      );
    }).toList();

    return _FinanceContent(records: records, isLoading: false);
  }
}

AppUser? _maybeUser(BuildContext context) {
  try {
    return Provider.of<AppUser>(context, listen: false);
  } catch (_) {
    return null;
  }
}

class _RestrictedFinanceView extends StatelessWidget {
  const _RestrictedFinanceView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: TacticalCard(
            icon: Icons.lock_outline,
            title: 'Finance Restricted',
            child: Text('Your active organization role cannot view finance.'),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: TacticalCard(
        icon: icon,
        title: label,
        padding: const EdgeInsets.all(14),
        child: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard();

  @override
  Widget build(BuildContext context) {
    const filters = [
      'Incident',
      'Date range',
      'Personnel',
      'Apparatus',
      'Ticket type',
      'Created by',
      'Sync status',
    ];

    return TacticalCard(
      icon: Icons.filter_alt_outlined,
      title: 'Filters',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters
            .map(
              (filter) => Chip(
                label: Text(filter),
                avatar: const Icon(Icons.tune, size: 16),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FinanceTicketRow extends StatelessWidget {
  final FinalizedTicketRecord record;

  const _FinanceTicketRow({
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('MMM d, yyyy').format(record.finalizedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        color: const Color(0xFF111611),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.incidentName.isEmpty
                      ? 'Unnamed Incident'
                      : record.incidentName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              _StatusPill(label: record.syncStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Incident # ${record.incidentNumber.isEmpty ? '-' : record.incidentNumber} · RO ${record.resourceOrderNumber.isEmpty ? '-' : record.resourceOrderNumber}',
          ),
          Text(
            '${record.apparatusName.isEmpty ? 'No apparatus' : record.apparatusName} · ${record.personnelCount} personnel · ${(record.totalPersonnelHours + record.totalApparatusHours).toStringAsFixed(1)} hours',
          ),
          Text('Finalized $dateText · Created by ${record.createdByName}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('View PDF'),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('Download'),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Export Metadata'),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
