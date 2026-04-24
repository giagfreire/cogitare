import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/servico_autenticacao.dart';
import 'editar_perfil_responsavel_page.dart';
import 'tela_configuracoes.dart';

class PerfilResponsavelPage extends StatefulWidget {
  const PerfilResponsavelPage({super.key});

  @override
  State<PerfilResponsavelPage> createState() => _PerfilResponsavelPageState();
}

class _PerfilResponsavelPageState extends State<PerfilResponsavelPage> {
  bool isLoading = true;
  Map<String, dynamic>? responsavel;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    setState(() => isLoading = true);

    try {
      final token = await ServicoAutenticacao.getToken();

      if (token != null && token.isNotEmpty) {
        ApiClient.setToken(token);
      }

      final response = await ApiClient.get('/api/responsavel/perfil');

      if (response['success'] == true && response['data'] != null) {
        responsavel = Map<String, dynamic>.from(response['data']);
      } else {
        responsavel = {};
      }
    } catch (e) {
      debugPrint('ERRO AO CARREGAR PERFIL RESPONSAVEL: $e');
      responsavel = {};
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  String textoSeguro(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String fotoSegura(dynamic valor) {
    if (valor == null) return '';

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return '';
    }

    if (!texto.startsWith('http://') && !texto.startsWith('https://')) {
      return '';
    }

    return texto;
  }

  String formatarData(dynamic data) {
    if (data == null) return 'Não informado';

    final texto = data.toString();

    if (texto.length >= 10 && texto.contains('-')) {
      final partes = texto.substring(0, 10).split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    }

    return textoSeguro(data);
  }

  Future<void> abrirEditarPerfil() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditarPerfilResponsavelPage(),
      ),
    );

    if (result == true) {
      await carregarPerfil();
    }
  }

  Future<void> abrirConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaConfiguracoes(),
      ),
    );

    await carregarPerfil();
  }

  Widget buildInfoCard({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roxo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
                    color: roxo.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    color: roxo,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuButton({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color color = roxo,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roxo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget buildAvatar(String fotoUrl) {
    final temFoto = fotoUrl.isNotEmpty;

    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white24,
      backgroundImage: temFoto ? NetworkImage(fotoUrl) : null,
      child: !temFoto
          ? const Icon(
              Icons.person,
              size: 42,
              color: Colors.white,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = textoSeguro(
      responsavel?['Nome'] ?? responsavel?['nome'],
      fallback: 'Responsável',
    );

    final email = textoSeguro(
      responsavel?['Email'] ?? responsavel?['email'],
    );

    final telefone = textoSeguro(
      responsavel?['Telefone'] ?? responsavel?['telefone'],
    );

    final cpf = textoSeguro(
      responsavel?['Cpf'] ?? responsavel?['cpf'],
    );

    final dataNascimento = formatarData(
      responsavel?['DataNascimento'] ?? responsavel?['dataNascimento'],
    );

    final fotoUrl = fotoSegura(
      responsavel?['FotoUrl'] ?? responsavel?['fotoUrl'],
    );

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: abrirConfiguracoes,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarPerfil,
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
                        buildAvatar(fotoUrl),
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
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: abrirEditarPerfil,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar perfil'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Informações da conta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: roxo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildInfoCard(
                    icon: Icons.badge_outlined,
                    titulo: 'CPF',
                    valor: cpf,
                  ),
                  buildInfoCard(
                    icon: Icons.phone_outlined,
                    titulo: 'Telefone',
                    valor: telefone,
                  ),
                  buildInfoCard(
                    icon: Icons.calendar_today_outlined,
                    titulo: 'Data de nascimento',
                    valor: dataNascimento,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Opções',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: roxo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildMenuButton(
                    icon: Icons.settings_outlined,
                    titulo: 'Configurações',
                    subtitulo: 'Termos, suporte, sobre o app e segurança',
                    onTap: abrirConfiguracoes,
                  ),
                ],
              ),
            ),
    );
  }
}