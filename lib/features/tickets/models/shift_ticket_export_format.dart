enum ShiftTicketExportFormat {
  of297,
  etr,
  ctr;

  String get label {
    switch (this) {
      case ShiftTicketExportFormat.of297:
        return 'OF-297';
      case ShiftTicketExportFormat.etr:
        return 'ETR';
      case ShiftTicketExportFormat.ctr:
        return 'CTR';
    }
  }

  String get filePrefix {
    switch (this) {
      case ShiftTicketExportFormat.of297:
        return 'OF297';
      case ShiftTicketExportFormat.etr:
        return 'ETR';
      case ShiftTicketExportFormat.ctr:
        return 'CTR';
    }
  }
}
