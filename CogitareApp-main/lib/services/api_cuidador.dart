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

      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao cadastrar cuidador: $e',
      };
    }
  }

  /// Buscar cuidador por ID
  static Future<Map<String, dynamic>> getById(int idCuidador) async {
    try {
      final response = await ApiClient.get('/api/cuidador/$idCuidador');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar cuidador: $e',
      };
    }
  }

  /// Salvar disponibilidade do cuidador
  static Future<Map<String, dynamic>> salvarDisponibilidade({
    required int idCuidador,
    required List<Map<String, dynamic>> disponibilidades,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/cuidador/$idCuidador/disponibilidade',
        {
          'disponibilidades': disponibilidades,
        },
      );

      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao salvar disponibilidade: $e',
      };
    }
  }

  /// Buscar disponibilidade do cuidador
  static Future<Map<String, dynamic>> getDisponibilidade(int idCuidador) async {
    try {
      final response =
          await ApiClient.get('/api/cuidador/$idCuidador/disponibilidade');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar disponibilidade: $e',
      };
    }
  }

  /// Buscar serviços do cuidador
  static Future<Map<String, dynamic>> getServicos() async {
    try {
      final response = await ApiClient.get('/api/cuidador/servicos');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar serviços: $e',
      };
    }
  }

  /// Buscar especialidades do cuidador
  static Future<Map<String, dynamic>> getEspecialidades() async {
    try {
      final response = await ApiClient.get('/api/cuidador/especialidades');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar especialidades: $e',
      };
    }
  }

  /// Buscar vagas abertas
  static Future<List<Map<String, dynamic>>> getVagasAbertas() async {
    try {
      final response = await ApiClient.get('/api/cuidador/vagas-abertas');

      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Aceitar vaga
  static Future<Map<String, dynamic>> aceitarVaga(int idVaga) async {
    try {
      final response =
          await ApiClient.post('/api/cuidador/aceitar-vaga', {'idVaga': idVaga});

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Resposta recebida',
        'data': response['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao aceitar vaga: $e',
      };
    }
  }

  /// Buscar status do plano do cuidador logado
  static Future<Map<String, dynamic>> getStatusPlano() async {
    try {
      final response = await ApiClient.get('/api/cuidador/status-plano');
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar status do plano: $e',
      };
    }
  }

  /// Buscar vagas aceitas pelo cuidador logado
  static Future<List<Map<String, dynamic>>> getMinhasVagasAceitas() async {
    try {
      final response = await ApiClient.get('/api/cuidador/minhas-vagas');

      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}