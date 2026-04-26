import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/api_cuidador.dart';
import 'minhas_vagas_aceitas_page.dart';
import 'planos_cuidador_page.dart';

class VagasCuidadorPage extends StatefulWidget {
  const VagasCuidadorPage({super.key});

  @override
  State<VagasCuidadorPage> createState() => _VagasCuidadorPageState();
}

class _VagasCuidadorPageState extends State<VagasCuidadorPage> {
  List<Map<String, dynamic>> vagas = [];

  String _planoAtual = 'Gratuito';
  int _usosPlano = 0;
  int _limitePlano = 0;

  bool _isLoadingPlano = true;
  bool _isLoadingVagas = true;
  int? _vagaSendoAceita;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _recarregarTudo();
  }

  Future<void> _loadPlano() async {
    try {
      final response = await ApiCuidador.getStatusPlano();

      if (!mounted) return;

      setState(() {
        if (response['success'] == true && response['data'] != null) {
          final data = Map<String, dynamic>.from(response['data']);

          _planoAtual = (data['PlanoAtual'] ?? 'Gratuito').toString();
          _usosPlano = int.tryParse('${data['UsosPlano'] ?? 0}') ?? 0;
          _limitePlano = int.tryParse('${data['LimitePlano'] ?? 0}') ?? 0;
        } else {
          _planoAtual = 'Gratuito';
          _usosPlano = 0;
          _limitePlano = 0;
        }

        _isLoadingPlano = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _planoAtual = 'Gratuito';
        _usosPlano = 0;
        _limitePlano = 0;
        _isLoadingPlano = false;
      });
    }
  }

  Future<void> _loadVagas() async {
    try {
      final response = await ApiCuidador.getVagasAbertas();

      if (!mounted) return;

      setState(() {
        vagas = response.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoadingVagas = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        vagas = [];
        _isLoadingVagas = false;
      });
    }
  }

  Future<void> _recarregarTudo() async {
    setState(() {
      _isLoadingPlano = true;
      _isLoadingVagas = true;
    });

    await Future.wait([
      _loadPlano(),
      _loadVagas(),
    ]);
  }

  bool get _planoGratuito {
    final plano = _planoAtual.toLowerCase();
    return plano == 'gratuito' ||
        plano == 'sem plano' ||
        plano == 'nenhum' ||
        _limitePlano <= 0;
  }

  bool get _limiteAtingido {
    return !_planoGratuito && _usosPlano >= _limitePlano;
  }

  bool get _bloqueadoPorPlano {
    return _planoGratuito || _limiteAtingido;
  }

  int get _contatosRestantes {
    final restante = _limitePlano - _usosPlano;
    return restante < 0 ? 0 : restante;
  }

  double get _usoPercentual {
    if (_limitePlano <= 0) return 0.0;

    final valor = _usosPlano / _limitePlano;

    if (valor > 1) return 1.0;
    if (valor < 0) return 0.0;

    return valor.toDouble();
  }

  Future<void> _abrirPlanos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlanosCuidadorPage(),
      ),
    );

    await _loadPlano();
  }

  String _texto(dynamic valor, {String fallback = '-'}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  int _toInt(dynamic valor) {
    if (valor == null) return 0;
    if (valor is int) return valor;
    return int.tryParse(valor.toString()) ?? 0;
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
    final texto = numero.toStringAsFixed(2).replaceAll('.', ',');

    return 'R\$ $texto';
  }

  String _idade(dynamic dataNascimento) {
    if (dataNascimento == null) return '-';

    try {
      final nascimento = DateTime.parse(dataNascimento.toString());
      final hoje = DateTime.now();

      int idade = hoje.year - nascimento.year;

      if (hoje.month < nascimento.month ||
          (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
        idade--;
      }

      return '$idade anos';
    } catch (_) {
      return '-';
    }
  }

  Widget _infoLinha(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: roxo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $valor',
              style: const TextStyle(
                fontSize: 15,
                color: roxo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarBloqueioPlano() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _planoGratuito ? 'Plano necessário' : 'Limite do plano atingido',
          ),
          content: Text(
            _planoGratuito
                ? 'Para aceitar vagas e liberar o WhatsApp dos responsáveis, escolha um plano.'
                : 'Você usou todos os contatos disponíveis neste plano. Compre um novo plano ou faça upgrade para continuar aceitando vagas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _abrirPlanos();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: rosa,
                foregroundColor: Colors.white,
              ),
              child: Text(_planoGratuito ? 'Ver planos' : 'Comprar plano'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _aceitarVaga(Map<String, dynamic> vaga) async {
    if (_bloqueadoPorPlano) {
      _mostrarBloqueioPlano();
      return;
    }

    final idVaga = _toInt(vaga['IdVaga']);

    if (idVaga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID da vaga inválido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _vagaSendoAceita = idVaga;
    });

    try {
      final response = await ApiCuidador.aceitarVaga(idVaga);

      if (!mounted) return;

      setState(() {
        _vagaSendoAceita = null;
      });

      if (response['success'] == true) {
        Navigator.pop(context);

        await _recarregarTudo();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vaga aceita! 1 uso foi descontado do seu plano. O WhatsApp está liberado em Minhas vagas aceitas.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MinhasVagasAceitasPage(),
          ),
        );

        await _recarregarTudo();
      } else {
        final mensagem =
            response['message']?.toString() ?? 'Erro ao aceitar vaga.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.red,
          ),
        );

        if (mensagem.toLowerCase().contains('premium') ||
            mensagem.toLowerCase().contains('plano') ||
            mensagem.toLowerCase().contains('limite')) {
          _mostrarBloqueioPlano();
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _vagaSendoAceita = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aceitar vaga: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _detalhesVagaLiberada(Map<String, dynamic> vaga) {
    final idVaga = _toInt(vaga['IdVaga']);
    final aceitando = _vagaSendoAceita == idVaga;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados da vaga',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: roxo,
          ),
        ),
        const SizedBox(height: 12),
        _infoLinha(Icons.work_outline, 'Título', _texto(vaga['Titulo'])),
        _infoLinha(Icons.location_on_outlined, 'Cidade', _texto(vaga['Cidade'])),
        _infoLinha(Icons.location_city_outlined, 'Bairro', _texto(vaga['Bairro'])),
        _infoLinha(Icons.signpost_outlined, 'Rua', _texto(vaga['Rua'])),
        _infoLinha(
          Icons.calendar_today_outlined,
          'Data',
          _formatarData(vaga['DataServico']),
        ),
        _infoLinha(Icons.access_time_outlined, 'Horário', _formatarHorario(vaga)),
        _infoLinha(Icons.attach_money, 'Valor', _formatarValor(vaga['Valor'])),
        const SizedBox(height: 12),
        const Text(
          'Descrição da vaga',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: roxo,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _texto(
            vaga['Descricao'],
            fallback: 'Sem descrição informada.',
          ),
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Dados do idoso',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: roxo,
          ),
        ),
        const SizedBox(height: 12),
        _infoLinha(Icons.elderly_outlined, 'Nome', _texto(vaga['NomeIdoso'])),
        _infoLinha(Icons.cake_outlined, 'Idade', _idade(vaga['DataNascimentoIdoso'])),
        _infoLinha(Icons.wc_outlined, 'Sexo', _texto(vaga['SexoIdoso'])),
        _infoLinha(
          Icons.accessibility_new_outlined,
          'Mobilidade',
          _texto(vaga['Mobilidade']),
        ),
        _infoLinha(
          Icons.health_and_safety_outlined,
          'Nível de autonomia',
          _texto(vaga['NivelAutonomia']),
        ),
        _infoLinha(
          Icons.medical_services_outlined,
          'Condições médicas',
          _texto(vaga['CuidadosMedicos']),
        ),
        _infoLinha(Icons.notes_outlined, 'Observações', _texto(vaga['DescricaoExtra'])),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: verde.withOpacity(0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: verde.withOpacity(0.45),
            ),
          ),
          child: Text(
            'O WhatsApp do responsável só será liberado depois que você aceitar a vaga. Ao aceitar, 1 uso será descontado do seu plano.',
            style: TextStyle(
              color: roxo.withOpacity(0.9),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: aceitando
                ? null
                : (_planoGratuito || _limiteAtingido)
                    ? _mostrarBloqueioPlano
                    : () => _aceitarVaga(vaga),
            icon: aceitando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              aceitando
                  ? 'Aceitando...'
                  : _planoGratuito
                      ? 'Ver planos'
                      : _limiteAtingido
                          ? 'Comprar plano'
                          : 'Aceitar vaga',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: roxo,
              foregroundColor: Colors.white,
              disabledBackgroundColor: roxo.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _verDetalhes(Map<String, dynamic> vaga) {
    if (_bloqueadoPorPlano) {
      _mostrarBloqueioPlano();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Text(
                  _texto(
                    vaga['Titulo'],
                    fallback: 'Detalhes da vaga',
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: roxo,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'O contato do responsável não aparece aqui. Ele será liberado somente depois que você aceitar a vaga.',
                  style: TextStyle(
                    color: roxo.withOpacity(0.65),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                _detalhesVagaLiberada(vaga),
              ],
            );
          },
        );
      },
    );
  }
Widget _vagaCard(Map<String, dynamic> vaga) {
  final bloqueado = _bloqueadoPorPlano;

  return AnimatedContainer(
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOut,
    margin: const EdgeInsets.only(bottom: 18),
    child: Stack(
      children: [
        Container(
          height: bloqueado ? 270 : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: bloqueado
                  ? rosa.withOpacity(0.5)
                  : roxo.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: bloqueado
                    ? rosa.withOpacity(0.12)
                    : roxo.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(18),
              color: Colors.white,
              child: Opacity(
                opacity: bloqueado ? 0.3 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: rosa.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Cuidado de idoso',
                        style: TextStyle(
                          color: rosa,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bloqueado
                          ? 'Cuidador para idoso'
                          : _texto(vaga['Titulo']),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: roxo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _infoLinha(
                      Icons.location_on_outlined,
                      'Cidade',
                      bloqueado
                          ? 'São Paulo - SP'
                          : _texto(vaga['Cidade']),
                    ),
                    if (!bloqueado) ...[
                      _infoLinha(
                        Icons.calendar_today_outlined,
                        'Data',
                        _formatarData(vaga['DataServico']),
                      ),
                      _infoLinha(
                        Icons.access_time_outlined,
                        'Horário',
                        _formatarHorario(vaga),
                      ),
                      _infoLinha(
                        Icons.attach_money,
                        'Valor',
                        _formatarValor(vaga['Valor']),
                      ),
                    ] else
                      const Text(
                        'R\$ 150,00 / diária',
                        style: TextStyle(
                          color: verde,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// 🔥 OVERLAY BLOQUEADO (CORRIGIDO)
        if (bloqueado)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.white.withOpacity(0.6),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 58,
                          width: 58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [rosa, roxo],
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Detalhes bloqueados',
                          style: TextStyle(
                            color: roxo,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _planoGratuito
                              ? 'Adquira um plano para visualizar'
                              : 'Compre um novo plano',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: roxo.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _abrirPlanos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rosa,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Ver planos'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
Widget _buildEmptyState() {
  return const Center(
    child: Text(
      'Nenhuma vaga disponível no momento.',
      style: TextStyle(fontSize: 16),
    ),
  );
}

Widget _buildPlanoResumoTopo() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: roxo,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    ),
    child: const Text(
      'Vagas disponíveis para você',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  final isLoading = _isLoadingPlano || _isLoadingVagas;

  return Scaffold(
    backgroundColor: fundo,
    appBar: AppBar(
      title: const Text('Vagas disponíveis'),
      backgroundColor: roxo,
      foregroundColor: Colors.white,
    ),
    body: isLoading
        ? const Center(
            child: CircularProgressIndicator(color: rosa),
          )
        : Column(
            children: [
              _buildPlanoResumoTopo(),
              Expanded(
                child: vagas.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vagas.length,
                        itemBuilder: (context, index) {
                          return _vagaCard(vagas[index]);
                        },
                      ),
              ),
            ],
          ),
  );
}
}