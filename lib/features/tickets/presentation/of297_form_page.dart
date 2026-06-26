// Tickets screen UI and user interaction flow.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wildland_companion_v2/app/theme/app_spacing.dart';
import 'package:wildland_companion_v2/core/widgets/wildland_background.dart';
import 'package:wildland_companion_v2/features/apparatus/data/apparatus_repository.dart';
import 'package:wildland_companion_v2/features/personnel/data/personnel_repository.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_equipment_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_personnel_time_entry.dart';
import 'package:wildland_companion_v2/features/tickets/models/of297_shift_ticket.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/of297_review_page.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_section_card.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_status_pill.dart';
import 'package:wildland_companion_v2/features/tickets/presentation/widgets/of297_text_field.dart';
import 'package:wildland_companion_v2/features/tickets/state/tickets_state.dart';
import 'package:wildland_companion_v2/features/tickets/utils/shift_ticket_time.dart';

/// First working OF-297 form.
///
/// This page saves the form data that will eventually feed PDF export. PDF
/// mapping is still intentionally left out so the data workflow can stabilize.
class OF297FormPage extends StatefulWidget {
  final String incidentId;
  final String incidentName;
  final String incidentNumber;
  final String resourceOrderNumber;
  final String financialCode;
  final String? ticketId;

  const OF297FormPage({
    super.key,
    required this.incidentId,
    required this.incidentName,
    this.incidentNumber = '',
    this.resourceOrderNumber = '',
    this.financialCode = '',
    this.ticketId,
  });

  @override
  State<OF297FormPage> createState() => _OF297FormPageState();
}

class _OF297FormPageState extends State<OF297FormPage> {
  final _uuid = const Uuid();
  final _dateFormat = DateFormat('MM/dd/yyyy');
  final _apparatusRepository = ApparatusRepository();
  final _personnelRepository = PersonnelRepository();

  final _agreementNumberController = TextEditingController();
  final _resourceOrderNumberController = TextEditingController();
  final _incidentNameController = TextEditingController();
  final _incidentNumberController = TextEditingController();
  final _financialCodeController = TextEditingController();
  final _contractorNameController = TextEditingController();
  final _ctrOfficeResponsibleForFireController = TextEditingController();
  final _equipmentMakeModelController = TextEditingController();
  final _equipmentTypeController = TextEditingController();
  final _serialVinController = TextEditingController();
  final _equipmentIdController = TextEditingController();
  final _remarksController = TextEditingController();
  final _contractorRepController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _globalShiftDateController = TextEditingController();
  final _globalBlock1StartController = TextEditingController();
  final _globalBlock1StopController = TextEditingController();
  final _globalBlock2StartController = TextEditingController();
  final _globalBlock2StopController = TextEditingController();

  final List<_EquipmentRowControllers> _equipmentRows =
      List.generate(4, (_) => _EquipmentRowControllers());
  final List<_PersonnelRowControllers> _personnelRows = [];

  OF297ShiftTicket? _ticket;
  bool _transportRetained = false;
  bool? _isMobilization;
  bool _rateIsHours = true;
  bool _rateIsMiles = false;
  bool _isInitializing = true;
  bool _apparatusSameAsCrewTimes = false;

  @override
  void initState() {
    super.initState();
    _globalShiftDateController.addListener(_syncApparatusTimeFromGlobalTime);
    _globalBlock1StartController.addListener(_syncApparatusTimeFromGlobalTime);
    _globalBlock1StopController.addListener(_syncApparatusTimeFromGlobalTime);
    _globalBlock2StartController.addListener(_syncApparatusTimeFromGlobalTime);
    _globalBlock2StopController.addListener(_syncApparatusTimeFromGlobalTime);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeTicket());
  }

  @override
  void dispose() {
    _agreementNumberController.dispose();
    _resourceOrderNumberController.dispose();
    _incidentNameController.dispose();
    _incidentNumberController.dispose();
    _financialCodeController.dispose();
    _contractorNameController.dispose();
    _ctrOfficeResponsibleForFireController.dispose();
    _equipmentMakeModelController.dispose();
    _equipmentTypeController.dispose();
    _serialVinController.dispose();
    _equipmentIdController.dispose();
    _remarksController.dispose();
    _contractorRepController.dispose();
    _supervisorController.dispose();
    _globalShiftDateController.dispose();
    _globalBlock1StartController.dispose();
    _globalBlock1StopController.dispose();
    _globalBlock2StartController.dispose();
    _globalBlock2StopController.dispose();
    for (final row in _equipmentRows) {
      row.dispose();
    }
    for (final row in _personnelRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeTicket() async {
    final ticketsState = context.read<TicketsState>();
    await ticketsState.loadTickets();

    var ticket = widget.ticketId == null
        ? null
        : ticketsState.ticketById(widget.ticketId!);

    if (ticket == null) {
      final now = DateTime.now();
      final selectedApparatus =
          await _apparatusRepository.getSelectedApparatus();
      final assignedPersonnel =
          await _personnelRepository.getAssignedPersonnel();

      ticket = OF297ShiftTicket(
        id: _uuid.v4(),
        incidentId: widget.incidentId,
        incidentName: widget.incidentName,
        incidentNumber: widget.incidentNumber,
        resourceOrderNumber: widget.resourceOrderNumber,
        financialCode: widget.financialCode,
        equipmentMakeModel: selectedApparatus?.equipmentMakeModel ?? '',
        equipmentType: selectedApparatus?.equipmentType ?? '',
        serialVinNumber: selectedApparatus?.serialVinNumber ?? '',
        equipmentId: selectedApparatus?.licenseIdNumber ?? '',
        personnelEntries: assignedPersonnel.map((person) {
          return OF297PersonnelTimeEntry(
            id: _uuid.v4(),
            name: person.name,
            position: person.qualification,
          );
        }).toList(),
        createdAt: now,
        updatedAt: now,
      );
      await ticketsState.addTicket(ticket);
    } else if (!ticket.isFinalized) {
      ticket = ticket.copyWith(
        incidentName: widget.incidentName,
        incidentNumber: widget.incidentNumber,
        resourceOrderNumber: widget.resourceOrderNumber,
        financialCode: widget.financialCode,
      );
    }

    if (!mounted) return;
    _populateForm(ticket);
  }

  void _populateForm(OF297ShiftTicket ticket) {
    setState(() {
      _ticket = ticket;
      _agreementNumberController.text = ticket.agreementNumber;
      _resourceOrderNumberController.text = ticket.resourceOrderNumber;
      _incidentNameController.text = ticket.incidentName;
      _incidentNumberController.text = ticket.incidentNumber;
      _financialCodeController.text = ticket.financialCode;
      _contractorNameController.text = ticket.contractorName;
      _ctrOfficeResponsibleForFireController.text =
          ticket.ctrOfficeResponsibleForFire;
      _equipmentMakeModelController.text = ticket.equipmentMakeModel;
      _equipmentTypeController.text = ticket.equipmentType;
      _serialVinController.text = ticket.serialVinNumber;
      _equipmentIdController.text = ticket.equipmentId;
      _remarksController.text = ticket.remarks;
      _contractorRepController.text = ticket.contractorRepresentativeName;
      _supervisorController.text = ticket.incidentSupervisorName;
      _globalShiftDateController.text = _formatDate(ticket.globalShiftDate);
      _globalBlock1StartController.text = ticket.globalBlock1Start;
      _globalBlock1StopController.text = ticket.globalBlock1Stop;
      _globalBlock2StartController.text = ticket.globalBlock2Start;
      _globalBlock2StopController.text = ticket.globalBlock2Stop;
      _transportRetained = ticket.transportRetained;
      _isMobilization = ticket.isMobilization;
      _rateIsHours = ticket.rateIsHours;
      _rateIsMiles = ticket.rateIsMiles;
      _apparatusSameAsCrewTimes =
          ticket.apparatusSameAsCrewTimes && _hasAssignedApparatus(ticket);
      _populateEquipmentRows(ticket);
      _populatePersonnelRows(ticket);
      _isInitializing = false;
    });
  }

  void _populateEquipmentRows(OF297ShiftTicket ticket) {
    final entries = ticket.equipmentEntries;
    for (var i = 0; i < _equipmentRows.length; i++) {
      if (i >= entries.length) continue;
      final row = _equipmentRows[i];
      final entry = entries[i];
      row.date.text = _formatDate(entry.date);
      if (_usesMileage) {
        row.start.text = _formatNullableNumber(entry.mileageStart);
        row.stop.text = _formatNullableNumber(entry.mileageEnd);
        row.total.text = _formatNumber(entry.totalMiles);
      } else {
        row.start.text = _formatTime(entry.startTime);
        row.stop.text = _formatTime(entry.stopTime);
        row.total.text = _formatNumber(entry.totalHours);
      }
      row.quantity.text = _formatNumber(entry.specialRateQuantity);
      row.type.text = entry.rateType;
      row.notes.text = entry.notes;
      row.calculatedTotalHours = entry.calculatedTotalHours;
      row.totalHoursManuallyOverridden = entry.totalHoursManuallyOverridden;
      if (row.hasPopulatedContent) {
        row.date.text = _globalDisplayDateForRow(ticket, entry.date);
      }
    }
  }

  void _populatePersonnelRows(OF297ShiftTicket ticket) {
    for (final row in _personnelRows) {
      row.dispose();
    }
    _personnelRows
      ..clear()
      ..addAll(
        List.generate(
          _personnelControllerCount(ticket.personnelEntries.length),
          (_) => _PersonnelRowControllers(),
        ),
      );

    final entries = ticket.personnelEntries;
    for (var i = 0; i < _personnelRows.length; i++) {
      if (i >= entries.length) continue;
      final row = _personnelRows[i];
      final entry = entries[i];
      row.date.text = _formatDate(entry.date);
      row.name.text = entry.name;
      row.position.text = entry.position;
      row.guaranteeStart.text = _formatTime(entry.guaranteeStartTime);
      row.guaranteeStop.text = _formatTime(entry.guaranteeStopTime);
      row.start.text = _formatTime(entry.startTime);
      row.stop.text = _formatTime(entry.stopTime);
      row.total.text = _formatNumber(entry.totalHours);
      row.notes.text = entry.notes;
      if (row.hasPopulatedContent) {
        row.date.text = _globalDisplayDateForRow(ticket, entry.date);
      }
    }
  }

  int _personnelControllerCount(int entryCount) {
    final minimumRows = entryCount == 0 ? 4 : entryCount;
    return ((minimumRows + 3) ~/ 4) * 4;
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;

    if (_isInitializing || ticket == null) {
      return const WildlandBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final readOnly = ticket.isFinalized;

    return WildlandBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('OF-297 Shift Ticket'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: OF297StatusPill(isFinalized: ticket.isFinalized),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            OF297SectionCard(
              title: 'Incident And Order',
              child: Column(
                children: [
                  OF297TextField(
                    label: '1. Agreement Number',
                    controller: _agreementNumberController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OF297TextField(
                    label: '2. Contractor/Agency Name',
                    controller: _contractorNameController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OF297TextField(
                    label: '3. Resource Order Number',
                    controller: _resourceOrderNumberController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OF297TextField(
                    label: '4. Incident Name',
                    controller: _incidentNameController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OF297TextField(
                    label: '5. Incident Number',
                    controller: _incidentNumberController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OF297TextField(
                    label: '6. Financial Code',
                    controller: _financialCodeController,
                    readOnly: readOnly,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OF297SectionCard(
              title: 'CTR Details',
              child: OF297TextField(
                label: 'Office Responsible For Fire',
                controller: _ctrOfficeResponsibleForFireController,
                readOnly: readOnly,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OF297SectionCard(
              title: 'Equipment',
              child: Column(
                children: [
                  OF297TextField(
                    label: '7. Equipment Make/Model',
                    controller: _equipmentMakeModelController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OF297TextField(
                    label: '8. Equipment Type',
                    controller: _equipmentTypeController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OF297TextField(
                    label: '9. Serial/VIN Number',
                    controller: _serialVinController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OF297TextField(
                    label: '10. License/ID Number',
                    controller: _equipmentIdController,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('12. Transport retained'),
                    value: _transportRetained,
                    onChanged: readOnly
                        ? null
                        : (value) {
                            setState(() => _transportRetained = value);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _FormToggleChip(
                        label: '13. Mobilization',
                        selected: _isMobilization == true,
                        enabled: !readOnly,
                        onSelected: (selected) {
                          setState(() {
                            _isMobilization = selected ? true : null;
                          });
                        },
                      ),
                      _FormToggleChip(
                        label: '13. Demobilization',
                        selected: _isMobilization == false,
                        enabled: !readOnly,
                        onSelected: (selected) {
                          setState(() {
                            _isMobilization = selected ? false : null;
                          });
                        },
                      ),
                      _FormToggleChip(
                        label: '14. Hours',
                        selected: _rateIsHours,
                        enabled: !readOnly,
                        onSelected: (value) {
                          _setRateBasis(hoursSelected: value);
                        },
                      ),
                      _FormToggleChip(
                        label: '14. Miles',
                        selected: _rateIsMiles,
                        enabled: !readOnly,
                        onSelected: (value) {
                          _setRateBasis(milesSelected: value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildGlobalShiftPeriodSection(readOnly: readOnly),
            const SizedBox(height: AppSpacing.lg),
            OF297SectionCard(
              title: 'Equipment Time 15-21',
              child: Column(
                children: [
                  for (var i = 0; i < _equipmentRows.length; i++) ...[
                    _EquipmentRowEditor(
                      rowNumber: i + 1,
                      row: _equipmentRows[i],
                      readOnly: readOnly,
                      useMiles: _usesMileage,
                      controlledByGlobalTime:
                          _apparatusSameAsCrewTimes && i == 0,
                    ),
                    if (i != _equipmentRows.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._buildPersonnelTimeSections(readOnly: readOnly),
            const SizedBox(height: AppSpacing.lg),
            OF297SectionCard(
              title: '30. Remarks',
              child: OF297TextField(
                label: 'Breakdowns, operating issues, or other information',
                controller: _remarksController,
                readOnly: readOnly,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: readOnly ? null : _saveDraft,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Draft'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  // Signatures and finalization happen on the review page after
                  // the user reviews the completed ticket.
                  child: FilledButton.icon(
                    onPressed: _openReview,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Review'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _saveDraft() async {
    if (!_validateEditableApparatusTotals()) return false;

    final ticket = _buildTicketFromForm();
    await context.read<TicketsState>().updateTicket(ticket);

    if (!mounted) return false;
    setState(() {
      _ticket = ticket.copyWith(updatedAt: DateTime.now());
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OF-297 draft saved.')),
    );
    return true;
  }

  Future<void> _openReview() async {
    if (!_ticket!.isFinalized) {
      final saved = await _saveDraft();
      if (!saved) return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OF297ReviewPage(
          incidentId: widget.incidentId,
          incidentName: widget.incidentName,
          ticketId: _ticket!.id,
        ),
      ),
    );

    if (!mounted) return;
    final refreshed = context.read<TicketsState>().ticketById(_ticket!.id);
    if (refreshed != null) {
      setState(() => _ticket = refreshed);
    }
  }

  bool get _usesMileage => _rateIsMiles && !_rateIsHours;

  bool _validateEditableApparatusTotals() {
    if (_usesMileage) return true;

    for (var i = 0; i < _equipmentRows.length; i++) {
      final row = _equipmentRows[i];
      final text = row.total.text.trim();
      if (text.isEmpty &&
          (row.start.text.isNotEmpty || row.stop.text.isNotEmpty)) {
        _showFormError('Equipment row ${i + 1} total hours is required.');
        return false;
      }
      final parsed = text.isEmpty ? 0 : double.tryParse(text);
      if (parsed == null || parsed < 0) {
        _showFormError(
          'Equipment row ${i + 1} total hours must be a valid non-negative duration.',
        );
        return false;
      }
    }

    return true;
  }

  void _showFormError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<Widget> _buildPersonnelTimeSections({required bool readOnly}) {
    final populatedPersonnelCount =
        _personnelRows.where((row) => row.hasPopulatedContent).length;
    final groupCount = (_personnelRows.length / 4).ceil();
    final sections = <Widget>[];

    if (populatedPersonnelCount > 4) {
      sections.add(
        OF297SectionCard(
          title: 'Personnel Export Notice',
          child: Text(
            'More than 4 personnel will create an additional OF-297 shift '
            'ticket when exported or finalized.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
      sections.add(const SizedBox(height: AppSpacing.lg));
    }

    for (var groupIndex = 0; groupIndex < groupCount; groupIndex++) {
      final start = groupIndex * 4;
      final end = (start + 4).clamp(0, _personnelRows.length);
      sections.add(
        OF297SectionCard(
          title: 'Personnel Time 22-29 - OF-297 ${groupIndex + 1}',
          child: Column(
            children: [
              for (var i = start; i < end; i++) ...[
                _PersonnelRowEditor(
                  rowNumber: i + 1,
                  row: _personnelRows[i],
                  readOnly: readOnly,
                ),
                if (i != end - 1) const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      );
      if (groupIndex != groupCount - 1) {
        sections.add(const SizedBox(height: AppSpacing.lg));
      }
    }

    return sections;
  }

  Widget _buildGlobalShiftPeriodSection({required bool readOnly}) {
    final canSyncApparatus =
        _hasAssignedApparatus(_ticket!) && !_usesMileage && !readOnly;

    return OF297SectionCard(
      title: 'Global Shift Period',
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _globalShiftDateController,
          _globalBlock1StartController,
          _globalBlock1StopController,
          _globalBlock2StartController,
          _globalBlock2StopController,
        ]),
        builder: (context, _) {
          final totalHours = _calculateGlobalShiftHours();
          final dateRange = _formatShiftDateRange(
            _globalShiftDateController.text,
            _globalBlock1StartController.text,
            _globalBlock1StopController.text,
            _globalBlock2StartController.text,
            _globalBlock2StopController.text,
          );
          final overnight = _globalShiftIsOvernight();
          final exceeds24 = totalHours != null && totalHours > 24;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResponsiveFields(
                children: [
                  _DatePickerTextField(
                    label: 'Shift Date',
                    controller: _globalShiftDateController,
                    readOnly: readOnly,
                  ),
                  _MilitaryTimeField(
                    label: 'Time Block 1 Start',
                    controller: _globalBlock1StartController,
                    readOnly: readOnly,
                  ),
                  _MilitaryTimeField(
                    label: 'Time Block 1 Stop',
                    controller: _globalBlock1StopController,
                    readOnly: readOnly,
                  ),
                  _MilitaryTimeField(
                    label: 'Time Block 2 Start',
                    controller: _globalBlock2StartController,
                    readOnly: readOnly,
                  ),
                  _MilitaryTimeField(
                    label: 'Time Block 2 Stop',
                    controller: _globalBlock2StopController,
                    readOnly: readOnly,
                  ),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Calculated Total Hours',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    child: Text(
                      totalHours == null ? '' : _formatHours(totalHours),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                overnight
                    ? 'Overnight shift detected: $dateRange'
                    : 'Same-day shift: $dateRange',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (exceeds24) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Warning: calculated total exceeds 24 hours.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Apparatus same as crew times'),
                subtitle: canSyncApparatus
                    ? const Text(
                        'Apparatus date, start, and stop follow the global crew time.',
                      )
                    : const Text('Assign apparatus and use hours to enable.'),
                value: _apparatusSameAsCrewTimes && canSyncApparatus,
                onChanged: canSyncApparatus
                    ? (value) {
                        setState(() {
                          _apparatusSameAsCrewTimes = value ?? false;
                        });
                        if (_apparatusSameAsCrewTimes) {
                          _syncApparatusTimeFromGlobalTime();
                        }
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: readOnly ? null : _applyGlobalShiftToRows,
                  icon: const Icon(Icons.playlist_add_check_outlined),
                  label: const Text('Apply to all rows'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _setRateBasis({bool? hoursSelected, bool? milesSelected}) {
    setState(() {
      if (hoursSelected != null) {
        _rateIsHours = hoursSelected;
        if (hoursSelected) {
          _rateIsMiles = false;
        }
      }

      if (milesSelected != null) {
        _rateIsMiles = milesSelected;
        if (milesSelected) {
          _rateIsHours = false;
        }
      }

      _recalculateAllRowTotals();
    });
  }

  double? _calculateShiftBlockHours(String startValue, String stopValue) {
    return _calculateHours(startValue, stopValue);
  }

  double? _calculateGlobalShiftHours() {
    final block1Hours = _calculateShiftBlockHours(
      _globalBlock1StartController.text,
      _globalBlock1StopController.text,
    );
    final block2HasAnyValue = _globalBlock2StartController.text.isNotEmpty ||
        _globalBlock2StopController.text.isNotEmpty;
    final block2Hours = _calculateShiftBlockHours(
      _globalBlock2StartController.text,
      _globalBlock2StopController.text,
    );

    if (block1Hours == null && (!block2HasAnyValue || block2Hours == null)) {
      return null;
    }

    return (block1Hours ?? 0) + (block2Hours ?? 0);
  }

  DateTime? _buildDateTimeFromDateAndMilitaryTime(
    String dateValue,
    String timeValue,
  ) {
    final date = _parseDate(dateValue);
    final minutes = _parseMilitaryMinutes(timeValue);
    if (date == null || minutes == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      minutes ~/ 60,
      minutes % 60,
    );
  }

  bool _isOvernightBlock(String startValue, String stopValue) {
    final startMinutes = _parseMilitaryMinutes(startValue);
    final stopMinutes = _parseMilitaryMinutes(stopValue);
    if (startMinutes == null || stopMinutes == null) return false;
    return stopMinutes < startMinutes;
  }

  bool _globalShiftIsOvernight() {
    return _isOvernightBlock(
          _globalBlock1StartController.text,
          _globalBlock1StopController.text,
        ) ||
        _isOvernightBlock(
          _globalBlock2StartController.text,
          _globalBlock2StopController.text,
        );
  }

  String _formatShiftDateRange(
    String dateValue,
    String block1Start,
    String block1Stop,
    String block2Start,
    String block2Stop,
  ) {
    final date = _parseDate(dateValue);
    if (date == null) return '';

    if (_isOvernightBlock(block2Start, block2Stop)) {
      return formatShiftDateRange(date, block2Start, block2Stop);
    }

    return formatShiftDateRange(date, block1Start, block1Stop);
  }

  String _globalDisplayDateForRow(
    OF297ShiftTicket ticket,
    DateTime? rowDate,
  ) {
    final shiftDate = _formatDate(rowDate ?? ticket.globalShiftDate);
    if (shiftDate.isEmpty) return '';

    return _formatShiftDateRange(
      shiftDate,
      ticket.globalBlock1Start,
      ticket.globalBlock1Stop,
      ticket.globalBlock2Start,
      ticket.globalBlock2Stop,
    );
  }

  void _applyGlobalShiftToRows() {
    setState(() {
      final shiftDate = _globalShiftDateController.text;
      final block1Start = _globalBlock1StartController.text;
      final block1Stop = _globalBlock1StopController.text;
      final block2Start = _globalBlock2StartController.text;
      final block2Stop = _globalBlock2StopController.text;
      final equipmentStart = block1Start.isNotEmpty ? block1Start : block2Start;
      final equipmentStop = block2Stop.isNotEmpty ? block2Stop : block1Stop;
      final shiftDisplayDate = _formatShiftDateRange(
        shiftDate,
        block1Start,
        block1Stop,
        block2Start,
        block2Stop,
      );
      var appliedRows = 0;

      for (final row in _equipmentRows) {
        if (!row.hasPopulatedContent) continue;

        row.date.text = shiftDisplayDate;
        if (!_usesMileage) {
          row.start.text = equipmentStart;
          row.stop.text = equipmentStop;
        }
        row.recalculateTotal(useMiles: _usesMileage);
        appliedRows++;
      }

      for (final row in _personnelRows) {
        if (!row.hasPopulatedContent) continue;

        row.date.text = shiftDisplayDate;
        row.guaranteeStart.text = block1Start;
        row.guaranteeStop.text = block1Stop;
        row.start.text = block2Start;
        row.stop.text = block2Stop;
        row.recalculateTotal();
        appliedRows++;
      }

      _showGlobalShiftApplyMessage(appliedRows);
    });
  }

  void _syncApparatusTimeFromGlobalTime() {
    if (!_apparatusSameAsCrewTimes || _isInitializing || _usesMileage) return;
    final ticket = _ticket;
    if (ticket == null || !_hasAssignedApparatus(ticket)) return;

    final row = _equipmentRows.first;
    final shiftDate = _globalShiftDateController.text;
    final block1Start = _globalBlock1StartController.text;
    final block1Stop = _globalBlock1StopController.text;
    final block2Start = _globalBlock2StartController.text;
    final block2Stop = _globalBlock2StopController.text;
    final equipmentStart = block1Start.isNotEmpty ? block1Start : block2Start;
    final equipmentStop = block2Stop.isNotEmpty ? block2Stop : block1Stop;
    final displayDate = _formatShiftDateRange(
      shiftDate,
      block1Start,
      block1Stop,
      block2Start,
      block2Stop,
    );

    row.isActive.value = true;
    row.date.text = displayDate.isEmpty ? shiftDate : displayDate;
    row.start.text = equipmentStart;
    row.stop.text = equipmentStop;
    row.recalculateTotal(useMiles: false);

    if (mounted) {
      setState(() {});
    }
  }

  void _recalculateAllRowTotals() {
    for (final row in _equipmentRows) {
      row.recalculateTotal(useMiles: _usesMileage);
    }
    for (final row in _personnelRows) {
      row.recalculateTotal();
    }
  }

  void _showGlobalShiftApplyMessage(int appliedRows) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          appliedRows == 0
              ? 'No populated rows available.'
              : 'Applied shift times to populated rows only.',
        ),
      ),
    );
  }

  OF297ShiftTicket _buildTicketFromForm() {
    final equipmentEntries = _equipmentRows
        .map(
          (row) => row.toEntry(
            _uuid.v4(),
            _parseDate,
            _parseTime,
            useMiles: _usesMileage,
          ),
        )
        .toList();
    final personnelEntries = _personnelRows
        .asMap()
        .entries
        .map(
          (item) => item.value.toEntry(
            item.key < _ticket!.personnelEntries.length
                ? _ticket!.personnelEntries[item.key].id
                : _uuid.v4(),
            _parseDate,
            _parseTime,
          ),
        )
        .toList();
    final primaryEquipmentEntry = _firstOrNull(
      equipmentEntries.where(
        (entry) =>
            entry.startTime != null ||
            entry.stopTime != null ||
            entry.mileageStart != null ||
            entry.mileageEnd != null,
      ),
    );
    final primaryPersonnelEntry = _firstOrNull(
      personnelEntries.where((entry) => entry.name.trim().isNotEmpty),
    );

    return _ticket!.copyWith(
      incidentName: _incidentNameController.text.trim(),
      incidentNumber: _incidentNumberController.text.trim(),
      financialCode: _financialCodeController.text.trim(),
      agreementNumber: _agreementNumberController.text.trim(),
      resourceOrderNumber: _resourceOrderNumberController.text.trim(),
      contractorName: _contractorNameController.text.trim(),
      ctrOfficeResponsibleForFire:
          _ctrOfficeResponsibleForFireController.text.trim(),
      equipmentMakeModel: _equipmentMakeModelController.text.trim(),
      equipmentType: _equipmentTypeController.text.trim(),
      serialVinNumber: _serialVinController.text.trim(),
      equipmentId: _equipmentIdController.text.trim(),
      transportRetained: _transportRetained,
      isMobilization: _isMobilization,
      rateIsHours: _rateIsHours,
      rateIsMiles: _rateIsMiles,
      globalShiftDate: _parseDate(_globalShiftDateController.text),
      globalBlock1Start: _globalBlock1StartController.text.trim(),
      globalBlock1Stop: _globalBlock1StopController.text.trim(),
      globalBlock2Start: _globalBlock2StartController.text.trim(),
      globalBlock2Stop: _globalBlock2StopController.text.trim(),
      apparatusSameAsCrewTimes: _apparatusSameAsCrewTimes,
      operatorName: primaryPersonnelEntry?.name ?? '',
      shiftStart: _usesMileage ? null : primaryEquipmentEntry?.startTime,
      shiftEnd: _usesMileage ? null : primaryEquipmentEntry?.stopTime,
      equipmentEntries: equipmentEntries,
      personnelEntries: personnelEntries,
      remarks: _remarksController.text.trim(),
      contractorRepresentativeName: _contractorRepController.text.trim(),
      incidentSupervisorName: _supervisorController.text.trim(),
      updatedAt: DateTime.now(),
    );
  }

  T? _firstOrNull<T>(Iterable<T> values) {
    for (final value in values) {
      return value;
    }
    return null;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final displayDate = trimmed.split('-').first.trim();
    return DateTime.tryParse(displayDate) ?? _tryDateFormat(displayDate);
  }

  DateTime? _parseTime(String timeValue, String dateValue) {
    final time = timeValue.trim();
    if (time.isEmpty) return null;

    final military = RegExp(r'^(\d{1,2})(\d{2})$').firstMatch(time);
    if (military != null) {
      return _buildDateTimeFromDateAndMilitaryTime(dateValue, time);
    }

    final direct = DateTime.tryParse(time);
    if (direct != null) return direct;

    final parts = time.split(':');
    if (parts.length == 2) {
      final date = _parseDate(dateValue) ?? DateTime.now();
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      if (hour > 23 || minute > 59) return null;

      return DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
    }

    return null;
  }

  DateTime? _tryDateFormat(String value) {
    try {
      return _dateFormat.parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return _dateFormat.format(value);
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    return DateFormat('HHmm').format(value);
  }

  String _formatNumber(double value) {
    if (value == 0) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  String _formatNullableNumber(double? value) {
    if (value == null || value == 0) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  bool _hasAssignedApparatus(OF297ShiftTicket ticket) {
    return ticket.equipmentMakeModel.trim().isNotEmpty ||
        ticket.equipmentType.trim().isNotEmpty ||
        ticket.serialVinNumber.trim().isNotEmpty ||
        ticket.equipmentId.trim().isNotEmpty ||
        _equipmentMakeModelController.text.trim().isNotEmpty ||
        _equipmentTypeController.text.trim().isNotEmpty ||
        _serialVinController.text.trim().isNotEmpty ||
        _equipmentIdController.text.trim().isNotEmpty;
  }
}

class _EquipmentRowControllers {
  final isActive = ValueNotifier<bool>(false);
  final date = TextEditingController();
  final start = TextEditingController();
  final stop = TextEditingController();
  final total = TextEditingController();
  final quantity = TextEditingController();
  final type = TextEditingController();
  final notes = TextEditingController();
  double calculatedTotalHours = 0;
  bool totalHoursManuallyOverridden = false;

  bool get hasPopulatedContent {
    return isActive.value ||
        date.text.trim().isNotEmpty ||
        start.text.trim().isNotEmpty ||
        stop.text.trim().isNotEmpty ||
        total.text.trim().isNotEmpty ||
        quantity.text.trim().isNotEmpty ||
        type.text.trim().isNotEmpty ||
        notes.text.trim().isNotEmpty;
  }

  void recalculateTotal({required bool useMiles}) {
    final calculatedTotal = useMiles
        ? _calculateMileage(start.text, stop.text)
        : _calculateHours(start.text, stop.text);
    if (!useMiles) {
      calculatedTotalHours = calculatedTotal ?? 0;
      if (!totalHoursManuallyOverridden) {
        total.text =
            calculatedTotal == null ? '' : _formatNumberValue(calculatedTotal);
      }
      return;
    }

    total.text =
        calculatedTotal == null ? '' : _formatNumberValue(calculatedTotal);
  }

  void markTotalManuallyChanged() {
    totalHoursManuallyOverridden = true;
  }

  void useCalculatedTotal() {
    totalHoursManuallyOverridden = false;
    total.text = calculatedTotalHours <= 0
        ? ''
        : _formatNumberValue(calculatedTotalHours);
  }

  OF297EquipmentTimeEntry toEntry(
      String id,
      DateTime? Function(String value) parseDate,
      DateTime? Function(String timeValue, String dateValue) parseTime,
      {required bool useMiles}) {
    final startMileage = _parseMileage(start.text);
    final stopMileage = _parseMileage(stop.text);
    final parsedStartTime = useMiles ? null : parseTime(start.text, date.text);
    final parsedStopTime = useMiles
        ? null
        : _adjustOvernightStop(
            parsedStartTime,
            parseTime(stop.text, date.text),
          );

    return OF297EquipmentTimeEntry(
      id: id,
      date: parseDate(date.text),
      startTime: parsedStartTime,
      stopTime: parsedStopTime,
      totalHours: useMiles
          ? 0
          : double.tryParse(total.text.trim()) ??
              _calculateHours(start.text, stop.text) ??
              0,
      calculatedTotalHours:
          useMiles ? 0 : _calculateHours(start.text, stop.text) ?? 0,
      totalHoursManuallyOverridden:
          useMiles ? false : totalHoursManuallyOverridden,
      mileageStart: useMiles ? startMileage : null,
      mileageEnd: useMiles ? stopMileage : null,
      totalMiles: useMiles
          ? _calculateMileage(start.text, stop.text) ??
              double.tryParse(total.text.trim()) ??
              0
          : 0,
      specialRateQuantity: double.tryParse(quantity.text.trim()) ?? 0,
      rateType: type.text.trim(),
      notes: notes.text.trim(),
    );
  }

  void dispose() {
    isActive.dispose();
    date.dispose();
    start.dispose();
    stop.dispose();
    total.dispose();
    quantity.dispose();
    type.dispose();
    notes.dispose();
  }
}

double? _calculateHours(String startValue, String stopValue) {
  return calculateShiftHours(startValue, stopValue);
}

double? _calculatePersonnelTotalHours(
  String block1Start,
  String block1Stop,
  String block2Start,
  String block2Stop,
) {
  final block1Hours = _calculateHours(block1Start, block1Stop);
  final block2Hours = _calculateHours(block2Start, block2Stop);
  if (block1Hours == null && block2Hours == null) return null;
  return (block1Hours ?? 0) + (block2Hours ?? 0);
}

DateTime? _adjustOvernightStop(DateTime? start, DateTime? stop) {
  if (start == null || stop == null) return stop;
  if (stop.isBefore(start)) {
    return stop.add(const Duration(days: 1));
  }
  return stop;
}

(DateTime?, DateTime?) _adjustSecondBlockAfterOvernightFirstBlock(
  String firstStartValue,
  String firstStopValue,
  String secondStartValue,
  DateTime? secondStart,
  DateTime? secondStop,
) {
  final firstStartMinutes = _parseMilitaryMinutes(firstStartValue);
  final firstStopMinutes = _parseMilitaryMinutes(firstStopValue);
  final secondStartMinutes = _parseMilitaryMinutes(secondStartValue);
  if (firstStartMinutes == null ||
      firstStopMinutes == null ||
      secondStartMinutes == null ||
      firstStopMinutes >= firstStartMinutes ||
      secondStartMinutes >= firstStartMinutes) {
    return (secondStart, secondStop);
  }

  return (
    secondStart?.add(const Duration(days: 1)),
    secondStop?.add(const Duration(days: 1)),
  );
}

double? _calculateMileage(String startValue, String stopValue) {
  final startMileage = _parseMileage(startValue);
  final stopMileage = _parseMileage(stopValue);
  if (startMileage == null ||
      stopMileage == null ||
      stopMileage < startMileage) {
    return null;
  }

  return stopMileage - startMileage;
}

double? _parseMileage(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

int? _parseMilitaryMinutes(String value) {
  final text = value.trim();
  if (text.length != 4) return null;

  final hour = int.tryParse(text.substring(0, 2));
  final minute = int.tryParse(text.substring(2, 4));
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return null;
  }

  return hour * 60 + minute;
}

String _formatHours(double hours) {
  return _formatNumberValue(hours);
}

String _formatNumberValue(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}

class _PersonnelRowControllers {
  final date = TextEditingController();
  final name = TextEditingController();
  final position = TextEditingController();
  final guaranteeStart = TextEditingController();
  final guaranteeStop = TextEditingController();
  final start = TextEditingController();
  final stop = TextEditingController();
  final total = TextEditingController();
  final notes = TextEditingController();

  bool get hasPopulatedContent =>
      name.text.trim().isNotEmpty || position.text.trim().isNotEmpty;

  void recalculateTotal() {
    final rowHours = _calculatePersonnelTotalHours(
      guaranteeStart.text,
      guaranteeStop.text,
      start.text,
      stop.text,
    );
    total.text = rowHours == null ? '' : _formatHours(rowHours);
  }

  OF297PersonnelTimeEntry toEntry(
    String id,
    DateTime? Function(String value) parseDate,
    DateTime? Function(String timeValue, String dateValue) parseTime,
  ) {
    final parsedGuaranteeStart = parseTime(guaranteeStart.text, date.text);
    final parsedGuaranteeStop = _adjustOvernightStop(
      parsedGuaranteeStart,
      parseTime(guaranteeStop.text, date.text),
    );
    var parsedStart = parseTime(start.text, date.text);
    var parsedStop = _adjustOvernightStop(
      parsedStart,
      parseTime(stop.text, date.text),
    );
    final adjustedSecondBlock = _adjustSecondBlockAfterOvernightFirstBlock(
      guaranteeStart.text,
      guaranteeStop.text,
      start.text,
      parsedStart,
      parsedStop,
    );
    parsedStart = adjustedSecondBlock.$1;
    parsedStop = adjustedSecondBlock.$2;
    final totalBlockHours = _calculatePersonnelTotalHours(
      guaranteeStart.text,
      guaranteeStop.text,
      start.text,
      stop.text,
    );

    return OF297PersonnelTimeEntry(
      id: id,
      date: parseDate(date.text),
      name: name.text.trim(),
      position: position.text.trim(),
      guaranteeStartTime: parsedGuaranteeStart,
      guaranteeStopTime: parsedGuaranteeStop,
      startTime: parsedStart,
      stopTime: parsedStop,
      totalHours: totalBlockHours ?? double.tryParse(total.text.trim()) ?? 0,
      notes: notes.text.trim(),
    );
  }

  void dispose() {
    date.dispose();
    name.dispose();
    position.dispose();
    guaranteeStart.dispose();
    guaranteeStop.dispose();
    start.dispose();
    stop.dispose();
    total.dispose();
    notes.dispose();
  }
}

class _EquipmentRowEditor extends StatelessWidget {
  final int rowNumber;
  final _EquipmentRowControllers row;
  final bool readOnly;
  final bool useMiles;
  final bool controlledByGlobalTime;

  const _EquipmentRowEditor({
    required this.rowNumber,
    required this.row,
    required this.readOnly,
    required this.useMiles,
    this.controlledByGlobalTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Equipment row $rowNumber'),
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: row.isActive,
          builder: (context, isActive, _) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Apply global shift to this equipment row'),
              value: isActive,
              onChanged: readOnly
                  ? null
                  : (value) {
                      row.isActive.value = value ?? false;
                    },
            );
          },
        ),
        _ResponsiveFields(
          children: [
            _DatePickerTextField(
              label: '15. Date',
              controller: row.date,
              readOnly: readOnly,
            ),
            if (useMiles)
              _MileageField(
                label: '16. Start Mileage',
                controller: row.start,
                readOnly: readOnly,
                onMileageChanged: () => row.recalculateTotal(useMiles: true),
              )
            else
              _MilitaryTimeField(
                label: '16. Start',
                controller: row.start,
                readOnly: readOnly || controlledByGlobalTime,
                helperText: controlledByGlobalTime
                    ? 'Controlled by global crew time'
                    : null,
                onTimeChanged: () => row.recalculateTotal(useMiles: false),
              ),
            if (useMiles)
              _MileageField(
                label: '17. Stop Mileage',
                controller: row.stop,
                readOnly: readOnly,
                onMileageChanged: () => row.recalculateTotal(useMiles: true),
              )
            else
              _MilitaryTimeField(
                label: '17. Stop',
                controller: row.stop,
                readOnly: readOnly || controlledByGlobalTime,
                helperText: controlledByGlobalTime
                    ? 'Controlled by global crew time'
                    : null,
                onTimeChanged: () => row.recalculateTotal(useMiles: false),
              ),
            _EquipmentTotalField(
              row: row,
              useMiles: useMiles,
              readOnly: readOnly,
            ),
            OF297TextField(
              label: '19. Quantity',
              controller: row.quantity,
              readOnly: readOnly,
              keyboardType: TextInputType.number,
            ),
            OF297TextField(
              label: '20. Type',
              controller: row.type,
              readOnly: readOnly,
            ),
            OF297TextField(
              label: '21. Travel/Other Remarks',
              controller: row.notes,
              readOnly: readOnly,
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonnelRowEditor extends StatelessWidget {
  final int rowNumber;
  final _PersonnelRowControllers row;
  final bool readOnly;

  const _PersonnelRowEditor({
    required this.rowNumber,
    required this.row,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Personnel row $rowNumber'),
      children: [
        _ResponsiveFields(
          children: [
            _DatePickerTextField(
              label: '22. Date',
              controller: row.date,
              readOnly: readOnly,
            ),
            OF297TextField(
              label: '23. Operator Name',
              controller: row.name,
              readOnly: readOnly,
            ),
            OF297TextField(
              label: 'Classification / Qualification',
              controller: row.position,
              readOnly: readOnly,
            ),
            _MilitaryTimeField(
              label: '24. Start',
              controller: row.guaranteeStart,
              readOnly: readOnly,
              onTimeChanged: row.recalculateTotal,
            ),
            _MilitaryTimeField(
              label: '25. Stop',
              controller: row.guaranteeStop,
              readOnly: readOnly,
              onTimeChanged: row.recalculateTotal,
            ),
            _MilitaryTimeField(
              label: '26. Start',
              controller: row.start,
              readOnly: readOnly,
              onTimeChanged: row.recalculateTotal,
            ),
            _MilitaryTimeField(
              label: '27. Stop',
              controller: row.stop,
              readOnly: readOnly,
              onTimeChanged: row.recalculateTotal,
            ),
            OF297TextField(
              label: '28. Total',
              controller: row.total,
              readOnly: true,
              keyboardType: TextInputType.number,
            ),
            OF297TextField(
              label: '29. Travel/Other Remarks',
              controller: row.notes,
              readOnly: readOnly,
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }
}

class _EquipmentTotalField extends StatefulWidget {
  final _EquipmentRowControllers row;
  final bool useMiles;
  final bool readOnly;

  const _EquipmentTotalField({
    required this.row,
    required this.useMiles,
    required this.readOnly,
  });

  @override
  State<_EquipmentTotalField> createState() => _EquipmentTotalFieldState();
}

class _EquipmentTotalFieldState extends State<_EquipmentTotalField> {
  @override
  void initState() {
    super.initState();
    widget.row.total.addListener(_handleTotalChanged);
  }

  @override
  void didUpdateWidget(covariant _EquipmentTotalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row == widget.row) return;
    oldWidget.row.total.removeListener(_handleTotalChanged);
    widget.row.total.addListener(_handleTotalChanged);
  }

  @override
  void dispose() {
    widget.row.total.removeListener(_handleTotalChanged);
    super.dispose();
  }

  void _handleTotalChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.useMiles ? '18. Total Miles' : '18. Total Hours';
    final text = widget.row.total.text.trim();
    final parsed = double.tryParse(text);
    final invalidHours =
        !widget.useMiles && text.isNotEmpty && (parsed == null || parsed < 0);
    final adjusted = !widget.useMiles &&
        widget.row.totalHoursManuallyOverridden &&
        widget.row.calculatedTotalHours > 0;
    final exceedsCalculated =
        adjusted && parsed != null && parsed > widget.row.calculatedTotalHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OF297TextField(
          label: label,
          controller: widget.row.total,
          readOnly: widget.readOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: widget.useMiles
              ? null
              : (_) {
                  widget.row.markTotalManuallyChanged();
                  setState(() {});
                },
        ),
        if (invalidHours) ...[
          const SizedBox(height: 4),
          Text(
            'Enter a valid non-negative duration.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (adjusted) ...[
          const SizedBox(height: 4),
          Text(
            'Adjusted from calculated time: '
            '${_formatHours(widget.row.calculatedTotalHours)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton(
            onPressed: widget.readOnly
                ? null
                : () {
                    widget.row.useCalculatedTotal();
                    setState(() {});
                  },
            child: const Text('Use calculated time'),
          ),
        ],
        if (exceedsCalculated) ...[
          const SizedBox(height: 4),
          Text(
            'Warning: total is greater than calculated elapsed time.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _DatePickerTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;

  const _DatePickerTextField({
    required this.label,
    required this.controller,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: readOnly ? null : () => _pickDate(context),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final formatter = DateFormat('MM/dd/yyyy');
    DateTime? existing;
    try {
      existing = formatter.parseStrict(controller.text);
    } catch (_) {
      existing = null;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: existing ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;
    controller.text = formatter.format(selectedDate);
  }
}

class _MilitaryTimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onTimeChanged;
  final String? helperText;

  const _MilitaryTimeField({
    required this.label,
    required this.controller,
    required this.readOnly,
    this.onTimeChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final errorText = _timeError(value.text);

        return Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              _normalizeTime();
            }
          },
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            enabled: !readOnly,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 1.5,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: 'HHMM',
              helperText: helperText ?? 'Military time',
              errorText: errorText,
              counterText: '',
              prefixIcon: const Icon(Icons.schedule_outlined),
            ),
            maxLength: 4,
            onEditingComplete: _normalizeTime,
            onChanged: (_) => onTimeChanged?.call(),
          ),
        );
      },
    );
  }

  String? _timeError(String value) {
    if (value.isEmpty) {
      return null;
    }

    if (value.length != 4) {
      return 'Use HHMM';
    }

    final hour = int.tryParse(value.substring(0, 2));
    final minute = int.tryParse(value.substring(2, 4));
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return 'Use 0000-2359';
    }

    return null;
  }

  void _normalizeTime() {
    final raw = controller.text.trim();
    if (raw.isEmpty) return;

    final padded = raw.padLeft(4, '0');
    if (_timeError(padded) == null) {
      controller.text = padded;
      onTimeChanged?.call();
    }
  }
}

class _MileageField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onMileageChanged;

  const _MileageField({
    required this.label,
    required this.controller,
    required this.readOnly,
    this.onMileageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      enabled: !readOnly,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        helperText: 'Odometer/mileage',
        prefixIcon: const Icon(Icons.speed_outlined),
      ),
      onChanged: (_) => onMileageChanged?.call(),
    );
  }
}

class _FormToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onSelected;

  const _FormToggleChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: FilterChip(
        label: Center(child: Text(label, textAlign: TextAlign.center)),
        selected: selected,
        onSelected: enabled ? onSelected : null,
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFields({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        final spacing = columns == 1 ? 0.0 : AppSpacing.md;
        final itemWidth =
            (constraints.maxWidth - spacing) / columns.clamp(1, 2);

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: children
              .map(
                (child) => SizedBox(
                  width: columns == 1 ? double.infinity : itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
