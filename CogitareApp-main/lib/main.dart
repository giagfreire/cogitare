import 'package:flutter/material.dart';

// WIDGETS
import 'widgets/verificador_inicial.dart';

// TELAS
import 'screens/onboarding.dart';
import 'screens/selecao_papel.dart';
import 'screens/tela_login_unificada.dart';
import 'screens/tela_cadastro_cuidador.dart';
import 'screens/tela_cadastro_responsavel.dart';
import 'screens/tela_cadastro_idoso.dart';
import 'screens/tela_sucesso.dart';
import 'screens/tela_editar_perfil_cuidador.dart';
import 'screens/tela_termos_condicoes.dart';
import 'screens/planos_cuidador_page.dart';
import 'screens/perfil_cuidador_page.dart';

// DASHBOARDS
import 'screens/tela_dashboard_responsavel.dart';
import 'screens/dashboard_cuidador.dart';

// NOVAS TELAS 🔥
import 'screens/tela_configuracoes_cuidador.dart';
import 'screens/tela_planos.dart';

// OUTRAS TELAS
import 'screens/tela_cuidadores_proximos.dart';
import 'screens/tela_propostas_detalhadas.dart';
import 'screens/tela_historico-servicos.dart';
import 'screens/tela_propostas_recebidas.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CogitareApp());
}

class CogitareApp extends StatelessWidget {
  const CogitareApp({super.key});

  static const Color brandGreen = Color(0xFFA5C04E);
  static const Color brandNavy = Color(0xFF28323C);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: brandGreen),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F7F8),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFD9E7B5).withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Colors.black54),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandNavy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      chipTheme: const ChipThemeData(
        color: WidgetStatePropertyAll(Color(0xFF7FAE3E)),
        labelStyle: TextStyle(color: Colors.white),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COGITARE',
      theme: theme,

      /// 🔥 TELA INICIAL
      home: const VerificadorInicial(),

      /// 🔥 ROTAS
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/selecao-papel': (_) => const SelecaoPapel(),
        TelaEditarPerfilCuidador.route: (_) => const TelaEditarPerfilCuidador(),
        TelaTermosCondicoes.route: (_) => const TelaTermosCondicoes(),
        '/planos': (context) => const PlanosCuidadorPage(),

        // LOGIN
        TelaLoginUnificada.route: (_) => const TelaLoginUnificada(),

        PerfilCuidadorPage.route: (context) => const PerfilCuidadorPage(),

        // CADASTROS
        TelaCadastroCuidador.route: (_) => const TelaCadastroCuidador(),
        TelaCadastroResponsavel.route: (_) => const TelaCadastroResponsavel(),
        TelaCadastroIdoso.route: (_) => const TelaCadastroIdoso(),

        // SUCESSO
        TelaSucesso.route: (_) => const TelaSucesso(),

        // DASHBOARDS
        TelaDashboardResponsavel.route: (_) =>
            const TelaDashboardResponsavel(),
        DashboardCuidador.route: (_) => const DashboardCuidador(),

        // NOVAS TELAS 🔥
        TelaConfiguracoesCuidador.route: (_) =>
            const TelaConfiguracoesCuidador(),
        TelaPlanos.route: (_) => const TelaPlanos(),

        // OUTRAS TELAS
        TelaCuidadoresProximos.route: (_) =>
            const TelaCuidadoresProximos(),
        TelaHistoricoServicos.route: (_) =>
            const TelaHistoricoServicos(),
        TelaPropostasRecebidas.route: (_) =>
            const TelaPropostasRecebidas(),
        TelaPropostasDetalhadas.route: (_) =>
            const TelaPropostasDetalhadas(),
      },
    );
  }
}