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

  String _planoAtual = 'Básico';
  int _usosPlano = 0;
  int _limitePlano = 0;

  bool _isLoadingPlano = true;
  bool _isLoadingVagas = true;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

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

          _planoAtual = (data['PlanoAtual'] ?? 'Básico').toString();
          _usosPlano = int.tryParse('${data['UsosPlano'] ?? 0}') ?? 0;
          _limitePlano = int.tryParse('${data['LimitePlano'] ?? 0}') ?? 0;

          if (_limitePlano <= 0) {
            _limitePlano =
                _planoAtual.toLowerCase() == 'premium' ? 20 : 5;
          }
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
        if (response is List) {
          vagas = response.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          vagas = [];
        }
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

  bool get _bloqueadoPorPlano {
    return _limitePlano > 0 && _usosPlano >= _limitePlano;
  }

  int get _contatosRestantes {
    final restante = _limitePlano - _usosPlano;
    return restante < 0 ? 0 : restante;
  }

  double get _usoPercentual {
    if (_limitePlano <= 0) return 0;
    final valor = _usosPlano / _limitePlano;
    if (valor > 1) return 1;
    if (valor < 0) return 0;
    return valor;
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

  void _mostrarUpgrade() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limite do plano atingido'),
          content: Text(
            _planoAtual.toLowerCase() == 'premium'
                ? 'Você atingiu o limite atual do seu plano.'
                : 'Você atingiu o limite do Plano Básico. Faça upgrade para Premium e desbloqueie mais oportunidades.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Agora não'),
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
    if (_bloqueadoPorPlano) {
      Navigator.pop(sheetContext);
      _mostrarUpgrade();
      return;
    }

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

    final numero = double.tryParse(valor.toString()) ?? 0;
    final texto = numero.toStringAsFixed(2).replaceAll('.', ',');

    return 'R\$ $texto';
  }

  Widget _infoLinha(IconData icon, String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: roxo),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $valor',
            style: const TextStyle(fontSize: 15, color: roxo),
          ),
        ),
      ],
    );
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
                      color: _planoAtual.toLowerCase() == 'premium'
                          ? verde
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _planoAtual.toLowerCase() == 'premium'
                            ? verde
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Text(
                      _planoAtual.toLowerCase() == 'premium'
                          ? 'Plano Premium'
                          : 'Plano Básico',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _planoAtual.toLowerCase() == 'premium'
                            ? Colors.black
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
                  color: roxo,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vaga['Descricao']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (_bloqueadoPorPlano)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: rosa.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: rosa.withOpacity(0.20)),
                  ),
                  child: const Text(
                    'Você atingiu o limite do seu plano atual. Faça upgrade para continuar aceitando vagas.',
                    style: TextStyle(
                      fontSize: 14,
                      color: roxo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (!_bloqueadoPorPlano && _limitePlano > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Uso do plano: $_usosPlano de $_limitePlano contatos',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: roxo,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _aceitarVaga(sheetContext, vaga),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bloqueadoPorPlano ? rosa : roxo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _bloqueadoPorPlano
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
                color: roxo,
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
                  side: const BorderSide(color: roxo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ver detalhes',
                  style: TextStyle(
                    color: roxo,
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

  Widget _buildPlanoResumoTopo() {
    final premium = _planoAtual.toLowerCase() == 'premium';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: roxo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
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
                  color: premium ? verde : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: premium
                        ? verde
                        : Colors.white.withOpacity(0.35),
                  ),
                ),
                child: Text(
                  premium ? 'Premium' : 'Básico',
                  style: TextStyle(
                    color: premium ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uso do plano: $_usosPlano de $_limitePlano',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _usoPercentual,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                    premium ? verde : rosa,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 10),
                Text(
                  'Restantes: $_contatosRestantes contato(s)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
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
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Vagas disponíveis'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPlanoResumoTopo(),
                Expanded(
                  child: vagas.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _recarregarTudo,
                          child: ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
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