import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_cuidador.dart';
import '../services/api_pagamento.dart';
import '../services/servico_autenticacao.dart';

class PlanosCuidadorPage extends StatefulWidget {
  const PlanosCuidadorPage({super.key});

  @override
  State<PlanosCuidadorPage> createState() => _PlanosCuidadorPageState();
}

class _PlanosCuidadorPageState extends State<PlanosCuidadorPage> {
  String? planoSelecionado;

  bool _isLoading = true;
  bool _isSaving = false;

  String planoAtual = 'Básico';
  int limitePlano = 5;
  int usosPlano = 0;

  String statusPagamento = '';
  double valorPagamento = 0;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _loadTudo();
  }

  int? _parseInt(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  double _parseDouble(dynamic valor) {
    if (valor == null) return 0;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString()) ?? 0;
  }

  Future<int?> _getCuidadorId() async {
    final userData = await ServicoAutenticacao.getUserData();

    return _parseInt(
      userData?['IdCuidador'] ??
          userData?['idCuidador'] ??
          userData?['cuidadorId'] ??
          userData?['id'] ??
          userData?['Id'],
    );
  }

  Future<void> _loadTudo() async {
    setState(() => _isLoading = true);

    try {
      final idCuidador = await _getCuidadorId();

      final planoResponse = await ApiCuidador.getStatusPlano();

      if (planoResponse['success'] == true && planoResponse['data'] != null) {
        final data = Map<String, dynamic>.from(planoResponse['data']);

        planoAtual = (data['PlanoAtual'] ?? 'Básico').toString();
        usosPlano = _parseInt(data['UsosPlano']) ?? 0;
        limitePlano = _parseInt(data['LimitePlano']) ??
            (planoAtual.toLowerCase() == 'premium' ? 20 : 5);
      }

      if (idCuidador != null) {
        final pagamentoResponse = await ApiPagamento.buscarStatusPagamento(
          idCuidador: idCuidador,
        );

        if (pagamentoResponse['success'] == true &&
            pagamentoResponse['data'] != null) {
          final pagamento = Map<String, dynamic>.from(
            pagamentoResponse['data'],
          );

          statusPagamento = (pagamento['Status'] ?? '').toString();
          valorPagamento = _parseDouble(pagamento['Valor']);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar plano/pagamento: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> selecionarPlano() async {
    if (planoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um plano para continuar.')),
      );
      return;
    }

    final bool premiumEscolhido = planoSelecionado == 'Premium';
    final bool premiumAtivo = planoAtual.toLowerCase() == 'premium';

    if (premiumEscolhido && premiumAtivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já está no Plano Premium.')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      final idCuidador = await _getCuidadorId();

      if (idCuidador == null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível identificar o cuidador logado.'),
          ),
        );
        return;
      }

      final response = await ApiPagamento.criarPreferencia(
        idCuidador: idCuidador,
        idPlano: premiumEscolhido ? 2 : 1,
        titulo: premiumEscolhido
            ? 'Plano Premium Cogitare'
            : 'Plano Básico Cogitare',
        preco: premiumEscolhido ? 59.90 : 29.90,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response['success'] == true) {
        await _loadTudo();

        final url = response['data']?['init_point']?.toString() ??
            response['data']?['sandbox_init_point']?.toString();

        if (url == null || url.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link de pagamento não encontrado.')),
          );
          return;
        }

        final abriu = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );

        if (!abriu && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o Mercado Pago.')),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Depois do pagamento, volte para esta tela e toque em atualizar.',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ?? 'Erro ao iniciar pagamento.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar pagamento: $e')),
      );
    }
  }

  Widget _statusPagamentoBox() {
    if (statusPagamento.isEmpty) return const SizedBox.shrink();

    Color cor = Colors.orange;
    IconData icon = Icons.schedule;
    String texto = 'Pagamento pendente';

    if (statusPagamento == 'approved') {
      cor = Colors.green;
      icon = Icons.check_circle_outline;
      texto = 'Pagamento aprovado';
    } else if (statusPagamento == 'rejected' ||
        statusPagamento == 'cancelled' ||
        statusPagamento == 'refunded') {
      cor = Colors.redAccent;
      icon = Icons.error_outline;
      texto = 'Pagamento não aprovado';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              valorPagamento > 0
                  ? '$texto • R\$ ${valorPagamento.toStringAsFixed(2).replaceAll('.', ',')}'
                  : texto,
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planoAtualBox() {
    final bool premium = planoAtual.toLowerCase() == 'premium';
    final int restantes = (limitePlano - usosPlano) < 0 ? 0 : limitePlano - usosPlano;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: premium ? verde : roxo,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seu plano atual',
            style: TextStyle(
              color: premium ? Colors.black87 : Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            premium ? 'Premium' : 'Básico',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: premium ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Uso: $usosPlano de $limitePlano contatos',
            style: TextStyle(
              color: premium ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: limitePlano <= 0 ? 0 : (usosPlano / limitePlano).clamp(0, 1),
            minHeight: 8,
            backgroundColor: premium ? Colors.black12 : Colors.white24,
            valueColor: AlwaysStoppedAnimation(premium ? Colors.black : rosa),
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 8),
          Text(
            'Restantes: $restantes contato(s)',
            style: TextStyle(
              color: premium ? Colors.black87 : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planoCard({
    required String titulo,
    required String preco,
    required String valor,
    required Color cor,
    required List<String> beneficios,
    bool destaque = false,
  }) {
    final bool selecionado = planoSelecionado == valor;
    final bool ativo = planoAtual.toLowerCase() == valor.toLowerCase();

    return GestureDetector(
      onTap: () => setState(() => planoSelecionado = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selecionado ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: cor.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ativo || destaque)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ativo ? 'Plano ativo' : 'Mais escolhido',
                  style: const TextStyle(
                    color: roxo,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Radio<String>(
                  value: valor,
                  groupValue: planoSelecionado,
                  activeColor: Colors.white,
                  fillColor: WidgetStateProperty.all(Colors.white),
                  onChanged: (value) {
                    setState(() => planoSelecionado = value);
                  },
                ),
              ],
            ),
            Text(
              preco,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            ...beneficios.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.white),
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
    final bool premiumAtivo = planoAtual.toLowerCase() == 'premium';
    final bool premiumSelecionado = planoSelecionado == 'Premium';

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Meu plano'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loadTudo,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTudo,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _statusPagamentoBox(),
                  _planoAtualBox(),
                  _planoCard(
                    titulo: 'Plano Básico',
                    preco: 'R\$ 29,90',
                    valor: 'Basico',
                    cor: roxo,
                    beneficios: const [
                      'Até 5 contatos liberados',
                      'Acesso às vagas disponíveis',
                      'Perfil ativo no app',
                    ],
                  ),
                  _planoCard(
                    titulo: 'Plano Premium',
                    preco: 'R\$ 59,90',
                    valor: 'Premium',
                    cor: rosa,
                    destaque: true,
                    beneficios: const [
                      'Até 20 contatos liberados',
                      'Destaque no app',
                      'Maior chance de ser encontrado',
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 100),
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
                            'Após o pagamento aprovado, toque no ícone de atualizar para sincronizar seu plano.',
                            style: TextStyle(
                              color: roxo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              onPressed: _isSaving || (premiumAtivo && premiumSelecionado)
                  ? null
                  : selecionarPlano,
              style: ElevatedButton.styleFrom(
                backgroundColor: rosa,
                disabledBackgroundColor: rosa.withOpacity(0.45),
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
                  : Text(
                      premiumAtivo && premiumSelecionado
                          ? 'Plano Premium ativo'
                          : 'Ir para pagamento',
                      style: const TextStyle(
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