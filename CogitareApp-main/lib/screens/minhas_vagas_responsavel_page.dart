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
  List vagas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVagas();
  }
  Future<void> excluirVaga(int idVaga) async {
  try {
    final response = await ApiClient.delete('/api/responsavel/vaga/$idVaga');

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vaga excluída com sucesso'),
        ),
      );

      fetchVagas();
    } else {
      throw Exception(response['message'] ?? 'Erro ao excluir vaga');
    }
  } catch (e) {
    print('ERRO AO EXCLUIR VAGA: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao excluir vaga: $e'),
      ),
    );
  }
}

  Future<void> fetchVagas() async {
    try {
      final response = await ApiClient.get('/api/responsavel/minhas-vagas');

      if (response['success'] == true) {
        setState(() {
          vagas = response['data'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Erro ao buscar vagas');
      }
    } catch (e) {
      print('ERRO VAGAS RESPONSAVEL: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Aberta':
        return Colors.green;
      case 'Em andamento':
        return Colors.orange;
      case 'Concluída':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void verDetalhesVaga(Map vaga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vaga['Titulo'] ?? 'Sem título'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descrição: ${vaga['Descricao'] ?? 'Não informada'}'),
            const SizedBox(height: 8),
            Text('Cidade: ${vaga['Cidade'] ?? 'Não informada'}'),
            const SizedBox(height: 8),
            Text('Valor: R\$ ${vaga['Valor'] ?? '0'}'),
            const SizedBox(height: 8),
            Text('Data: ${vaga['DataServico'] ?? 'Não informada'}'),
            const SizedBox(height: 8),
            Text('Status: ${vaga['Status'] ?? 'Não informado'}'),
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

  void confirmarExcluirVaga(Map vaga) {
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
              : ListView.builder(
                  itemCount: vagas.length,
                  itemBuilder: (context, index) {
                    final vaga = vagas[index];
                    final status = vaga['Status'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          vaga['Titulo'] ?? 'Sem título',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(vaga['Descricao'] ?? ''),
                            const SizedBox(height: 8),
                            Text('📍 ${vaga['Cidade'] ?? 'Sem cidade'}'),
                            Text('💰 R\$ ${vaga['Valor'] ?? '0'}'),
                            Text('📅 ${vaga['DataServico'] ?? ''}'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    getStatusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              tooltip: 'Ver detalhes',
                              onPressed: () => verDetalhesVaga(vaga),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              tooltip: 'Excluir vaga',
                              onPressed: () => confirmarExcluirVaga(vaga),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}