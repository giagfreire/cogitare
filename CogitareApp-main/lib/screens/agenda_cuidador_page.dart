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

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarAgenda();
  }

  Future<void> carregarAgenda() async {
    try {
      final cuidadorId = await SessionService.getCuidadorId();

      if (cuidadorId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final response = await ServicoApi.get(
        '/api/cuidador/$cuidadorId/disponibilidade',
      );

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> dados = response['data'];

        for (var diaLocal in dias) {
          final registro = dados.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item?['DiaSemana'] == diaLocal['dia'],
            orElse: () => null,
          );

          if (registro != null) {
            final dataInicio = registro['DataInicio'];
            final dataFim = registro['DataFim'];

            diaLocal['ativo'] = dataInicio != null && dataFim != null;
            diaLocal['inicio'] = dataInicio != null
                ? dataInicio.toString().substring(0, 5)
                : '08:00';
            diaLocal['fim'] = dataFim != null
                ? dataFim.toString().substring(0, 5)
                : '18:00';
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar agenda: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> selecionarHora(int index, bool inicio) async {
    final horaAtual = inicio ? dias[index]["inicio"] : dias[index]["fim"];
    final partes = horaAtual.split(':');

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(partes[0]),
        minute: int.parse(partes[1]),
      ),
    );

    if (picked != null) {
      setState(() {
        final horaFormatada =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";

        if (inicio) {
          dias[index]["inicio"] = horaFormatada;
        } else {
          dias[index]["fim"] = horaFormatada;
        }
      });
    }
  }

  Future<void> salvarAgenda() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final cuidadorId = await SessionService.getCuidadorId();

      if (cuidadorId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível identificar o cuidador logado.'),
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final disponibilidade = dias.map((dia) {
        return {
          "dia": dia["dia"],
          "ativo": dia["ativo"],
          "inicio": dia["inicio"],
          "fim": dia["fim"],
        };
      }).toList();

      final response = await ServicoApi.post(
        '/api/cuidador/$cuidadorId/disponibilidade',
        {
          "disponibilidade": disponibilidade,
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Disponibilidade salva com sucesso!"),
          ),
        );
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
        SnackBar(
          content: Text('Erro ao salvar disponibilidade: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildDiaCard(int index) {
    final dia = dias[index];
    final bool ativo = dia["ativo"];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF35064E),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    dia["dia"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(
                  value: ativo,
                  activeThumbColor: const Color(0xFF35064E),
                  onChanged: (value) {
                    setState(() {
                      dia["ativo"] = value;
                    });
                  },
                ),
              ],
            ),
            if (ativo) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => selecionarHora(index, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F0F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD8CBE1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Início",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dia["inicio"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF35064E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => selecionarHora(index, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F0F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD8CBE1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Fim",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dia["fim"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF35064E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diasAtivos = dias.where((dia) => dia["ativo"] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        title: const Text("Minha Disponibilidade"),
        backgroundColor: const Color(0xFF35064E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF35064E),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Defina os dias e horários em que você está disponível para atender.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$diasAtivos dia(s) selecionado(s)",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: dias.length,
                    itemBuilder: (context, index) => _buildDiaCard(index),
                  ),
                ),
              ],
            ),
      bottomSheet: _isLoading
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : salvarAgenda,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF35064E),
                      disabledBackgroundColor:
                          const Color(0xFF35064E).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Salvar disponibilidade",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}