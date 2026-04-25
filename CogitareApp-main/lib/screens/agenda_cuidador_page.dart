import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';

class AgendaCuidadorPage extends StatefulWidget {
  const AgendaCuidadorPage({super.key});

  @override
  State<AgendaCuidadorPage> createState() => _AgendaCuidadorPageState();
}

class _AgendaCuidadorPageState extends State<AgendaCuidadorPage> {
  final List<Map<String, dynamic>> dias = [
    {"dia": "Segunda", "ativo": false, "inicio": "08:00", "fim": "18:00"},
    {"dia": "Terça", "ativo": false, "inicio": "08:00", "fim": "18:00"},
    {"dia": "Quarta", "ativo": false, "inicio": "08:00", "fim": "18:00"},
    {"dia": "Quinta", "ativo": false, "inicio": "08:00", "fim": "18:00"},
    {"dia": "Sexta", "ativo": false, "inicio": "08:00", "fim": "18:00"},
    {"dia": "Sábado", "ativo": false, "inicio": "08:00", "fim": "18:00"},
    {"dia": "Domingo", "ativo": false, "inicio": "08:00", "fim": "18:00"},
  ];

  List<Map<String, dynamic>> servicos = [];

  bool _isSaving = false;
  bool _isLoading = true;
  int? _cuidadorId;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF8F7FB);

  @override
  void initState() {
    super.initState();
    carregarTudo();
  }

  int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  Future<int?> _getCuidadorIdLogado() async {
    final token = await ServicoAutenticacao.getToken();
    final userData = await ServicoAutenticacao.getUserData();

    if (token != null && token.isNotEmpty) {
      ServicoApi.setToken(token);
    }

    return _parseInt(
      userData?['IdCuidador'] ??
          userData?['idCuidador'] ??
          userData?['cuidadorId'] ??
          userData?['id'] ??
          userData?['Id'],
    );
  }

  Future<void> carregarTudo() async {
    setState(() => _isLoading = true);

    _cuidadorId = await _getCuidadorIdLogado();

    await Future.wait([
      carregarAgenda(),
      carregarServicos(),
    ]);

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> carregarServicos() async {
    try {
      final response = await ServicoApi.get('/api/cuidador/minhas-vagas');

      if (response['success'] == true && response['data'] != null) {
        servicos = List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      debugPrint('Erro serviços: $e');
    }
  }

  Future<void> carregarAgenda() async {
    try {
      if (_cuidadorId == null) return;

      final response = await ServicoApi.get(
        '/api/cuidador/$_cuidadorId/disponibilidade',
      );

      if (response['success'] == true && response['data'] != null) {
        final dados = List<Map<String, dynamic>>.from(response['data']);

        for (var diaLocal in dias) {
          final registro = dados.where(
            (item) => item['DiaSemana'] == diaLocal['dia'],
          );

          if (registro.isNotEmpty) {
            final item = registro.first;

            diaLocal['ativo'] =
                item['DataInicio'] != null && item['DataFim'] != null;

            diaLocal['inicio'] =
                item['DataInicio']?.toString().substring(0, 5) ?? '08:00';

            diaLocal['fim'] =
                item['DataFim']?.toString().substring(0, 5) ?? '18:00';
          }
        }
      }
    } catch (e) {
      debugPrint('Erro agenda: $e');
    }
  }

  Future<void> salvarDisponibilidade() async {
    if (_cuidadorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuidador não identificado.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await ServicoApi.post(
        '/api/cuidador/$_cuidadorId/disponibilidade',
        {'disponibilidade': dias},
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilidade salva com sucesso!')),
        );
        await carregarTudo();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Erro ao salvar disponibilidade.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar disponibilidade: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> selecionarHorario(Map<String, dynamic> dia, String campo) async {
    final atual = dia[campo]?.toString() ?? '08:00';
    final partes = atual.split(':');

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(partes[0]) ?? 8,
        minute: int.tryParse(partes.length > 1 ? partes[1] : '0') ?? 0,
      ),
    );

    if (time != null) {
      setState(() {
        dia[campo] =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        dia['ativo'] = true;
      });
    }
  }

  String formatarData(dynamic data) {
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

  String formatarValor(dynamic valor) {
    if (valor == null) return 'R\$ 0,00';
    final numero = double.tryParse(valor.toString()) ?? 0;
    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _cardServico(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s['Titulo']?.toString() ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: roxo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s['NomeResponsavel']?.toString() ?? '',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: roxo),
              const SizedBox(width: 6),
              Text(formatarData(s['DataServico'])),
              const SizedBox(width: 14),
              const Icon(Icons.access_time, size: 16, color: roxo),
              const SizedBox(width: 6),
              Expanded(
                child: Text("${s['HoraInicio']} - ${s['HoraFim']}"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Valor: ${formatarValor(s['Valor'])}',
            style: const TextStyle(
              color: roxo,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyServicos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Você ainda não tem serviços agendados.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _cardDisponibilidade(Map<String, dynamic> d) {
    final ativo = d['ativo'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ativo ? verde.withOpacity(0.7) : roxo.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d['dia'],
                  style: const TextStyle(
                    color: roxo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: ativo,
                activeColor: rosa,
                onChanged: (value) {
                  setState(() {
                    d['ativo'] = value;
                  });
                },
              ),
            ],
          ),
          if (ativo) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => selecionarHorario(d, 'inicio'),
                    icon: const Icon(Icons.schedule),
                    label: Text('Início: ${d['inicio']}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: roxo,
                      side: const BorderSide(color: roxo),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => selecionarHorario(d, 'fim'),
                    icon: const Icon(Icons.schedule),
                    label: Text('Fim: ${d['fim']}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: roxo,
                      side: const BorderSide(color: roxo),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Indisponível',
                style: TextStyle(color: roxo.withOpacity(0.55)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diasAtivos = dias.where((d) => d['ativo'] == true).length;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Agenda'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: carregarTudo,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarTudo,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Meus serviços',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: roxo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  servicos.isEmpty
                      ? _emptyServicos()
                      : Column(
                          children: servicos.map((s) => _cardServico(s)).toList(),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Minha disponibilidade',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: roxo,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: verde.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$diasAtivos ativo(s)',
                          style: const TextStyle(
                            color: roxo,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...dias.map(_cardDisponibilidade),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : salvarDisponibilidade,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Salvando...' : 'Salvar disponibilidade',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rosa,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}