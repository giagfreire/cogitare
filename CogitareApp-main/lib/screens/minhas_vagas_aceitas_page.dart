import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_cuidador.dart';

class MinhasVagasAceitasPage extends StatefulWidget {
  const MinhasVagasAceitasPage({super.key});

  @override
  State<MinhasVagasAceitasPage> createState() =>
      _MinhasVagasAceitasPageState();
}

class _MinhasVagasAceitasPageState
    extends State<MinhasVagasAceitasPage> {
  List<Map<String, dynamic>> vagas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    setState(() => loading = true);

    final lista = await ApiCuidador.getMinhasVagasAceitas();

    if (!mounted) return;

    setState(() {
      vagas = lista;
      loading = false;
    });
  }

  String _texto(dynamic valor) {
    if (valor == null) return 'Não informado';
    final t = valor.toString().trim();
    if (t.isEmpty) return 'Não informado';
    return t;
  }

  String _data(dynamic valor) {
    if (valor == null) return 'Não informado';
    try {
      final d = DateTime.parse(valor.toString());
      return DateFormat('dd/MM/yyyy').format(d);
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

  void _abrirDetalhes(Map<String, dynamic> vaga) {
    final status = _texto(vaga['Status']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              Text(
                _texto(vaga['Titulo']),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text('Descrição: ${_texto(vaga['Descricao'])}'),
              const SizedBox(height: 8),
              Text('Cidade: ${_texto(vaga['Cidade'])}'),
              const SizedBox(height: 8),
              Text('Data: ${_data(vaga['DataServico'])}'),
              const SizedBox(height: 8),
              Text(
                'Horário: ${_texto(vaga['HoraInicio'])} às ${_texto(vaga['HoraFim'])}',
              ),
              const SizedBox(height: 8),
              Text('Valor: R\$ ${_texto(vaga['Valor'])}'),
              const SizedBox(height: 8),
              Text('Status: $status'),

              const Divider(height: 24),

              const Text(
                'Responsável',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Nome: ${_texto(vaga['NomeResponsavel'])}'),
              Text('Email: ${_texto(vaga['EmailResponsavel'])}'),
              Text('Telefone: ${_texto(vaga['TelefoneResponsavel'])}'),

              if (vaga['DataAceite'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Você aceitou em: ${_data(vaga['DataAceite'])}',
                ),
              ],
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
              ? const Center(
                  child: Text('Você ainda não aceitou nenhuma vaga'),
                )
              : RefreshIndicator(
                  onRefresh: _carregarVagas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vagas.length,
                    itemBuilder: (context, index) {
                      final vaga = vagas[index];
                      final status = _texto(vaga['Status']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            _texto(vaga['Titulo']),
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
                                Text('Cidade: ${_texto(vaga['Cidade'])}'),
                                const SizedBox(height: 4),
                                Text('Data: ${_data(vaga['DataServico'])}'),
                                const SizedBox(height: 4),
                                Text('Valor: R\$ ${_texto(vaga['Valor'])}'),
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