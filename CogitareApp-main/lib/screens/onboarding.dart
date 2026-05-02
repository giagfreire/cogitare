import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/servico_autenticacao.dart';
import '../utils/navigation_utils.dart';
import 'old screens/selecao_papel.dart';

class OnboardingScreen extends StatefulWidget {
  final bool skipToLastPage;

  const OnboardingScreen({super.key, this.skipToLastPage = false});

  static String? get route => null;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  late int _currentPage;

  static const Color roxo = Color(0xFF42124C);
  static const Color rosa = Color(0xFFFE0472);
  static const Color verde = Color(0xFF8AFF00);
  static const Color fundo = Color(0xFFF7F8FC);

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Cuidado com mais segurança",
      "subtitle": "Encontre cuidadores disponíveis para apoiar a rotina do idoso.",
      "benefits": [
        "Perfis com informações básicas.",
        "Facilidade para encontrar cuidadores.",
        "Mais organização na busca por apoio."
      ],
      "image": "assets/images/onboarding1.png"
    },
    {
      "title": "Organize tudo em um só lugar",
      "subtitle": "Cadastre informações importantes do idoso e gerencie suas vagas.",
      "benefits": [
        "Dados de saúde e mobilidade.",
        "Necessidades do dia a dia.",
        "Controle das vagas criadas."
      ],
      "image": "assets/images/onboarding2.png"
    },
    {
      "title": "Conecte famílias e cuidadores",
      "subtitle": "Publique vagas e encontre profissionais disponíveis.",
      "benefits": [
        "Criação rápida de vagas.",
        "Visualização de oportunidades.",
        "Processo simples e direto."
      ],
      "image": "assets/images/onboarding3.png"
    },
  ];

  @override
  void initState() {
    super.initState();

    final initialPage = widget.skipToLastPage ? onboardingData.length : 0;
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);
  }

  Future<void> _goToLogin() async {
    try {
      NavigationUtils.navigateToLogin(context);
      return;
    } catch (_) {}

    try {
      Navigator.pushNamed(context, '/login');
      return;
    } catch (_) {}

    try {
      Navigator.pushNamed(context, '/entrar');
      return;
    } catch (_) {}

    try {
      Navigator.pushNamed(context, '/tela-login');
      return;
    } catch (_) {}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A rota de login ainda não está configurada no app.'),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Termos de Uso'),
          content: const SingleChildScrollView(
            child: Text(
              'Ao utilizar o aplicativo Cogitare, você concorda em fornecer '
              'informações verdadeiras e atualizadas. Os dados cadastrados '
              'serão utilizados para facilitar a conexão entre responsáveis '
              'e cuidadores, melhorar a organização da rotina de cuidados '
              'e oferecer mais praticidade no uso do app.\n\n'
              'O usuário é responsável pelas informações inseridas no sistema. '
              'A plataforma se compromete a preservar a privacidade e a segurança '
              'dos dados, adotando boas práticas de proteção das informações.\n\n'
              'Ao prosseguir, você declara estar ciente e de acordo com essas condições.',
              style: TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startApp() async {
    await ServicoAutenticacao.markOnboardingSeen();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const SelecaoPapel(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: const <PointerDeviceKind>{
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length + 1,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              if (index == onboardingData.length) {
                return _buildWelcomeScreen(context);
              }

              final data = onboardingData[index];

              return Container(
                color: fundo,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                    color: Colors.black.withOpacity(0.06),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    data["title"] as String,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: roxo,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    data["subtitle"] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ...((data["benefits"] as List).map(
                                    (benefit) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2),
                                            child: Icon(
                                              Icons.check_circle,
                                              size: 18,
                                              color: rosa,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              benefit as String,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.grey.shade800,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Image.asset(
                              data["image"] as String,
                              fit: BoxFit.contain,
                              height: 210,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildDots(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          SizedBox(
            height: 42,
            child: Image.asset(
              'assets/images/logo_cogitare_horizontal.png',
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          if (_currentPage < onboardingData.length)
            TextButton(
              onPressed: () {
                _pageController.animateToPage(
                  onboardingData.length,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: roxo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Pular',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDots(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (_currentPage == onboardingData.length) {
      return const SizedBox.shrink();
    }

    return Container(
      color: fundo,
      padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding + 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          onboardingData.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 28 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index ? rosa : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    return Container(
      color: fundo,
      child: Column(
        children: [
          _buildWelcomeHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ],
                    ),
child: Column(
  children: [
    const Text(
      "Bem-vindo ao Cogitare",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: roxo,
        height: 1.2,
      ),
    ),
    const SizedBox(height: 12),
    Text(
      "Cuidados com mais praticidade, organização e confiança para a sua rotina.",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade700,
        height: 1.45,
      ),
    ),
    const SizedBox(height: 20),
    Image.asset(
      'assets/images/velhas.png',
      height: 200,
      fit: BoxFit.contain,
    ),
  ],
),
),
const SizedBox(height: 20),
],
),
),
),
_buildWelcomeFooter(context),
],
),
);
}
  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          SizedBox(
            height: 42,
            child: Image.asset(
              'assets/images/logo_cogitare_horizontal.png',
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildWelcomeFooter(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 10, 24, bottomPadding + 18),
      color: fundo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: rosa,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Vamos começar!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Já tem uma conta? ",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton(
                onPressed: _goToLogin,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Faça login.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: roxo,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: "Ao prosseguir você concorda com os "),
                TextSpan(
                  text: "Termos de Uso",
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: roxo,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}