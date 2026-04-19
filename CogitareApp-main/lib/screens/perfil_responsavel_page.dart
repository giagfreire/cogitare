import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/servico_autenticacao.dart';
import 'tela_login_unificada.dart';

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
    setState(() {
      isLoading = true;
    });

    try {
      final userData = await ServicoAutenticacao.getUserData();

      setState(() {
        responsavel = userData != null ? Map<String, dynamic>.from(userData) : {};
        isLoading = false;
      });
    } catch (e) {
      print('ERRO AO CARREGAR PERFIL RESPONSAVEL: $e');
      setState(() {
        responsavel = {};
        isLoading = false;
      });
    }
  }

  String textoSeguro(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
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

  void abrirEditarPerfil() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximo passo: tela de editar perfil'),
      ),
    );
  }

  void abrirConfiguracoes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximo passo: tela de configurações'),
      ),
    );
  }

  void abrirTermos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termos e Condições'),
        content: const SingleChildScrollView(
          child: Text(
            'Este aplicativo conecta responsáveis e cuidadores para facilitar '
            'o encontro de oportunidades de cuidado. Ao utilizar a plataforma, '
            'o usuário concorda em fornecer informações verdadeiras, utilizar '
            'o sistema de forma ética e respeitar os demais usuários. '
            '\n\n'
            'A plataforma não substitui a verificação individual de documentos, '
            'experiência e referências profissionais. Cada usuário é responsável '
            'pelas informações fornecidas em seu perfil e pelas interações realizadas.'
            '\n\n'
            'Se desejar, depois eu transformo isso em uma tela bonita e completa '
            'de termos e política de privacidade.',
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

  void confirmarApagarConta() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar conta'),
        content: const Text(
          'Essa ação é permanente. Depois eu posso ligar esse botão ao banco '
          'de dados para apagar a conta de verdade. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Próximo passo: apagar conta de verdade'),
                ),
              );
            },
            child: const Text(
              'Apagar',
              style: TextStyle(color: Colors.red),
            ),
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
                        const CircleAvatar(
                          radius: 38,
                          child: Icon(Icons.person, size: 38),
                        ),
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
                    subtitulo: 'Preferências e ajustes da conta',
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
                  buildMenuCard(
                    icon: Icons.delete_outline,
                    titulo: 'Apagar conta',
                    subtitulo: 'Excluir sua conta permanentemente',
                    onTap: confirmarApagarConta,
                    iconColor: Colors.red,
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),
    );
  }
}