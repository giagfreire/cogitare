import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_pagamento.dart';
import '../services/servico_autenticacao.dart';

class PlanosCuidadorPage extends StatefulWidget {
  const PlanosCuidadorPage({super.key});

  @override
  State<PlanosCuidadorPage> createState() => _PlanosCuidadorPageState();
}

class _PlanosCuidadorPageState extends State<PlanosCuidadorPage> {
  String? planoSelecionado;
  bool _isSaving = false;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  Future<void> selecionarPlano() async {
    if (planoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um plano para continuar.'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final userData = await ServicoAutenticacao.getUserData();
      final dynamic idDinamico =
          userData?['IdCuidador'] ??
          userData?['idCuidador'] ??
          userData?['cuidadorId'] ??
          userData?['id'] ??
          userData?['Id'];

      final int? idCuidador = _parseInt(idDinamico);

      if (idCuidador == null) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível identificar o cuidador logado.'),
          ),
        );
        return;
      }

      final bool premium = planoSelecionado == 'Premium';

      final response = await ApiPagamento.criarPreferencia(
        idCuidador: idCuidador,
        idPlano: premium ? 2 : 1,
        titulo: premium
            ? 'Plano Premium Cogitare'
            : 'Plano Básico Cogitare',
        preco: premium ? 59.90 : 29.90,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (response['success'] == true) {
        final String? url =
            response['data']?['init_point']?.toString() ??
            response['data']?['sandbox_init_point']?.toString();

        if (url == null || url.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link de pagamento não encontrado.'),
            ),
          );
          return;
        }

        final uri = Uri.parse(url);
        final abriu = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!abriu && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir o Mercado Pago.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ??
                  'Erro ao iniciar o pagamento.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar pagamento: $e'),
        ),
      );
    }
  }

  int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  Widget _planoCard({
    required String titulo,
    required String preco,
    required String descricao,
    required List<String> beneficios,
    required bool destaque,
    required String valor,
    required Color corPrincipal,
    bool textoEscuro = false,
  }) {
    final bool selecionado = planoSelecionado == valor;
    final textColor = textoEscuro ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() {
          planoSelecionado = valor;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: corPrincipal,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selecionado ? rosa : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: corPrincipal.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (destaque)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Mais escolhido',
                  style: TextStyle(
                    color: roxo,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (destaque) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Radio<String>(
                  value: valor,
                  groupValue: planoSelecionado,
                  activeColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (selecionado) return Colors.white;
                    return textColor.withOpacity(0.8);
                  }),
                  onChanged: (value) {
                    setState(() {
                      planoSelecionado = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              preco,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 14),
            ...beneficios.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: textColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Meu plano'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: roxo,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: const Text(
              'Escolha o plano ideal para acessar oportunidades no app e ampliar sua visibilidade.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _planoCard(
                  titulo: 'Plano Básico',
                  preco: 'R\$ 29,90',
                  descricao: 'Ideal para começar no app.',
                  beneficios: const [
                    'Até 5 contatos liberados',
                    'Acesso às vagas',
                    'Perfil ativo no app',
                  ],
                  destaque: false,
                  valor: 'Basico',
                  corPrincipal: roxo,
                ),
                _planoCard(
                  titulo: 'Plano Premium',
                  preco: 'R\$ 59,90',
                  descricao: 'Mais visibilidade e mais oportunidades.',
                  beneficios: const [
                    'Até 20 contatos liberados',
                    'Destaque no app',
                    'Maior chance de ser encontrado',
                  ],
                  destaque: true,
                  valor: 'Premium',
                  corPrincipal: rosa,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: verde.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: roxo),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Após o pagamento aprovado, seu plano será atualizado no app.',
                          style: TextStyle(
                            color: roxo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : selecionarPlano,
              style: ElevatedButton.styleFrom(
                backgroundColor: rosa,
                disabledBackgroundColor: rosa.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Ir para pagamento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}