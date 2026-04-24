import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

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

  final bool _isSaving = false;
  bool _isLoading = true;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);

  @override
  void initState() {
    super.initState();
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    await Future.wait([
      carregarAgenda(),
      carregarServicos(),
    ]);

    setState(() {
      _isLoading = false;
    });
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
      final cuidadorId = await SessionService.getCuidadorId();

      final response =
          await ServicoApi.get('/api/cuidador/$cuidadorId/disponibilidade');

      if (response['success'] == true && response['data'] != null) {
        final dados = response['data'];

        for (var diaLocal in dias) {
          final registro = dados.firstWhere(
            (item) => item['DiaSemana'] == diaLocal['dia'],
            orElse: () => null,
          );

          if (registro != null) {
            diaLocal['ativo'] =
                registro['DataInicio'] != null && registro['DataFim'] != null;
            diaLocal['inicio'] =
                registro['DataInicio']?.toString().substring(0, 5) ?? "08:00";
            diaLocal['fim'] =
                registro['DataFim']?.toString().substring(0, 5) ?? "18:00";
          }
        }
      }
    } catch (e) {
      debugPrint('Erro agenda: $e');
    }
  }

  String formatarData(data) {
    if (data == null) return "-";
    final partes = data.toString().substring(0, 10).split("-");
    return "${partes[2]}/${partes[1]}/${partes[0]}";
  }

  Widget _cardServico(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roxo.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s['Titulo'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(s['NomeResponsavel'] ?? '',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 6),
              Text(formatarData(s['DataServico'])),
              const SizedBox(width: 14),
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 6),
              Text("${s['HoraInicio']} - ${s['HoraFim']}"),
            ],
          ),
          const SizedBox(height: 10),
          Text("Valor: R\$ ${s['Valor']}",
              style: const TextStyle(
                  color: roxo, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _emptyServicos() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Text(
          "Você ainda não tem serviços agendados.",
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diasAtivos = dias.where((d) => d["ativo"] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        title: const Text("Agenda"),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                /// SERVIÇOS
                const Text("Meus serviços",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                servicos.isEmpty
                    ? _emptyServicos()
                    : Column(
                        children:
                            servicos.map((s) => _cardServico(s)).toList(),
                      ),

                const SizedBox(height: 20),

                /// DISPONIBILIDADE
                const Text("Minha disponibilidade",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                const SizedBox(height: 6),
                Text("$diasAtivos dias ativos"),

                const SizedBox(height: 10),

                ...dias.map((d) {
                  return Card(
                    child: ListTile(
                      title: Text(d['dia']),
                      subtitle: d['ativo']
                          ? Text("${d['inicio']} - ${d['fim']}")
                          : const Text("Indisponível"),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}