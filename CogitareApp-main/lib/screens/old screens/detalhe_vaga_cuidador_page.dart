import 'package:flutter/material.dart';
import '../../services/api_cuidador.dart';
import '../planos_cuidador_page.dart';

class DetalheVagaCuidadorPage extends StatefulWidget {
  final Map<String, dynamic> vaga;
  final String planoAtual;
  final int usosPlano;
  final int limitePlano;

  const DetalheVagaCuidadorPage({
    super.key,
    required this.vaga,
    required this.planoAtual,
    required this.usosPlano,
    required this.limitePlano,
  });

  @override
  State<DetalheVagaCuidadorPage> createState() =>
      _DetalheVagaCuidadorPageState();
}

class _DetalheVagaCuidadorPageState extends State<DetalheVagaCuidadorPage> {
  bool _isSubmitting = false;

  String _t(dynamic valor, {String fallback = '-'}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String _formatarData(dynamic data) {
    if (data == null) return '-';

    final texto = data.toString();
    if (texto.length >= 10) {
      final partes = texto.substring(0, 10).split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    }
    return texto;
  }

  String _formatarHorario() {
    final inicio = widget.vaga['HoraInicio']?.toString() ?? '';
    final fim = widget.vaga['HoraFim']?.toString() ?? '';

    if (inicio.isEmpty && fim.isEmpty) return '-';
    if (fim.isEmpty) return inicio;
    if (inicio.isEmpty) return fim;

    final horaInicio = inicio.length >= 5 ? inicio.substring(0, 5) : inicio;
    final horaFim = fim.length >= 5 ? fim.substring(0, 5) : fim;

    return '$horaInicio às $horaFim';
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'R\$ 0,00';
    final texto = valor.toString().replaceAll('.', ',');
    return 'R\$ $texto';
  }

  bool get _bloqueada {
    return widget.planoAtual != 'Premium' &&
        widget.limitePlano > 0 &&
        widget.usosPlano >= widget.limitePlano;
  }

  Future<void> _mostrarUpgrade() async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recurso Premium'),
          content: const Text(
            'Para aceitar mais vagas, faça upgrade para o Plano Premium e desbloqueie mais oportunidades.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Agora não'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlanosCuidadorPage(),
                  ),
                );
                if (!mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text('Ver planos'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _aceitarVaga() async {
    final idVaga = int.tryParse('${widget.vaga['IdVaga'] ?? 0}') ?? 0;

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
      _isSubmitting = true;
    });

    try {
      final response = await ApiCuidador.aceitarVaga(idVaga);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Resposta recebida'),
          backgroundColor:
              response['success'] == true ? Colors.green : Colors.red,
        ),
      );

      if (response['success'] == true) {
        Navigator.pop(context, true);
      } else if ((response['message'] ?? '')
          .toString()
          .toLowerCase()
          .contains('premium')) {
        await _mostrarUpgrade();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aceitar vaga: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _infoLinha(IconData icon, String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF35064E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $valor',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _t(widget.vaga['Titulo']);
    final nomeResponsavel = _t(widget.vaga['NomeResponsavel']);
    final cidade = _t(widget.vaga['Cidade']);
    final data = _formatarData(widget.vaga['DataServico']);
    final horario = _formatarHorario();
    final valor = _formatarValor(widget.vaga['Valor']);
    final telefone = _t(widget.vaga['TelefoneResponsavel']);
    final descricao = _t(widget.vaga['Descricao'], fallback: 'Sem descrição.');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        title: const Text('Detalhes da vaga'),
        backgroundColor: const Color(0xFF35064E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF35064E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeResponsavel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.planoAtual == 'Premium'
                          ? Colors.white
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      widget.planoAtual == 'Premium'
                          ? 'Plano Premium'
                          : 'Plano Básico',
                      style: TextStyle(
                        color: widget.planoAtual == 'Premium'
                            ? const Color(0xFF35064E)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF35064E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoLinha(Icons.location_on_outlined, 'Cidade', cidade),
                    const SizedBox(height: 12),
                    _infoLinha(Icons.calendar_today_outlined, 'Data', data),
                    const SizedBox(height: 12),
                    _infoLinha(Icons.access_time_outlined, 'Horário', horario),
                    const SizedBox(height: 12),
                    _infoLinha(Icons.attach_money, 'Valor', valor),
                    const SizedBox(height: 12),
                    _infoLinha(Icons.phone_outlined, 'Contato', telefone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descrição',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF35064E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descricao,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_bloqueada)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD8A8)),
                        ),
                        child: const Text(
                          'Você atingiu o limite do seu plano atual. Faça upgrade para continuar aceitando vagas.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8A4B00),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (!_bloqueada && widget.limitePlano > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Uso do plano: ${widget.usosPlano} de ${widget.limitePlano}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _aceitarVaga,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF35064E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _bloqueada
                                    ? 'Desbloquear com Premium'
                                    : 'Aceitar vaga',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}