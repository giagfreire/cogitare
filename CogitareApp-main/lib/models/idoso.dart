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
  final String? photoUrl;
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
    this.photoUrl,
    this.selectedServices,
    this.availability,
  });

  Map<String, dynamic> toJson() {
    return {
      'IdResponsavel': guardianId,
      'IdMobilidade': mobilityId,
      'IdNivelAutonomia': autonomyLevelId,
      'Nome': name,
      'DataNascimento': birthDate?.toIso8601String().split('T')[0],
      'Sexo': gender,
      'CuidadosMedicos': medicalCare,
      'DescricaoExtra': extraDescription,
      'FotoUrl': photoUrl,
      'SelectedServices': selectedServices,
      'Availability': availability,
    };
  }

  factory Idoso.fromJson(Map<String, dynamic> json) {
    return Idoso(
      id: json['IdIdoso'] ?? json['id'],
      guardianId: json['IdResponsavel'] ?? json['guardianId'],
      mobilityId: json['IdMobilidade'] ?? json['mobilityId'],
      autonomyLevelId: json['IdNivelAutonomia'] ?? json['autonomyLevelId'],
      name: json['Nome'] ?? json['name'] ?? '',
      birthDate: json['DataNascimento'] != null
          ? DateTime.tryParse(json['DataNascimento'].toString())
          : (json['birthDate'] != null
              ? DateTime.tryParse(json['birthDate'].toString())
              : null),
      gender: json['Sexo'] ?? json['gender'],
      medicalCare: json['CuidadosMedicos'] ?? json['medicalCare'],
      extraDescription: json['DescricaoExtra'] ?? json['extraDescription'],
      photoUrl: json['FotoUrl'] ?? json['photoUrl'],
      selectedServices: json['SelectedServices'] != null
          ? List<int>.from(json['SelectedServices'])
          : null,
      availability: json['Availability'] != null
          ? Map<String, bool>.from(json['Availability'])
          : null,
    );
  }
}