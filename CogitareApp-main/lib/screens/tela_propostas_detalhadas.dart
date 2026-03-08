import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelaPropostasDetalhadas extends StatelessWidget {
  static const route = '/propostas-detalhadas';

  const TelaPropostasDetalhadas({super.key});

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

                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/logo_cogitare_horizontal.png",
                          height: 38,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // TÍTULO
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Informações\nda Proposta",
                style: TextStyle(
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF28323C),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CARD DE DETALHES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOPO - FOTO E IDADE
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "João Maria",
                            style: TextStyle(
                              color: Color(0xFF28323C),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          "88 anos",
                          style: TextStyle(
                            color: Color(0xFF495866),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    const Text.rich(
                      TextSpan(
                        text: "Local: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF28323C),
                        ),
                        children: [
                          TextSpan(
                            text: "São Caetano do Sul/SP - Bairro Olímpico",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF495866),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    const Text.rich(
                      TextSpan(
                        text: "Serviço solicitado: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF28323C),
                        ),
                        children: [
                          TextSpan(
                            text: "Cuidado diário de 08:00 às 12:00",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF495866),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    const Text.rich(
                      TextSpan(
                        text: "Data do atendimento: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF28323C),
                        ),
                        children: [
                          TextSpan(
                            text: "De 22/08 a 27/08 (1 semana)",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF495866),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    const Text.rich(
                      TextSpan(
                        text: "Valor total: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF28323C),
                        ),
                        children: [
                          TextSpan(
                            text: "R\$ 400,00",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF495866),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Text(
                          "Status da proposta:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF28323C),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF495866),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Pendente",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // BOTÕES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      child: const Text(
                        "Recusar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF495866),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      child: const Text(
                        "Aceitar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
