import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'agenda_cuidador_page.dart';
import 'perfil_cuidador_page.dart';
import 'planos_cuidador_page.dart';
import 'vagas_cuidador_page.dart';

class DashboardCuidador extends StatefulWidget {
  static const route = '/dashboard-cuidador';

  const DashboardCuidador({super.key});

  @override
  State<DashboardCuidador> createState() => _DashboardCuidadorState();
}

class _DashboardCuidadorState extends State<DashboardCuidador> {
  bool _isLoading = true;
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

  Future<void> _carregarDados() async {
    try {
      final token = await ServicoAutenticacao.getToken();
      final userData = await ServicoAutenticacao.getUserData();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      final id = userData?['id'];

      if (id == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await ServicoApi.get('/api/cuidador/$id');
      final plano = await ServicoApi.get('/api/cuidador/$id/plano');

      setState(() {
        _cuidador = response['data'];
        _planoAtual = plano['data']?['PlanoAtual'] ?? 'Básico';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dashboard cuidador: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getSaudacao() {
    final sexo = (_cuidador?['sexo'] ?? '').toString().toLowerCase();

    if (sexo == 'feminino') return 'Bem-vinda';
    if (sexo == 'masculino') return 'Bem-vindo';
    return 'Bem-vindo';
  }

  String getNome() {
    return _cuidador?['nome']?.toString() ??
        _cuidador?['Nome']?.toString() ??
        'Cuidador';
  }

  String valorOuPadrao(dynamic valor, {String padrao = 'Não informado'}) {
    if (valor == null) return padrao;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return padrao;
    return texto;
  }

  String getBiografiaCurta() {
    final bio = valorOuPadrao(
      _cuidador?['biografia'],
      padrao: 'Você ainda não cadastrou uma biografia.',
    );

    if (bio.length <= 120) return bio;
    return '${bio.substring(0, 120)}...';
  }

  int getPerfilCompletoPercentual() {
    int preenchidos = 0;
    int total = 5;

    final cidade = _cuidador?['cidade'];
    final valorHora = _cuidador?['valorHora'];
    final telefone = _cuidador?['telefone'];
    final bio = _cuidador?['biografia'];
    final foto = _cuidador?['fotoUrl'];

    if (cidade != null && cidade.toString().trim().isNotEmpty) preenchidos++;
    if (valorHora != null && valorHora.toString().trim().isNotEmpty) {
      preenchidos++;
    }
    if (telefone != null && telefone.toString().trim().isNotEmpty) {
      preenchidos++;
    }
    if (bio != null && bio.toString().trim().isNotEmpty) preenchidos++;
    if (foto != null && foto.toString().trim().isNotEmpty) preenchidos++;

    return ((preenchidos / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final nome = getNome();

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: roxo,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: Image.asset(
              'assets/images/logo_cogitare.png',
              height: 38,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const Text(
          'Início',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerfilCuidadorPage(),
                ),
              );
              _carregarDados();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: (_cuidador?['fotoUrl'] != null &&
                        _cuidador!['fotoUrl'].toString().isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _cuidador!['fotoUrl'].toString(),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(nome),
                    const SizedBox(height: 22),
                    const Text(
                      'Acesso rápido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: roxo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.08,
                      children: [
                        _buildActionBox(
                          titulo: 'Vagas disponíveis',
                          icon: Icons.work_outline,
                          cor: roxo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VagasCuidadorPage(),
                              ),
                            );
                          },
                        ),
                        _buildActionBox(
                          titulo: 'Agenda',
                          icon: Icons.calendar_month_outlined,
                          cor: rosa,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AgendaCuidadorPage(),
                              ),
                            );
                          },
                        ),
                        _buildActionBox(
                          titulo: 'Meu plano',
                          icon: Icons.workspace_premium_outlined,
                          cor: verde,
                          textoEscuro: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PlanosCuidadorPage(),
                              ),
                            );
                          },
                        ),
                        _buildActionBox(
                          titulo: 'Configurações',
                          icon: Icons.settings_outlined,
                          cor: rosa,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PerfilCuidadorPage(),
                              ),
                            );
                            _carregarDados();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Próximo atendimento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: roxo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNextServiceCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Resumo do perfil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: roxo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildResumoPerfilCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Sobre você',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: roxo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSobreCard(),
                    const SizedBox(height: 24),
                    _buildCompletarPerfilCard(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: rosa,
        unselectedItemColor: roxo.withOpacity(0.55),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AgendaCuidadorPage(),
              ),
            );
          }

          if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PerfilCuidadorPage(),
              ),
            );
            _carregarDados();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Config',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String nome) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF42124C), Color(0xFFFE0472)],
        ),
        boxShadow: [
          BoxShadow(
            color: rosa.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $nome',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${getSaudacao()} de volta!',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _planoAtual.toLowerCase() == 'premium'
                  ? verde
                  : Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _planoAtual,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _planoAtual.toLowerCase() == 'premium'
                    ? Colors.black
                    : roxo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBox({
    required String titulo,
    required IconData icon,
    required Color cor,
    required VoidCallback onTap,
    bool textoEscuro = false,
  }) {
    final textColor = textoEscuro ? Colors.black : Colors.white;

    return Material(
      color: cor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: 30),
              const Spacer(),
              Text(
                titulo,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: textoEscuro
                        ? Colors.black.withOpacity(0.08)
                        : Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: textColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextServiceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: roxo.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: rosa.withOpacity(0.12),
            child: const Icon(Icons.calendar_today, color: roxo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nenhum atendimento agendado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: roxo,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Assim que você aceitar uma vaga ou agendar um serviço, ele vai aparecer aqui.',
                  style: TextStyle(
                    fontSize: 14,
                    color: roxo.withOpacity(0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AgendaCuidadorPage(),
                      ),
                    );
                  },
                  child: const Text('Ver agenda'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoPerfilCard() {
    final percentual = getPerfilCompletoPercentual();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: roxo.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniResumoItem(
                  'Cidade',
                  valorOuPadrao(_cuidador?['cidade']),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniResumoItem(
                  'Valor/hora',
                  valorOuPadrao(_cuidador?['valorHora'], padrao: 'A definir'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniResumoItem(
                  'Plano',
                  _planoAtual,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniResumoItem(
                  'Perfil',
                  '$percentual%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentual / 100,
            minHeight: 8,
            backgroundColor: roxo.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation(rosa),
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PerfilCuidadorPage(),
                  ),
                );
                _carregarDados();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: roxo),
                foregroundColor: roxo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Editar perfil'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniResumoItem(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: roxo.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              color: roxo,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSobreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: roxo.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biografia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: roxo,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            getBiografiaCurta(),
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: roxo.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerfilCuidadorPage(),
                ),
              );
              _carregarDados();
            },
            child: const Text('Ver perfil completo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletarPerfilCard() {
    final percentual = getPerfilCompletoPercentual();

    if (percentual >= 100) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: verde.withOpacity(0.18),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: roxo),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seu perfil está completo. Isso ajuda você a transmitir mais confiança.',
                style: TextStyle(
                  color: roxo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: rosa.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: rosa.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: rosa),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete seu perfil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: roxo,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Perfis mais completos têm mais chances de transmitir confiança e conseguir oportunidades.',
                  style: TextStyle(
                    fontSize: 14,
                    color: roxo.withOpacity(0.78),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PerfilCuidadorPage(),
                      ),
                    );
                    _carregarDados();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rosa,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Completar agora'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}