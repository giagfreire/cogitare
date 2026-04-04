import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_responsavel.dart';

class MinhasVagasResponsavelPage extends StatefulWidget {
  const MinhasVagasResponsavelPage({super.key});

  @override
  State<MinhasVagasResponsavelPage> createState() =>
      _MinhasVagasResponsavelPageState();
}

class _MinhasVagasResponsavelPageState
    extends State<MinhasVagasResponsavelPage> {
  List<Map<String, dynamic>> vagas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    setState(() => loading = true);

    try {
      final lista = await ApiResponsavel.getMinhasVagas();

      if (!mounted) return;

      setState(() {
        vagas = lista;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        vagas = [];
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar vagas: $e')),
      );
    }
  }

  String _textoCampo(dynamic valor) {
    if (valor == null) return 'Não informado';
    final texto = valor.toString().trim();
    if (texto.isEmpty) return 'Não informado';
    return texto;
  }

  String _formatarData(dynamic valor) {
    if (valor == null) return 'Não informado';

    try {
      final data = DateTime.parse(valor.toString());
      return DateFormat('dd/MM/yyyy').format(data);
    } catch (_) {
      return valor.toString();
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Aberta':
        return Colors.green;
      case 'Encerrada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _alterarStatus(Map<String, dynamic> vaga) async {
    final int idVaga = vaga['IdVaga'];
    final String statusAtual = _textoCampo(vaga['Status']);
    final bool estaAberta = statusAtual == 'Aberta';

    final response = estaAberta
        ? await ApiResponsavel.encerrarVaga(idVaga)
        : await ApiResponsavel.reabrirVaga(idVaga);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message'] ?? 'Ação concluída'),
        backgroundColor:
            response['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (response['success'] == true) {
      await _carregarVagas();
    }
  }

  Future<void> _excluirVaga(int idVaga) async {
    final response = await ApiResponsavel.excluirVaga(idVaga);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message'] ?? 'Ação concluída'),
        backgroundColor:
            response['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (response['success'] == true) {
      await _carregarVagas();
    }
  }

  Future<void> _confirmarExclusao(int idVaga) async {
    final confirmado = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await _excluirVaga(idVaga);
    }
  }

  Future<void> _abrirInteressados(int idVaga) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final interessados = await ApiResponsavel.getInteressados(idVaga);

    if (!mounted) return;
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: interessados.isEmpty
              ? const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text('Nenhum cuidador se interessou por esta vaga ainda.'),
                  ),
                )
              : SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Interessados',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: interessados.length,
                          itemBuilder: (context, index) {
                            final item = interessados[index];

                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(_textoCampo(item['Nome'])),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text('Telefone: ${_textoCampo(item['Telefone'])}'),
                                    Text('Email: ${_textoCampo(item['Email'])}'),
                                    Text('Biografia: ${_textoCampo(item['Biografia'])}'),
                                    Text('Valor/Hora: R\$ ${_textoCampo(item['ValorHora'])}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _abrirEdicao(Map<String, dynamic> vaga) async {
    final tituloController =
        TextEditingController(text: _textoCampo(vaga['Titulo']));
    final descricaoController =
        TextEditingController(text: _textoCampo(vaga['Descricao']));
    final cidadeController =
        TextEditingController(text: _textoCampo(vaga['Cidade']));
    final dataController =
        TextEditingController(text: _textoCampo(vaga['DataServico']).split(' ').first);
    final horaInicioController =
        TextEditingController(text: _textoCampo(vaga['HoraInicio']));
    final horaFimController =
        TextEditingController(text: _textoCampo(vaga['HoraFim']));
    final valorController =
        TextEditingController(text: _textoCampo(vaga['Valor']));

    final formKey = GlobalKey<FormState>();

    final salvar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editar vaga',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tituloController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe o título' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe a descrição'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: cidadeController,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe a cidade' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: dataController,
                    decoration: const InputDecoration(
                      labelText: 'Data do serviço',
                      hintText: '2026-04-04',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe a data' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: horaInicioController,
                    decoration: const InputDecoration(
                      labelText: 'Hora início',
                      hintText: '08:00:00',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe a hora inicial'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: horaFimController,
                    decoration: const InputDecoration(
                      labelText: 'Hora fim',
                      hintText: '17:00:00',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe a hora final' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: valorController,
                    decoration: const InputDecoration(labelText: 'Valor'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe o valor' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Salvar alterações'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (salvar != true) return;

    final valor = double.tryParse(
          valorController.text.replaceAll(',', '.'),
        ) ??
        0.0;

    final response = await ApiResponsavel.editarVaga(
      idVaga: vaga['IdVaga'],
      titulo: tituloController.text.trim(),
      descricao: descricaoController.text.trim(),
      cidade: cidadeController.text.trim(),
      dataServico: dataController.text.trim(),
      horaInicio: horaInicioController.text.trim(),
      horaFim: horaFimController.text.trim(),
      valor: valor,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message'] ?? 'Ação concluída'),
        backgroundColor:
            response['success'] == true ? Colors.green : Colors.red,
      ),
    );

    if (response['success'] == true) {
      await _carregarVagas();
    }
  }

  void _abrirDetalhes(Map<String, dynamic> vaga) {
    final status = _textoCampo(vaga['Status']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              Text(
                _textoCampo(vaga['Titulo']),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Descrição: ${_textoCampo(vaga['Descricao'])}'),
              const SizedBox(height: 8),
              Text('Cidade: ${_textoCampo(vaga['Cidade'])}'),
              const SizedBox(height: 8),
              Text('Data do serviço: ${_formatarData(vaga['DataServico'])}'),
              const SizedBox(height: 8),
              Text(
                'Horário: ${_textoCampo(vaga['HoraInicio'])} às ${_textoCampo(vaga['HoraFim'])}',
              ),
              const SizedBox(height: 8),
              Text('Valor: R\$ ${_textoCampo(vaga['Valor'])}'),
              const SizedBox(height: 8),
              Text('Status: $status'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrirInteressados(vaga['IdVaga']);
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Ver interessados'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrirEdicao(vaga);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar vaga'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _alterarStatus(vaga);
                  },
                  icon: Icon(
                    status == 'Aberta' ? Icons.pause_circle : Icons.play_circle,
                  ),
                  label: Text(
                    status == 'Aberta' ? 'Encerrar vaga' : 'Reabrir vaga',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmarExclusao(vaga['IdVaga']);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Excluir vaga'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Vagas'),
        actions: [
          IconButton(
            onPressed: _carregarVagas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : vagas.isEmpty
              ? const Center(child: Text('Nenhuma vaga cadastrada'))
              : RefreshIndicator(
                  onRefresh: _carregarVagas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vagas.length,
                    itemBuilder: (context, index) {
                      final vaga = vagas[index];
                      final status = _textoCampo(vaga['Status']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            _textoCampo(vaga['Titulo']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cidade: ${_textoCampo(vaga['Cidade'])}'),
                                const SizedBox(height: 4),
                                Text(
                                  'Data: ${_formatarData(vaga['DataServico'])}',
                                ),
                                const SizedBox(height: 4),
                                Text('Valor: R\$ ${_textoCampo(vaga['Valor'])}'),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => _abrirDetalhes(vaga),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}