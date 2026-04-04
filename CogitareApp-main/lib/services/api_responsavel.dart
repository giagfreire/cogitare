import '../models/responsavel.dart';
import '../models/endereco.dart';
import 'api_client.dart';

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
      return {
        'success': false,
        'message': 'Erro ao cadastrar endereço: $e',
      };
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
        'dataNascimento':
            guardian.birthDate?.toIso8601String().split('T')[0],
        'senha': guardian.password,
        'fotoUrl': guardian.photoUrl,
      });
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao cadastrar responsável: $e',
      };
    }
  }

  /// Cadastro completo
  static Future<Map<String, dynamic>> createComplete({
    required Endereco address,
    required Responsavel guardian,
  }) async {
    try {
      return await ApiClient.post('/api/responsavel/completo', {
        'cidade': address.city,
        'bairro': address.neighborhood,
        'rua': address.street,
        'numero': address.number,
        'complemento': address.complement,
        'cep': address.zipCode,
        'cpf': guardian.cpf,
        'nome': guardian.name,
        'email': guardian.email,
        'telefone': guardian.phone,
        'dataNascimento':
            guardian.birthDate?.toIso8601String().split('T')[0],
        'senha': guardian.password,
        'fotoUrl': guardian.photoUrl,
      });
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro no cadastro completo: $e',
      };
    }
  }

  /// Lista todos
  static Future<List<Responsavel>> list() async {
    try {
      final response = await ApiClient.get('/api/responsavel');

      if (response['success'] == true) {
        final List data = response['data'];
        return data.map((json) => Responsavel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Busca por ID
  static Future<Responsavel?> getById(int id) async {
    try {
      final response = await ApiClient.get('/api/responsavel/$id');

      if (response['success'] == true) {
        return Responsavel.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Criar vaga
  static Future<Map<String, dynamic>> criarVaga({
    required String titulo,
    required String descricao,
    required String cidade,
    required String dataServico,
    required String horaInicio,
    required String horaFim,
    required double valor,
  }) async {
    try {
      final response = await ApiClient.post('/api/responsavel/vagas', {
        'titulo': titulo,
        'descricao': descricao,
        'cidade': cidade,
        'dataServico': dataServico,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'valor': valor,
      });

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Resposta recebida',
        'data': response['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao criar vaga: $e',
      };
    }
  }

  /// Minhas vagas do responsável logado
  static Future<List<Map<String, dynamic>>> getMinhasVagas() async {
    try {
      final response = await ApiClient.get('/api/responsavel/vagas/minhas');

      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Editar vaga
  static Future<Map<String, dynamic>> editarVaga({
    required int idVaga,
    required String titulo,
    required String descricao,
    required String cidade,
    required String dataServico,
    required String horaInicio,
    required String horaFim,
    required double valor,
  }) async {
    try {
      final response = await ApiClient.put('/api/responsavel/vagas/$idVaga', {
        'titulo': titulo,
        'descricao': descricao,
        'cidade': cidade,
        'dataServico': dataServico,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'valor': valor,
      });

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Vaga atualizada com sucesso',
        'data': response['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao editar vaga: $e',
      };
    }
  }

  /// Encerrar vaga
  static Future<Map<String, dynamic>> encerrarVaga(int idVaga) async {
    try {
      final response =
          await ApiClient.put('/api/responsavel/vagas/$idVaga/status', {
        'status': 'Encerrada',
      });

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Vaga encerrada com sucesso',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao encerrar vaga: $e',
      };
    }
  }

  /// Reabrir vaga
  static Future<Map<String, dynamic>> reabrirVaga(int idVaga) async {
    try {
      final response =
          await ApiClient.put('/api/responsavel/vagas/$idVaga/status', {
        'status': 'Aberta',
      });

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Vaga reaberta com sucesso',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao reabrir vaga: $e',
      };
    }
  }

  /// Excluir vaga
  static Future<Map<String, dynamic>> excluirVaga(int idVaga) async {
    try {
      final response = await ApiClient.delete('/api/responsavel/vagas/$idVaga');

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Vaga excluída com sucesso',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao excluir vaga: $e',
      };
    }
  }

  /// Ver interessados
  static Future<List<Map<String, dynamic>>> getInteressados(int idVaga) async {
    try {
      final response =
          await ApiClient.get('/api/responsavel/vagas/$idVaga/interessados');

      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}