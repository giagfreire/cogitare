import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_cuidador.dart';

class MinhasVagasAceitasPage extends StatefulWidget {
  const MinhasVagasAceitasPage({super.key});

  @override
  State<MinhasVagasAceitasPage> createState() =>
      _MinhasVagasAceitasPageState();
}

class _MinhasVagasAceitasPageState extends State<MinhasVagasAceitasPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _vagas = [];

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void initState() {
    super.initState();
    _carregarVagas();
  }

  Future<void> _carregarVagas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vagas = await ApiCuidador.getMinhasVagasAceitas();

      if (!mounted) return;

      setState(() {
        _vagas = vagas.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erro ao carregar Vagas visualizadas.';
        _isLoading = false;
      });
    }
  }

  Future<void> _atualizar() async {
    await _carregarVagas();
  }

  String _t(dynamic v, {String fallback = 'Não informado'}) {
    if (v == null) return fallback;

    final texto = v.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;

    return texto;
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Não informada';

    try {
      final texto = data.toString().split('T').first;
      final partes = texto.split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }

      return texto;
    } catch (_) {
      return data.toString();
    }
  }

  String _formatarHora(dynamic hora) {
    if (hora == null) return '--:--';

    final texto = hora.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return '--:--';

    return texto.length >= 5 ? texto.substring(0, 5) : texto;
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'A combinar';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return valor.toString();

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _somenteNumeros(String texto) {
    return texto.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _abrirWhatsapp(String numero) async {
    String telefone = _somenteNumeros(numero);

    if (telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp não informado para esta vaga.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!telefone.startsWith('55')) {
      telefone = '55$telefone';
    }

    final uri = Uri.parse('https://wa.me/$telefone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _pegarWhatsapp(Map<String, dynamic> vaga) {
    return _t(
      vaga['WhatsappContato'] ??
          vaga['ContatoWhatsapp'] ??
          vaga['WhatsappResponsavel'] ??
          vaga['WhatsAppResponsavel'] ??
          vaga['Whatsapp'] ??
          vaga['whatsapp'],
      fallback: '',
    );
  }

  Widget _infoLinha(IconData icon, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: roxo.withOpacity(0.75)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _atualizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.check_circle_outline,
            size: 76,
            color: verde,
          ),
          const SizedBox(height: 16),
          const Text(
            'Você ainda não visualizou nenhuma vaga.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: roxo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando você aceitar uma vaga, ela aparecerá aqui com o WhatsApp do responsável liberado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: roxo.withOpacity(0.65),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: rosa,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarVagas,
              style: ElevatedButton.styleFrom(
                backgroundColor: rosa,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardVaga(Map<String, dynamic> vaga) {
    final titulo = _t(vaga['Titulo'], fallback: 'Sem título');
    final cidade = _t(vaga['Cidade']);
    final data = _formatarData(vaga['DataServico']);
    final horaInicio = _formatarHora(vaga['HoraInicio']);
    final horaFim = _formatarHora(vaga['HoraFim']);
    final valor = _formatarValor(vaga['Valor']);

    final responsavel = _t(
      vaga['NomeResponsavel'] ?? vaga['Nome'],
      fallback: 'Responsável não informado',
    );

    final status = _t(
      vaga['StatusAceite'] ?? vaga['Status'],
      fallback: 'Aceita',
    );

    final whatsapp = _pegarWhatsapp(vaga);
    final temWhatsapp = whatsapp.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            rosa.withOpacity(0.24),
            verde.withOpacity(0.24),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.all(1.4),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetalheVagaAceitaPage(vaga: vaga),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: rosa,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rosa.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: verde.withOpacity(0.55),
                        ),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: roxo,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoLinha(Icons.location_on_outlined, 'Cidade: $cidade'),
                const SizedBox(height: 6),
                _infoLinha(Icons.calendar_today_outlined, 'Data: $data'),
                const SizedBox(height: 6),
                _infoLinha(
                  Icons.access_time_outlined,
                  'Horário: $horaInicio às $horaFim',
                ),
                const SizedBox(height: 6),
                _infoLinha(Icons.attach_money_outlined, 'Valor: $valor'),
                const SizedBox(height: 6),
                _infoLinha(Icons.person_outline, 'Responsável: $responsavel'),
                const SizedBox(height: 14),
                if (temWhatsapp)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => _abrirWhatsapp(whatsapp),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Chamar no WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: verde,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: rosa.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'WhatsApp ainda não retornado pelo backend.',
                      style: TextStyle(
                        color: rosa,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver detalhes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: rosa,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: rosa,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListaVagas() {
    return RefreshIndicator(
      onRefresh: _atualizar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _vagas.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [roxo, rosa, verde],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Total de Vagas visualizadas: ${_vagas.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          }

          final vaga = _vagas[index - 1];
          return _buildCardVaga(vaga);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Vagas Visualizadas'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _carregarVagas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: rosa),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _vagas.isEmpty
                  ? _buildEmptyState()
                  : _buildListaVagas(),
    );
  }
}

class DetalheVagaAceitaPage extends StatelessWidget {
  final Map<String, dynamic> vaga;

  const DetalheVagaAceitaPage({
    super.key,
    required this.vaga,
  });

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  String _t(dynamic v, {String fallback = 'Não informado'}) {
    if (v == null) return fallback;

    final texto = v.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;

    return texto;
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Não informada';

    try {
      final texto = data.toString().split('T').first;
      final partes = texto.split('-');

      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }

      return texto;
    } catch (_) {
      return data.toString();
    }
  }

  String _formatarHora(dynamic hora) {
    if (hora == null) return '--:--';

    final texto = hora.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return '--:--';

    return texto.length >= 5 ? texto.substring(0, 5) : texto;
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'A combinar';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return valor.toString();

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _somenteNumeros(String texto) {
    return texto.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _pegarWhatsapp(Map<String, dynamic> vaga) {
    return _t(
      vaga['WhatsappContato'] ??
          vaga['ContatoWhatsapp'] ??
          vaga['WhatsappResponsavel'] ??
          vaga['WhatsAppResponsavel'] ??
          vaga['Whatsapp'] ??
          vaga['whatsapp'],
      fallback: '',
    );
  }

  Future<void> _abrirWhatsapp(BuildContext context, String numero) async {
    String telefone = _somenteNumeros(numero);

    if (telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp não informado para esta vaga.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!telefone.startsWith('55')) {
      telefone = '55$telefone';
    }

    final uri = Uri.parse('https://wa.me/$telefone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _detalheLinha(IconData icon, String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: roxo.withOpacity(0.75)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $valor',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            rosa.withOpacity(0.18),
            verde.withOpacity(0.18),
          ],
        ),
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(1.2),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: rosa,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _t(vaga['Titulo'], fallback: 'Sem título');
    final descricao = _t(vaga['Descricao']);
    final cidade = _t(vaga['Cidade']);
    final bairro = _t(vaga['Bairro']);
    final rua = _t(vaga['Rua']);
    final cep = _t(vaga['Cep']);
    final data = _formatarData(vaga['DataServico']);
    final horaInicio = _formatarHora(vaga['HoraInicio']);
    final horaFim = _formatarHora(vaga['HoraFim']);
    final valor = _formatarValor(vaga['Valor']);

    final nomeIdoso = _t(
      vaga['NomeIdoso'],
      fallback: 'Idoso não informado',
    );

    final sexoIdoso = _t(vaga['SexoIdoso']);
    final nascimentoIdoso = _formatarData(vaga['DataNascimentoIdoso']);
    final cuidadosMedicos = _t(vaga['CuidadosMedicos']);
    final descricaoExtra = _t(vaga['DescricaoExtra']);
    final mobilidade = _t(vaga['Mobilidade']);
    final autonomia = _t(vaga['NivelAutonomia']);

    final responsavel = _t(
      vaga['NomeResponsavel'] ?? vaga['Nome'],
      fallback: 'Responsável não informado',
    );

    final telefone = _t(
      vaga['TelefoneResponsavel'] ?? vaga['Telefone'],
    );

    final email = _t(
      vaga['EmailResponsavel'] ?? vaga['Email'],
    );

    final whatsapp = _pegarWhatsapp(vaga);

    final status = _t(
      vaga['StatusAceite'] ?? vaga['Status'],
      fallback: 'Aceita',
    );

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Detalhes da vaga'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              titulo: titulo,
              children: [
                _detalheLinha(Icons.location_on_outlined, 'Cidade', cidade),
                const SizedBox(height: 10),
                _detalheLinha(Icons.location_city_outlined, 'Bairro', bairro),
                const SizedBox(height: 10),
                _detalheLinha(Icons.signpost_outlined, 'Rua', rua),
                const SizedBox(height: 10),
                _detalheLinha(Icons.markunread_mailbox_outlined, 'CEP', cep),
                const SizedBox(height: 10),
                _detalheLinha(Icons.calendar_today_outlined, 'Data', data),
                const SizedBox(height: 10),
                _detalheLinha(
                  Icons.access_time_outlined,
                  'Horário',
                  '$horaInicio às $horaFim',
                ),
                const SizedBox(height: 10),
                _detalheLinha(Icons.attach_money_outlined, 'Valor', valor),
                const SizedBox(height: 10),
                _detalheLinha(Icons.info_outline, 'Status', status),
              ],
            ),
            _card(
              titulo: 'Descrição da vaga',
              children: [
                Text(
                  descricao,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            _card(
              titulo: 'Dados do idoso',
              children: [
                _detalheLinha(Icons.elderly_outlined, 'Nome', nomeIdoso),
                const SizedBox(height: 10),
                _detalheLinha(Icons.wc_outlined, 'Sexo', sexoIdoso),
                const SizedBox(height: 10),
                _detalheLinha(
                  Icons.cake_outlined,
                  'Nascimento',
                  nascimentoIdoso,
                ),
                const SizedBox(height: 10),
                _detalheLinha(
                  Icons.medical_services_outlined,
                  'Cuidados médicos',
                  cuidadosMedicos,
                ),
                const SizedBox(height: 10),
                _detalheLinha(
                  Icons.accessibility_new_outlined,
                  'Mobilidade',
                  mobilidade,
                ),
                const SizedBox(height: 10),
                _detalheLinha(
                  Icons.health_and_safety_outlined,
                  'Nível de autonomia',
                  autonomia,
                ),
                const SizedBox(height: 10),
                _detalheLinha(
                  Icons.description_outlined,
                  'Observações',
                  descricaoExtra,
                ),
              ],
            ),
            _card(
              titulo: 'Responsável',
              children: [
                _detalheLinha(Icons.person_outline, 'Nome', responsavel),
                const SizedBox(height: 10),
                _detalheLinha(Icons.chat_outlined, 'WhatsApp', whatsapp),
                const SizedBox(height: 10),
                _detalheLinha(Icons.phone_outlined, 'Telefone', telefone),
                const SizedBox(height: 10),
                _detalheLinha(Icons.email_outlined, 'E-mail', email),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: whatsapp.isEmpty
                        ? null
                        : () => _abrirWhatsapp(context, whatsapp),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Chamar no WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: verde,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}