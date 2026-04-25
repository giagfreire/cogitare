import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/servico_autenticacao.dart';
import 'editar_perfil_responsavel_page.dart';

class PerfilResponsavelPage extends StatefulWidget {
  const PerfilResponsavelPage({super.key});

  @override
  State<PerfilResponsavelPage> createState() => _PerfilResponsavelPageState();
}

class _PerfilResponsavelPageState extends State<PerfilResponsavelPage> {
  bool isLoading = true;
  Map<String, dynamic> responsavel = {};

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    carregarPerfil();
  }

  Future<void> carregarPerfil() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final token = await ServicoAutenticacao.getToken();

      if (token != null && token.isNotEmpty) {
        ApiClient.setToken(token);
      }

      final response = await ApiClient.get('/api/responsavel/perfil');
      final data = response['data'];

      if (response['success'] == true && data != null) {
        if (data is Map<String, dynamic>) {
          responsavel = data;
        } else if (data is Map) {
          responsavel = Map<String, dynamic>.from(data);
        } else if (data is List && data.isNotEmpty) {
          responsavel = Map<String, dynamic>.from(data.first);
        } else {
          responsavel = {};
        }
      } else {
        responsavel = {};
      }
    } catch (e) {
      debugPrint('ERRO AO CARREGAR PERFIL RESPONSAVEL: $e');
      responsavel = {};
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  String textoSeguro(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String fotoSegura(dynamic valor) {
    if (valor == null) return '';

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return '';

    if (texto.startsWith('http://') ||
        texto.startsWith('https://') ||
        texto.startsWith('data:image')) {
      return texto;
    }

    return '';
  }

  String formatarData(dynamic data) {
    if (data == null) return 'Não informado';

    final texto = data.toString();

    if (texto.length >= 10 && texto.contains('-')) {
      final partes = texto.substring(0, 10).split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    }

    return textoSeguro(data);
  }

  Future<void> abrirEditarPerfil() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditarPerfilResponsavelPage(),
      ),
    );

    if (result == true) {
      await carregarPerfil();
    }
  }

  Widget buildAvatar(String fotoUrl) {
    if (fotoUrl.startsWith('data:image')) {
      try {
        final base64Limpo = fotoUrl.split(',').last;

        return CircleAvatar(
          radius: 52,
          backgroundColor: Colors.white24,
          backgroundImage: MemoryImage(base64Decode(base64Limpo)),
        );
      } catch (_) {}
    }

    if (fotoUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: Colors.white24,
        backgroundImage: NetworkImage(fotoUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    return const CircleAvatar(
      radius: 52,
      backgroundColor: Colors.white24,
      child: Icon(
        Icons.person,
        size: 52,
        color: Colors.white,
      ),
    );
  }

  Widget tituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              color: rosa,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: roxo,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoCard({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: roxo.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rosa.withOpacity(0.12),
            child: Icon(icon, color: rosa),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: roxo.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    color: roxo,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = textoSeguro(
      responsavel['Nome'] ?? responsavel['nome'],
      fallback: 'Responsável',
    );

    final email = textoSeguro(
      responsavel['Email'] ?? responsavel['email'],
    );

    final telefone = textoSeguro(
      responsavel['Telefone'] ?? responsavel['telefone'],
    );

    final cpf = textoSeguro(
      responsavel['Cpf'] ?? responsavel['cpf'],
    );

    final dataNascimento = formatarData(
      responsavel['DataNascimento'] ?? responsavel['dataNascimento'],
    );

    final fotoUrl = fotoSegura(
      responsavel['FotoUrl'] ?? responsavel['fotoUrl'],
    );

    final cep = textoSeguro(responsavel['Cep'] ?? responsavel['cep']);
    final cidade = textoSeguro(responsavel['Cidade'] ?? responsavel['cidade']);
    final estado = textoSeguro(responsavel['Estado'] ?? responsavel['estado']);
    final bairro = textoSeguro(responsavel['Bairro'] ?? responsavel['bairro']);
    final rua = textoSeguro(responsavel['Rua'] ?? responsavel['rua']);
    final numero = textoSeguro(responsavel['Numero'] ?? responsavel['numero']);
    final complemento = textoSeguro(
      responsavel['Complemento'] ?? responsavel['complemento'],
    );

    final contatoWhatsapp = textoSeguro(
      responsavel['ContatoWhatsapp'] ?? responsavel['contatoWhatsapp'],
    );

    final contatoTelefone = textoSeguro(
      responsavel['ContatoTelefone'] ?? responsavel['contatoTelefone'],
    );

    final contatoEmail = textoSeguro(
      responsavel['ContatoEmail'] ?? responsavel['contatoEmail'],
    );

    final preferenciaContato = textoSeguro(
      responsavel['PreferenciaContato'] ?? responsavel['preferenciaContato'],
    );

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: rosa))
          : RefreshIndicator(
              onRefresh: carregarPerfil,
              color: rosa,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [roxo, rosa],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      children: [
                        buildAvatar(fotoUrl),
                        const SizedBox(height: 14),
                        Text(
                          nome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: abrirEditarPerfil,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text(
                              'Editar perfil',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  tituloSecao('Dados pessoais'),

                  buildInfoCard(
                    icon: Icons.person_outline,
                    titulo: 'Nome completo',
                    valor: nome,
                  ),

                  buildInfoCard(
                    icon: Icons.badge_outlined,
                    titulo: 'CPF',
                    valor: cpf,
                  ),

                  buildInfoCard(
                    icon: Icons.calendar_today_outlined,
                    titulo: 'Data de nascimento',
                    valor: dataNascimento,
                  ),

                  buildInfoCard(
                    icon: Icons.phone_outlined,
                    titulo: 'Telefone',
                    valor: telefone,
                  ),

                  buildInfoCard(
                    icon: Icons.email_outlined,
                    titulo: 'E-mail',
                    valor: email,
                  ),

                  tituloSecao('Endereço'),

                  buildInfoCard(
                    icon: Icons.location_searching,
                    titulo: 'CEP',
                    valor: cep,
                  ),

                  buildInfoCard(
                    icon: Icons.location_city_outlined,
                    titulo: 'Cidade',
                    valor: cidade,
                  ),

                  buildInfoCard(
                    icon: Icons.map_outlined,
                    titulo: 'Estado',
                    valor: estado,
                  ),

                  buildInfoCard(
                    icon: Icons.apartment_outlined,
                    titulo: 'Bairro',
                    valor: bairro,
                  ),

                  buildInfoCard(
                    icon: Icons.signpost_outlined,
                    titulo: 'Rua',
                    valor: rua,
                  ),

                  buildInfoCard(
                    icon: Icons.numbers_outlined,
                    titulo: 'Número',
                    valor: numero,
                  ),

                  buildInfoCard(
                    icon: Icons.add_location_alt_outlined,
                    titulo: 'Complemento',
                    valor: complemento,
                  ),

                  tituloSecao('Contato para cuidadores'),

                  buildInfoCard(
                    icon: Icons.chat_outlined,
                    titulo: 'WhatsApp',
                    valor: contatoWhatsapp,
                  ),

                  buildInfoCard(
                    icon: Icons.call_outlined,
                    titulo: 'Telefone de contato',
                    valor: contatoTelefone,
                  ),

                  buildInfoCard(
                    icon: Icons.alternate_email,
                    titulo: 'E-mail de contato',
                    valor: contatoEmail,
                  ),

                  buildInfoCard(
                    icon: Icons.contact_phone_outlined,
                    titulo: 'Preferência de contato',
                    valor: preferenciaContato,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}