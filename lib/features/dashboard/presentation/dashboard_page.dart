import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wildland_companion_v2/app/theme/app_colors.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/topographic_card.dart';
import 'package:wildland_companion_v2/app/app_router.dart';

// ─── Zero-state data constants ────────────────────────────────────────────────
// Update these when real state/providers are wired up.
const _activeIncidentName = ''; // empty = no active incident
const _apparatusCount = 0;
const _personnelCount = 0;
const _weatherTemp = '--';
const _weatherCondition = 'Not Loaded';
const _weatherWind = '--';
const _weatherRh = '--';

// ─── DashboardPage ────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Tick every second for live clock
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardLogoHeader(),
              const SizedBox(height: AppSpacing.xl),
              _ActiveIncidentCard(context: context),
              const SizedBox(height: AppSpacing.md),
              _DateTimeCard(now: _now),
              const SizedBox(height: AppSpacing.md),
              _ApparatusPersonnelCard(context: context),
              const SizedBox(height: AppSpacing.md),
              _WeatherCard(),
              const SizedBox(height: AppSpacing.md),
              _DashboardSectionLabel(label: 'QUICK ACTIONS'),
              const SizedBox(height: AppSpacing.sm),
              _QuickActionsGrid(context: context, isMobile: isMobile),
              const SizedBox(height: AppSpacing.xl),
              _DashboardFooter(now: _now),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logo / Header ────────────────────────────────────────────────────────────

class _DashboardLogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryAccent.withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.local_fire_department,
            size: 52,
            color: AppColors.primaryAccent,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'WILDLAND COMPANION',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 5.0,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 1,
              color: AppColors.primaryAccent.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            const Text(
              'FIELD OPERATIONS TOOLKIT',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3.0,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 1,
              color: AppColors.primaryAccent.withValues(alpha: 0.7),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Active Incident Card ─────────────────────────────────────────────────────

class _ActiveIncidentCard extends StatelessWidget {
  final BuildContext context;
  const _ActiveIncidentCard({required this.context});

  @override
  Widget build(BuildContext outerContext) {
    final hasIncident = _activeIncidentName.isNotEmpty;
    final incidentLabel = hasIncident
        ? _activeIncidentName
        : 'No Active Incident';

    return TopographicCard(
      padding: const EdgeInsets.all(20),
      onTap: () => AppRouter.navigate(outerContext, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LabelChip(label: 'ACTIVE INCIDENT'),
              const Spacer(),
              Icon(
                hasIncident ? Icons.warning_amber_rounded : Icons.info_outline,
                color: hasIncident
                    ? AppColors.primaryAccent
                    : AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  incidentLabel,
                  style: TextStyle(
                    fontSize: hasIncident ? 28 : 20,
                    fontWeight: FontWeight.bold,
                    color: hasIncident
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
          if (hasIncident) ...[
            const SizedBox(height: 6),
            Container(width: 40, height: 2, color: AppColors.primaryAccent),
          ],
          if (!hasIncident) ...[
            const SizedBox(height: 6),
            Text(
              'Tap to manage incidents',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Date / Time Split Card ───────────────────────────────────────────────────

class _DateTimeCard extends StatelessWidget {
  final DateTime now;
  const _DateTimeCard({required this.now});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    final dayFmt = DateFormat('EEEE');
    final timeFmt = DateFormat('HH:mm');
    final tzAbbr = _tzAbbreviation(now);

    return _TacticalSplitCard(
      left: _SplitHalf(
        icon: Icons.calendar_month_outlined,
        label: 'DATE',
        primaryText: dateFmt.format(now),
        secondaryText: dayFmt.format(now),
      ),
      right: _SplitHalf(
        icon: Icons.access_time_rounded,
        label: 'TIME',
        primaryText: timeFmt.format(now),
        secondaryText: tzAbbr,
      ),
    );
  }

  String _tzAbbreviation(DateTime dt) {
    // Extract offset like -07:00 → PDT/MST approximation
    final offset = dt.timeZoneOffset;
    final h = offset.inHours;
    if (h == -7) return 'PDT';
    if (h == -8) return 'PST / PDT';
    if (h == -6) return 'MDT';
    if (h == -5) return 'CDT / EST';
    if (h == 0) return 'UTC';
    return 'UTC${h >= 0 ? '+' : ''}$h';
  }
}

// ─── Apparatus / Personnel Split Card ────────────────────────────────────────

class _ApparatusPersonnelCard extends StatelessWidget {
  final BuildContext context;
  const _ApparatusPersonnelCard({required this.context});

  @override
  Widget build(BuildContext outerContext) {
    final apparatusText = _apparatusCount > 0
        ? '$_apparatusCount Assigned'
        : 'No Apparatus Assigned';
    final personnelText = _personnelCount > 0
        ? '$_personnelCount Assigned'
        : 'No Personnel Assigned';

    return _TacticalSplitCard(
      onTapLeft: () => AppRouter.navigate(outerContext, 2),
      onTapRight: () => AppRouter.navigate(outerContext, 1),
      left: _SplitHalf(
        icon: Icons.fire_truck_outlined,
        label: 'APPARATUS',
        primaryText: apparatusText,
        secondaryText: 'Tap to manage',
        dimPrimary: _apparatusCount == 0,
      ),
      right: _SplitHalf(
        icon: Icons.people_outline,
        label: 'PERSONNEL',
        primaryText: personnelText,
        secondaryText: 'Tap to manage',
        dimPrimary: _personnelCount == 0,
      ),
    );
  }
}

// ─── Weather Card ─────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TopographicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LabelChip(label: 'WEATHER'),
          const SizedBox(height: 16),
          Row(
            children: [
              // Temperature
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_outlined,
                        color: AppColors.primaryAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherTemp,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            _weatherCondition,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.secondaryAccent.withValues(alpha: 0.25),
              ),
              const SizedBox(width: 12),
              // Wind
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    const Icon(Icons.air, color: AppColors.textMuted, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Wind $_weatherWind',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            'mph',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.secondaryAccent.withValues(alpha: 0.25),
              ),
              const SizedBox(width: 12),
              // RH
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'RH $_weatherRh',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            'Relative Humidity',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Grid ───────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final BuildContext context;
  final bool isMobile;

  const _QuickActionsGrid({required this.context, required this.isMobile});

  @override
  Widget build(BuildContext outerContext) {
    final actions = [
      _ActionItem(
        label: 'CREATE\nSHIFT TICKET',
        icon: Icons.assignment_outlined,
        routeIndex: 4,
      ),
      _ActionItem(
        label: 'LOG\nWEATHER',
        icon: Icons.cloud_outlined,
        routeIndex: 6,
      ),
      _ActionItem(
        label: 'VIEW\nFIRE MAP',
        icon: Icons.map_outlined,
        routeIndex: 5,
      ),
      _ActionItem(
        label: 'MANAGE\nCREW',
        icon: Icons.people_outline,
        routeIndex: 1,
      ),
    ];

    if (isMobile) {
      // 2-column grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  item: actions[0],
                  onTap: () =>
                      AppRouter.navigate(outerContext, actions[0].routeIndex),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionTile(
                  item: actions[1],
                  onTap: () =>
                      AppRouter.navigate(outerContext, actions[1].routeIndex),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  item: actions[2],
                  onTap: () =>
                      AppRouter.navigate(outerContext, actions[2].routeIndex),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickActionTile(
                  item: actions[3],
                  onTap: () =>
                      AppRouter.navigate(outerContext, actions[3].routeIndex),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 4-column row for tablet/desktop
    return Row(
      children: actions.map((item) {
        final isLast = item == actions.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
            child: _QuickActionTile(
              item: item,
              onTap: () => AppRouter.navigate(outerContext, item.routeIndex),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final int routeIndex;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.routeIndex,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _ActionItem item;
  final VoidCallback onTap;

  const _QuickActionTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(12));
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          // Main card body with uniform border (no non-uniform sides)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1C201C), Color(0xFF171B17)],
                  ),
                  borderRadius: radius,
                  border: Border.all(color: const Color(0xFF2A2F2A), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primaryAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.6,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Orange bottom accent line — positioned so it won't affect layout
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 2, color: AppColors.primaryAccent),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Split Card ──────────────────────────────────────────────────────

class _TacticalSplitCard extends StatelessWidget {
  final _SplitHalf left;
  final _SplitHalf right;
  final VoidCallback? onTapLeft;
  final VoidCallback? onTapRight;

  const _TacticalSplitCard({
    required this.left,
    required this.right,
    this.onTapLeft,
    this.onTapRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C201C), Color(0xFF181C18), Color(0xFF141714)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondaryAccent.withValues(alpha: 0.30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildHalfSection(left, onTapLeft, isLeft: true)),
              Container(
                width: 1,
                color: AppColors.secondaryAccent.withValues(alpha: 0.20),
              ),
              Expanded(
                child: _buildHalfSection(right, onTapRight, isLeft: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHalfSection(
    _SplitHalf half,
    VoidCallback? onTap, {
    required bool isLeft,
  }) {
    final radius = BorderRadius.horizontal(
      left: isLeft ? const Radius.circular(14) : Radius.zero,
      right: isLeft ? Radius.zero : const Radius.circular(14),
    );

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(half.icon, color: AppColors.primaryAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  half.label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  half.primaryText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: half.dimPrimary
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (half.secondaryText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    half.secondaryText!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 16,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      );
    }

    return content;
  }
}

class _SplitHalf {
  final IconData icon;
  final String label;
  final String primaryText;
  final String? secondaryText;
  final bool dimPrimary;

  const _SplitHalf({
    required this.icon,
    required this.label,
    required this.primaryText,
    this.secondaryText,
    this.dimPrimary = false,
  });
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _LabelChip extends StatelessWidget {
  final String label;

  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondaryAccent.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.secondaryAccent.withValues(alpha: 0.35),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DashboardSectionLabel extends StatelessWidget {
  final String label;
  const _DashboardSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DashboardFooter extends StatelessWidget {
  final DateTime now;
  const _DashboardFooter({required this.now});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.secondaryAccent,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          'Offline Ready  •  Last sync ${fmt.format(now)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
