import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/servico_autenticacao.dart';
import 'tela_login_unificada.dart';
import 'editar_perfil_responsavel_page.dart';
import 'configuracoes_responsavel_page.dart';

class PerfilResponsavelPage extends StatefulWidget {
  const PerfilResponsavelPage({super.key});

  @override
  State<PerfilResponsavelPage> createState() => _PerfilResponsavelPageState();
}

class _PerfilResponsavelPageState extends State<PerfilResponsavelPage> {
  bool isLoading = true;
  Map<String, dynamic>? responsavel;

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiClient.get('/api/responsavel/perfil');

      if (response['success'] == true && response['data'] != null) {
        responsavel = Map<String, dynamic>.from(response['data']);
      } else {
        responsavel = {};
      }
    } catch (e) {
      print('ERRO AO CARREGAR PERFIL RESPONSAVEL: $e');
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

  Future<void> sairDaConta() async {
    await ServicoAutenticacao.clearLoginData();
    ApiClient.clearToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TelaLoginUnificada()),
      (route) => false,
    );
  }

  void confirmarSair() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              sairDaConta();
            },
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void abrirEditarPerfil() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditarPerfilResponsavelPage(),
      ),
    );

    if (result == true) {
      await carregarPerfil();
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  void abrirConfiguracoes() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfiguracoesResponsavelPage(),
      ),
    );

    if (result == true) {
      await carregarPerfil();
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  void abrirTermos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termos e Condições'),
        content: const SingleChildScrollView(
          child: Text(
            '''
TERMOS E CONDIÇÕES DE USO – COGITARE

1. OBJETIVO DA PLATAFORMA
A plataforma Cogitare tem como objetivo conectar responsáveis e cuidadores, facilitando a divulgação e a busca por oportunidades de cuidado.

2. CADASTRO E RESPONSABILIDADE
O usuário declara que todas as informações fornecidas são verdadeiras e atualizadas. O usuário é responsável pela veracidade dos dados inseridos no sistema.

3. USO DA PLATAFORMA
É proibido:
- Utilizar dados falsos ou de terceiros sem autorização
- Praticar qualquer tipo de fraude ou tentativa de golpe
- Utilizar a plataforma para fins ilegais ou indevidos

4. RELAÇÃO ENTRE USUÁRIOS
A Cogitare atua apenas como intermediadora entre responsáveis e cuidadores.
A plataforma não se responsabiliza por:
- Conduta dos usuários
- Acordos realizados fora da plataforma
- Serviços prestados

5. PRIVACIDADE
Os dados dos usuários são utilizados exclusivamente para funcionamento da plataforma, não sendo compartilhados com terceiros sem consentimento, exceto quando exigido por lei.

6. SEGURANÇA
O usuário é responsável por manter a confidencialidade de sua conta e senha.

7. EXCLUSÃO DE CONTA
O usuário pode solicitar a exclusão de sua conta a qualquer momento.
A exclusão poderá resultar na remoção permanente de seus dados.

8. ALTERAÇÕES NOS TERMOS
A Cogitare pode alterar estes termos a qualquer momento, sendo responsabilidade do usuário revisá-los periodicamente.

9. ACEITE
Ao utilizar a plataforma, o usuário declara estar de acordo com todos os termos acima.

---
Cogitare © 2026
            ''',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(titulo),
        subtitle: Text(valor),
      ),
    );
  }

  Widget buildMenuCard({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          titulo,
          style: TextStyle(color: textColor),
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
      radius: 38,
      backgroundColor: const Color(0xFFE8DDF8),
      backgroundImage: temFoto ? NetworkImage(fotoUrl) : null,
      child: !temFoto
          ? const Icon(
              Icons.person,
              size: 38,
              color: Color(0xFF6A4C93),
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

    final dataNascimento = textoSeguro(
      responsavel?['DataNascimento'] ?? responsavel?['dataNascimento'],
    );

    final fotoUrl = fotoSegura(
      responsavel?['FotoUrl'] ?? responsavel?['fotoUrl'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarPerfil,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        buildAvatar(fotoUrl),
                        const SizedBox(height: 12),
                        Text(
                          nome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          textAlign: TextAlign.center,
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
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildMenuCard(
                    icon: Icons.edit_outlined,
                    titulo: 'Editar perfil',
                    subtitulo: 'Atualize seus dados pessoais',
                    onTap: abrirEditarPerfil,
                  ),
                  buildMenuCard(
                    icon: Icons.settings_outlined,
                    titulo: 'Configurações',
                    subtitulo: 'Perfil, termos, sair e apagar conta',
                    onTap: abrirConfiguracoes,
                  ),
                  buildMenuCard(
                    icon: Icons.description_outlined,
                    titulo: 'Termos e condições',
                    subtitulo: 'Leia os termos de uso da plataforma',
                    onTap: abrirTermos,
                  ),
                  buildMenuCard(
                    icon: Icons.logout,
                    titulo: 'Sair da conta',
                    subtitulo: 'Encerrar sessão neste dispositivo',
                    onTap: confirmarSair,
                    iconColor: Colors.orange,
                  ),
                ],
              ),
            ),
    );
  }
}