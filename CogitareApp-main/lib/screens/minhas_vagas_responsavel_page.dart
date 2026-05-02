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
      final data = response['data'];

      if (!mounted) return;

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
      _mostrarSnack('Erro ao carregar vagas: $e', cor: Colors.red);
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

  bool _vagaAberta(Map<String, dynamic> vaga) {
    final status = _texto(vaga['Status'], fallback: 'Aberta').toLowerCase();
    return status == 'aberta';
  }

  bool _vagaInterrompida(Map<String, dynamic> vaga) {
    final status = _texto(vaga['Status'], fallback: '').toLowerCase();
    return status == 'interrompida' || status == 'pausada';
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
      _mostrarSnack('Erro ao excluir vaga: $e', cor: Colors.red);
    }
  }

  Future<void> alterarStatus(int idVaga, String novoStatus) async {
    try {
      await _prepararToken();

      final response = await ServicoApi.put(
        '/api/responsavel/vaga/$idVaga/status',
        {'status': novoStatus},
      );

      if (!mounted) return;

      if (response['success'] == true) {
        _mostrarSnack(
          novoStatus == 'Aberta'
              ? 'Vaga reaberta com sucesso.'
              : 'Vaga interrompida com sucesso.',
        );

        await fetchVagas();
      } else {
        _mostrarSnack(
          response['message'] ?? 'Erro ao alterar vaga.',
          cor: Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarSnack('Erro ao alterar vaga: $e', cor: Colors.red);
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
    final idVaga = _toInt(v['IdVaga']);

    final titulo = _texto(v['Titulo'], fallback: 'Vaga sem título');
    final descricao = _texto(v['Descricao'], fallback: 'Sem descrição.');
    final nomeIdoso = _texto(v['NomeIdoso'], fallback: 'Não informado');

    final cidade = _texto(v['Cidade']);
    final bairro = _texto(v['Bairro']);
    final rua = _texto(v['Rua']);
    final cep = _texto(v['Cep']);
    final whatsapp = _whatsappVaga(v);

    final aberta = _vagaAberta(v);
    final interrompida = _vagaInterrompida(v);

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
          initialChildSize: 0.76,
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
                Text(
                  titulo,
                  style: const TextStyle(
                    color: roxo,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _secaoDetalhes(
                  titulo: 'Informações da vaga',
                  children: [
                    _linhaDetalhe(Icons.elderly_outlined, 'Idoso: $nomeIdoso'),
                    _linhaDetalhe(Icons.description_outlined, descricao),
                    _linhaDetalhe(
                      Icons.location_on_outlined,
                      [
                        if (rua != '-') rua,
                        if (bairro != '-') bairro,
                        if (cidade != '-') cidade,
                        if (cep != '-') 'CEP $cep',
                      ].join(' - '),
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
                      'Esse WhatsApp aparece para o cuidador depois que ele visualiza a vaga e consome 1 uso do plano.',
                      style: TextStyle(
                        color: roxo.withOpacity(0.65),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _botaoAcao(
                  icon: Icons.edit_outlined,
                  texto: 'Editar vaga',
                  cor: rosa,
                  onPressed: () {
                    Navigator.pop(context);
                    abrirEditarVaga(v);
                  },
                ),
                if (aberta)
                  _botaoAcao(
                    icon: Icons.pause_circle_outline,
                    texto: 'Interromper vaga',
                    cor: Colors.orange.shade700,
                    onPressed: () {
                      Navigator.pop(context);
                      alterarStatus(idVaga, 'Interrompida');
                    },
                  ),
                if (interrompida)
                  _botaoAcao(
                    icon: Icons.lock_open_outlined,
                    texto: 'Reabrir vaga',
                    cor: Colors.green,
                    onPressed: () {
                      Navigator.pop(context);
                      alterarStatus(idVaga, 'Aberta');
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
    final titulo = _texto(v['Titulo'], fallback: 'Vaga sem título');
    final nomeIdoso = _texto(v['NomeIdoso'], fallback: 'Não informado');
    final cidade = _texto(v['Cidade']);
    final bairro = _texto(v['Bairro']);
    final whatsapp = _whatsappVaga(v);

    final aberta = _vagaAberta(v);
    final interrompida = _vagaInterrompida(v);

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
            Text(
              titulo,
              style: const TextStyle(
                color: roxo,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
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
              Icons.chat_outlined,
              'WhatsApp da vaga: $whatsapp',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => abrirEditarVaga(v),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rosa,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (aberta)
                  ElevatedButton.icon(
                    onPressed: () {
                      alterarStatus(_toInt(v['IdVaga']), 'Interrompida');
                    },
                    icon: const Icon(Icons.pause_circle_outline, size: 18),
                    label: const Text('Interromper'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (interrompida)
                  ElevatedButton.icon(
                    onPressed: () {
                      alterarStatus(_toInt(v['IdVaga']), 'Aberta');
                    },
                    icon: const Icon(Icons.lock_open_outlined, size: 18),
                    label: const Text('Reabrir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => excluirVaga(_toInt(v['IdVaga'])),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
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
                  '${vagas.length} vaga(s) publicada(s)',
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