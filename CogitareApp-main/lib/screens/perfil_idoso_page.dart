import 'package:flutter/material.dart';

import '../models/idoso.dart';
import '../services/api_idoso.dart';
import 'tela_cadastro_idoso.dart';

class PerfilIdosoPage extends StatefulWidget {
  const PerfilIdosoPage({super.key});

  @override
  State<PerfilIdosoPage> createState() => _PerfilIdosoPageState();
}

class _PerfilIdosoPageState extends State<PerfilIdosoPage> {
  bool _isLoading = true;
  List<Idoso> idosos = [];

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarIdosos();
  }

  Future<void> _carregarIdosos() async {
    setState(() => _isLoading = true);

    final lista = await ApiIdoso.listMeus();

    if (!mounted) return;

    setState(() {
      idosos = lista;
      _isLoading = false;
    });
  }

  Future<void> _abrirCadastro() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaCadastroIdoso()),
    );

    if (result == true) {
      await _carregarIdosos();
    }
  }

  Future<void> _editarIdoso(Idoso idoso) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaCadastroIdoso(idosoParaEditar: idoso),
      ),
    );

    if (result == true) {
      await _carregarIdosos();
    }
  }

  int _idade(DateTime? nascimento) {
    if (nascimento == null) return 0;

    final hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;

    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }

    return idade;
  }

  String _texto(String? valor, {String fallback = 'Não informado'}) {
    if (valor == null || valor.trim().isEmpty) return fallback;
    return valor;
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [roxo, rosa],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.elderly_outlined, color: Colors.white, size: 38),
          SizedBox(height: 12),
          Text(
            'Perfil do idoso',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cadastre e gerencie as informações do idoso para facilitar a criação das vagas.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _botaoPrincipal({
    required String titulo,
    required String subtitulo,
    required IconData icon,
    required VoidCallback onTap,
    required Color cor,
    bool textoEscuro = false,
  }) {
    final textColor = textoEscuro ? Colors.black : Colors.white;

    return Material(
      color: cor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: textoEscuro
                    ? Colors.black.withOpacity(0.08)
                    : Colors.white.withOpacity(0.18),
                child: Icon(icon, color: textColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: textColor.withOpacity(0.78),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardIdoso(Idoso idoso) {
    final idade = _idade(idoso.birthDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roxo.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            idoso.name,
            style: const TextStyle(
              color: roxo,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            idade > 0
                ? '${idoso.gender ?? 'Sexo não informado'} • $idade anos'
                : idoso.gender ?? 'Sexo não informado',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            _texto(idoso.medicalCare, fallback: 'Cuidados médicos não informados.'),
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _editarIdoso(idoso),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: roxo,
                side: const BorderSide(color: roxo),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaIdosos() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (idosos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Nenhum idoso cadastrado ainda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: idosos.map(_cardIdoso).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Perfil do idoso'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _carregarIdosos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            const SizedBox(height: 18),
            _botaoPrincipal(
              titulo: 'Cadastrar idoso',
              subtitulo: 'Adicione um novo perfil de idoso.',
              icon: Icons.add_circle_outline,
              cor: rosa,
              onTap: _abrirCadastro,
            ),
            const SizedBox(height: 22),
            const Text(
              'Idosos cadastrados',
              style: TextStyle(
                color: roxo,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _listaIdosos(),
          ],
        ),
      ),
    );
  }
}