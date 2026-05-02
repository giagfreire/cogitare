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

  Future<void> _excluirIdoso(Idoso idoso) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Excluir perfil',
          style: TextStyle(
            color: roxo,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tem certeza que deseja excluir o perfil de ${idoso.name}? Essa ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final id = idoso.id;

    if (id == null) {
      _mostrarSnack('Não foi possível identificar o idoso.', Colors.red);
      return;
    }

    final response = await ApiIdoso.delete(id);

    if (!mounted) return;

    if (response['success'] == true) {
      _mostrarSnack('Perfil excluído com sucesso.', roxo);
      await _carregarIdosos();
    } else {
      _mostrarSnack(
        response['message'] ?? 'Erro ao excluir perfil.',
        Colors.red,
      );
    }
  }

  void _mostrarSnack(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
      ),
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.elderly_outlined, color: Colors.white, size: 38),
          const SizedBox(height: 12),
          const Text(
            'Perfis dos idosos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veja, edite ou cadastre os perfis dos idosos vinculados a você.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '${idosos.length} perfil(is) cadastrado(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoCadastrar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _abrirCadastro,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Cadastrar novo idoso',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: rosa,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _linhaResumo(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: rosa),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: roxo.withOpacity(0.82),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaInfo(IconData icon, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: rosa),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$titulo: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: roxo,
                    ),
                  ),
                  TextSpan(text: valor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardIdoso(Idoso idoso) {
    final idade = _idade(idoso.birthDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: roxo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: rosa.withOpacity(0.12),
                child: const Icon(Icons.elderly_outlined, color: rosa),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  idoso.name,
                  style: const TextStyle(
                    color: roxo,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Excluir',
                onPressed: () => _excluirIdoso(idoso),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _linhaResumo(
            Icons.cake_outlined,
            idade > 0 ? '$idade anos' : 'Idade não informada',
          ),
          _linhaResumo(
            Icons.wc_outlined,
            'Sexo: ${_texto(idoso.gender)}',
          ),
          _linhaResumo(
            Icons.health_and_safety_outlined,
            'Cuidados médicos: ${_texto(idoso.medicalCare, fallback: 'Não informado')}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirDetalhes(idoso),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver detalhes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: roxo,
                    side: const BorderSide(color: roxo),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _editarIdoso(idoso),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verde,
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirDetalhes(Idoso idoso) {
    final idade = _idade(idoso.birthDate);

    showModalBottomSheet(
      context: context,
      backgroundColor: fundo,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Text(
                  idoso.name,
                  style: const TextStyle(
                    color: roxo,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _secaoDetalhes(
                  titulo: 'Informações principais',
                  children: [
                    _linhaInfo(
                      Icons.cake_outlined,
                      'Idade',
                      idade > 0 ? '$idade anos' : 'Não informada',
                    ),
                    _linhaInfo(Icons.wc_outlined, 'Sexo', _texto(idoso.gender)),
                    _linhaInfo(
                      Icons.accessibility_new_outlined,
                      'Mobilidade',
                      idoso.mobilityId?.toString() ?? 'Não informada',
                    ),
                    _linhaInfo(
                      Icons.health_and_safety_outlined,
                      'Nível de autonomia',
                      idoso.autonomyLevelId?.toString() ?? 'Não informado',
                    ),
                  ],
                ),
                _secaoDetalhes(
                  titulo: 'Cuidados',
                  children: [
                    _linhaInfo(
                      Icons.medical_services_outlined,
                      'Cuidados médicos',
                      _texto(
                        idoso.medicalCare,
                        fallback: 'Cuidados médicos não informados.',
                      ),
                    ),
                    _linhaInfo(
                      Icons.description_outlined,
                      'Descrição extra',
                      _texto(idoso.extraDescription),
                    ),
                  ],
                ),
                _secaoDetalhes(
                  titulo: 'Serviços necessários',
                  children: [
                    _linhaInfo(
                      Icons.medication_outlined,
                      'Usa medicação',
                      _texto(idoso.usaMedicacao),
                    ),
                    _linhaInfo(
                      Icons.notes_outlined,
                      'Detalhes da medicação',
                      _texto(idoso.medicacaoDetalhes),
                    ),
                    _linhaInfo(
                      Icons.bathtub_outlined,
                      'Precisa de banho',
                      _texto(idoso.precisaBanho),
                    ),
                    _linhaInfo(
                      Icons.notes_outlined,
                      'Detalhes do banho',
                      _texto(idoso.banhoDetalhes),
                    ),
                    _linhaInfo(
                      Icons.restaurant_outlined,
                      'Precisa de alimentação',
                      _texto(idoso.precisaAlimentacao),
                    ),
                    _linhaInfo(
                      Icons.notes_outlined,
                      'Detalhes da alimentação',
                      _texto(idoso.alimentacaoDetalhes),
                    ),
                    _linhaInfo(
                      Icons.groups_outlined,
                      'Precisa de acompanhamento',
                      _texto(idoso.precisaAcompanhamento),
                    ),
                    _linhaInfo(
                      Icons.notes_outlined,
                      'Detalhes do acompanhamento',
                      _texto(idoso.acompanhamentoDetalhes),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editarIdoso(idoso);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verde,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _excluirIdoso(idoso);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Excluir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _secaoDetalhes({
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roxo.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: roxo,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _listaIdosos() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(color: rosa),
        ),
      );
    }

    if (idosos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        title: const Text('Perfis dos idosos'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _carregarIdosos,
        color: rosa,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            const SizedBox(height: 18),
            _botaoCadastrar(),
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