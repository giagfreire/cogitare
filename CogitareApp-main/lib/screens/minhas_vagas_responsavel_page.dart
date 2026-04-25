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
    setState(() => isLoading = true);

    try {
      await _prepararToken();

      final response = await ServicoApi.get('/api/responsavel/minhas-vagas');

      if (!mounted) return;

      setState(() {
        vagas = response['success'] == true ? response['data'] ?? [] : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => vagas = []);
      _mostrarSnack('Erro ao carregar vagas: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _mostrarSnack(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aberta':
        return Colors.green;
      case 'encerrada':
        return Colors.red;
      case 'concluida':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String formatarData(dynamic valor) {
    if (valor == null) return '-';
    try {
      final data = DateTime.parse(valor.toString());
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    } catch (_) {
      return valor.toString();
    }
  }

  String formatarHora(dynamic valor) {
    if (valor == null) return '-';
    final texto = valor.toString();
    if (texto.length >= 5) return texto.substring(0, 5);
    return texto;
  }

  Future<void> excluirVaga(int idVaga) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir vaga'),
        content: const Text('Tem certeza que deseja excluir esta vaga?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: rosa),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _prepararToken();
      final response = await ServicoApi.delete('/api/responsavel/vaga/$idVaga');

      if (response['success'] == true) {
        _mostrarSnack('Vaga excluída com sucesso.');
        fetchVagas();
      } else {
        _mostrarSnack(response['message'] ?? 'Erro ao excluir vaga.');
      }
    } catch (e) {
      _mostrarSnack('Erro ao excluir vaga: $e');
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

      if (response['success'] == true) {
        _mostrarSnack(
          novoStatus == 'Aberta' ? 'Vaga reaberta.' : 'Vaga encerrada.',
        );
        fetchVagas();
      } else {
        _mostrarSnack(response['message'] ?? 'Erro ao alterar status.');
      }
    } catch (e) {
      _mostrarSnack('Erro ao alterar status: $e');
    }
  }

  Future<void> verInteressados(int idVaga) async {
    try {
      await _prepararToken();

      final response =
          await ServicoApi.get('/api/responsavel/vaga/$idVaga/interessados');

      if (!mounted) return;

      final lista = response['data'] ?? [];

      showModalBottomSheet(
        context: context,
        backgroundColor: fundo,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.all(18),
            child: lista.isEmpty
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 44, color: roxo),
                      SizedBox(height: 10),
                      Text(
                        'Nenhum interessado ainda',
                        style: TextStyle(
                          color: roxo,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final c = Map<String, dynamic>.from(lista[i]);
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: roxo,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(c['Nome']?.toString() ?? 'Cuidador'),
                          subtitle: Text(
                            '${c['Telefone']?.toString() ?? 'Telefone não informado'}\n${c['Email']?.toString() ?? ''}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          );
        },
      );
    } catch (e) {
      _mostrarSnack('Erro ao buscar interessados: $e');
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
      fetchVagas();
    }
  }

  void abrirDetalhes(Map<String, dynamic> v) {
    final status = v['Status']?.toString() ?? 'Aberta';
    final aberta = status.toLowerCase() == 'aberta';
    final idVaga = int.tryParse(v['IdVaga'].toString()) ?? 0;
    final totalInteressados =
        int.tryParse((v['TotalInteressados'] ?? 0).toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: fundo,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v['Titulo']?.toString() ?? 'Vaga',
                  style: const TextStyle(
                    color: roxo,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Idoso: ${v['NomeIdoso']?.toString() ?? 'Não informado'}',
                  style: const TextStyle(color: roxo),
                ),
                const SizedBox(height: 12),
                _linhaDetalhe(Icons.location_on, '${v['Cidade'] ?? ''} - ${v['Bairro'] ?? ''}'),
                _linhaDetalhe(Icons.calendar_today, formatarData(v['DataServico'])),
                _linhaDetalhe(Icons.access_time, '${formatarHora(v['HoraInicio'])} às ${formatarHora(v['HoraFim'])}'),
                _linhaDetalhe(Icons.people, '$totalInteressados interessado(s)'),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      verInteressados(idVaga);
                    },
                    icon: const Icon(Icons.people),
                    label: Text('Ver interessados ($totalInteressados)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roxo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      abrirEditarVaga(v);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar vaga'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rosa,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      alterarStatus(idVaga, aberta);
                    },
                    icon: Icon(aberta ? Icons.lock : Icons.lock_open),
                    label: Text(aberta ? 'Encerrar vaga' : 'Reabrir vaga'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      excluirVaga(idVaga);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Excluir vaga',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _linhaDetalhe(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: roxo, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: roxo),
            ),
          ),
        ],
      ),
    );
  }

  Widget cardVaga(Map<String, dynamic> v) {
    final status = v['Status']?.toString() ?? 'Aberta';
    final totalInteressados =
        int.tryParse((v['TotalInteressados'] ?? 0).toString()) ?? 0;

    return InkWell(
      onTap: () => abrirDetalhes(v),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: roxo.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: roxo.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    v['Titulo']?.toString() ?? 'Vaga sem título',
                    style: const TextStyle(
                      color: roxo,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Idoso: ${v['NomeIdoso']?.toString() ?? 'Não informado'}',
              style: const TextStyle(color: roxo, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _linhaDetalhe(Icons.location_on, v['Cidade']?.toString() ?? '-'),
            _linhaDetalhe(Icons.calendar_today, formatarData(v['DataServico'])),
            _linhaDetalhe(Icons.access_time,
                '${formatarHora(v['HoraInicio'])} às ${formatarHora(v['HoraFim'])}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, color: rosa, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$totalInteressados interessado(s)',
                  style: const TextStyle(
                    color: roxo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 16, color: roxo),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> abrirCriarVaga() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CriarVagaPage(),
      ),
    );

    if (result == true) {
      fetchVagas();
    }
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
            onPressed: fetchVagas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: rosa,
        foregroundColor: Colors.white,
        onPressed: abrirCriarVaga,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: rosa))
          : vagas.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.work_outline, size: 58, color: roxo),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma vaga publicada ainda',
                          style: TextStyle(
                            color: roxo,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: abrirCriarVaga,
                          icon: const Icon(Icons.add),
                          label: const Text('Criar nova vaga'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rosa,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchVagas,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90, top: 8),
                    itemCount: vagas.length,
                    itemBuilder: (_, i) =>
                        cardVaga(Map<String, dynamic>.from(vagas[i])),
                  ),
                ),
    );
  }
}