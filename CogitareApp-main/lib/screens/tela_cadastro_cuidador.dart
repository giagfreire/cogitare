import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'tela_sucesso.dart';

class TelaCadastroCuidador extends StatefulWidget {
  static const route = '/cadastro-cuidador';

  const TelaCadastroCuidador({super.key});

  @override
  State<TelaCadastroCuidador> createState() => _TelaCadastroCuidadorState();
}

class _TelaCadastroCuidadorState extends State<TelaCadastroCuidador> {
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isBuscandoCep = false;
  bool _aceitouTermos = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();
  final telefoneController = TextEditingController();
  final cpfController = TextEditingController();

  final cepController = TextEditingController();
  final estadoController = TextEditingController();
  final cidadeController = TextEditingController();
  final bairroController = TextEditingController();
  final ruaController = TextEditingController();
  final numeroController = TextEditingController();
  final complementoController = TextEditingController();

  DateTime? dataNascimento;
  String? sexoSelecionado;

  String fumante = 'Não';
  String temFilhos = 'Não';
  String possuiCnh = 'Não';
  String temCarro = 'Não';

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF6F4F8);

  @override
  void dispose() {
    _pageController.dispose();

    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    telefoneController.dispose();
    cpfController.dispose();

    cepController.dispose();
    estadoController.dispose();
    cidadeController.dispose();
    bairroController.dispose();
    ruaController.dispose();
    numeroController.dispose();
    complementoController.dispose();

    super.dispose();
  }

  String _onlyNumbers(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _buscarCep() async {
    final cep = _onlyNumbers(cepController.text.trim());

    if (cep.length != 8 || _isBuscandoCep) return;

    setState(() {
      _isBuscandoCep = true;
    });

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['erro'] == true) {
          _mostrarErro('CEP não encontrado.');
          return;
        }

        setState(() {
          ruaController.text = data['logradouro']?.toString() ?? '';
          bairroController.text = data['bairro']?.toString() ?? '';
          cidadeController.text = data['localidade']?.toString() ?? '';
          estadoController.text = data['uf']?.toString() ?? '';
        });
      } else {
        _mostrarErro('Não foi possível buscar o CEP.');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro ao buscar CEP: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBuscandoCep = false;
        });
      }
    }
  }

  bool _emailValido(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());
  }

  bool _senhaForte(String senha) {
    final temMinimo = senha.length >= 8;
    final temMaiuscula = RegExp(r'[A-Z]').hasMatch(senha);
    final temMinuscula = RegExp(r'[a-z]').hasMatch(senha);
    final temNumero = RegExp(r'[0-9]').hasMatch(senha);
    final temEspecial =
        RegExp(r'[!@#\$&*~%^()_+\-=\[\]{};:"\\|,.<>/?]').hasMatch(senha);

    return temMinimo &&
        temMaiuscula &&
        temMinuscula &&
        temNumero &&
        temEspecial;
  }

  int _idade(DateTime nascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;

    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }

    return idade;
  }

  bool _maiorDeIdade() {
    if (dataNascimento == null) return false;
    return _idade(dataNascimento!) >= 18;
  }

  String? _validarEtapaAtual() {
    if (_currentStep == 0) {
      if (nomeController.text.trim().isEmpty) {
        return 'Informe seu nome completo.';
      }

      if (!_emailValido(emailController.text.trim())) {
        return 'Informe um e-mail válido.';
      }

      if (telefoneController.text.trim().isEmpty) {
        return 'Informe seu telefone.';
      }

      if (_onlyNumbers(cpfController.text).length < 11) {
        return 'Informe um CPF válido.';
      }

      if (sexoSelecionado == null) {
        return 'Selecione o sexo.';
      }

      if (dataNascimento == null) {
        return 'Informe sua data de nascimento.';
      }

      if (!_maiorDeIdade()) {
        return 'Para se cadastrar como cuidador, é necessário ter 18 anos ou mais.';
      }

      if (!_senhaForte(senhaController.text.trim())) {
        return 'A senha deve ter no mínimo 8 caracteres, letra maiúscula, letra minúscula, número e caractere especial.';
      }

      if (confirmarSenhaController.text.trim() != senhaController.text.trim()) {
        return 'As senhas não coincidem.';
      }
    }

    if (_currentStep == 1) {
      if (_onlyNumbers(cepController.text).length != 8 ||
          estadoController.text.trim().isEmpty ||
          cidadeController.text.trim().isEmpty ||
          bairroController.text.trim().isEmpty ||
          ruaController.text.trim().isEmpty ||
          numeroController.text.trim().isEmpty) {
        return 'Preencha o endereço completo.';
      }
    }

    if (_currentStep == 2) {
      if (!_aceitouTermos) {
        return 'Você precisa aceitar os termos para continuar.';
      }
    }

    return null;
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _proximo() {
    final erro = _validarEtapaAtual();

    if (erro != null) {
      _mostrarErro(erro);
      return;
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    } else {
      _finalizarCadastro();
    }
  }

  void _voltar() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _selecionarDataNascimento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          dataNascimento ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dataNascimento = picked;
      });
    }
  }

  Future<void> _finalizarCadastro() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final body = {
        'nome': nomeController.text.trim(),
        'email': emailController.text.trim(),
        'senha': senhaController.text.trim(),
        'telefone': _onlyNumbers(telefoneController.text.trim()),
        'cpf': _onlyNumbers(cpfController.text.trim()),
        'dataNascimento': dataNascimento?.toIso8601String().split('T')[0],
        'sexo': sexoSelecionado,
        'cep': _onlyNumbers(cepController.text.trim()),
        'estado': estadoController.text.trim(),
        'cidade': cidadeController.text.trim(),
        'bairro': bairroController.text.trim(),
        'rua': ruaController.text.trim(),
        'numero': numeroController.text.trim(),
        'complemento': complementoController.text.trim(),
        'fumante': fumante,
        'temFilhos': temFilhos,
        'possuiCnh': possuiCnh,
        'temCarro': temCarro,
        'biografia': '',
        'valorHora': null,
      };

      final response = await ServicoApi.post('/api/cuidador/cadastro', body);

      if (!mounted) return;

      if (response['success'] == true) {
        Navigator.pushReplacementNamed(
          context,
          TelaSucesso.route,
          arguments: 'Cadastro do cuidador realizado com sucesso!',
        );
      } else {
        _mostrarErro(
          response['message']?.toString() ?? 'Erro ao realizar cadastro.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('Erro no cadastro: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      enabled: enabled,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        counterText: '',
      ),
    );
  }

  Widget _titulo(String titulo, String subtitulo) {
    return Column(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: const BoxDecoration(
            color: rosa,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: roxo,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: roxo.withOpacity(0.72),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _requisitoSenha(String texto, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          color: ok ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              color: ok ? Colors.green.shade700 : Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _senhaRequisitos() {
    final senha = senhaController.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roxo.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sua senha precisa ter:',
            style: TextStyle(
              color: roxo,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _requisitoSenha('Mínimo de 8 caracteres', senha.length >= 8),
          const SizedBox(height: 6),
          _requisitoSenha(
            'Uma letra maiúscula',
            RegExp(r'[A-Z]').hasMatch(senha),
          ),
          const SizedBox(height: 6),
          _requisitoSenha(
            'Uma letra minúscula',
            RegExp(r'[a-z]').hasMatch(senha),
          ),
          const SizedBox(height: 6),
          _requisitoSenha(
            'Um número',
            RegExp(r'[0-9]').hasMatch(senha),
          ),
          const SizedBox(height: 6),
          _requisitoSenha(
            'Um caractere especial',
            RegExp(r'[!@#\$&*~%^()_+\-=\[\]{};:"\\|,.<>/?]').hasMatch(senha),
          ),
        ],
      ),
    );
  }

  Widget _radioSimNao({
    required String titulo,
    required String valor,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roxo.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: roxo,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Radio<String>(
                value: 'Sim',
                groupValue: valor,
                activeColor: rosa,
                onChanged: (v) => onChanged(v!),
              ),
              const Text('Sim'),
              const SizedBox(width: 20),
              Radio<String>(
                value: 'Não',
                groupValue: valor,
                activeColor: rosa,
                onChanged: (v) => onChanged(v!),
              ),
              const Text('Não'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepDadosPessoais() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _titulo(
          'Crie sua conta',
          'Informe seus dados principais para começar como cuidador no Cogitare.',
        ),
        const SizedBox(height: 24),
        _campo(
          controller: nomeController,
          label: 'Nome completo',
          hint: 'Digite seu nome completo',
        ),
        const SizedBox(height: 12),
        _campo(
          controller: emailController,
          label: 'E-mail',
          hint: 'Digite seu e-mail',
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _campo(
          controller: telefoneController,
          label: 'Telefone',
          hint: 'Digite seu telefone',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _campo(
          controller: cpfController,
          label: 'CPF',
          hint: 'Digite seu CPF',
          keyboard: TextInputType.number,
          maxLength: 14,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: sexoSelecionado,
          decoration: const InputDecoration(labelText: 'Sexo'),
          items: const [
            DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
            DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
          ],
          onChanged: (value) {
            setState(() {
              sexoSelecionado = value;
            });
          },
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selecionarDataNascimento,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Data de nascimento',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              dataNascimento != null
                  ? DateFormat('dd/MM/yyyy').format(dataNascimento!)
                  : 'Selecione sua data de nascimento',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _campo(
          controller: senhaController,
          label: 'Senha',
          hint: 'Crie uma senha segura',
          obscure: !_senhaVisivel,
          onChanged: (_) => setState(() {}),
          suffixIcon: IconButton(
            icon: Icon(
              _senhaVisivel ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _senhaVisivel = !_senhaVisivel;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        _campo(
          controller: confirmarSenhaController,
          label: 'Confirmar senha',
          hint: 'Digite a senha novamente',
          obscure: !_confirmarSenhaVisivel,
          suffixIcon: IconButton(
            icon: Icon(
              _confirmarSenhaVisivel ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        _senhaRequisitos(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _stepEndereco() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _titulo(
          'Endereço',
          'Digite o CEP para preencher rua, bairro, cidade e estado automaticamente.',
        ),
        const SizedBox(height: 24),
        _campo(
          controller: cepController,
          label: 'CEP',
          hint: 'Digite seu CEP',
          keyboard: TextInputType.number,
          maxLength: 8,
          suffixIcon: _isBuscandoCep
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscarCep,
                ),
          onChanged: (value) {
            if (_onlyNumbers(value).length == 8) {
              _buscarCep();
            }
          },
        ),
        const SizedBox(height: 12),
        _campo(
          controller: estadoController,
          label: 'Estado',
          hint: 'UF',
          enabled: false,
        ),
        const SizedBox(height: 12),
        _campo(
          controller: cidadeController,
          label: 'Cidade',
          hint: 'Cidade',
        ),
        const SizedBox(height: 12),
        _campo(
          controller: bairroController,
          label: 'Bairro',
          hint: 'Bairro',
        ),
        const SizedBox(height: 12),
        _campo(
          controller: ruaController,
          label: 'Rua',
          hint: 'Rua',
        ),
        const SizedBox(height: 12),
        _campo(
          controller: numeroController,
          label: 'Número',
          hint: 'Digite o número',
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 12),
        _campo(
          controller: complementoController,
          label: 'Complemento',
          hint: 'Apto, casa, bloco...',
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _stepPreferencias() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _titulo(
          'Quase pronto',
          'Agora só precisamos de algumas informações rápidas para finalizar.',
        ),
        const SizedBox(height: 24),
        _radioSimNao(
          titulo: 'Você é fumante?',
          valor: fumante,
          onChanged: (value) {
            setState(() {
              fumante = value;
            });
          },
        ),
        _radioSimNao(
          titulo: 'Você tem filhos?',
          valor: temFilhos,
          onChanged: (value) {
            setState(() {
              temFilhos = value;
            });
          },
        ),
        _radioSimNao(
          titulo: 'Possui CNH?',
          valor: possuiCnh,
          onChanged: (value) {
            setState(() {
              possuiCnh = value;
            });
          },
        ),
        _radioSimNao(
          titulo: 'Tem carro?',
          valor: temCarro,
          onChanged: (value) {
            setState(() {
              temCarro = value;
            });
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: verde.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Depois do cadastro, você poderá completar seu perfil com foto, experiência, diplomas, escolaridade e valor por hora.',
            style: TextStyle(
              color: roxo,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _aceitouTermos,
          activeColor: rosa,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Li e aceito os Termos de Uso e Política de Privacidade.',
            style: TextStyle(color: roxo),
          ),
          onChanged: (value) {
            setState(() {
              _aceitouTermos = value ?? false;
            });
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _indicadorEtapas() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final ativo = index == _currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: ativo ? 26 : 8,
          decoration: BoxDecoration(
            color: ativo ? rosa : roxo.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }

  Widget _bottomBar() {
    final isLast = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: roxo.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _indicadorEtapas(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _voltar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: roxo,
                      side: const BorderSide(color: roxo),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_currentStep == 0 ? 'Voltar' : 'Anterior'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _proximo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rosa,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(isLast ? 'Finalizar' : 'Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Cadastro do cuidador'),
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        children: [
          _stepDadosPessoais(),
          _stepEndereco(),
          _stepPreferencias(),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }
}