import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'tela_editar_perfil_cuidador.dart';
import 'tela_configuracoes_cuidador.dart';

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
  String _planoAtual = 'Basico';

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
      final cuidadorId = await SessionService.getCuidadorId();

      if (cuidadorId == null) {
        setState(() {
          _errorMessage = 'Não foi possível identificar o cuidador logado.';
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

        if (responsePlano['success'] == true && responsePlano['data'] != null) {
          _planoAtual =
              (responsePlano['data']['PlanoAtual'] ?? 'Basico').toString();
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _irParaEditarPerfil() async {
    final resultado = await Navigator.pushNamed(
      context,
      TelaEditarPerfilCuidador.route,
    );

    if (resultado == true) {
      await _carregarDados();
    }
  }

  Future<void> _irParaConfiguracoes() async {
    await Navigator.pushNamed(
      context,
      TelaConfiguracoesCuidador.route,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF35064E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
   final nome = _textoSeguro(_cuidador?['nome'], fallback: 'Cuidador');
final email = _textoSeguro(_cuidador?['email']);
final telefone = _textoSeguro(_cuidador?['telefone']);
final cpf = _textoSeguro(_cuidador?['cpf']);
final cidade = _textoSeguro(_cuidador?['cidade']);
final valorHora = _textoSeguro(_cuidador?['valorHora'], fallback: 'A definir');
final biografia = _textoSeguro(
  _cuidador?['biografia'],
  fallback: 'Você ainda não cadastrou uma biografia.',
);
final dataNascimento = _formatarData(_cuidador?['dataNascimento']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: const Color(0xFF35064E),
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
                          color: const Color(0xFF35064E),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white24,
                              child: Icon(
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
                                    ? Colors.white
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white30,
                                ),
                              ),
                              child: Text(
                                _planoAtual.toLowerCase() == 'premium'
                                    ? 'Plano Premium'
                                    : 'Plano Básico',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: _planoAtual.toLowerCase() == 'premium'
                                      ? const Color(0xFF35064E)
                                      : Colors.white,
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
                                      foregroundColor: const Color(0xFF35064E),
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          biografia,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
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