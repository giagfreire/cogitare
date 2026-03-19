import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class DashboardCuidador extends StatefulWidget {
  static const route = '/dashboard-cuidador';

  const DashboardCuidador({super.key});

  @override
  State<DashboardCuidador> createState() => _DashboardCuidadorState();
}

class _DashboardCuidadorState extends State<DashboardCuidador> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _cuidador;

  @override
  void initState() {
    super.initState();
    _loadCuidador();
  }

  Future<void> _loadCuidador() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cuidadorId = await SessionService.getCuidadorId();

        print('ID DO CUIDADOR: $cuidadorId');

      if (cuidadorId == null) {
        setState(() {
          _errorMessage = 'Não foi possível identificar o cuidador logado.';
          _isLoading = false;
        });
        return;
      }

      final response = await ServicoApi.get('/api/cuidador/$cuidadorId');

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _cuidador = Map<String, dynamic>.from(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao carregar dados do cuidador.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tela de agenda em construção')),
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, '/configuracoes-cuidador');
    }
  }

  String _textoSeguro(dynamic valor, {String fallback = 'Não informado'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  @override
  Widget build(BuildContext context) {
    final nome = _textoSeguro(_cuidador?['Nome'], fallback: 'Cuidador');
    final email = _textoSeguro(_cuidador?['Email']);
    final telefone = _textoSeguro(_cuidador?['Telefone']);
    final cidade = _textoSeguro(_cuidador?['Cidade']);
    final valorHora = _textoSeguro(_cuidador?['ValorHora'], fallback: 'A definir');
    final biografia = _textoSeguro(
      _cuidador?['Biografia'],
      fallback: 'Você ainda não cadastrou uma biografia.',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCuidador,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCuidador,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                child: Icon(Icons.person, size: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Olá, $nome 👋',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Bem-vinda de volta',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Meu Perfil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _infoRow(Icons.email_outlined, 'E-mail', email),
                                const SizedBox(height: 12),
                                _infoRow(Icons.phone_outlined, 'Telefone', telefone),
                                const SizedBox(height: 12),
                                _infoRow(
                                  Icons.location_on_outlined,
                                  'Cidade',
                                  cidade,
                                ),
                                const SizedBox(height: 12),
                                _infoRow(
                                  Icons.attach_money,
                                  'Valor por hora',
                                  valorHora,
                                ),
                                const SizedBox(height: 12),
                                _infoRow(
                                  Icons.verified_user_outlined,
                                  'Status',
                                  'Ativo',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Sobre mim',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              biografia,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Planos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.workspace_premium, size: 32),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Plano atual: Básico',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Veja opções para destacar seu perfil no app.',
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/planos');
                                  },
                                  child: const Text('Ver'),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/configuracoes-cuidador',
                              );
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Configurações'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Config',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}