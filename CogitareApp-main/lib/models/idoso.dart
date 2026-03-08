class Idoso {
  final int? id;
  final int? guardianId;
  final int? mobilityId;
  final int? autonomyLevelId;
  final String name;
  final DateTime? birthDate;
  final String? gender;
  final String? medicalCare;
  final String? extraDescription;
  final List<int>? selectedServices;
  final Map<String, bool>? availability;

  Idoso({
    this.id,
    this.guardianId,
    this.mobilityId,
    this.autonomyLevelId,
    required this.name,
    this.birthDate,
    this.gender,
    this.medicalCare,
    this.extraDescription,
    this.selectedServices,
    this.availability,
  });

  Map<String, dynamic> toJson() {
  return {
    'IdResponsavel': guardianId,
    'IdMobilidade': mobilityId,
    'IdNivelAutonomia': autonomyLevelId,
    'Nome': name,
    'DataNascimento': birthDate?.toIso8601String().split('T')[0], // yyyy-MM-dd
    'Sexo': gender,
    'CuidadosMedicos': medicalCare,
    'DescricaoExtra': extraDescription,
    'FotoUrl': null, 
    'SelectedServices': selectedServices,
    'Availability': availability,
  };
}


  factory Idoso.fromJson(Map<String, dynamic> json) {
    return Idoso(
      id: json['id'],
      guardianId: json['guardianId'],
      mobilityId: json['mobilityId'],
      autonomyLevelId: json['autonomyLevelId'],
      name: json['name'] ?? '',
      birthDate:
          json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      gender: json['gender'],
      medicalCare: json['medicalCare'],
      extraDescription: json['extraDescription'],
      selectedServices: json['selectedServices']?.cast<int>(),
      availability: json['availability']?.cast<String, bool>(),
    );
  }

  Idoso copyWith({
    int? id,
    int? guardianId,
    int? mobilityId,
    int? autonomyLevelId,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? medicalCare,
    String? extraDescription,
    List<int>? selectedServices,
    Map<String, bool>? availability,
  }) {
    return Idoso(
      id: id ?? this.id,
      guardianId: guardianId ?? this.guardianId,
      mobilityId: mobilityId ?? this.mobilityId,
      autonomyLevelId: autonomyLevelId ?? this.autonomyLevelId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      medicalCare: medicalCare ?? this.medicalCare,
      extraDescription: extraDescription ?? this.extraDescription,
      selectedServices: selectedServices ?? this.selectedServices,
      availability: availability ?? this.availability,
    );
  }
}
