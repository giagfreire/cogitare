import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tela_cadastro_cuidador.dart';
import 'tela_cadastro_responsavel.dart';
import '../utils/navigation_utils.dart';
import '../services/servico_autenticacao.dart';

class SelecaoPapel extends StatelessWidget {
  static const route = '/selecao-papel';
  const SelecaoPapel({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header com logo horizontal e botão voltar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Botão voltar
                  IconButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await NavigationUtils.navigateToRoleSelection(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF424242),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Logo horizontal COGITARE
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: Image.asset(
                        'assets/images/logo_cogitare_horizontal.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ilustração da idosa
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: Image.asset(
                      'assets/images/idosa01.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Card de seleção
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Texto "Eu sou..."
                        const Text(
                          'Eu sou...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Botão CUIDADOR
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              // Marcar que está no processo de cadastro
                              await ServicoAutenticacao.markInSignupProcess();
                              Navigator.pushNamed(
                                  context, TelaCadastroCuidador.route);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF424242),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'CUIDADOR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Texto "ou"
                        const Text(
                          'ou',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF424242),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botão RESPONSÁVEL
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              // Marcar que está no processo de cadastro
                              await ServicoAutenticacao.markInSignupProcess();
                              Navigator.pushNamed(
                                  context, TelaCadastroResponsavel.route);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF424242),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'RESPONSÁVEL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
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

            // Home indicator (simulado)
            Container(
              margin: EdgeInsets.only(bottom: bottomPadding + 20),
              width: 134,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
