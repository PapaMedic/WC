import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/tactical_card.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/of297_form_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/of297_review_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_status_pill.dart';
import 'package:wildland_companion_v2/features/tickets/state/tickets_state.dart';

/// Shows OF-297 tickets that belong to one selected incident.
class IncidentTicketsPage extends StatefulWidget {
  final String incidentId;
  final String incidentName;
  final String incidentNumber;
  final String resourceOrderNumber;
  final String financialCode;
  final VoidCallback? onBack;

  const IncidentTicketsPage({
    super.key,
    required this.incidentId,
    required this.incidentName,
    this.incidentNumber = '',
    this.resourceOrderNumber = '',
    this.financialCode = '',
    this.onBack,
  });

  @override
  State<IncidentTicketsPage> createState() => _IncidentTicketsPageState();
}

class _IncidentTicketsPageState extends State<IncidentTicketsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketsState>().loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketsState>(
      builder: (context, ticketsState, _) {
        final draftTickets =
            ticketsState.draftTicketsForIncident(widget.incidentId);
        final finalizedTickets =
            ticketsState.finalizedTicketsForIncident(widget.incidentId);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back to incidents',
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.incidentName.isEmpty
                              ? 'Unnamed Incident'
                              : widget.incidentName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'OF-297 Emergency Equipment Shift Tickets',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create OF-297'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _TicketSection(
                title: 'Draft Tickets',
                emptyMessage: 'No draft OF-297 tickets for this incident.',
                tickets: draftTickets,
                onOpen: (ticket) => _openForm(context, ticket.id),
                onDelete: (ticket) => ticketsState.deleteDraftTicket(ticket.id),
              ),
              const SizedBox(height: AppSpacing.lg),
              _TicketSection(
                title: 'Finalized Tickets',
                emptyMessage: 'No finalized OF-297 tickets for this incident.',
                tickets: finalizedTickets,
                onOpen: (ticket) => _openReview(context, ticket.id),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openForm(BuildContext context, [String? ticketId]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OF297FormPage(
          incidentId: widget.incidentId,
          incidentName: widget.incidentName,
          incidentNumber: widget.incidentNumber,
          resourceOrderNumber: widget.resourceOrderNumber,
          financialCode: widget.financialCode,
          ticketId: ticketId,
        ),
      ),
    );
  }

  void _openReview(BuildContext context, String ticketId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OF297ReviewPage(
          incidentId: widget.incidentId,
          incidentName: widget.incidentName,
          ticketId: ticketId,
        ),
      ),
    );
  }
}

class _TicketSection extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<OF297ShiftTicket> tickets;
  final ValueChanged<OF297ShiftTicket> onOpen;
  final ValueChanged<OF297ShiftTicket>? onDelete;

  const _TicketSection({
    required this.title,
    required this.emptyMessage,
    required this.tickets,
    required this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      title: title,
      child: tickets.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(emptyMessage),
            )
          : Column(
              children: tickets.map((ticket) {
                return _TicketTile(
                  ticket: ticket,
                  onOpen: () => onOpen(ticket),
                  onDelete: onDelete == null ? null : () => onDelete!(ticket),
                );
              }).toList(),
            ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final OF297ShiftTicket ticket;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  const _TicketTile({
    required this.ticket,
    required this.onOpen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    final subtitle = 'Updated: ${formatter.format(ticket.updatedAt)}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.receipt_long_outlined,
        color: AppColors.primaryAccent,
      ),
      title: Text(
        ticket.contractorName.isEmpty ? 'OF-297 Draft' : ticket.contractorName,
      ),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OF297StatusPill(isFinalized: ticket.isFinalized),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Delete draft',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      onTap: onOpen,
    );
  }
}
