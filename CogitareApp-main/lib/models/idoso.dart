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

  // 🔥 NOVOS CAMPOS
  final String? usaMedicacao;
  final String? medicacaoDetalhes;

  final String? precisaBanho;
  final String? banhoDetalhes;

  final String? precisaAlimentacao;
  final String? alimentacaoDetalhes;

  final String? precisaAcompanhamento;
  final String? acompanhamentoDetalhes;

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
    this.usaMedicacao,
    this.medicacaoDetalhes,
    this.precisaBanho,
    this.banhoDetalhes,
    this.precisaAlimentacao,
    this.alimentacaoDetalhes,
    this.precisaAcompanhamento,
    this.acompanhamentoDetalhes,
  });

  Map<String, dynamic> toJson() {
    return {
      'IdMobilidade': mobilityId,
      'IdNivelAutonomia': autonomyLevelId,
      'Nome': name,
      'DataNascimento': birthDate?.toIso8601String().split('T')[0],
      'Sexo': gender,
      'CuidadosMedicos': medicalCare,
      'DescricaoExtra': extraDescription,

      // 🔥 NOVOS CAMPOS
      'UsaMedicacao': usaMedicacao,
      'MedicacaoDetalhes': medicacaoDetalhes,
      'PrecisaBanho': precisaBanho,
      'BanhoDetalhes': banhoDetalhes,
      'PrecisaAlimentacao': precisaAlimentacao,
      'AlimentacaoDetalhes': alimentacaoDetalhes,
      'PrecisaAcompanhamento': precisaAcompanhamento,
      'AcompanhamentoDetalhes': acompanhamentoDetalhes,
    };
  }

  factory Idoso.fromJson(Map<String, dynamic> json) {
    return Idoso(
      id: json['IdIdoso'],
      guardianId: json['IdResponsavel'],
      mobilityId: json['IdMobilidade'],
      autonomyLevelId: json['IdNivelAutonomia'],
      name: json['Nome'] ?? '',
      birthDate: json['DataNascimento'] != null
          ? DateTime.tryParse(json['DataNascimento'].toString())
          : null,
      gender: json['Sexo'],
      medicalCare: json['CuidadosMedicos'],
      extraDescription: json['DescricaoExtra'],

      // 🔥 NOVOS CAMPOS
      usaMedicacao: json['UsaMedicacao'],
      medicacaoDetalhes: json['MedicacaoDetalhes'],
      precisaBanho: json['PrecisaBanho'],
      banhoDetalhes: json['BanhoDetalhes'],
      precisaAlimentacao: json['PrecisaAlimentacao'],
      alimentacaoDetalhes: json['AlimentacaoDetalhes'],
      precisaAcompanhamento: json['PrecisaAcompanhamento'],
      acompanhamentoDetalhes: json['AcompanhamentoDetalhes'],
    );
  }
}