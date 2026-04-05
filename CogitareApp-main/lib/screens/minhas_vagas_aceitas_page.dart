import 'package:flutter/material.dart';
import '../services/api_cuidador.dart';

class MinhasVagasCuidadorPage extends StatefulWidget {
  const MinhasVagasCuidadorPage({super.key});

  @override
  State<MinhasVagasCuidadorPage> createState() =>
      _MinhasVagasCuidadorPageState();
}

class _MinhasVagasCuidadorPageState
    extends State<MinhasVagasCuidadorPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _vagas = [];

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vagas = await ApiCuidador.getMinhasVagasAceitas();

      setState(() {
        _vagas = vagas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar vagas';
        _isLoading = false;
      });
    }
  }

  String _t(dynamic v) =>
      (v == null || v.toString().trim().isEmpty) ? 'Não informado' : v.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas vagas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _vagas.isEmpty
                  ? const Center(
                      child: Text('Você ainda não aceitou nenhuma vaga'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vagas.length,
                      itemBuilder: (context, index) {
                        final vaga = _vagas[index];

                        return Card(
                          child: ListTile(
                            title: Text(_t(vaga['Titulo'])),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cidade: ${_t(vaga['Cidade'])}'),
                                Text('Data: ${_t(vaga['DataServico'])}'),
                                Text('Valor: R\$ ${_t(vaga['Valor'])}'),
                                Text('Responsável: ${_t(vaga['NomeResponsavel'] ?? vaga['Nome'])}'),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(_t(vaga['Titulo'])),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Descrição: ${_t(vaga['Descricao'])}'),
                                      const SizedBox(height: 10),
                                      Text('Telefone: ${_t(vaga['TelefoneResponsavel'] ?? vaga['Telefone'])}'),
                                      Text('Email: ${_t(vaga['EmailResponsavel'] ?? vaga['Email'])}'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}