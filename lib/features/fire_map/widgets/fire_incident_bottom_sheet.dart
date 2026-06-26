// Fire Map reusable UI widget.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/features/fire_map/models/fire_incident.dart';
import 'package:wildland_companion_v2/features/fire_map/models/fire_incident_status.dart';
import 'package:wildland_companion_v2/features/fire_map/widgets/fire_map_status_chip.dart';

class FireIncidentDetailCard extends StatelessWidget {
  final FireIncident incident;
  final FireMapFeedStatus feedStatus;
  final DateTime? lastUpdated;
  final bool isCreatingIncident;
  final VoidCallback onCreateLocalIncident;
  final VoidCallback onClose;

  const FireIncidentDetailCard({
    super.key,
    required this.incident,
    required this.feedStatus,
    required this.lastUpdated,
    required this.isCreatingIncident,
    required this.onCreateLocalIncident,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = incidentStatusLabel(incident);
    final resolved = isResolved(incident);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.55;
    final bottomInset = mediaQuery.padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderOlive),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          incident.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                        color: AppColors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(label: statusLabel, isResolved: resolved),
                      _TinyMetric(
                          label: 'Acres', value: _acres(incident.acres)),
                      _TinyMetric(
                        label: 'Containment',
                        value: incident.containmentPercent == null
                            ? '-'
                            : '${incident.containmentPercent!.toStringAsFixed(0)}%',
                      ),
                      _TinyMetric(
                        label: 'Updated',
                        value: _date(incident.modifiedDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FireMapStatusChip(
                        status: feedStatus,
                        lastUpdated: lastUpdated,
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            isCreatingIncident ? null : onCreateLocalIncident,
                        icon: isCreatingIncident
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_location_alt_outlined),
                        label: const Text(
                          'Create / Update Local',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _date(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('MMM d, HH:mm').format(value.toLocal());
  }

  String _acres(double? value) {
    if (value == null) return '-';
    return NumberFormat('#,##0.#').format(value);
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isResolved;

  const _StatusChip({
    required this.label,
    required this.isResolved,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isResolved ? const Color(0xFF888D84) : AppColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TinyMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF111511),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
