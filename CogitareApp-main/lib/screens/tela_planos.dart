import 'package:flutter/material.dart';

class TelaPlanos extends StatelessWidget {
  static const route = '/planos';

  const TelaPlanos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _planoCard(
              titulo: 'Plano Básico',
              descricao: 'Seu perfil aparece normalmente no app.',
              preco: 'Grátis',
            ),
            const SizedBox(height: 16),
            _planoCard(
              titulo: 'Plano Premium',
              descricao: 'Mais visibilidade e destaque para seu perfil.',
              preco: 'R\$ 29,90/mês',
            ),
          ],
        ),
      ),
    );
  }

  Widget _planoCard({
    required String titulo,
    required String descricao,
    required String preco,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(descricao),
            const SizedBox(height: 12),
            Text(
              preco,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Selecionar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}