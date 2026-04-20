import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'onboarding.dart';
import 'perfil_cuidador_page.dart';
import 'tela_editar_perfil_cuidador.dart';
import 'tela_termos_condicoes.dart';

class TelaConfiguracoesCuidador extends StatelessWidget {
  static const route = '/configuracoes-cuidador';

  const TelaConfiguracoesCuidador({super.key});

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color fundo = Color(0xFFF6F4F8);

  Future<void> _logout(BuildContext context) async {
    try {
      ServicoApi.clearToken();
      await ServicoAutenticacao.clearLoginData();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao sair da conta: $e')),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _logout(context);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Widget _itemConfig({
    required BuildContext context,
    required IconData icon,
    required String titulo,
    String? subtitulo,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? roxo,
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor ?? roxo,
        ),
      ),
      subtitle: subtitulo != null ? Text(subtitulo) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _itemConfig(
            context: context,
            icon: Icons.person_outline,
            titulo: 'Ver perfil',
            subtitulo: 'Visualize suas informações cadastradas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerfilCuidadorPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _itemConfig(
            context: context,
            icon: Icons.edit_outlined,
            titulo: 'Editar perfil',
            subtitulo: 'Atualize seus dados pessoais',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TelaEditarPerfilCuidador(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _itemConfig(
            context: context,
            icon: Icons.description_outlined,
            titulo: 'Termos e condições',
            subtitulo: 'Leia os termos de uso do aplicativo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TelaTermosCondicoes(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _itemConfig(
            context: context,
            icon: Icons.logout,
            titulo: 'Sair da conta',
            subtitulo: 'Encerrar sessão neste dispositivo',
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }
}