import 'package:flutter/material.dart';
import '../services/api_cuidador.dart';
import 'planos_cuidador_page.dart';

class VagasCuidadorPage extends StatefulWidget {
  const VagasCuidadorPage({super.key});

  @override
  State<VagasCuidadorPage> createState() => _VagasCuidadorPageState();
}

class _VagasCuidadorPageState extends State<VagasCuidadorPage> {
  List<Map<String, dynamic>> vagas = [];
  String _planoAtual = 'Basico';
  int _usosPlano = 0;
  int _limitePlano = 0;

  bool _isLoadingPlano = true;
  bool _isLoadingVagas = true;

  @override
  void initState() {
    super.initState();
    _loadPlano();
    _loadVagas();
  }

  Future<void> _loadPlano() async {
    try {
      final response = await ApiCuidador.getStatusPlano();

      if (!mounted) return;

      setState(() {
        if (response['success'] == true && response['data'] != null) {
          final data = Map<String, dynamic>.from(response['data']);
          _planoAtual = (data['PlanoAtual'] ?? 'Basico').toString();
          _usosPlano = int.tryParse('${data['UsosPlano'] ?? 0}') ?? 0;
          _limitePlano = int.tryParse('${data['LimitePlano'] ?? 0}') ?? 0;
        }
        _isLoadingPlano = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPlano = false;
      });
    }
  }

  Future<void> _loadVagas() async {
    try {
      final response = await ApiCuidador.getVagasAbertas();

      if (!mounted) return;

      setState(() {
        vagas = response;
        _isLoadingVagas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingVagas = false;
      });
    }
  }

  Future<void> _recarregarTudo() async {
    await Future.wait([
      _loadPlano(),
      _loadVagas(),
    ]);
  }

  void _mostrarUpgrade() {
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
                _loadPlano();
              },
              child: const Text('Ver planos'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _aceitarVaga(
    BuildContext sheetContext,
    Map<String, dynamic> vaga,
  ) async {
    final idVaga = int.tryParse('${vaga['IdVaga'] ?? 0}') ?? 0;

    if (idVaga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID da vaga inválido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(sheetContext);

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
      await _recarregarTudo();
    } else if ((response['message'] ?? '')
        .toString()
        .toLowerCase()
        .contains('premium')) {
      _mostrarUpgrade();
    }
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
    final texto = valor.toString().replaceAll('.', ',');
    return 'R\$ $texto';
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

  void _verDetalhes(Map<String, dynamic> vaga) {
    final bloqueada =
        _planoAtual != 'Premium' && _limitePlano > 0 && _usosPlano >= _limitePlano;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Wrap(
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vaga['NomeResponsavel']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 22,
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
                      color: _planoAtual == 'Premium'
                          ? const Color(0xFF35064E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _planoAtual == 'Premium'
                            ? const Color(0xFF35064E)
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Text(
                      _planoAtual == 'Premium'
                          ? 'Plano Premium'
                          : 'Plano Básico',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _planoAtual == 'Premium'
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoLinha(
                Icons.work_outline,
                'Título',
                vaga['Titulo']?.toString() ?? '-',
              ),
              const SizedBox(height: 12),
              _infoLinha(
                Icons.location_on_outlined,
                'Cidade',
                vaga['Cidade']?.toString() ?? '-',
              ),
              const SizedBox(height: 12),
              _infoLinha(
                Icons.calendar_today_outlined,
                'Data',
                _formatarData(vaga['DataServico']),
              ),
              const SizedBox(height: 12),
              _infoLinha(
                Icons.access_time_outlined,
                'Horário',
                _formatarHorario(vaga),
              ),
              const SizedBox(height: 12),
              _infoLinha(
                Icons.attach_money,
                'Valor',
                _formatarValor(vaga['Valor']),
              ),
              const SizedBox(height: 12),
              _infoLinha(
                Icons.phone_outlined,
                'Contato',
                vaga['TelefoneResponsavel']?.toString() ?? '-',
              ),
              const SizedBox(height: 20),
              const Text(
                'Descrição',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vaga['Descricao']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              if (bloqueada)
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
              if (!bloqueada && _limitePlano > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Uso do plano: $_usosPlano de $_limitePlano',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _aceitarVaga(sheetContext, vaga),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF35064E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    bloqueada ? 'Desbloquear com Premium' : 'Aceitar vaga',
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
        );
      },
    );
  }

  Widget _vagaCard(Map<String, dynamic> vaga) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vaga['Titulo']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35064E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vaga['NomeResponsavel']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            _infoLinha(
              Icons.location_on_outlined,
              'Cidade',
              vaga['Cidade']?.toString() ?? '-',
            ),
            const SizedBox(height: 8),
            _infoLinha(
              Icons.calendar_today_outlined,
              'Data',
              _formatarData(vaga['DataServico']),
            ),
            const SizedBox(height: 8),
            _infoLinha(
              Icons.access_time_outlined,
              'Horário',
              _formatarHorario(vaga),
            ),
            const SizedBox(height: 8),
            _infoLinha(
              Icons.attach_money,
              'Valor',
              _formatarValor(vaga['Valor']),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _verDetalhes(vaga),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF35064E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ver detalhes',
                  style: TextStyle(
                    color: Color(0xFF35064E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _recarregarTudo,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Nenhuma vaga disponível no momento.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoadingPlano || _isLoadingVagas;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        title: const Text('Vagas Disponíveis'),
        backgroundColor: const Color(0xFF35064E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF35064E),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${vagas.length} vaga(s) encontrada(s) para você',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _planoAtual == 'Premium'
                              ? Colors.white
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          _planoAtual == 'Premium' ? 'Premium' : 'Básico',
                          style: TextStyle(
                            color: _planoAtual == 'Premium'
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
                Expanded(
                  child: vagas.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _recarregarTudo,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: vagas.length,
                            itemBuilder: (context, index) =>
                                _vagaCard(vagas[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}