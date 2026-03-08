import '../models/responsavel.dart';
import '../models/endereco.dart';
import 'api_client.dart';

/// Serviço de API para Responsáveis
class ApiResponsavel {
  /// Cria endereço
  static Future<Map<String, dynamic>> createEndereco(Endereco address) async {
    try {
      return await ApiClient.post('/api/responsavel/endereco', {
        'cidade': address.city,
        'bairro': address.neighborhood,
        'rua': address.street,
        'numero': address.number,
        'complemento': address.complement,
        'cep': address.zipCode,
      });
    } catch (e) {
      return {'success': false, 'message': 'Erro ao cadastrar endereço: $e'};
    }
  }

  /// Cria responsável
  static Future<Map<String, dynamic>> createResponsavel(
    Responsavel guardian,
  ) async {
    try {
      return await ApiClient.post('/api/responsavel', {
        'idEndereco': guardian.addressId,
        'cpf': guardian.cpf,
        'nome': guardian.name,
        'email': guardian.email,
        'telefone': guardian.phone,
        'dataNascimento': guardian.birthDate?.toIso8601String().split('T')[0],
        'senha': guardian.password,
        'fotoUrl': guardian.photoUrl,
      });
    } catch (e) {
      return {'success': false, 'message': 'Erro ao cadastrar responsável: $e'};
    }
  }

  /// Cadastro completo (endereço + responsável)
  static Future<Map<String, dynamic>> createComplete({
    required Endereco address,
    required Responsavel guardian,
  }) async {
    try {
      return await ApiClient.post('/api/responsavel/completo', {
        // Dados do endereço
        'cidade': address.city,
        'bairro': address.neighborhood,
        'rua': address.street,
        'numero': address.number,
        'complemento': address.complement,
        'cep': address.zipCode,
        // Dados do responsável
        'cpf': guardian.cpf,
        'nome': guardian.name,
        'email': guardian.email,
        'telefone': guardian.phone,
        'dataNascimento': guardian.birthDate?.toIso8601String().split('T')[0],
        'senha': guardian.password,
        'fotoUrl': guardian.photoUrl,
      });
    } catch (e) {
      return {'success': false, 'message': 'Erro no cadastro completo: $e'};
    }
  }

  /// Lista todos os responsáveis
  static Future<List<Responsavel>> list() async {
    try {
      final response = await ApiClient.get('/api/responsavel');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Responsavel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Erro ao listar responsáveis: $e');
      return [];
    }
  }

  /// Busca responsável por ID
  static Future<Responsavel?> getById(int id) async {
    try {
      final response = await ApiClient.get('/api/responsavel/$id');

      if (response['success'] == true) {
        return Responsavel.fromJson(response['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('Erro ao buscar responsável: $e');
      return null;
    }
  }
}

