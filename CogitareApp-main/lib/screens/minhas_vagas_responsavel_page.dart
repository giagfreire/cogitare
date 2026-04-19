import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MinhasVagasResponsavelPage extends StatefulWidget {
  const MinhasVagasResponsavelPage({super.key});

  @override
  State<MinhasVagasResponsavelPage> createState() =>
      _MinhasVagasResponsavelPageState();
}

class _MinhasVagasResponsavelPageState
    extends State<MinhasVagasResponsavelPage> {
  bool _carregando = true;
  List<dynamic> _vagas = [];

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    setState(() {
      _carregando = true;
    });

    try {
      // por enquanto fixo para destravar a tela
      const responsavelId = 1;

      final response = await ServicoApi.get(
        '/api/responsavel/$responsavelId/vagas',
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _vagas = response['data'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erro ao carregar vagas'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar vagas: $e'),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _carregando = false;
    });
  }

  String _texto(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Sem data';
    try {
      final texto = data.toString();
      if (texto.contains('-') && texto.length >= 10) {
        final partes = texto.substring(0, 10).split('-');
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
      return texto;
    } catch (_) {
      return data.toString();
    }
  }

  Color _corStatus(String status) {
    switch (status.toLowerCase()) {
      case 'aberta':
        return Colors.green;
      case 'encerrada':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        title: const Text('Minhas vagas'),
        backgroundColor: const Color(0xFF35064E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _vagas.isEmpty
              ? _buildEstadoVazio()
              : RefreshIndicator(
                  onRefresh: _carregarVagas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vagas.length,
                    itemBuilder: (context, index) {
                      final vaga = _vagas[index];

                      final titulo = _texto(vaga['titulo'] ?? vaga['Titulo']);
                      final cidade = _texto(vaga['cidade'] ?? vaga['Cidade']);
                      final valor =
                          _texto(vaga['valor'] ?? vaga['Valor'], fallback: 'A combinar');
                      final status =
                          _texto(vaga['status'] ?? vaga['Status'], fallback: 'Sem status');
                      final data = _formatarData(
                        vaga['dataServico'] ?? vaga['DataServico'],
                      );
                      final horaInicio =
                          _texto(vaga['horaInicio'] ?? vaga['HoraInicio'], fallback: '--:--');
                      final horaFim =
                          _texto(vaga['horaFim'] ?? vaga['HoraFim'], fallback: '--:--');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    titulo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF35064E),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _corStatus(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _corStatus(status),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _linhaInfo(Icons.location_on_outlined, cidade),
                            const SizedBox(height: 8),
                            _linhaInfo(Icons.calendar_today_outlined, data),
                            const SizedBox(height: 8),
                            _linhaInfo(Icons.access_time_outlined, '$horaInicio às $horaFim'),
                            const SizedBox(height: 8),
                            _linhaInfo(Icons.attach_money_outlined, 'R\$ $valor'),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'A tela de detalhes/gerenciar vaga será a próxima.',
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF35064E),
                                  side: const BorderSide(
                                    color: Color(0xFF35064E),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Ver detalhes'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _linhaInfo(IconData icone, String texto) {
    return Row(
      children: [
        Icon(
          icone,
          size: 18,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline_rounded,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Você ainda não criou vagas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assim que você criar uma vaga, ela aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _carregarVagas,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF35064E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}