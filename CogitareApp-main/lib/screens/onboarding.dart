import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'selecao_papel.dart';
import '../services/servico_autenticacao.dart';
import '../utils/navigation_utils.dart';

class OnboardingScreen extends StatefulWidget {
  final bool skipToLastPage;

  const OnboardingScreen({super.key, this.skipToLastPage = false});

  static String? get route => null;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  late int _currentPage;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Conecte-se a cuidadores de confiança",
      "subtitle":
          "Encontre profissionais verificados perto de você, com experiência e avaliações reais.",
      "benefits": [
        "Perfis verificados e com certificados.",
        "Avaliações e comentários de famílias.",
        "Mensagem direta com os cuidadores pelo app."
      ],
      "image": "assets/images/onboarding1.png"
    },
    {
      "title": "Organize a rotina e a saude",
      "subtitle":
          "Lembretes de remédio, agendamentos e o histórico de atendimentos em um só lugar.",
      "benefits": [
        "Lembretes automáticos para medicação e consultas.",
        "Agenda com dias, horários e quem vai cuidar.",
        "Histórico de serviços e anotações do cuidador."
      ],
      "image": "assets/images/onboarding2.png"
    },
    {
      "title": "Converse, combine e pague com segurança",
      "subtitle": "Chat seguro, propostas fáceis e recibos organizados.",
      "benefits": [
        "Chat direto com notificações em tempo real.",
        "Envie proposta, aceite ou recuse em um toque.",
        "Histórico financeiro e comprovantes de pagamento."
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: MaterialScrollBehavior().copyWith(
            dragDevices: const <PointerDeviceKind>{
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: onboardingData.length + 1,
            itemBuilder: (context, index) {
              if (index == onboardingData.length) {
                return _buildWelcomeScreen();
              }

              final data = onboardingData[index];

              return Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              data["title"] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF28323C),
                              ),
                            ),
                            if (data["subtitle"] != null &&
                                (data["subtitle"] as String).isNotEmpty)
                              Text(
                                data["subtitle"] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                              ),
                            if (data["benefits"] != null &&
                                (data["benefits"] as List).isNotEmpty) ...[
                              const SizedBox(height: 24),
                              ...((data["benefits"] as List).map(
                                (benefit) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "• ",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          benefit as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                            ],
                            if (data["image"] != null)
                              SizedBox(
                                width: double.infinity,
                                child: Image.asset(
                                  data["image"] as String,
                                  fit: BoxFit.fitWidth,
                                ),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          SizedBox(
            height: 40,
            child: Image.asset(
              'assets/images/logo_cogitare_horizontal.png',
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              _pageController.animateToPage(
                onboardingData.length,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Pular',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding + 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          onboardingData.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildWelcomeHeader(),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 280,
                height: 350,
                child: Image.asset(
                  'assets/images/idosa_lendo.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          SizedBox(
            height: 40,
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
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding + 40),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await ServicoAutenticacao.markOnboardingSeen();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SelecaoPapel()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28323C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Vamos começar!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              children: [
                const TextSpan(text: "Já tem uma conta? "),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      NavigationUtils.navigateToLogin(context);
                    },
                    child: const Text(
                      "Faça login.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF28323C),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              children: [
                TextSpan(text: "Ao prosseguir você concorda com os "),
                TextSpan(
                  text: "Termos de Uso",
                  style: TextStyle(decoration: TextDecoration.underline),
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