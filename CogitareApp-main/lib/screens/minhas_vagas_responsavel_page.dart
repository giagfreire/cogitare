import 'package:flutter/material.dart';
import '../services/api_client.dart';

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

  @override
  void initState() {
    super.initState();
    fetchVagas();
  }

  Future<void> fetchVagas() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get('/api/responsavel/vagas/minhas');

      print('RESPOSTA MINHAS VAGAS RESPONSAVEL: $response');

      if (response != null && response['success'] == true) {
        setState(() {
          vagas = response['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          vagas = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('ERRO AO BUSCAR MINHAS VAGAS: $e');
      setState(() {
        vagas = [];
        isLoading = false;
      });
    }
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

  String formatarData(dynamic valor) {
    if (valor == null) return 'Não informada';

    final texto = valor.toString();

    try {
      final data = DateTime.parse(texto);
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final ano = data.year.toString();
      return '$dia/$mes/$ano';
    } catch (_) {
      return texto.split('T').first;
    }
  }

  String formatarHora(dynamic valor) {
    if (valor == null) return 'Não informada';

    final texto = valor.toString();

    if (texto.contains(':')) {
      final partes = texto.split(':');
      if (partes.length >= 2) {
        return '${partes[0]}:${partes[1]}';
      }
    }

    return texto;
  }

  Future<void> atualizarVaga({
    required int idVaga,
    required String titulo,
    required String descricao,
    required String cidade,
    required String dataServico,
    required String horaInicio,
    required String horaFim,
    required String valor,
  }) async {
    try {
      final response = await ApiClient.put(
        '/api/responsavel/vagas/$idVaga',
        {
          'titulo': titulo,
          'descricao': descricao,
          'cidade': cidade,
          'dataServico': dataServico,
          'horaInicio': horaInicio,
          'horaFim': horaFim,
          'valor': double.tryParse(valor.replaceAll(',', '.')) ?? 0,
        },
      );

      print('RESPOSTA ATUALIZAR VAGA: $response');

      if (response != null && response['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaga atualizada com sucesso'),
          ),
        );

        fetchVagas();
      } else {
        throw Exception(response?['message'] ?? 'Erro ao atualizar vaga');
      }
    } catch (e) {
      print('ERRO AO ATUALIZAR VAGA: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar vaga: $e'),
        ),
      );
    }
  }

  Future<void> excluirVaga(int idVaga) async {
    try {
      final response = await ApiClient.delete('/api/responsavel/vagas/$idVaga');

      print('RESPOSTA EXCLUIR VAGA: $response');

      if (response != null && response['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaga excluída com sucesso'),
          ),
        );

        fetchVagas();
      } else {
        throw Exception(response?['message'] ?? 'Erro ao excluir vaga');
      }
    } catch (e) {
      print('ERRO AO EXCLUIR VAGA: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir vaga: $e'),
        ),
      );
    }
  }

  void verDetalhesVaga(Map<String, dynamic> vaga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vaga['Titulo'] ?? 'Sem título'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descrição: ${vaga['Descricao'] ?? 'Não informada'}'),
              const SizedBox(height: 8),
              Text('Cidade: ${vaga['Cidade'] ?? 'Não informada'}'),
              const SizedBox(height: 8),
              Text('Data: ${formatarData(vaga['DataServico'])}'),
              const SizedBox(height: 8),
              Text('Hora início: ${formatarHora(vaga['HoraInicio'])}'),
              const SizedBox(height: 8),
              Text('Hora fim: ${formatarHora(vaga['HoraFim'])}'),
              const SizedBox(height: 8),
              Text('Valor: R\$ ${vaga['Valor'] ?? '0'}'),
              const SizedBox(height: 8),
              Text('Status: ${vaga['Status'] ?? 'Não informado'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void abrirEditarVaga(Map<String, dynamic> vaga) {
    final tituloController =
        TextEditingController(text: vaga['Titulo']?.toString() ?? '');
    final descricaoController =
        TextEditingController(text: vaga['Descricao']?.toString() ?? '');
    final cidadeController =
        TextEditingController(text: vaga['Cidade']?.toString() ?? '');
    final dataController = TextEditingController(
      text: vaga['DataServico']?.toString().split('T').first ?? '',
    );
    final horaInicioController = TextEditingController(
      text: formatarHora(vaga['HoraInicio']),
    );
    final horaFimController = TextEditingController(
      text: formatarHora(vaga['HoraFim']),
    );
    final valorController =
        TextEditingController(text: vaga['Valor']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar vaga'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
              TextField(
                controller: cidadeController,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
              TextField(
                controller: dataController,
                decoration:
                    const InputDecoration(labelText: 'Data (AAAA-MM-DD)'),
              ),
              TextField(
                controller: horaInicioController,
                decoration:
                    const InputDecoration(labelText: 'Hora início (HH:MM)'),
              ),
              TextField(
                controller: horaFimController,
                decoration:
                    const InputDecoration(labelText: 'Hora fim (HH:MM)'),
              ),
              TextField(
                controller: valorController,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await atualizarVaga(
                idVaga: vaga['IdVaga'],
                titulo: tituloController.text.trim(),
                descricao: descricaoController.text.trim(),
                cidade: cidadeController.text.trim(),
                dataServico: dataController.text.trim(),
                horaInicio: horaInicioController.text.trim(),
                horaFim: horaFimController.text.trim(),
                valor: valorController.text.trim(),
              );
            },
            child: const Text(
              'Salvar',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void confirmarExcluirVaga(Map<String, dynamic> vaga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir vaga'),
        content: Text(
          'Tem certeza que deseja excluir a vaga "${vaga['Titulo'] ?? 'Sem título'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              excluirVaga(vaga['IdVaga']);
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCardVaga(Map<String, dynamic> vaga) {
    final status = (vaga['Status'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vaga['Titulo'] ?? 'Sem título',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(vaga['Descricao'] ?? ''),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(vaga['Cidade'] ?? 'Sem cidade'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(formatarData(vaga['DataServico'])),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('R\$ ${vaga['Valor'] ?? '0'}'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: getStatusColor(status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.isEmpty ? 'Sem status' : status,
                style: TextStyle(
                  color: getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Ver detalhes',
                  onPressed: () => verDetalhesVaga(vaga),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar vaga',
                  onPressed: () => abrirEditarVaga(vaga),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Excluir vaga',
                  onPressed: () => confirmarExcluirVaga(vaga),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Vagas'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : vagas.isEmpty
              ? const Center(child: Text('Nenhuma vaga encontrada'))
              : RefreshIndicator(
                  onRefresh: fetchVagas,
                  child: ListView.builder(
                    itemCount: vagas.length,
                    itemBuilder: (context, index) {
                      final vaga = Map<String, dynamic>.from(vagas[index]);
                      return buildCardVaga(vaga);
                    },
                  ),
                ),
    );
  }
}