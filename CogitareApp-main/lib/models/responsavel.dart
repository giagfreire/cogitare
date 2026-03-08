class Responsavel {
  final int? id;
  final int? addressId;
  final String? cpf;
  final String? name;
  final String? email;
  final String? phone;
  final DateTime? birthDate;
  final String? photoUrl;
  final String? password;

  Responsavel({
    this.id,
    this.addressId,
    this.cpf,
    this.name,
    this.email,
    this.phone,
    this.birthDate,
    this.photoUrl,
    this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'IdEndereco': addressId,
      'Cpf': cpf,
      'Nome': name,
      'Email': email,
      'Telefone': phone,
      'DataNascimento': birthDate?.toIso8601String().split('T')[0],
      'FotoUrl': photoUrl,
      'senha': password, 
    };
  }

  factory Responsavel.fromJson(Map<String, dynamic> json) {
    return Responsavel(
      id: json['IdResponsavel'],
      addressId: json['IdEndereco'],
      cpf: json['Cpf'],
      name: json['Nome'],
      email: json['Email'],
      phone: json['Telefone'],
      birthDate: json['DataNascimento'] != null
          ? DateTime.parse(json['DataNascimento'])
          : null,
      photoUrl: json['FotoUrl'],
    );
  }

  Responsavel copyWith({
    int? id,
    int? addressId,
    String? cpf,
    String? name,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? photoUrl,
    String? password,
  }) {
    return Responsavel(
      id: id ?? this.id,
      addressId: addressId ?? this.addressId,
      cpf: cpf ?? this.cpf,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      password: password ?? this.password,
    );
  }
}
