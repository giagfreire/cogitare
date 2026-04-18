import 'package:flutter/material.dart';
import 'pagamento_plano_cuidador_page.dart';

class PlanosCuidadorPage extends StatefulWidget {
  const PlanosCuidadorPage({super.key});

  @override
  State<PlanosCuidadorPage> createState() => _PlanosCuidadorPageState();
}

class _PlanosCuidadorPageState extends State<PlanosCuidadorPage> {
  String? planoSelecionado;
  bool _isSaving = false;

  Future<void> selecionarPlano() async {
    if (planoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um plano para continuar.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    final bool premium = planoSelecionado == 'Premium';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PagamentoPlanoCuidadorPage(
          nomePlano: premium ? 'Premium' : 'Básico',
          preco: premium ? 'R\$ 59,90' : 'R\$ 29,90',
          beneficios: premium
              ? const [
                  'Até 20 contatos liberados',
                  'Destaque no app',
                  'Maior chance de ser encontrado',
                ]
              : const [
                  'Até 5 contatos liberados',
                  'Acesso às vagas',
                  'Perfil ativo no app',
                ],
        ),
      ),
    );
  }

  Widget _planoCard({
    required String titulo,
    required String preco,
    required String descricao,
    required List<String> beneficios,
    required bool destaque,
    required String valor,
  }) {
    final bool selecionado = planoSelecionado == valor;

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado ? const Color(0xFF35064E) : Colors.grey.shade300,
            width: selecionado ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                  color: const Color(0xFF35064E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Mais escolhido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (destaque) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF35064E),
                    ),
                  ),
                ),
                Radio<String>(
                  value: valor,
                  groupValue: planoSelecionado,
                  activeColor: const Color(0xFF35064E),
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            ...beneficios.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Color(0xFF35064E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
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
      backgroundColor: const Color(0xFFF8F7FB),
      appBar: AppBar(
        title: const Text('Escolher Plano'),
        backgroundColor: const Color(0xFF35064E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF35064E),
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
                    'Até 5 contatos',
                    'Acesso às vagas',
                    'Perfil ativo no app',
                  ],
                  destaque: false,
                  valor: 'Basico',
                ),
                _planoCard(
                  titulo: 'Plano Premium',
                  preco: 'R\$ 59,90',
                  descricao: 'Mais visibilidade e mais oportunidades.',
                  beneficios: const [
                    'Até 20 contatos',
                    'Destaque no app',
                    'Maior chance de ser encontrado',
                  ],
                  destaque: true,
                  valor: 'Premium',
                ),
                const SizedBox(height: 90),
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
                backgroundColor: const Color(0xFF35064E),
                disabledBackgroundColor:
                    const Color(0xFF35064E).withOpacity(0.6),
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
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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