import 'package:flutter/material.dart';

class TelaDashboardResponsavel extends StatefulWidget {
  static const route = '/dashboard-responsavel';

  const TelaDashboardResponsavel({super.key});

  @override
  State<TelaDashboardResponsavel> createState() =>
      _TelaDashboardResponsavelState();
}

class _TelaDashboardResponsavelState extends State<TelaDashboardResponsavel> {
  int _currentIndex = 0;

  // Dados temporários para deixar a tela funcionando já
  String _userName = 'Responsável';
  bool _possuiNecessidade = false;
  String _statusAnuncio = 'Ativo';

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      _buildPerfilPage(),
      _buildConfiguracoesPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8EEF9),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Config.',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 24),
          Text(
            'Olá, $_userName 👋',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gerencie aqui sua necessidade de cuidado de forma simples e rápida.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 24),

          // Card principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sua necessidade',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _possuiNecessidade
                            ? const Color(0xFFE8F7EE)
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _possuiNecessidade
                            ? _statusAnuncio
                            : 'Nenhuma necessidade criada',
                        style: TextStyle(
                          color: _possuiNecessidade
                              ? const Color(0xFF1E8E4D)
                              : const Color(0xFF777777),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _possuiNecessidade
                      ? 'Sua necessidade está publicada e visível para os cuidadores.'
                      : 'Você ainda não criou uma necessidade. Crie agora para encontrar cuidadores.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _abrirFormularioNecessidade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28323C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _possuiNecessidade
                          ? 'Editar necessidade'
                          : 'Criar necessidade',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _possuiNecessidade ? _visualizarAnuncio : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF28323C),
                      side: const BorderSide(color: Color(0xFF28323C)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Visualizar anúncio',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Acesso rápido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.assignment_outlined,
                  title: 'Minha necessidade',
                  subtitle: _possuiNecessidade ? 'Editar publicação' : 'Criar agora',
                  onTap: _abrirFormularioNecessidade,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.remove_red_eye_outlined,
                  title: 'Visualizar',
                  subtitle: 'Ver como aparece',
                  onTap: _visualizarAnuncio,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.phone_outlined,
                  title: 'Suporte',
                  subtitle: 'Falar com a equipe',
                  onTap: () {
                    _showInfoSnackBar('Suporte em desenvolvimento.');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.info_outline,
                  title: 'Dicas',
                  subtitle: 'Como funciona o app',
                  onTap: () {
                    _showInfoSnackBar('Área de dicas em desenvolvimento.');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como funciona?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Crie sua necessidade\n'
                  '2. Publique no app\n'
                  '3. Cuidadores poderão visualizar seu anúncio\n'
                  '4. Quando um cuidador liberar seu contato, ele falará com você fora do app',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF5E6670),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perfil',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 15,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFEAEAEA),
                  child: Icon(
                    Icons.person,
                    size: 34,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'responsavel@email.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoTile(Icons.phone_outlined, 'Telefone', '(11) 99999-9999'),
                _buildInfoTile(Icons.location_on_outlined, 'Cidade', 'São Caetano do Sul'),
                _buildInfoTile(Icons.badge_outlined, 'Tipo de conta', 'Responsável'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showInfoSnackBar('Edição de perfil em desenvolvimento.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28323C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Editar perfil',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracoesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingsCard(
            icon: Icons.lock_outline,
            title: 'Alterar senha',
            onTap: () {
              _showInfoSnackBar('Alteração de senha em desenvolvimento.');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            icon: Icons.description_outlined,
            title: 'Termos de uso',
            onTap: () {
              _showInfoSnackBar('Termos de uso em desenvolvimento.');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de privacidade',
            onTap: () {
              _showInfoSnackBar('Política de privacidade em desenvolvimento.');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            icon: Icons.headset_mic_outlined,
            title: 'Suporte',
            onTap: () {
              _showInfoSnackBar('Suporte em desenvolvimento.');
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            icon: Icons.logout,
            title: 'Sair da conta',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: _confirmarLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        SizedBox(
          height: 38,
          child: Image.asset(
            'assets/images/logo_cogitare_horizontal.png',
            fit: BoxFit.contain,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: () {
              _showInfoSnackBar('Notificações em desenvolvimento.');
            },
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF28323C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF28323C), size: 24),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF777777),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF28323C),
    Color textColor = const Color(0xFF1E1E1E),
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF28323C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirFormularioNecessidade() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final tituloController = TextEditingController();
        final descricaoController = TextEditingController();
        final cidadeController = TextEditingController();
        final bairroController = TextEditingController();
        final horarioController = TextEditingController();
        final valorController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Necessidade de cuidado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _buildTextField(tituloController, 'Título'),
                const SizedBox(height: 12),
                _buildTextField(descricaoController, 'Descrição'),
                const SizedBox(height: 12),
                _buildTextField(cidadeController, 'Cidade'),
                const SizedBox(height: 12),
                _buildTextField(bairroController, 'Bairro'),
                const SizedBox(height: 12),
                _buildTextField(horarioController, 'Horário'),
                const SizedBox(height: 12),
                _buildTextField(valorController, 'Faixa de valor'),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _possuiNecessidade = true;
                        _statusAnuncio = 'Ativo';
                      });

                      Navigator.pop(context);

                      _showInfoSnackBar(
                        'Necessidade salva com sucesso.',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28323C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _possuiNecessidade ? 'Salvar alterações' : 'Publicar necessidade',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _visualizarAnuncio() {
    if (!_possuiNecessidade) {
      _showInfoSnackBar('Crie uma necessidade primeiro.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Visualização do anúncio'),
          content: const Text(
            'Aqui aparecerá a visualização do anúncio do responsável para o cuidador.\n\n'
            'Você pode depois trocar esta janela por uma tela real.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja realmente sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login-unificado',
                  (route) => false,
                );
              },
              child: const Text(
                'Sair',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}