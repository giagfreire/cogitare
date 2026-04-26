import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/login_controller.dart';
import '../utils/navigation_utils.dart';
import 'tela_cadastro_cuidador.dart';

class TelaLoginUnificada extends StatefulWidget {
  static const route = '/login-unificado';
  const TelaLoginUnificada({super.key});

  @override
  State<TelaLoginUnificada> createState() => _TelaLoginUnificadaState();
}

class _TelaLoginUnificadaState extends State<TelaLoginUnificada> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? selectedUserType;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header com logo horizontal e botão voltar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      NavigationUtils.navigateToOnboardingLastPage(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF424242),
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.only(right: 200),
                      child: Image.asset(
                        'assets/images/logo_cogitare_horizontal.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mensagem de boas-vindas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cuidado com carinho.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Card de login
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE3F2FD),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo E-mail
                    const Text(
                      'E-mail',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Digite seu e-mail',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Campo Tipo de Usuário
                    const Text(
                      'Tipo de usuário',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedUserType,
                          hint: Text(
                            'Selecione seu tipo',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'cuidador',
                              child: Text('Cuidador'),
                            ),
                            DropdownMenuItem(
                              value: 'responsavel',
                              child: Text('Responsável'),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedUserType = newValue;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Campo Senha
                    const Text(
                      'Senha',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Digite sua senha',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botão Entrar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28323C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
const Center(
  child: Text(
    'Entre com seu e-mail e senha para continuar.',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 13,
      color: Colors.grey,
    ),
  ),
),

const SizedBox(height: 16),

Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(context, TelaCadastroCuidador.route);
        },
        child: const Text('Sou cuidador'),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/cadastro-responsavel');
        },
        child: const Text('Sou responsável'),
      ),
    ),
  ],
), ],
                ),
              ),
            ),

            // Home indicator
            Container(
              margin: EdgeInsets.only(bottom: bottomPadding + 20),
              width: 134,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
Future<void> _handleLogin() async {
  final validationError = LoginController.validateFields(
    email: emailController.text,
    senha: passwordController.text,
    userType: selectedUserType,
  );

  if (validationError != null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(validationError),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final result = await LoginController.performLogin(
      email: emailController.text.trim(),
      senha: passwordController.text,
      userType: selectedUserType!,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      HapticFeedback.lightImpact();

      // NÃO mostra snackbar aqui antes/depois usando o contexto antigo.
      // Só navega para o dashboard.
      LoginController.navigateToDashboard(
        context,
        result['userType'],
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Erro no login'),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro de conexão: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}