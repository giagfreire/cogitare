import '../models/cuidador_proximo.dart';
import '../models/responsavel.dart';
import '../services/servico_autenticacao.dart';
import '../services/api_contrato.dart';
import '../services/api_cuidadores_proximos.dart';

/// Controller responsável pela lógica de negócio do Dashboard do Responsável
class DashboardResponsavelController {
  /// Carrega o nome do usuário logado
  static Future<String> loadUserName() async {
    try {
      final userData = await ServicoAutenticacao.getUserData();

      if (userData != null) {
        // Tentar diferentes possíveis nomes de campo
        final nome = userData['nome'] ?? userData['Nome'] ?? userData['name'];

        if (nome != null && nome.toString().isNotEmpty) {
          return nome.toString();
        }
      }
      return 'Usuário'; // Valor padrão
    } catch (e) {
      print('Erro ao carregar nome do usuário: $e');
      return 'Usuário';
    }
  }

  /// Carrega os dados do dashboard (contrato ativo e sugestões de cuidadores)
  static Future<Map<String, dynamic>> loadDashboardData(
      Responsavel responsavel) async {
    try {
      // Carregar contrato ativo
      final contract = await ApiContrato.getActive(responsavel.id ?? 1);

      // Se não tem contrato ativo, carregar sugestões de cuidadores
      List<CuidadorProximo> suggestions = [];
      if (contract == null) {
        suggestions = await ApiCuidadoresProximos.getNearby(
          maxDistanceKm: 50.0,
          limit: 3,
        );
      }

      return {
        'activeContract': contract,
        'suggestedCaregivers': suggestions,
      };
    } catch (e) {
      print('Erro ao carregar dados do dashboard: $e');
      rethrow;
    }
  }

  /// Obtém o responsável logado (mock por enquanto, deve vir do estado global)
  static Responsavel getCurrentResponsavel() {
    return Responsavel(
      id: 1,
      addressId: 1,
      cpf: '123.456.789-00',
      name: 'João Maria',
      email: 'joao@email.com',
      phone: '(11) 99999-9999',
      birthDate: DateTime(1980, 1, 1),
      photoUrl: null,
    );
  }

  /// Executa o processo de logout
  static Future<void> performLogout() async {
    await ServicoAutenticacao.clearLoginData();
  }
}
