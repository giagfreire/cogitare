import 'package:flutter/material.dart';

class TelaHistoricoServicos extends StatelessWidget {
  static const route = '/historico-servicos';

  const TelaHistoricoServicos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios,
                  size: 22, color: Color(0xFF424242)),
            ),
            const Expanded(
              child: Center(
                child: SizedBox(
                  height: 36,
                  child: Image(
                    image: AssetImage(
                        'assets/images/logo_cogitare_horizontal.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Histórico de\nServiços',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: Color(0xFF28323C),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // === LISTA DE SERVIÇOS (simulação de itens) ===
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3, // depois você troca pelo tamanho real da lista
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _HistoricoCard(
                      nome: 'João Maria',
                      servico: 'Cuidado diário',
                      data: '22/09/2025',
                      duracao: '4 horas',
                      status: 'Pago',
                      valor: 'R\$ 400,00',
                      avaliacao: 4.5,
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoricoCard extends StatelessWidget {
  final String nome;
  final String servico;
  final String data;
  final String duracao;
  final String status;
  final String valor;
  final double avaliacao;

  const _HistoricoCard({
    required this.nome,
    required this.servico,
    required this.data,
    required this.duracao,
    required this.status,
    required this.valor,
    required this.avaliacao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(
                  'assets/images/avatar_placeholder.png',
                ),
              ),
              const SizedBox(width: 10),
              Text(
                nome,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _linha('Serviço:', servico),
          _linha('Data:', data),
          _linha('Duração:', duracao),
          _linha('Status:', status),
          _linha('Valor:', valor),

          const SizedBox(height: 12),

          Row(
            children: [
              const Text(
                'Avaliação:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(width: 6),
              ..._estrelas(avaliacao),
            ],
          )
        ],
      ),
    );
  }

  Widget _linha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label   $valor',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  List<Widget> _estrelas(double nota) {
    List<Widget> icons = [];
    for (var i = 1; i <= 5; i++) {
      if (nota >= i) {
        icons.add(const Icon(Icons.star, color: Colors.amber, size: 20));
      } else if (nota + 0.5 >= i) {
        icons.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
      } else {
        icons.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
      }
    }
    return icons;
  }
}
