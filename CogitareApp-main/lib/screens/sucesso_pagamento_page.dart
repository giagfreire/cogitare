import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class SucessoPagamentoPage extends StatefulWidget {
  final String nomePlano;

  const SucessoPagamentoPage({
    super.key,
    required this.nomePlano,
  });

  @override
  State<SucessoPagamentoPage> createState() =>
      _SucessoPagamentoPageState();
}

class _SucessoPagamentoPageState extends State<SucessoPagamentoPage> {
  bool _carregando = false;

  Future<void> _finalizar() async {
    setState(() {
      _carregando = true;
    });

    try {
      final cuidadorId = await SessionService.getCuidadorId();

      if (cuidadorId == null) {
        throw Exception('Cuidador não identificado');
      }

      final int idPlano = widget.nomePlano.toLowerCase() == 'premium' ? 2 : 1;

      final response = await ServicoApi.post(
        '/api/planos/assinar',
        {
          'idCuidador': cuidadorId,
          'idPlano': idPlano,
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano atualizado com sucesso!')),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        setState(() {
          _carregando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erro ao atualizar plano'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar plano: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 72,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Pagamento realizado com sucesso!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Seu plano ${widget.nomePlano} foi ativado com sucesso no app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              Container(
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
                    _linhaInfo('Plano ativado', widget.nomePlano),
                    const SizedBox(height: 12),
                    _linhaInfo('Status', 'Pagamento aprovado'),
                    const SizedBox(height: 12),
                    _linhaInfo('Acesso', 'Liberado com sucesso'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _finalizar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF35064E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ir para o início',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _carregando
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linhaInfo(String titulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}