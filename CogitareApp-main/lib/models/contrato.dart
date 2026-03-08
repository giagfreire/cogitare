class Contrato {
  final int? id;
  final int? responsavelId;
  final int? cuidadorId;
  final int? idosoId;
  final DateTime dataInicio;
  final DateTime dataFim;
  final double valor;
  final String local;
  final String? observacoes;
  final String status;
  final String cuidadorNome;
  final String idosoNome;

  Contrato({
    this.id,
    this.responsavelId,
    this.cuidadorId,
    this.idosoId,
    required this.dataInicio,
    required this.dataFim,
    required this.valor,
    required this.local,
    this.observacoes,
    required this.status,
    required this.cuidadorNome,
    required this.idosoNome,
  });

  // Verifica se o contrato está terminando em breve (menos de 7 dias)
  bool get isEndingSoon {
    final now = DateTime.now();
    final daysRemaining = dataFim.difference(now).inDays;
    return daysRemaining <= 7 && daysRemaining >= 0;
  }

  // Retorna o número de dias restantes
  int get daysRemaining {
    final now = DateTime.now();
    return dataFim.difference(now).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'responsavelId': responsavelId,
      'cuidadorId': cuidadorId,
      'idosoId': idosoId,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
      'valor': valor,
      'local': local,
      'observacoes': observacoes,
      'status': status,
      'cuidadorNome': cuidadorNome,
      'idosoNome': idosoNome,
    };
  }

  factory Contrato.fromJson(Map<String, dynamic> json) {
    return Contrato(
      id: json['id'],
      responsavelId: json['responsavelId'],
      cuidadorId: json['cuidadorId'],
      idosoId: json['idosoId'],
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      valor: json['valor']?.toDouble() ?? 0.0,
      local: json['local'] ?? '',
      observacoes: json['observacoes'],
      status: json['status'] ?? 'ativo',
      cuidadorNome: json['cuidadorNome'] ?? '',
      idosoNome: json['idosoNome'] ?? '',
    );
  }

  Contrato copyWith({
    int? id,
    int? responsavelId,
    int? cuidadorId,
    int? idosoId,
    DateTime? dataInicio,
    DateTime? dataFim,
    double? valor,
    String? local,
    String? observacoes,
    String? status,
    String? cuidadorNome,
    String? idosoNome,
  }) {
    return Contrato(
      id: id ?? this.id,
      responsavelId: responsavelId ?? this.responsavelId,
      cuidadorId: cuidadorId ?? this.cuidadorId,
      idosoId: idosoId ?? this.idosoId,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      valor: valor ?? this.valor,
      local: local ?? this.local,
      observacoes: observacoes ?? this.observacoes,
      status: status ?? this.status,
      cuidadorNome: cuidadorNome ?? this.cuidadorNome,
      idosoNome: idosoNome ?? this.idosoNome,
    );
  }
}
