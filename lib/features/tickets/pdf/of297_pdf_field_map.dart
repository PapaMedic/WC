// Tickets PDF generation and export support.
/// Central mapping between Wildland Companion ticket data and the official
/// OF-297 2024 PDF template fields.
///
/// The actual PDF field names may differ and can be adjusted after inspecting
/// the official PDF form fields. Keep field names centralized here so the PDF
/// export layer can change without touching the Flutter form or ticket model.
class Of297PdfFieldMap {
  static const templateAssetPath = 'assets/OF297/OF297-24.pdf';

  // OF-297 top section: agreement, contractor, incident, and equipment.
  static const agreementNumber = '_1_Agreement_Number';
  static const contractorName = '_2_ContractorAgency_Name';
  static const resourceOrderNumber = '_3_Resource_Order_Number';
  static const incidentName = '_4_Incident_Name';
  static const incidentNumber = '_5_Incident_Number';
  static const financialCode = '_6_Financial_Code';
  static const equipmentMakeModel = '_7_Equipment_MakeModel';
  static const equipmentType = '_8_Equipment_Type';
  static const serialVinNumber = '_9_SerialVIN_Number';
  static const equipmentId = '_10_LicenseID_Number';
  static const transportRetainedYes = '_12_Transport_Retained_Yes';
  static const transportRetainedNo = '_12_Transport_Retained_No';
  static const mobilization = '_13_Mobilization';
  static const demobilization = '_13_Demobilization';
  static const rateHours = '_14_Hours';
  static const rateMiles = '_14_Miles';

  // OF-297 equipment time rows: blocks 15-21.
  static String equipmentDate(int row) => '_15_DateRow$row';
  static String equipmentStart(int row) => '_16_StartRow$row';
  static String equipmentStop(int row) => '_17_StopRow$row';
  static String equipmentTotal(int row) => '_18_TotalRow$row';
  static String equipmentQuantity(int row) => '_19_QuantityRow$row';
  static String equipmentRateType(int row) => '_20_TypeRow$row';
  static String equipmentNotes(int row) =>
      '_21_Note_Travel_Other_remarksRow$row';

  // OF-297 personnel/operator time rows: blocks 22-29.
  static String personnelDate(int row) => '_22_DateRow$row';
  static String personnelName(int row) =>
      '_23_Operator_Name_First__LastRow$row';
  static String personnelStartOne(int row) => '_24_StartRow$row';
  static String personnelStopOne(int row) => '_25_StopRow$row';
  static String personnelStartTwo(int row) => '_26_StartRow$row';
  static String personnelStopTwo(int row) => '_27_StopRow$row';
  static String personnelTotal(int row) => '_28_TotalRow$row';
  static String personnelNotes(int row) =>
      '_29_Note_Travel_Other_remarksRow$row';

  // OF-297 bottom section: remarks and signatures.
  static const remarks =
      '_30_Remarks__Provide_details_of_any_equipment_breakdown_or_operating_issues_Include_other_information_as_necessary';
  static const contractorRepresentativeName =
      '_31_ContractorAgency_Representative_Printed_Name';
  static const contractorSignature =
      '_32_ContractorAgency_Representative_Signature';
  static const supervisorName =
      '_33_Incident_Supervisor_Printed_Name__Resource_Order_number';
  static const supervisorSignature = '_34_Incident_Supervisor_Signature';
}
