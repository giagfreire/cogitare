import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';
import 'criar_vaga_page.dart';

class MinhasVagasResponsavelPage extends StatefulWidget {
  const MinhasVagasResponsavelPage({super.key});

  @override
  State<MinhasVagasResponsavelPage> createState() =>
      _MinhasVagasResponsavelPageState();
}

class _MinhasVagasResponsavelPageState
    extends State<MinhasVagasResponsavelPage> {
  List<dynamic> vagas = [];
  bool isLoading = true;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    fetchVagas();
  }

  Future<void> _prepararToken() async {
    final token = await ServicoAutenticacao.getToken();

    if (token != null && token.isNotEmpty) {
      ServicoApi.setToken(token);
    }
  }

  Future<void> fetchVagas() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      await _prepararToken();

      final response = await ServicoApi.get('/api/responsavel/minhas-vagas');

      debugPrint('RESPOSTA MINHAS VAGAS RESPONSAVEL: $response');

      if (!mounted) return;

      final data = response['data'];

      setState(() {
        if (response['success'] == true && data is List) {
          vagas = data;
        } else {
          vagas = [];
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => vagas = []);

      _mostrarSnack(
        'Erro ao carregar vagas: $e',
        cor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _mostrarSnack(String mensagem, {Color cor = roxo}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
      ),
    );
  }

  int _toInt(dynamic valor) {
    if (valor == null) return 0;
    if (valor is int) return valor;

    return int.tryParse(valor.toString()) ?? 0;
  }

  String _texto(dynamic valor, {String fallback = '-'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _whatsappVaga(Map<String, dynamic> vaga) {
    return _texto(
      vaga['WhatsappContato'] ??
          vaga['WhatsAppContato'] ??
          vaga['WhatsappResponsavel'] ??
          vaga['ContatoWhatsapp'] ??
          vaga['whatsapp'],
      fallback: '-',
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aberta':
        return Colors.green;
      case 'encerrada':
        return Colors.red;
      case 'concluida':
      case 'concluída':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'aberta':
        return Icons.lock_open_outlined;
      case 'encerrada':
        return Icons.lock_outline;
      case 'concluida':
      case 'concluída':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  String formatarData(dynamic valor) {
    if (valor == null) return '-';

    try {
      final data = DateTime.parse(valor.toString());

      return '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/'
          '${data.year}';
    } catch (_) {
      return valor.toString();
    }
  }

  String formatarHora(dynamic valor) {
    if (valor == null) return '-';

    final texto = valor.toString();

    if (texto.length >= 5) {
      return texto.substring(0, 5);
    }

    return texto;
  }

  String formatarValor(dynamic valor) {
    if (valor == null) return 'A combinar';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return valor.toString();

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> excluirVaga(int idVaga) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Excluir vaga',
          style: TextStyle(
            color: roxo,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Tem certeza que deseja excluir esta vaga? Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _prepararToken();

      final response = await ServicoApi.delete('/api/responsavel/vaga/$idVaga');

      if (!mounted) return;

      if (response['success'] == true) {
        _mostrarSnack('Vaga excluída com sucesso.');
        await fetchVagas();
      } else {
        _mostrarSnack(
          response['message'] ?? 'Erro ao excluir vaga.',
          cor: Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarSnack(
        'Erro ao excluir vaga: $e',
        cor: Colors.red,
      );
    }
  }

  Future<void> alterarStatus(int idVaga, bool aberta) async {
    try {
      await _prepararToken();

      final novoStatus = aberta ? 'Encerrada' : 'Aberta';

      final response = await ServicoApi.put(
        '/api/responsavel/vaga/$idVaga/status',
        {'status': novoStatus},
      );

      if (!mounted) return;

      if (response['success'] == true) {
        _mostrarSnack(
          novoStatus == 'Aberta' ? 'Vaga reaberta.' : 'Vaga encerrada.',
        );

        await fetchVagas();
      } else {
        _mostrarSnack(
          response['message'] ?? 'Erro ao alterar status.',
          cor: Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarSnack(
        'Erro ao alterar status: $e',
        cor: Colors.red,
      );
    }
  }

  Future<void> verInteressados(int idVaga) async {
    try {
      await _prepararToken();

      final response =
          await ServicoApi.get('/api/responsavel/vaga/$idVaga/interessados');

      if (!mounted) return;

      final lista = response['data'] is List ? response['data'] : [];

      showModalBottomSheet(
        context: context,
        backgroundColor: fundo,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        builder: (_) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: lista.isEmpty ? 0.35 : 0.68,
            minChildSize: 0.25,
            maxChildSize: 0.92,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                child: lista.isEmpty
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 50,
                            color: roxo,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Nenhum interessado ainda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: roxo,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Quando algum cuidador aceitar esta vaga, ele aparecerá aqui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: lista.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.people, color: roxo),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cuidadores interessados (${lista.length})',
                                    style: const TextStyle(
                                      color: roxo,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final c = Map<String, dynamic>.from(lista[i - 1]);

                          final nome = _texto(
                            c['Nome'] ?? c['nome'],
                            fallback: 'Cuidador',
                          );

                          final telefone = _texto(
                            c['Telefone'] ?? c['telefone'],
                            fallback: 'Telefone não informado',
                          );

                          final email = _texto(
                            c['Email'] ?? c['email'],
                            fallback: '',
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: roxo.withOpacity(0.08),
                              ),
                            ),
child: ListTile(
  contentPadding: const EdgeInsets.all(12),
  leading: const CircleAvatar(
    backgroundColor: roxo,
    child: Icon(
      Icons.person,
      color: Colors.white,
    ),
  ),
  title: Text(
    nome,
    style: const TextStyle(
      color: roxo,
      fontWeight: FontWeight.bold,
    ),
  ),
  subtitle: Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      [
        telefone,
        if (email.isNotEmpty) email,
      ].join('\n'),
    ),
  ),
)
                          );
                        },
                      ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarSnack(
        'Erro ao buscar interessados: $e',
        cor: Colors.red,
      );
    }
  }

  Future<void> abrirEditarVaga(Map<String, dynamic> vaga) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CriarVagaPage(vagaParaEditar: vaga),
      ),
    );

    if (result == true) {
      await fetchVagas();
    }
  }

  Future<void> abrirCriarVaga() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CriarVagaPage(),
      ),
    );

    if (result == true) {
      await fetchVagas();
    } else {
      await fetchVagas();
    }
  }

  void abrirDetalhes(Map<String, dynamic> v) {
    final status = _texto(v['Status'], fallback: 'Aberta');
    final aberta = status.toLowerCase() == 'aberta';
    final idVaga = _toInt(v['IdVaga']);
    final totalInteressados = _toInt(v['TotalInteressados']);

    final titulo = _texto(v['Titulo'], fallback: 'Vaga sem título');
    final descricao = _texto(v['Descricao'], fallback: 'Sem descrição.');
    final nomeIdoso = _texto(v['NomeIdoso'], fallback: 'Não informado');

    final cidade = _texto(v['Cidade']);
    final bairro = _texto(v['Bairro']);
    final rua = _texto(v['Rua']);
    final cep = _texto(v['Cep']);

    final whatsapp = _whatsappVaga(v);
    final valor = formatarValor(v['Valor']);

    showModalBottomSheet(
      context: context,
      backgroundColor: fundo,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          color: roxo,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 16),
                _secaoDetalhes(
                  titulo: 'Informações da vaga',
                  children: [
                    _linhaDetalhe(Icons.elderly_outlined, 'Idoso: $nomeIdoso'),
                    _linhaDetalhe(Icons.description_outlined, descricao),
                    _linhaDetalhe(Icons.attach_money, 'Valor: $valor'),
                    _linhaDetalhe(
                      Icons.location_on_outlined,
                      [
                        if (rua != '-') rua,
                        if (bairro != '-') bairro,
                        if (cidade != '-') cidade,
                        if (cep != '-') 'CEP $cep',
                      ].join(' - '),
                    ),
                    _linhaDetalhe(
                      Icons.calendar_today_outlined,
                      formatarData(v['DataServico']),
                    ),
                    _linhaDetalhe(
                      Icons.access_time_outlined,
                      '${formatarHora(v['HoraInicio'])} às ${formatarHora(v['HoraFim'])}',
                    ),
                  ],
                ),
                _secaoDetalhes(
                  titulo: 'Contato cadastrado para a vaga',
                  children: [
                    _linhaDetalhe(
                      Icons.chat_outlined,
                      'WhatsApp: $whatsapp',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Esse WhatsApp só aparece para o cuidador depois que ele aceita a vaga e consome 1 uso do plano.',
                      style: TextStyle(
                        color: roxo.withOpacity(0.65),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                _secaoDetalhes(
                  titulo: 'Interesses',
                  children: [
                    _linhaDetalhe(
                      Icons.people_outline,
                      '$totalInteressados cuidador(es) interessado(s)',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _botaoAcao(
                  icon: Icons.people,
                  texto: 'Ver interessados ($totalInteressados)',
                  cor: roxo,
                  onPressed: () {
                    Navigator.pop(context);
                    verInteressados(idVaga);
                  },
                ),
                _botaoAcao(
                  icon: Icons.edit_outlined,
                  texto: 'Editar vaga',
                  cor: rosa,
                  onPressed: () {
                    Navigator.pop(context);
                    abrirEditarVaga(v);
                  },
                ),
                _botaoAcao(
                  icon: aberta ? Icons.lock_outline : Icons.lock_open_outlined,
                  texto: aberta ? 'Encerrar vaga' : 'Reabrir vaga',
                  cor: aberta ? Colors.orange.shade700 : Colors.green,
                  onPressed: () {
                    Navigator.pop(context);
                    alterarStatus(idVaga, aberta);
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      excluirVaga(idVaga);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Excluir vaga',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _secaoDetalhes({
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roxo.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: roxo,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _botaoAcao({
    required IconData icon,
    required String texto,
    required Color cor,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            texto,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final cor = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(status),
            size: 15,
            color: cor,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaDetalhe(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: roxo, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: roxo,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget cardVaga(Map<String, dynamic> v) {
    final status = _texto(v['Status'], fallback: 'Aberta');
    final totalInteressados = _toInt(v['TotalInteressados']);

    final titulo = _texto(v['Titulo'], fallback: 'Vaga sem título');
    final nomeIdoso = _texto(v['NomeIdoso'], fallback: 'Não informado');
    final cidade = _texto(v['Cidade']);
    final bairro = _texto(v['Bairro']);
    final whatsapp = _whatsappVaga(v);

    return InkWell(
      onTap: () => abrirDetalhes(v),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: roxo.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: roxo.withOpacity(0.045),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                      color: roxo,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            _linhaDetalhe(
              Icons.elderly_outlined,
              'Idoso: $nomeIdoso',
            ),
            _linhaDetalhe(
              Icons.location_on_outlined,
              [
                if (bairro != '-') bairro,
                if (cidade != '-') cidade,
              ].join(' - '),
            ),
            _linhaDetalhe(
              Icons.calendar_today_outlined,
              formatarData(v['DataServico']),
            ),
            _linhaDetalhe(
              Icons.access_time_outlined,
              '${formatarHora(v['HoraInicio'])} às ${formatarHora(v['HoraFim'])}',
            ),
            _linhaDetalhe(
              Icons.chat_outlined,
              'WhatsApp da vaga: $whatsapp',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rosa.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, color: rosa, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$totalInteressados interessado(s)',
                      style: const TextStyle(
                        color: roxo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    'Ver detalhes',
                    style: TextStyle(
                      color: roxo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: roxo,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: rosa.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline,
                size: 58,
                color: roxo,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhuma vaga publicada ainda',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: roxo,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie uma vaga para encontrar cuidadores disponíveis para o idoso cadastrado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: abrirCriarVaga,
              icon: const Icon(Icons.add),
              label: const Text('Criar nova vaga'),
              style: ElevatedButton.styleFrom(
                backgroundColor: rosa,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerLista() {
    final abertas = vagas.where((vaga) {
      final v = Map<String, dynamic>.from(vaga);
      return _texto(v['Status'], fallback: 'Aberta').toLowerCase() == 'aberta';
    }).length;

    final encerradas = vagas.length - abertas;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [roxo, rosa],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.work_history_outlined,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Minhas vagas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${vagas.length} publicada(s) • $abertas aberta(s) • $encerradas encerrada(s)',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: rosa),
      );
    }

    if (vagas.isEmpty) {
      return _emptyState();
    }

    return RefreshIndicator(
      onRefresh: fetchVagas,
      color: rosa,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: vagas.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _headerLista();

          final vaga = Map<String, dynamic>.from(vagas[i - 1]);
          return cardVaga(vaga);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Minhas vagas'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: fetchVagas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: rosa,
        foregroundColor: Colors.white,
        onPressed: abrirCriarVaga,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nova vaga',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _body(),
    );
  }
}