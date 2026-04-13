import 'package:flutter/material.dart';
import '../services/api_cuidador.dart';
import 'planos_cuidador_page.dart';
import 'detalhe_vaga_cuidador_page.dart';

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
                await _loadPlano();
              },
              child: const Text('Ver planos'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verDetalhes(Map<String, dynamic> vaga) async {
    final atualizou = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalheVagaCuidadorPage(
          vaga: vaga,
          planoAtual: _planoAtual,
          usosPlano: _usosPlano,
          limitePlano: _limitePlano,
        ),
      ),
    );

    if (atualizou == true) {
      await _recarregarTudo();
    } else {
      await _loadPlano();
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

    String formatar(String valor) {
      if (valor.isEmpty) return '';
      return valor.length >= 5 ? valor.substring(0, 5) : valor;
    }

    final inicioFormatado = formatar(inicio);
    final fimFormatado = formatar(fim);

    if (inicioFormatado.isEmpty && fimFormatado.isEmpty) return '-';
    if (fimFormatado.isEmpty) return inicioFormatado;
    if (inicioFormatado.isEmpty) return fimFormatado;

    return '$inicioFormatado às $fimFormatado';
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