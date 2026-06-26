// Personnel data model and serialization helpers.
class Personnel {
  final String id;
  final String name;
  final String qualification;
  final String homeUnit;
  final String phoneNumber;
  final bool isAssigned;

  Personnel({
    required this.id,
    required this.name,
    required this.qualification,
    required this.homeUnit,
    required this.phoneNumber,
    this.isAssigned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qualification': qualification,
        'homeUnit': homeUnit,
        'phoneNumber': phoneNumber,
        'isAssigned': isAssigned,
      };

  factory Personnel.fromJson(Map<String, dynamic> json) {
    return Personnel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      qualification: json['qualification'] ?? '',
      homeUnit: json['homeUnit'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isAssigned: json['isAssigned'] ?? false,
    );
  }

  Personnel copyWith({
    bool? isAssigned,
  }) {
    return Personnel(
      id: id,
      name: name,
      qualification: qualification,
      homeUnit: homeUnit,
      phoneNumber: phoneNumber,
      isAssigned: isAssigned ?? this.isAssigned,
    );
  }
}
