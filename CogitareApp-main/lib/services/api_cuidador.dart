import '../models/cuidador.dart';
import '../models/endereco.dart';
import 'api_client.dart';

/// Serviço de API para Cuidadores
class ApiCuidador {
  /// Cadastro completo do cuidador + endereço
  static Future<Map<String, dynamic>> createComplete({
    required Endereco address,
    required Cuidador caregiver,
  }) async {
    try {
      final response = await ApiClient.post('/api/cuidador/cadastro', {
        'nome': caregiver.name,
        'email': caregiver.email,
        'senha': caregiver.password,
        'telefone': caregiver.phone,
        'cpf': caregiver.cpf,
        'dataNascimento':
            caregiver.birthDate?.toIso8601String().split('T')[0],

        // endereço
        'cidade': address.city,
        'bairro': address.neighborhood,
        'rua': address.street,
        'numero': address.number,
        'complemento': address.complement,
        'cep': address.zipCode,

        // extras do cuidador
        'fumante': caregiver.smokingStatus,
        'temFilhos': caregiver.hasChildren,
        'possuiCnh': caregiver.hasLicense,
        'temCarro': caregiver.hasCar,
        'biografia': caregiver.biography,
        'valorHora': caregiver.hourlyRate,
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Cuidador cadastrado com sucesso',
          'caregiverId': response['data']?['idCuidador'],
          'addressId': response['data']?['idEndereco'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao cadastrar cuidador',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  /// Busca cuidador por ID
  static Future<Cuidador?> getById(int id) async {
    try {
      final response = await ApiClient.get('/api/cuidador/$id');

      if (response['success'] == true) {
        return Cuidador.fromJson(response['data']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Atualiza cuidador
  static Future<Map<String, dynamic>> update(int id, Cuidador caregiver) async {
    try {
      final response = await ApiClient.put('/api/cuidador/$id', {
        'nome': caregiver.name,
        'telefone': caregiver.phone,
        'cpf': caregiver.cpf,
        'dataNascimento':
            caregiver.birthDate?.toIso8601String().split('T')[0],
      });

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Cuidador atualizado com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Erro ao atualizar cuidador',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
}