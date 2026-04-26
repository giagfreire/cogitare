import '../models/cuidador.dart';
import '../models/endereco.dart';
import 'api_client.dart';
import 'servico_autenticacao.dart';

class ApiCuidador {
  static int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  static Future<int?> _getCuidadorIdLogado() async {
    final userData = await ServicoAutenticacao.getUserData();

    return _parseInt(
      userData?['IdCuidador'] ??
          userData?['idCuidador'] ??
          userData?['cuidadorId'] ??
          userData?['id'] ??
          userData?['Id'],
    );
  }

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
        'dataNascimento': caregiver.birthDate?.toIso8601String().split('T')[0],
        'cidade': address.city,
        'bairro': address.neighborhood,
        'rua': address.street,
        'numero': address.number,
        'complemento': address.complement,
        'cep': address.zipCode,
        'fumante': caregiver.smokingStatus,
        'temFilhos': caregiver.hasChildren,
        'possuiCnh': caregiver.hasLicense,
        'temCarro': caregiver.hasCar,
        'biografia': caregiver.biography,
        'fotoUrl': caregiver.photoUrl,
      });

      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao cadastrar cuidador: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getById(int idCuidador) async {
    try {
      final response = await ApiClient.get('/api/cuidador/$idCuidador');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar cuidador: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> salvarDisponibilidade({
    required int idCuidador,
    required List<Map<String, dynamic>> disponibilidades,
  }) async {
    try {
      final response = await ApiClient.post(
        '/api/cuidador/$idCuidador/disponibilidade',
        {'disponibilidade': disponibilidades},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao salvar disponibilidade: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getDisponibilidade(int idCuidador) async {
    try {
      final response =
          await ApiClient.get('/api/cuidador/$idCuidador/disponibilidade');

      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar disponibilidade: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getEspecialidades() async {
    try {
      final response = await ApiClient.get('/api/cuidador/especialidades');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar especialidades: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getServicos() async {
    try {
      final response = await ApiClient.get('/api/cuidador/servicos');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar serviços: $e',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getVagasAbertas() async {
    try {
      final response = await ApiClient.get('/api/cuidador/vagas-abertas');

      if (response['success'] == true && response['data'] is List) {
        final data = response['data'] as List;

        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> aceitarVaga(int idVaga) async {
    try {
      final response = await ApiClient.post(
        '/api/cuidador/aceitar-vaga',
        {'idVaga': idVaga},
      );

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

  static Future<Map<String, dynamic>> getStatusPlano([int? idCuidador]) async {
    try {
      final id = idCuidador ?? await _getCuidadorIdLogado();

      if (id == null) {
        return {
          'success': false,
          'message': 'Não foi possível identificar o cuidador logado.',
          'data': {
            'PlanoAtual': 'Básico',
            'UsosPlano': 0,
            'LimitePlano': 5,
            'Restantes': 5,
            'Destaque': false,
          },
        };
      }

      final response = await ApiClient.get('/api/cuidador/$id/plano');

      if (response['success'] == true && response['data'] is Map) {
        final data = Map<String, dynamic>.from(response['data']);

        final planoAtual =
            (data['PlanoAtual'] ?? data['plano'] ?? 'Básico').toString();

        final usosPlano = _parseInt(data['UsosPlano'] ?? data['usosPlano']) ?? 0;

        final limitePlano =
            _parseInt(data['LimitePlano'] ?? data['limiteContatos']) ??
                (planoAtual.toLowerCase() == 'premium' ? 20 : 5);

        final restantes = limitePlano - usosPlano;

        return {
          'success': true,
          'data': {
            'PlanoAtual': planoAtual,
            'UsosPlano': usosPlano,
            'LimitePlano': limitePlano,
            'Restantes': restantes < 0 ? 0 : restantes,
            'Destaque': planoAtual.toLowerCase() == 'premium',
          },
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Erro ao buscar status do plano.',
        'data': {
          'PlanoAtual': 'Básico',
          'UsosPlano': 0,
          'LimitePlano': 5,
          'Restantes': 5,
          'Destaque': false,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao buscar status do plano: $e',
        'data': {
          'PlanoAtual': 'Básico',
          'UsosPlano': 0,
          'LimitePlano': 5,
          'Restantes': 5,
          'Destaque': false,
        },
      };
    }
  }

  static Future<Map<String, dynamic>> getPlanoStatus([int? idCuidador]) async {
    return getStatusPlano(idCuidador);
  }

static Future<List<Map<String, dynamic>>> getMinhasVagasAceitas() async {
  try {
    final token = await ServicoAutenticacao.getToken();

    if (token != null && token.isNotEmpty) {
      ApiClient.setToken(token);
    }

    final response = await ApiClient.get('/api/cuidador/minhas-vagas');

    print('RESPOSTA MINHAS VAGAS ACEITAS: $response');

    if (response['success'] == true && response['data'] is List) {
      final data = response['data'] as List;

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  } catch (e) {
    print('ERRO MINHAS VAGAS ACEITAS: $e');
    return [];
  }
}}