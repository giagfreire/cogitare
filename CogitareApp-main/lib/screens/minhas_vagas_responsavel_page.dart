import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/servico_autenticacao.dart';

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

  @override
  void initState() {
    super.initState();
    fetchVagas();
  }

  Future<void> fetchVagas() async {
    setState(() => isLoading = true);
    try {
   final token = await ServicoAutenticacao.getToken();
   if (token != null && token.isNotEmpty) {
   ServicoApi.setToken(token);
}
final response = await ServicoApi.get('/api/responsavel/vagas/minhas');
      if (response != null && response['success'] == true) {
        vagas = response['data'] ?? [];
      } else {
        vagas = [];
      }
    } catch (e) {
      vagas = [];
    }

    setState(() => isLoading = false);
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
      return "${data.day}/${data.month}/${data.year}";
    } catch (_) {
      return valor.toString();
    }
  }

  Future<void> excluirVaga(int idVaga) async {
    await ServicoApi.delete('/api/responsavel/vagas/$idVaga');
    fetchVagas();
  }

  Future<void> alterarStatus(int idVaga, bool aberta) async {
    await ServicoApi.put(
      '/api/responsavel/vagas/$idVaga/status',
      {'status': aberta ? 'Encerrada' : 'Aberta'},
    );
    fetchVagas();
  }

  Future<void> verInteressados(int idVaga) async {
    final response =
        await ServicoApi.get('/api/responsavel/vagas/$idVaga/interessados');

    if (!mounted) return;

    final lista = response['data'] ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Interessados'),
        content: lista.isEmpty
            ? const Text('Nenhum interessado ainda')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final c = lista[i];
                    return ListTile(
                      title: Text(c['Nome'] ?? ''),
                      subtitle: Text(c['Telefone'] ?? ''),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget cardVaga(Map<String, dynamic> v) {
    final status = v['Status'] ?? 'Aberta';
    final aberta = status.toLowerCase() == 'aberta';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// titulo + status
          Row(
            children: [
              Expanded(
                child: Text(
                  v['Titulo'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

          Text(v['Descricao'] ?? ''),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.location_on, size: 18),
              const SizedBox(width: 5),
              Text(v['Cidade'] ?? ''),
            ],
          ),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 5),
              Text(formatarData(v['DataServico'])),
            ],
          ),

          Row(
            children: [
              const Icon(Icons.attach_money, size: 18),
              const SizedBox(width: 5),
              Text("R\$ ${v['Valor']}"),
            ],
          ),

          const SizedBox(height: 12),

          /// ações
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => alterarStatus(v['IdVaga'], aberta),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aberta ? Colors.red : Colors.green,
                ),
                child: Text(aberta ? 'Encerrar' : 'Reabrir'),
              ),
              ElevatedButton(
                onPressed: () => verInteressados(v['IdVaga']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: roxo,
                ),
                child: const Text('Interessados'),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => excluirVaga(v['IdVaga']),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Vagas'),
        backgroundColor: roxo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : vagas.isEmpty
              ? const Center(child: Text('Nenhuma vaga ainda'))
              : RefreshIndicator(
                  onRefresh: fetchVagas,
                  child: ListView.builder(
                    itemCount: vagas.length,
                    itemBuilder: (_, i) =>
                        cardVaga(Map<String, dynamic>.from(vagas[i])),
                  ),
                ),
    );
  }
}