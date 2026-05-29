import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/features/fire_map/models/fire_incident.dart';
import 'package:wildland_companion_v2/features/fire_map/models/fire_incident_status.dart';
import 'package:wildland_companion_v2/features/fire_map/widgets/fire_map_status_chip.dart';

class FireIncidentBottomSheet extends StatelessWidget {
  final FireIncident incident;
  final FireMapFeedStatus feedStatus;
  final DateTime? lastUpdated;
  final bool isCreatingIncident;
  final VoidCallback onCreateLocalIncident;

  const FireIncidentBottomSheet({
    super.key,
    required this.incident,
    required this.feedStatus,
    required this.lastUpdated,
    required this.isCreatingIncident,
    required this.onCreateLocalIncident,
  });

  @override
  Widget build(BuildContext context) {
    final updates = incident.importantUpdates ?? incident.status;
    final statusLabel = incidentStatusLabel(incident);
    final resolved = isResolved(incident);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final title = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        incident.isRx
                            ? Icons.eco_outlined
                            : Icons.local_fire_department,
                        color: resolved
                            ? const Color(0xFF888D84)
                            : incident.isRx
                                ? AppColors.secondaryAccent
                                : AppColors.primaryAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          incident.name,
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 10),
                        FireMapStatusChip(
                          status: feedStatus,
                          lastUpdated: lastUpdated,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 12),
                      FireMapStatusChip(
                        status: feedStatus,
                        lastUpdated: lastUpdated,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _StatusRow(label: statusLabel, isResolved: resolved),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Acres Burned',
                      value: _acres(incident.acres),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Contained',
                      value: incident.containmentPercent == null
                          ? '-'
                          : '${incident.containmentPercent!.toStringAsFixed(0)}%',
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Updated',
                      value: _date(incident.modifiedDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Details',
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Jurisdiction / Unit',
                      value: incident.jurisdiction,
                    ),
                    _DetailRow(label: 'Agency', value: incident.agency),
                    _DetailRow(
                      label: 'Incident Type',
                      value: incident.incidentType,
                    ),
                    _DetailRow(
                      label: 'Discovery / Start',
                      value: _date(incident.discoveryDate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Updates',
                child: Text(
                  (updates == null || updates.trim().isEmpty)
                      ? 'No official update text provided.'
                      : updates,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          isCreatingIncident ? null : onCreateLocalIncident,
                      icon: isCreatingIncident
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Create Local Incident From Fire'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('MMM d, yyyy HH:mm').format(value.toLocal());
  }

  String _acres(double? value) {
    if (value == null) return '-';
    return NumberFormat('#,##0.#').format(value);
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isResolved;

  const _StatusRow({
    required this.label,
    required this.isResolved,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isResolved ? const Color(0xFF888D84) : AppColors.primaryAccent;

    return Row(
      children: [
        const Text(
          'Status:',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151A15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryAccent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151A15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.secondaryAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (value == null || value!.trim().isEmpty) ? '-' : value!,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
