import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'onboarding.dart';
import 'tela_termos_condicoes.dart';



class TelaConfiguracoes extends StatelessWidget {
  static const route = '/configuracoes-cuidador';

 const TelaConfiguracoes({super.key});

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
            style: ElevatedButton.styleFrom(
              backgroundColor: rosa,
              foregroundColor: Colors.white,
            ),
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

  void _showSuporteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Suporte / Ajuda'),
        content: const Text(
          'Precisa de ajuda?\n\n'
          'Entre em contato com o suporte do Cogitare pelo e-mail:\n'
          'suporte@cogitare.com.br\n\n'
          'Em breve adicionaremos uma central de ajuda com perguntas frequentes.',
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

  void _showSobreDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Cogitare',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/images/logo_cogitare.png',
        height: 48,
      ),
      children: const [
        Text(
          'O Cogitare conecta responsáveis por idosos a cuidadores, '
          'facilitando a busca por serviços, oportunidades e organização do cuidado.',
        ),
        SizedBox(height: 12),
        Text(
          'Projeto acadêmico desenvolvido para fins de protótipo e apresentação.',
        ),
      ],
    );
  }

  void _showExcluirContaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Por segurança, a exclusão de conta será confirmada por um código enviado ao e-mail cadastrado.\n\n'
          'Essa funcionalidade será ativada na próxima etapa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Próxima etapa: implementar envio de código por e-mail.',
                  ),
                ),
              );
            },
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Widget _itemConfig({
    required IconData icon,
    required String titulo,
    String? subtitulo,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          backgroundColor: (iconColor ?? roxo).withOpacity(0.12),
          child: Icon(icon, color: iconColor ?? roxo),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textColor ?? roxo,
          ),
        ),
        subtitle: subtitulo != null ? Text(subtitulo) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
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
        padding: const EdgeInsets.all(16),
        children: [
          _itemConfig(
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
          _itemConfig(
            icon: Icons.help_outline,
            titulo: 'Suporte / Ajuda',
            subtitulo: 'FAQ, dúvidas e contato com suporte',
            onTap: () => _showSuporteDialog(context),
          ),
          _itemConfig(
            icon: Icons.info_outline,
            titulo: 'Sobre o app',
            subtitulo: 'Versão, créditos e licenças',
            onTap: () => _showSobreDialog(context),
          ),
          _itemConfig(
            icon: Icons.delete_outline,
            titulo: 'Excluir conta',
            subtitulo: 'Solicitar exclusão com confirmação por e-mail',
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () => _showExcluirContaDialog(context),
          ),
          _itemConfig(
            icon: Icons.logout,
            titulo: 'Sair da conta',
            subtitulo: 'Encerrar sessão neste dispositivo',
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }
}