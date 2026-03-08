class Cuidador {
  final int? id;
  final int? addressId;
  final String? cpf;
  final String? name;
  final String? email;
  final String? phone;
  final String? password;
  final DateTime? birthDate;
  final String? photoUrl;
  final String? biography;
  final String? smokingStatus;
  final String? hasChildren;
  final String? hasLicense;
  final String? hasCar;
  final String? hourlyRate;

  Cuidador({
    this.id,
    this.addressId,
    this.cpf,
    this.name,
    this.email,
    this.phone,
    this.password,
    this.birthDate,
    this.photoUrl,
    this.biography,
    this.smokingStatus = 'Não',
    this.hasChildren = 'Não',
    this.hasLicense = 'Não',
    this.hasCar = 'Não',
    this.hourlyRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'endereco_id': addressId,
      'cpf': cpf,
      'nome': name,
      'email': email,
      'telefone': phone,
      'senha': password,
      'data_nascimento': birthDate?.toIso8601String().split('T')[0],
      'foto_url': photoUrl,
      'biografia': biography,
      'fumante': smokingStatus,
      'tem_filhos': hasChildren,
      'possui_cnh': hasLicense,
      'tem_carro': hasCar,
      'valor_hora': hourlyRate,
    };
  }

  factory Cuidador.fromJson(Map<String, dynamic> json) {
    return Cuidador(
      id: json['id'],
      addressId: json['endereco_id'],
      cpf: json['cpf'],
      name: json['nome'],
      email: json['email'],
      phone: json['telefone'],
      password: json['senha'],
      birthDate: json['data_nascimento'] != null
          ? DateTime.parse(json['data_nascimento'])
          : null,
      photoUrl: json['foto_url'],
      biography: json['biografia'],
      smokingStatus: json['fumante'],
      hasChildren: json['tem_filhos'],
      hasLicense: json['possui_cnh'],
      hasCar: json['tem_carro'],
      hourlyRate: json['valor_hora'],
    );
  }

  Cuidador copyWith({
    int? id,
    int? addressId,
    String? cpf,
    String? name,
    String? email,
    String? phone,
    String? password,
    DateTime? birthDate,
    String? photoUrl,
    String? biography,
    String? smokingStatus,
    String? hasChildren,
    String? hasLicense,
    String? hasCar,
    String? hourlyRate,
  }) {
    return Cuidador(
      id: id ?? this.id,
      addressId: addressId ?? this.addressId,
      cpf: cpf ?? this.cpf,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      biography: biography ?? this.biography,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      hasChildren: hasChildren ?? this.hasChildren,
      hasLicense: hasLicense ?? this.hasLicense,
      hasCar: hasCar ?? this.hasCar,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }
}
