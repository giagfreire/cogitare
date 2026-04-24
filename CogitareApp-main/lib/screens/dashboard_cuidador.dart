import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'agenda_cuidador_page.dart';
import 'perfil_cuidador_page.dart';
import 'planos_cuidador_page.dart';
import 'vagas_cuidador_page.dart';
import 'tela_configuracoes.dart';

class DashboardCuidador extends StatefulWidget {
  static const route = '/dashboard-cuidador';

  const DashboardCuidador({super.key});

  @override
  State<DashboardCuidador> createState() => _DashboardCuidadorState();
}

class _DashboardCuidadorState extends State<DashboardCuidador> {
  bool _isLoading = true;
  Map<String, dynamic>? _cuidador;
  List<Map<String, dynamic>> _servicosAceitos = [];

  String _planoAtual = 'Básico';
  int _usosPlano = 0;
  int _limitePlano = 5;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  String valorOuPadrao(dynamic valor, {String padrao = 'Não informado'}) {
    if (valor == null) return padrao;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return padrao;
    return texto;
  }

  String getNome() {
    return _cuidador?['nome']?.toString() ??
        _cuidador?['Nome']?.toString() ??
        'Cuidador';
  }

  String getSaudacao() {
    final sexo = (_cuidador?['sexo'] ?? _cuidador?['Sexo'] ?? '')
        .toString()
        .toLowerCase();

    if (sexo == 'feminino') return 'Bem-vinda';
    if (sexo == 'masculino') return 'Bem-vindo';
    return 'Bem-vindo';
  }

  String getBiografiaCurta() {
    final bio = valorOuPadrao(
      _cuidador?['biografia'] ?? _cuidador?['Biografia'],
      padrao: 'Você ainda não cadastrou uma biografia.',
    );

    if (bio.length <= 120) return bio;
    return '${bio.substring(0, 120)}...';
  }

  ImageProvider? _fotoProvider() {
    final fotoUrl = (_cuidador?['fotoUrl'] ?? _cuidador?['FotoUrl'])
        ?.toString()
        .trim();

    if (fotoUrl == null || fotoUrl.isEmpty || fotoUrl.toLowerCase() == 'null') {
      return null;
    }

    if (fotoUrl.startsWith('data:image')) {
      try {
        final base64String = fotoUrl.split(',').last;
        final Uint8List bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    if (fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://')) {
      return NetworkImage(fotoUrl);
    }

    return null;
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await ServicoAutenticacao.getToken();
      final userData = await ServicoAutenticacao.getUserData();

      if (token != null && token.isNotEmpty) {
        ServicoApi.setToken(token);
      }

      final id = _parseInt(
        userData?['IdCuidador'] ??
            userData?['idCuidador'] ??
            userData?['cuidadorId'] ??
            userData?['id'] ??
            userData?['Id'],
      );

      if (id == null) {
        setState(() => _isLoading = false);
        return;
      }

      final responseCuidador = await ServicoApi.get('/api/cuidador/$id');
      final responsePlano = await ServicoApi.get('/api/cuidador/$id/plano');

      try {
        final responseServicos = await ServicoApi.get('/api/cuidador/minhas-vagas');

        if (responseServicos['success'] == true &&
            responseServicos['data'] != null) {
          _servicosAceitos =
              List<Map<String, dynamic>>.from(responseServicos['data']);
        }
      } catch (_) {
        _servicosAceitos = [];
      }

      if (!mounted) return;

      setState(() {
        if (responseCuidador['success'] == true &&
            responseCuidador['data'] != null) {
          _cuidador = Map<String, dynamic>.from(responseCuidador['data']);
        }

        final planoData = responsePlano['data'] ?? {};
        _planoAtual = (planoData['PlanoAtual'] ?? 'Básico').toString();
        _usosPlano = _parseInt(planoData['UsosPlano']) ?? 0;
        _limitePlano = _parseInt(planoData['LimitePlano']) ??
            (_planoAtual.toLowerCase() == 'premium' ? 20 : 5);

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dashboard cuidador: $e');

      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int getContatosRestantes() {
    final restante = _limitePlano - _usosPlano;
    return restante < 0 ? 0 : restante;
  }

  double getUsoPercentual() {
    if (_limitePlano <= 0) return 0;
    final valor = _usosPlano / _limitePlano;
    if (valor > 1) return 1;
    if (valor < 0) return 0;
    return valor;
  }

  int getPerfilCompletoPercentual() {
    int preenchidos = 0;
    const int total = 5;

    final cidade = _cuidador?['cidade'] ?? _cuidador?['Cidade'];
    final valorHora = _cuidador?['valorHora'] ?? _cuidador?['ValorHora'];
    final telefone = _cuidador?['telefone'] ?? _cuidador?['Telefone'];
    final bio = _cuidador?['biografia'] ?? _cuidador?['Biografia'];
    final foto = _cuidador?['fotoUrl'] ?? _cuidador?['FotoUrl'];

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

  String _formatarData(dynamic data) {
    if (data == null) return '-';

    final texto = data.toString();
    if (texto.length >= 10 && texto.contains('-')) {
      final partes = texto.substring(0, 10).split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    }

    return texto;
  }

  String _formatarHorario(Map<String, dynamic> vaga) {
    final inicio = vaga['HoraInicio']?.toString() ?? '';
    final fim = vaga['HoraFim']?.toString() ?? '';

    if (inicio.isEmpty && fim.isEmpty) return '-';
    if (fim.isEmpty) return inicio;
    if (inicio.isEmpty) return fim;

    return '$inicio às $fim';
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'R\$ 0,00';

    final numero = double.tryParse(valor.toString()) ?? 0;
    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _abrirPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilCuidadorPage()),
    );
    await _carregarDados();
  }

  Future<void> _abrirConfiguracoes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaConfiguracoes()),
    );
    await _carregarDados();
  }

  Future<void> _abrirPlanos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanosCuidadorPage()),
    );
    await _carregarDados();
  }

  Future<void> _abrirAgenda() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AgendaCuidadorPage()),
    );
    await _carregarDados();
  }

  Future<void> _abrirVagas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VagasCuidadorPage()),
    );
    await _carregarDados();
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
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _abrirConfiguracoes,
          ),
          GestureDetector(
            onTap: _abrirPerfil,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: _fotoProvider(),
                child: _fotoProvider() == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
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
                          onTap: _abrirVagas,
                        ),
                        _buildActionBox(
                          titulo: 'Agenda',
                          icon: Icons.calendar_month_outlined,
                          cor: rosa,
                          onTap: _abrirAgenda,
                        ),
                        _buildActionBox(
                          titulo: 'Meu plano',
                          icon: Icons.workspace_premium_outlined,
                          cor: verde,
                          textoEscuro: true,
                          onTap: _abrirPlanos,
                        ),
                        _buildActionBox(
                          titulo: 'Meu perfil',
                          icon: Icons.person_outline,
                          cor: rosa,
                          onTap: _abrirPerfil,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Meu plano',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: roxo,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPlanoStatusCard(),
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
          colors: [roxo, rosa],
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$_usosPlano / $_limitePlano contatos',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanoStatusCard() {
    final restante = getContatosRestantes();
    final premium = _planoAtual.toLowerCase() == 'premium';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: premium
                    ? verde.withOpacity(0.22)
                    : rosa.withOpacity(0.12),
                child: Icon(
                  premium
                      ? Icons.workspace_premium_rounded
                      : Icons.star_border_rounded,
                  color: premium ? Colors.black : roxo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  premium ? 'Premium ativo' : 'Plano básico ativo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: roxo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniResumoItem('Usados', '$_usosPlano')),
              const SizedBox(width: 10),
              Expanded(child: _miniResumoItem('Limite', '$_limitePlano')),
              const SizedBox(width: 10),
              Expanded(child: _miniResumoItem('Restantes', '$restante')),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: getUsoPercentual(),
            minHeight: 8,
            backgroundColor: roxo.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation(premium ? verde : rosa),
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 12),
          Text(
            premium
                ? 'Seu plano Premium aumenta seu alcance e libera mais contatos.'
                : 'Quer acessar mais contatos? Atualize para Premium.',
            style: TextStyle(
              fontSize: 14,
              color: roxo.withOpacity(0.76),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _abrirPlanos,
              style: ElevatedButton.styleFrom(
                backgroundColor: premium ? roxo : rosa,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(premium ? 'Gerenciar plano' : 'Atualizar plano'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextServiceCard() {
    if (_servicosAceitos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
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
                    'Assim que você aceitar uma vaga, ela vai aparecer aqui.',
                    style: TextStyle(
                      fontSize: 14,
                      color: roxo.withOpacity(0.72),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _abrirVagas,
                    child: const Text('Ver vagas disponíveis'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final servico = _servicosAceitos.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: verde.withOpacity(0.22),
                child: const Icon(Icons.event_available, color: roxo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  servico['Titulo']?.toString() ?? 'Atendimento agendado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: roxo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _linhaServico(
            Icons.person_outline,
            'Responsável',
            valorOuPadrao(servico['NomeResponsavel']),
          ),
          const SizedBox(height: 8),
          _linhaServico(
            Icons.calendar_today_outlined,
            'Data',
            _formatarData(servico['DataServico']),
          ),
          const SizedBox(height: 8),
          _linhaServico(
            Icons.access_time_outlined,
            'Horário',
            _formatarHorario(servico),
          ),
          const SizedBox(height: 8),
          _linhaServico(
            Icons.attach_money,
            'Valor',
            _formatarValor(servico['Valor']),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _abrirAgenda,
              style: OutlinedButton.styleFrom(
                foregroundColor: roxo,
                side: const BorderSide(color: roxo),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Ver agenda completa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaServico(IconData icon, String label, String valor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: roxo),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $valor',
            style: TextStyle(
              color: roxo.withOpacity(0.82),
              fontSize: 14,
            ),
          ),
        ),
      ],
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

  Widget _buildResumoPerfilCard() {
    final percentual = getPerfilCompletoPercentual();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniResumoItem(
                  'Cidade',
                  valorOuPadrao(_cuidador?['cidade'] ?? _cuidador?['Cidade']),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniResumoItem(
                  'Valor/hora',
                  valorOuPadrao(
                    _cuidador?['valorHora'] ?? _cuidador?['ValorHora'],
                    padrao: 'A definir',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniResumoItem('Plano', _planoAtual)),
              const SizedBox(width: 10),
              Expanded(child: _miniResumoItem('Perfil', '$percentual%')),
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
              onPressed: _abrirPerfil,
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
      decoration: _cardDecoration(),
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
            onPressed: _abrirPerfil,
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
        border: Border.all(color: rosa.withOpacity(0.18)),
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
                  onPressed: _abrirPerfil,
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: roxo.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: roxo.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}