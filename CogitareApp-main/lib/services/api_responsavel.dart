import '../models/responsavel.dart';
import '../models/endereco.dart';
import 'api_client.dart';

class ApiResponsavel {
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
        'dataNascimento': guardian.birthDate?.toIso8601String().split('T')[0],
        'senha': guardian.password,
        'fotoUrl': guardian.photoUrl,
      });
    } catch (e) {
      return {'success': false, 'message': 'Erro no cadastro completo: $e'};
    }
  }

  static Future<List<Responsavel>> list() async {
    try {
      final response = await ApiClient.get('/api/responsavel');

      if (response['success'] == true) {
        final List data = response['data'];
        return data.map((json) => Responsavel.fromJson(json)).toList();
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Responsavel?> getById(int id) async {
    try {
      final response = await ApiClient.get('/api/responsavel/$id');

      if (response['success'] == true) {
        return Responsavel.fromJson(response['data']);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPerfil() async {
    try {
      final response = await ApiClient.get('/api/responsavel/perfil');

      if (response['success'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

static Future<Map<String, dynamic>> atualizarPerfil({
  required String nome,
  required String email,
  required String telefone,
  required String dataNascimento,
  String? fotoUrl,
  String? cep,
  String? cidade,
  String? bairro,
  String? rua,
  String? numero,
  String? estado, // 👈 NOVO
  String? complemento, // 👈 NOVO
  String? contatoWhatsapp,
  String? contatoTelefone,
  String? contatoEmail,
  String? preferenciaContato,
}) async {
  try {
    final response = await ApiClient.put('/api/responsavel/perfil', {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'dataNascimento': dataNascimento,
      'fotoUrl': fotoUrl,
      'cep': cep,
      'cidade': cidade,
      'bairro': bairro,
      'rua': rua,
      'numero': numero,
      'estado': estado, // 👈 NOVO
      'complemento': complemento, // 👈 NOVO
      'contatoWhatsapp': contatoWhatsapp,
      'contatoTelefone': contatoTelefone,
      'contatoEmail': contatoEmail,
      'preferenciaContato': preferenciaContato,
    });

    return {
      'success': response['success'] == true,
      'message': response['message'] ?? 'Perfil atualizado',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'Erro ao atualizar perfil: $e',
    };
  }
}

  static Future<Map<String, dynamic>> apagarConta() async {
    try {
      final response = await ApiClient.delete('/api/responsavel/perfil');

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Conta apagada com sucesso',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao apagar conta: $e'};
    }
  }

  static Future<Map<String, dynamic>> criarVaga({
    required int idIdoso,
    required String titulo,
    required String cep,
    required String cidade,
    required String bairro,
    required String rua,
    required String dataServico,
    required String horaInicio,
    required String horaFim,
  }) async {
    try {
      final response = await ApiClient.post('/api/responsavel/vagas', {
        'idIdoso': idIdoso,
        'titulo': titulo,
        'cep': cep,
        'cidade': cidade,
        'bairro': bairro,
        'rua': rua,
        'dataServico': dataServico,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
      });

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Resposta recebida',
        'data': response['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao criar vaga: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getMinhasVagas() async {
    try {
      final response = await ApiClient.get('/api/responsavel/minhas-vagas');

      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> editarVaga({
    required int idVaga,
    required String titulo,
    required String cep,
    required String cidade,
    required String bairro,
    required String rua,
    required String dataServico,
    required String horaInicio,
    required String horaFim,
  }) async {
    try {
      final response = await ApiClient.put('/api/responsavel/vaga/$idVaga', {
        'titulo': titulo,
        'cep': cep,
        'cidade': cidade,
        'bairro': bairro,
        'rua': rua,
        'dataServico': dataServico,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
      });

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Vaga atualizada com sucesso',
        'data': response['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao editar vaga: $e'};
    }
  }

  static Future<Map<String, dynamic>> alterarStatusVaga({
    required int idVaga,
    required String status,
  }) async {
    try {
      final response =
          await ApiClient.put('/api/responsavel/vaga/$idVaga/status', {
        'status': status,
      });

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Status atualizado',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao alterar status: $e'};
    }
  }

  static Future<Map<String, dynamic>> encerrarVaga(int idVaga) {
    return alterarStatusVaga(idVaga: idVaga, status: 'Encerrada');
  }

  static Future<Map<String, dynamic>> reabrirVaga(int idVaga) {
    return alterarStatusVaga(idVaga: idVaga, status: 'Aberta');
  }

  static Future<Map<String, dynamic>> excluirVaga(int idVaga) async {
    try {
      final response = await ApiClient.delete('/api/responsavel/vaga/$idVaga');

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Vaga excluída com sucesso',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao excluir vaga: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getInteressados(int idVaga) async {
    try {
      final response =
          await ApiClient.get('/api/responsavel/vaga/$idVaga/interessados');

      if (response['success'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }

      return [];
    } catch (_) {
      return [];
    }
  }
}