class Endereco {
  final int? id;
  final String city;
  final String neighborhood;
  final String street;
  final String number;
  final String? complement;
  final String zipCode;

  Endereco({
    this.id,
    required this.city,
    required this.neighborhood,
    required this.street,
    required this.number,
    this.complement,
    required this.zipCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cidade': city,
      'bairro': neighborhood,
      'rua': street,
      'numero': number,
      'complemento': complement,
      'cep': zipCode,
    };
  }

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      id: json['IdEndereco'] ?? json['id'],
      city: json['Cidade'] ?? json['city'] ?? '',
      neighborhood: json['Bairro'] ?? json['neighborhood'] ?? '',
      street: json['Rua'] ?? json['street'] ?? '',
      number: json['Numero'] ?? json['number'] ?? '',
      complement: json['Complemento'] ?? json['complement'],
      zipCode: json['Cep'] ?? json['zipCode'] ?? '',
    );
  }

  Endereco copyWith({
    int? id,
    String? city,
    String? neighborhood,
    String? street,
    String? number,
    String? complement,
    String? zipCode,
  }) {
    return Endereco(
      id: id ?? this.id,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      zipCode: zipCode ?? this.zipCode,
    );
  }
}
