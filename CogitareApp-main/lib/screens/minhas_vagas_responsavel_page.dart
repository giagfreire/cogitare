import 'package:flutter/material.dart';
import '../services/api_responsavel.dart';
import '../services/session_service.dart';

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
    try {
      final idSalvo = await SessionService.getCuidadorId();

      if (idSalvo == null) {
        setState(() {
          vagas = [];
          loading = false;
        });
        return;
      }

      final int idResponsavel = idSalvo;

      final List<Map<String, dynamic>> lista =
          await ApiResponsavel.getVagasDoResponsavel(idResponsavel);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Vagas'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : vagas.isEmpty
              ? const Center(
                  child: Text('Nenhuma vaga cadastrada'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vagas.length,
                  itemBuilder: (context, index) {
                    final vaga = vagas[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _textoCampo(vaga['Titulo']),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Descrição: ${_textoCampo(vaga['Descricao'])}'),
                            Text('Cidade: ${_textoCampo(vaga['Cidade'])}'),
                            Text(
                              'Data do serviço: ${_textoCampo(vaga['DataServico'])}',
                            ),
                            Text(
                              'Horário: ${_textoCampo(vaga['HoraInicio'])} às ${_textoCampo(vaga['HoraFim'])}',
                            ),
                            Text('Valor: R\$ ${_textoCampo(vaga['Valor'])}'),
                            Text('Status: ${_textoCampo(vaga['Status'])}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}