import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'tela_configuracoes_cuidador.dart';
import 'tela_editar_perfil_cuidador.dart';

class PerfilCuidadorPage extends StatefulWidget {
  static const route = '/perfil-cuidador';

  const PerfilCuidadorPage({super.key});

  @override
  State<PerfilCuidadorPage> createState() => _PerfilCuidadorPageState();
}

class _PerfilCuidadorPageState extends State<PerfilCuidadorPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _cuidador;
  String _planoAtual = 'Básico';

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  String _textoSeguro(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Não informado';

    final texto = data.toString();
    if (texto.length >= 10) {
      final partes = texto.substring(0, 10).split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    }

    return texto;
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await ServicoAutenticacao.getToken();
      final userData = await ServicoAutenticacao.getUserData();
      final userType = await ServicoAutenticacao.getUserType();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      if (userType != 'cuidador' || userData == null) {
        setState(() {
          _errorMessage = 'Não foi possível identificar o cuidador logado.';
          _isLoading = false;
        });
        return;
      }

      final dynamic cuidadorIdDinamico =
          userData['IdCuidador'] ??
          userData['idCuidador'] ??
          userData['cuidadorId'] ??
          userData['id'] ??
          userData['Id'];

      final int? cuidadorId = _parseInt(cuidadorIdDinamico);

      if (cuidadorId == null) {
        setState(() {
          _errorMessage = 'ID do cuidador não encontrado.';
          _isLoading = false;
        });
        return;
      }

      final responseCuidador = await ServicoApi.get('/api/cuidador/$cuidadorId');

      if (responseCuidador['success'] == true &&
          responseCuidador['data'] != null) {
        _cuidador = Map<String, dynamic>.from(responseCuidador['data']);
      } else {
        _errorMessage =
            responseCuidador['message'] ?? 'Erro ao carregar perfil.';
      }

      try {
        final responsePlano =
            await ServicoApi.get('/api/cuidador/$cuidadorId/plano');

        if (responsePlano['success'] == true &&
            responsePlano['data'] != null) {
          _planoAtual =
              (responsePlano['data']['PlanoAtual'] ?? 'Básico').toString();
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar perfil: $e';
        _isLoading = false;
      });
    }
  }

  int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  Future<void> _irParaEditarPerfil() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaEditarPerfilCuidador(),
      ),
    );

    if (resultado == true) {
      await _carregarDados();
    }
  }

  Future<void> _irParaConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaConfiguracoesCuidador(),
      ),
    );

    await _carregarDados();
  }

  Widget _infoTile({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roxo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: roxo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: roxo.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: roxo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _textoSeguro(
      _cuidador?['Nome'] ?? _cuidador?['nome'],
      fallback: 'Cuidador',
    );
    final email = _textoSeguro(_cuidador?['Email'] ?? _cuidador?['email']);
    final telefone = _textoSeguro(
      _cuidador?['Telefone'] ?? _cuidador?['telefone'],
    );
    final cpf = _textoSeguro(_cuidador?['CPF'] ?? _cuidador?['cpf']);
    final cidade = _textoSeguro(_cuidador?['Cidade'] ?? _cuidador?['cidade']);
    final valorHora = _textoSeguro(
      _cuidador?['ValorHora'] ?? _cuidador?['valorHora'],
      fallback: 'A definir',
    );
    final biografia = _textoSeguro(
      _cuidador?['Biografia'] ?? _cuidador?['biografia'],
      fallback: 'Você ainda não cadastrou uma biografia.',
    );
    final dataNascimento = _formatarData(
      _cuidador?['DataNascimento'] ?? _cuidador?['dataNascimento'],
    );

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 52,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _carregarDados,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [roxo, rosa],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white24,
                              child: (_cuidador?['fotoUrl'] != null &&
                                      _cuidador!['fotoUrl']
                                          .toString()
                                          .isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        _cuidador!['fotoUrl'].toString(),
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.person,
                                          size: 42,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 42,
                                      color: Colors.white,
                                    ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              nome,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _planoAtual.toLowerCase() == 'premium'
                                    ? verde
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _planoAtual.toLowerCase() == 'premium'
                                    ? 'Plano Premium'
                                    : 'Plano Básico',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color:
                                      _planoAtual.toLowerCase() == 'premium'
                                          ? Colors.black
                                          : roxo,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _irParaEditarPerfil,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white54,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _irParaConfiguracoes,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: roxo,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.settings_outlined),
                                    label: const Text('Configurações'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Informações pessoais',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: roxo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoTile(
                        icon: Icons.phone_outlined,
                        titulo: 'Telefone',
                        valor: telefone,
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        icon: Icons.badge_outlined,
                        titulo: 'CPF',
                        valor: cpf,
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        icon: Icons.cake_outlined,
                        titulo: 'Data de nascimento',
                        valor: dataNascimento,
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        icon: Icons.location_on_outlined,
                        titulo: 'Cidade',
                        valor: cidade,
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        icon: Icons.attach_money_outlined,
                        titulo: 'Valor por hora',
                        valor: valorHora,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Sobre mim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: roxo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: roxo.withOpacity(0.08)),
                        ),
                        child: Text(
                          biografia,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: roxo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}