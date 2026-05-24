class Apparatus {
  final String id;
  final String agencyName;
  final String equipmentMakeModel;
  final String equipmentType;
  final String serialVinNumber;
  final String licenseIdNumber;
  final bool isSelected;

  Apparatus({
    required this.id,
    required this.agencyName,
    required this.equipmentMakeModel,
    required this.equipmentType,
    required this.serialVinNumber,
    required this.licenseIdNumber,
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'agencyName': agencyName,
        'equipmentMakeModel': equipmentMakeModel,
        'equipmentType': equipmentType,
        'serialVinNumber': serialVinNumber,
        'licenseIdNumber': licenseIdNumber,
        'isSelected': isSelected,
      };

  factory Apparatus.fromJson(Map<String, dynamic> json) {
  return Apparatus(
    id: json['id'] ?? '',
    agencyName: json['agencyName'] ?? '',
    equipmentMakeModel: json['equipmentMakeModel'] ?? json['name'] ?? '',
    equipmentType: json['equipmentType'] ?? json['type'] ?? '',
    serialVinNumber: json['serialVinNumber'] ?? '',
    licenseIdNumber: json['licenseIdNumber'] ?? json['unitNumber'] ?? '',
    isSelected: json['isSelected'] ?? false,
  );
}

  Apparatus copyWith({
    bool? isSelected,
  }) {
    return Apparatus(
      id: id,
      agencyName: agencyName,
      equipmentMakeModel: equipmentMakeModel,
      equipmentType: equipmentType,
      serialVinNumber: serialVinNumber,
      licenseIdNumber: licenseIdNumber,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}