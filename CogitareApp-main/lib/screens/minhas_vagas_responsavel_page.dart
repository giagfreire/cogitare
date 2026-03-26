import 'package:flutter/material.dart';
import 'services/api_responsavel.dart';
import 'services/session_service.dart';

class MinhasVagasResponsavelPage extends StatefulWidget {
  const MinhasVagasResponsavelPage({super.key});

  @override
  State<MinhasVagasResponsavelPage> createState() =>
      _MinhasVagasResponsavelPageState();
}

class _MinhasVagasResponsavelPageState
    extends State<MinhasVagasResponsavelPage> {
  List vagas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    final idResponsavel = await SessionService.getResponsavelId();

    if (idResponsavel == null) return;

    final response =
        await ApiResponsavel.getVagasDoResponsavel(idResponsavel);

    if (response['success'] == true) {
      setState(() {
        vagas = response['data'];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildCardVaga(Map vaga) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(vaga['Titulo'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vaga['Cidade'] ?? ''),
            Text('Valor: R\$ ${vaga['Valor']}'),
            Text('Status: ${vaga['Status']}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _mostrarDetalhes(vaga);
        },
      ),
    );
  }

  void _mostrarDetalhes(Map vaga) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(vaga['Titulo']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vaga['Descricao']),
            const SizedBox(height: 10),
            Text('Cidade: ${vaga['Cidade']}'),
            Text('Data: ${vaga['DataServico']}'),
            Text('Hora: ${vaga['HoraInicio']} - ${vaga['HoraFim']}'),
            Text('Valor: R\$ ${vaga['Valor']}'),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas vagas'),
        backgroundColor: const Color(0xFF35064E),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : vagas.isEmpty
              ? const Center(child: Text('Nenhuma vaga criada ainda'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vagas.length,
                  itemBuilder: (context, index) {
                    return _buildCardVaga(vagas[index]);
                  },
                ),
    );
  }
}