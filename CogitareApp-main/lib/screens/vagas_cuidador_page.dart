import 'package:flutter/material.dart';
import '../services/api_cuidador.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'planos_cuidador_page.dart';

class VagasCuidadorPage extends StatefulWidget {
  const VagasCuidadorPage({super.key});

  @override
  State<VagasCuidadorPage> createState() => _VagasCuidadorPageState();
}

class _VagasCuidadorPageState extends State<VagasCuidadorPage> {
  List<Map<String, dynamic>> vagas = [];

  String _planoAtual = 'Basico';
  bool _isLoadingPlano = true;
  bool _isLoadingVagas = true;

  int _usosPlano = 0;
  int _limitePlano = 5;
  int _restantePlano = 5;

  @override
  void initState() {
    super.initState();
    _loadPlano();
    _loadStatusPlano();
    _loadVagas();
  }

  Future<void> _loadPlano() async {
    try {
      final cuidadorId = await SessionService.getCuidadorId();

      if (cuidadorId == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingPlano = false;
        });
        return;
      }

      final response = await ServicoApi.get('/api/cuidador/$cuidadorId/plano');

      if (!mounted) return;

      setState(() {
        if (response['success'] == true && response['data'] != null) {
          _planoAtual = response['data']['PlanoAtual'] ?? 'Basico';
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

  Future<void> _loadStatusPlano() async {
    try {
      final cuidadorId = await SessionService.getCuidadorId();

      if (cuidadorId == null) return;

      final response = await ApiCuidador.getStatusPlano(cuidadorId);

      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        setState(() {
          _planoAtual = data['planoAtual'] ?? 'Basico';
          _usosPlano = data['usosPlano'] ?? 0;
          _limitePlano = data['limitePlano'] ?? 5;
          _restantePlano = data['restante'] ?? 0;
        });
      }
    } catch (e) {
      // pode deixar vazio por enquanto
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

  void _mostrarUpgrade() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upgrade de plano'),
          content: const Text(
            'Seu plano atual atingiu o limite ou não permite continuar. Veja os planos para desbloquear mais vagas.',
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
                _loadStatusPlano();
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
    final cuidadorId = await SessionService.getCuidadorId();

    if (cuidadorId == null) {
      if (!mounted) return;
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão inválida. Faça login novamente.'),
        ),
      );
      return;
    }

    final idVaga = vaga['IdVaga'];
    if (idVaga == null) {
      if (!mounted) return;
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vaga inválida.'),
        ),
      );
      return;
    }

    final resultado = await ApiCuidador.aceitarVaga(
      idVaga: idVaga is int ? idVaga : int.tryParse(idVaga.toString()) ?? 0,
      idCuidador: cuidadorId,
    );

    if (!mounted) return;

    Navigator.pop(sheetContext);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['message'] ?? 'Resposta recebida'),
      ),
    );

    if (resultado['success'] == true) {
      await _loadPlano();
      await _loadStatusPlano();
      await _loadVagas();
    } else {
      final mensagem = (resultado['message'] ?? '').toString().toLowerCase();
      if (mensagem.contains('upgrade') ||
          mensagem.contains('limite') ||
          mensagem.contains('plano')) {
        _mostrarUpgrade();
      }
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

    String limparHora(String valor) {
      if (valor.isEmpty) return '';
      return valor.length >= 5 ? valor.substring(0, 5) : valor;
    }

    final inicioFormatado = limparHora(inicio);
    final fimFormatado = limparHora(fim);

    if (inicioFormatado.isEmpty && fimFormatado.isEmpty) return '-';
    if (inicioFormatado.isEmpty) return fimFormatado;
    if (fimFormatado.isEmpty) return inicioFormatado;

    return '$inicioFormatado às $fimFormatado';
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'R\$ 0,00';

    final texto = valor.toString().replaceAll('.', ',');
    return 'R\$ $texto';
  }

  void _verDetalhes(Map<String, dynamic> vaga) {
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
                  child: const Text(
                    'Aceitar vaga',
                    style: TextStyle(
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
      onRefresh: _loadVagas,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vagas.length} vaga(s) encontrada(s) para você',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Usos do plano: $_usosPlano / $_limitePlano • Restantes: $_restantePlano',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
                          onRefresh: _loadVagas,
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