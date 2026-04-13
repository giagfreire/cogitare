import 'package:flutter/material.dart';
import '../services/api_cuidador.dart';

class MinhasVagasCuidadorPage extends StatefulWidget {
  const MinhasVagasCuidadorPage({super.key});

  @override
  State<MinhasVagasCuidadorPage> createState() =>
      _MinhasVagasCuidadorPageState();
}

class _MinhasVagasCuidadorPageState extends State<MinhasVagasCuidadorPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _vagas = [];

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vagas = await ApiCuidador.getMinhasVagasAceitas();

      setState(() {
        _vagas = vagas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar vagas aceitas.';
        _isLoading = false;
      });
    }
  }

  Future<void> _atualizar() async {
    await _carregarVagas();
  }

  String _t(dynamic v, {String fallback = 'Não informado'}) {
    if (v == null) return fallback;
    final texto = v.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Não informada';

    try {
      final texto = data.toString().split('T').first;
      final partes = texto.split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }

      return texto;
    } catch (_) {
      return data.toString();
    }
  }

  String _formatarHora(dynamic hora) {
    if (hora == null) return '--:--';

    final texto = hora.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return '--:--';

    return texto.length >= 5 ? texto.substring(0, 5) : texto;
  }

  Color _corStatus(String status) {
    final s = status.toLowerCase();

    if (s.contains('aceit')) return Colors.green;
    if (s.contains('pendente')) return Colors.orange;
    if (s.contains('cancel')) return Colors.red;
    if (s.contains('conclu')) return Colors.blue;

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas vagas aceitas'),
        actions: [
          IconButton(
            onPressed: _carregarVagas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _carregarVagas,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _vagas.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _atualizar,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 100),
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 72,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Você ainda não aceitou nenhuma vaga.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Quando você aceitar uma vaga, ela aparecerá aqui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _atualizar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vagas.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Total de vagas aceitas: ${_vagas.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }

                          final vaga = _vagas[index - 1];

                          final titulo = _t(vaga['Titulo'], fallback: 'Sem título');
                          final cidade = _t(vaga['Cidade']);
                          final data = _formatarData(vaga['DataServico']);
                          final horaInicio = _formatarHora(vaga['HoraInicio']);
                          final horaFim = _formatarHora(vaga['HoraFim']);
                          final valor = _t(vaga['Valor'], fallback: 'A combinar');
                          final responsavel = _t(
                            vaga['NomeResponsavel'] ?? vaga['Nome'],
                            fallback: 'Responsável não informado',
                          );
                          final status = _t(
                            vaga['StatusAceite'] ?? vaga['Status'],
                            fallback: 'Aceita',
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalheVagaAceitaPage(vaga: vaga),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            titulo,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
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
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _infoLinha(Icons.location_on_outlined, 'Cidade: $cidade'),
                                    const SizedBox(height: 6),
                                    _infoLinha(Icons.calendar_today_outlined, 'Data: $data'),
                                    const SizedBox(height: 6),
                                    _infoLinha(Icons.access_time_outlined, 'Horário: $horaInicio às $horaFim'),
                                    const SizedBox(height: 6),
                                    _infoLinha(Icons.attach_money_outlined, 'Valor: R\$ $valor'),
                                    const SizedBox(height: 6),
                                    _infoLinha(Icons.person_outline, 'Responsável: $responsavel'),
                                    const SizedBox(height: 12),
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Ver detalhes',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF35064E),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Color(0xFF35064E),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _infoLinha(IconData icon, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class DetalheVagaAceitaPage extends StatelessWidget {
  final Map<String, dynamic> vaga;

  const DetalheVagaAceitaPage({
    super.key,
    required this.vaga,
  });

  String _t(dynamic v, {String fallback = 'Não informado'}) {
    if (v == null) return fallback;
    final texto = v.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Não informada';

    try {
      final texto = data.toString().split('T').first;
      final partes = texto.split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }

      return texto;
    } catch (_) {
      return data.toString();
    }
  }

  String _formatarHora(dynamic hora) {
    if (hora == null) return '--:--';

    final texto = hora.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return '--:--';

    return texto.length >= 5 ? texto.substring(0, 5) : texto;
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _t(vaga['Titulo'], fallback: 'Sem título');
    final descricao = _t(vaga['Descricao']);
    final cidade = _t(vaga['Cidade']);
    final data = _formatarData(vaga['DataServico']);
    final horaInicio = _formatarHora(vaga['HoraInicio']);
    final horaFim = _formatarHora(vaga['HoraFim']);
    final valor = _t(vaga['Valor'], fallback: 'A combinar');
    final responsavel = _t(
      vaga['NomeResponsavel'] ?? vaga['Nome'],
      fallback: 'Responsável não informado',
    );
    final telefone = _t(
      vaga['TelefoneResponsavel'] ?? vaga['Telefone'],
    );
    final email = _t(
      vaga['EmailResponsavel'] ?? vaga['Email'],
    );
    final status = _t(
      vaga['StatusAceite'] ?? vaga['Status'],
      fallback: 'Aceita',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da vaga'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    _detalheLinha(Icons.location_on_outlined, 'Cidade', cidade),
                    const SizedBox(height: 10),
                    _detalheLinha(Icons.calendar_today_outlined, 'Data', data),
                    const SizedBox(height: 10),
                    _detalheLinha(
                      Icons.access_time_outlined,
                      'Horário',
                      '$horaInicio às $horaFim',
                    ),
                    const SizedBox(height: 10),
                    _detalheLinha(Icons.attach_money_outlined, 'Valor', 'R\$ $valor'),
                    const SizedBox(height: 10),
                    _detalheLinha(Icons.info_outline, 'Status', status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descrição',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      descricao,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Responsável',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _detalheLinha(Icons.person_outline, 'Nome', responsavel),
                    const SizedBox(height: 10),
                    _detalheLinha(Icons.phone_outlined, 'Telefone', telefone),
                    const SizedBox(height: 10),
                    _detalheLinha(Icons.email_outlined, 'E-mail', email),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detalheLinha(IconData icon, String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
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
}