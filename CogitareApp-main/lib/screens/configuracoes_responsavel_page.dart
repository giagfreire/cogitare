import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/servico_autenticacao.dart';
import 'editar_perfil_responsavel_page.dart';
import 'tela_login_unificada.dart';

class ConfiguracoesResponsavelPage extends StatefulWidget {
  const ConfiguracoesResponsavelPage({super.key});

  @override
  State<ConfiguracoesResponsavelPage> createState() =>
      _ConfiguracoesResponsavelPageState();
}

class _ConfiguracoesResponsavelPageState
    extends State<ConfiguracoesResponsavelPage> {
  bool isDeleting = false;

  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    carregarUser();
  }

  Future<void> carregarUser() async {
    final data = await ServicoAutenticacao.getUserData();
    setState(() {
      user = data;
    });
  }

  String textoSeguro(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final t = v.toString().trim();
    if (t.isEmpty || t.toLowerCase() == 'null') return fallback;
    return t;
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
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair da conta?'),
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
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> apagarConta() async {
    setState(() => isDeleting = true);

    try {
      final res = await ApiClient.delete('/api/responsavel/perfil');

      if (res != null && res['success'] == true) {
        await ServicoAutenticacao.clearLoginData();
        ApiClient.clearToken();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TelaLoginUnificada()),
          (_) => false,
        );
      } else {
        throw Exception(res?['message']);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }

    setState(() => isDeleting = false);
  }

  void confirmarApagarConta() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar conta'),
        content: const Text('Essa ação é permanente. Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              apagarConta();
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget item({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = textoSeguro(user?['Nome'] ?? user?['nome'], fallback: 'Usuário');
    final email = textoSeguro(user?['Email'] ?? user?['email']);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 🔥 HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(height: 10),
                    Text(nome,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(email),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text('Conta',
                  style: TextStyle(fontWeight: FontWeight.bold)),

              Card(
                child: Column(
                  children: [
                    item(
                      icon: Icons.edit,
                      title: 'Editar perfil',
                      onTap: () async {
                        final r = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const EditarPerfilResponsavelPage(),
                          ),
                        );
                        if (r == true) Navigator.pop(context, true);
                      },
                    ),
                    const Divider(height: 1),
                    item(
                      icon: Icons.description,
                      title: 'Termos e condições',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text('Sessão',
                  style: TextStyle(fontWeight: FontWeight.bold)),

              Card(
                child: item(
                  icon: Icons.logout,
                  title: 'Sair',
                  onTap: confirmarSair,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 20),

              const Text('Zona de risco',
                  style: TextStyle(fontWeight: FontWeight.bold)),

              Card(
                child: item(
                  icon: Icons.delete,
                  title: 'Apagar conta',
                  onTap: confirmarApagarConta,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          if (isDeleting)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}