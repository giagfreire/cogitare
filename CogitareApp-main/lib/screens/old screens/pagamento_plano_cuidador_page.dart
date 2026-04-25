import 'package:flutter/material.dart';
import 'sucesso_pagamento_page.dart';

class PagamentoPlanoCuidadorPage extends StatefulWidget {
  final String nomePlano;
  final String preco;
  final List<String> beneficios;

  const PagamentoPlanoCuidadorPage({
    super.key,
    required this.nomePlano,
    required this.preco,
    required this.beneficios,
  });

  @override
  State<PagamentoPlanoCuidadorPage> createState() =>
      _PagamentoPlanoCuidadorPageState();
}

class _PagamentoPlanoCuidadorPageState
    extends State<PagamentoPlanoCuidadorPage> {
  bool _carregando = false;

  Future<void> _irParaPagamento() async {
    setState(() {
      _carregando = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _carregando = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SucessoPagamentoPage(
          nomePlano: widget.nomePlano,
        ),
      ),
    );
  }

  Color get _corPlano {
    if (widget.nomePlano.toLowerCase() == 'premium') {
      return const Color(0xFF7B61FF);
    }
    return const Color(0xFF2E7D32);
  }

  IconData get _iconePlano {
    if (widget.nomePlano.toLowerCase() == 'premium') {
      return Icons.workspace_premium_rounded;
    }
    return Icons.verified_user_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Pagamento do plano'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPlanoCard(),
              const SizedBox(height: 20),
              _buildResumoPagamento(),
              const SizedBox(height: 20),
              _buildBeneficiosCard(),
              const SizedBox(height: 28),
              _buildBotaoPagamento(),
              const SizedBox(height: 12),
              _buildBotaoVoltar(),
              const SizedBox(height: 16),
              _buildAviso(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Finalizar assinatura',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Revise as informações do plano escolhido antes de seguir para o pagamento.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _corPlano.withOpacity(0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: _corPlano.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _iconePlano,
              color: _corPlano,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nomePlano,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plano selecionado para assinatura',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _corPlano,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              widget.preco,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoPagamento() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLinhaResumo('Plano', widget.nomePlano),
          const SizedBox(height: 12),
          _buildLinhaResumo('Valor', widget.preco),
          const SizedBox(height: 12),
          _buildLinhaResumo('Forma de pagamento', 'Mercado Pago'),
          const Divider(height: 28),
          _buildLinhaResumo(
            'Total',
            widget.preco,
            destaque: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaResumo(String titulo, String valor, {bool destaque = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 14,
            color: destaque ? Colors.black87 : Colors.grey.shade700,
            fontWeight: destaque ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: destaque ? 17 : 14,
            color: destaque ? _corPlano : Colors.black87,
            fontWeight: destaque ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBeneficiosCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'O que está incluso',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          ...widget.beneficios.map(
            (beneficio) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: _corPlano,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      beneficio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoPagamento() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _carregando ? null : _irParaPagamento,
        icon: _carregando
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.payment_rounded),
        label: Text(
          _carregando ? 'Processando...' : 'Pagar com Mercado Pago',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009EE3),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoVoltar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _carregando ? null : () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Voltar',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildAviso() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFE082),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF9A825),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Após confirmar o pagamento, o plano poderá ser atualizado automaticamente no app.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}