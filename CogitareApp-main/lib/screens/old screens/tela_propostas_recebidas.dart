import 'package:cogitare_app/screens/tela_propostas_detalhadas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelaPropostasRecebidas extends StatelessWidget {
  static const route = '/propostas-cuidadores';

  const TelaPropostasRecebidas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // LOGO CENTRALIZADA
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/logo_cogitare_horizontal.png",
                          height: 40,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // balanceamento visual
                ],
              ),
            ),

            const SizedBox(height: 8),

            // TÍTULO
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Propostas\npara Você",
                style: TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF28323C),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // LISTA DE PROPOSTAS
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPropostaCard(
                    context,
                    nome: "Carlos Silva",
                    descricao: "Precisa de cuidados diurnos para seu pai",
                    data: "12/11/2025",
                  ),
                  _buildPropostaCard(
                    context,
                    nome: "Maria Souza",
                    descricao: "Busca cuidador para idosa com Alzheimer leve",
                    data: "13/11/2025",
                  ),
                  _buildPropostaCard(
                    context,
                    nome: "Ana Oliveira",
                    descricao: "Assistência noturna para idosa independente",
                    data: "14/11/2025",
                  ),
                ],
              ),
            ),

            // LINHA FINAL SUTIL
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 1,
                color: const Color(0xFFD9D9D9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Agora o método recebe o [BuildContext]
  Widget _buildPropostaCard(
    BuildContext context, {
    required String nome,
    required String descricao,
    required String data,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ÍCONE DE USUÁRIO
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF495866),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          // INFORMAÇÕES DA PROPOSTA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    color: Color(0xFF28323C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: Color(0xFF495866),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Data: $data",
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // BOTÕES DE AÇÃO
          Column(
            children: [
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 116, 97, 96),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, TelaPropostasDetalhadas.route);
                },
                child: const Text(
                  "Detalhes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
