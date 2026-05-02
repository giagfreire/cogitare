import '../models/responsavel.dart';
import '../models/endereco.dart';
import 'api_client.dart';
import 'servico_autenticacao.dart';

class ApiResponsavel {
  static Future<void> _prepararToken() async {
    final token = await ServicoAutenticacao.getToken();

    if (token != null && token.isNotEmpty) {
      ApiClient.setToken(token);
    }
  }

  static Future<Map<String, dynamic>> createComplete({
    required Endereco address,
    required Responsavel guardian,
  }) async {
    try {
      await _prepararToken();

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

  static Future<Map<String, dynamic>?> getPerfil() async {
    try {
      await _prepararToken();

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
    String? estado,
    String? complemento,
    String? contatoWhatsapp,
    String? contatoTelefone,
    String? contatoEmail,
    String? preferenciaContato,
  }) async {
    try {
      await _prepararToken();

      final body = {
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
        'estado': estado,
        'complemento': complemento,
        'contatoWhatsapp': contatoWhatsapp,
        'contatoTelefone': contatoTelefone,
        'contatoEmail': contatoEmail,
        'preferenciaContato': preferenciaContato,
      };

      body.removeWhere((key, value) => value == null);

      final response = await ApiClient.put('/api/responsavel/perfil', body);

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Perfil atualizado',
        'data': response['data'],
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
      await _prepararToken();

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
    String? descricao,
    String? whatsappContato,
  }) async {
    try {
      await _prepararToken();

      final response = await ApiClient.post('/api/responsavel/vagas', {
        'idIdoso': idIdoso,
        'titulo': titulo,
        'descricao': descricao ?? 'Sem descrição',
        'cep': cep,
        'cidade': cidade,
        'bairro': bairro,
        'rua': rua,
        'whatsappContato': whatsappContato,
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
      await _prepararToken();

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
    String? descricao,
    String? whatsappContato,
  }) async {
    try {
      await _prepararToken();

      final response = await ApiClient.put('/api/responsavel/vaga/$idVaga', {
        'titulo': titulo,
        'descricao': descricao ?? 'Sem descrição',
        'cep': cep,
        'cidade': cidade,
        'bairro': bairro,
        'rua': rua,
        'whatsappContato': whatsappContato,
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
      await _prepararToken();

      final response = await ApiClient.put(
        '/api/responsavel/vaga/$idVaga/status',
        {'status': status},
      );

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Status atualizado',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao alterar status: $e'};
    }
  }

  static Future<Map<String, dynamic>> interromperVaga(int idVaga) {
    return alterarStatusVaga(idVaga: idVaga, status: 'Interrompida');
  }

  static Future<Map<String, dynamic>> reabrirVaga(int idVaga) {
    return alterarStatusVaga(idVaga: idVaga, status: 'Aberta');
  }

  static Future<Map<String, dynamic>> excluirVaga(int idVaga) async {
    try {
      await _prepararToken();

      final response = await ApiClient.delete('/api/responsavel/vaga/$idVaga');

      return {
        'success': response['success'] == true,
        'message': response['message'] ?? 'Vaga excluída com sucesso',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao excluir vaga: $e'};
    }
  }
}